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

import Foundation
import GoogleMobileAds

final class NativeAdLoader: NSObject {

  /// The native ad configuration.
  private let adConfiguration: MediationNativeAdConfiguration

  /// The ad event delegate which is used to report native related information to the Google Mobile
  /// Ads SDK.
  private weak var eventDelegate: MediationNativeAdEventDelegate?

  /// The completion handler that needs to be called upon finishing loading an ad.
  private var nativeAdLoadCompletionHandler: ((MediationNativeAd?, NSError?) -> Void)?

  /// The queue for processing an ad load completion.
  private let adLoadCompletionQueue: DispatchQueue

  /// The ad load completion handler the must be run after ad load completion.
  private var adLoadCompletionHandler: GADMediationNativeLoadCompletionHandler?

  private let client: BidMachineClient

  init(
    adConfiguration: MediationNativeAdConfiguration,
    loadCompletionHandler: @escaping GADMediationNativeLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.adLoadCompletionQueue = DispatchQueue(
      label: "com.google.mediationNativeAdLoadCompletionQueue")
    self.client = BidMachineClientFactory.createClient()
    super.init()
  }

  func loadAd() {
    // TODO: implement and make sure to call |nativeAdLoadCompletionHandler| after loading an ad.
  }

  private func handleLoadedAd(_ ad: MediationNativeAd?, error: NSError?) {
    adLoadCompletionQueue.sync {
      guard let adLoadCompletionHandler else { return }
      eventDelegate = adLoadCompletionHandler(ad, error)
      self.adLoadCompletionHandler = nil
    }
  }

}

// MARK: - GADMediationNativeAd

extension NativeAdLoader: MediationNativeAd {

  // TODO: implement computed properties and methods below. Implement more optional methods from
  // |GADMediationNativeAd|, if needed.

  var headline: String? {
    return nil
  }

  var images: [NativeAdImage]? {
    return nil
  }

  var body: String? {
    return nil
  }

  var icon: NativeAdImage? {
    return nil
  }

  var callToAction: String? {
    return nil
  }

  var starRating: NSDecimalNumber? {
    return nil
  }

  var store: String? {
    return nil
  }

  var price: String? {
    return nil
  }

  var advertiser: String? {
    return nil
  }

  var extraAssets: [String: Any]? {
    return nil
  }

  var hasVideoContent: Bool {
    // TODO: implement
    return true
  }

  func handlesUserClicks() -> Bool {
    // TODO: implement
    return true
  }

  func handlesUserImpressions() -> Bool {
    // TODO: implement
    return true
  }

}

// MARK: - <OtherProtocol>
// TODO: extend and implement any other protocol, if any.
