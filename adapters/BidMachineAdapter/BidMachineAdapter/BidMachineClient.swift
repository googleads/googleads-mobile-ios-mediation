// Copyright 2025 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import BidMachine
import GoogleMobileAds
import UIKit

/// Factory that creates Client.
final class BidMachineClientFactory {

  private init() {}

  #if DEBUG
    /// This property will be returned by |createClient| function if set in Debug mode.
    nonisolated(unsafe) static var debugClient: BidMachineClient?
  #endif

  static func createClient() -> BidMachineClient {
    #if DEBUG
      return debugClient ?? BidMachineClientImpl()
    #else
      return ClientImpl()
    #endif
  }

}

protocol BidMachineClient: NSObject {

  /// Returns a version string of BidMachine SDK.
  func version() -> String

  /// Initializes the BidMachine SDK.
  func initialize(with sourceId: String, isTestMode: Bool, isCOPPA: Bool?)

  /// Collects the signals  for the specified ad format.
  func collectSignals(for adFormat: AdFormat, completionHandler: @escaping (String?) -> Void)
    throws(BidMachineAdapterError)

  /// Loads a RTB banner ad.
  func loadRTBBannerAd(
    with bidResponse: String, delegate: BidMachineAdDelegate,
    completionHandler: @escaping (NSError?) -> Void) throws

}

final class BidMachineClientImpl: NSObject, BidMachineClient {

  func version() -> String {
    return BidMachineSdk.sdkVersion
  }

  func initialize(with sourceId: String, isTestMode: Bool, isCOPPA: Bool?) {
    BidMachineSdk.shared.populate {
      $0.withTestMode(isTestMode)
        .withBidLoggingMode(isTestMode)
        .withEventLoggingMode(isTestMode)
        .withLoggingMode(isTestMode)
    }

    if let isCOPPA {
      BidMachineSdk.shared.regulationInfo.populate {
        $0.withCOPPA(isCOPPA)
      }
    }

    BidMachineSdk.shared.initializeSdk(sourceId)
  }

  func collectSignals(for adFormat: AdFormat, completionHandler: @escaping (String?) -> Void)
    throws(BidMachineAdapterError)
  {
    let placementFormat = try adFormat.toPlacementFormat()
    BidMachineSdk.shared.token(with: placementFormat) { signals in
      completionHandler(signals)
    }
  }

  func loadRTBBannerAd(
    with bidResponse: String, delegate: BidMachineAdDelegate,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    let config = try BidMachineSdk.shared.requestConfiguration(.banner)
    config.populate {
      $0.withPayload(bidResponse)
    }

    BidMachineSdk.shared.banner(config) { bidMachineBanner, error in
      guard let bidMachineBanner, error == nil else {
        completionHandler(error as? NSError)
        return
      }

      completionHandler(nil)
      nonisolated(unsafe) let delegate = delegate
      DispatchQueue.main.async {
        bidMachineBanner.delegate = delegate
        bidMachineBanner.controller = Util.rootViewController()
        bidMachineBanner.loadAd()
      }
    }
  }

}

extension AdFormat {

  fileprivate func toPlacementFormat() throws(BidMachineAdapterError) -> PlacementFormat {
    switch self {
    case .banner: return .banner
    case .interstitial: return .interstitial
    case .rewarded: return .rewarded
    case .native: return .native
    default:
      throw BidMachineAdapterError(
        errorCode: .invalidRTBRequestParameters,
        description: "Unsupported ad format. Provided format: \(self).")
    }
  }

}
