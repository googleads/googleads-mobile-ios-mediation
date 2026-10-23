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
import ObjectiveC
import UIKit

#if canImport(AdSurgeSDK)
  import AdSurgeSDK
#endif

/// Factory that creates Client.
final class ClientFactory {

  private init() {}

  #if DEBUG
    /// This property will be returned by |createClient| function if set in Debug mode.
    nonisolated(unsafe) static var debugClient: (any Client)?
  #endif

  static func createClient() -> any Client {
    #if DEBUG
      return debugClient ?? ClientImpl()
    #else
      return ClientImpl()
    #endif
  }

}

/// Delegate protocol for banner ad lifecycle events from the AdSurge client.
protocol BannerAdClientDelegate: AnyObject, Sendable {

  /// Called when a banner ad has been successfully loaded.
  func bannerDidLoad()

  /// Called when a banner ad fails to load.
  func bannerDidFailToLoad(with error: any Error)

  /// Called when a banner ad is clicked.
  func bannerDidClick()

  /// Called when a banner ad is hidden.
  func bannerDidHide()

  /// Called when a banner ad generates revenue (impression).
  func bannerDidPayRevenue()

}

protocol Client: AnyObject, Sendable {

  /// Sets user age restriction privacy status.
  func setAgeRestrictedUser(_ ageRestrictedUser: NSNumber?)

  /// Initializes the AdSurge SDK with an application ID.
  func initialize(with appId: String) async throws

  /// Retrieves a bidder token from the AdSurge SDK.
  func getBidderToken() async throws -> String

  /// Returns the SDK version string.
  func version() -> String

  /// Creates a banner ad view for the given ad unit identifier.
  @MainActor func createBannerAdView(for adUnitId: String) -> UIView

  /// Loads a banner ad into the provided banner view.
  @MainActor func loadBannerAd(
    _ bannerView: UIView,
    bidPayload: String,
    viewController: UIViewController?,
    delegate: any BannerAdClientDelegate
  )

}

final class ClientImpl: Client, @unchecked Sendable {

  func setAgeRestrictedUser(_ ageRestrictedUser: NSNumber?) {
    #if canImport(AdSurgeSDK)
      if let ageRestrictedUser {
        AdSurgePrivacyConfiguration().ageRestrictedUser = ageRestrictedUser
      }
    #endif
  }

  func initialize(with appId: String) async throws {
    #if canImport(AdSurgeSDK)
      try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<Void, any Error>) in
        let config = AdSurgeSDKConfig()
        config.appId = appId
        AdSurgeAdSdk.shared().initialize(with: config) { success, error in
          if success {
            continuation.resume()
          } else {
            let nsError: NSError
            if let error {
              nsError = Util.error(
                withDomain: AdSurgeAdapterError.domain,
                code: error.code.rawValue,
                description: error.message)
            } else {
              nsError = AdSurgeAdapterError(
                errorCode: .serverConfigurationMissingApplicationId,
                description: "AdSurge SDK failed to initialize."
              ).toNSError()
            }
            continuation.resume(throwing: nsError)
          }
        }
      }
    #endif
  }

  func getBidderToken() async throws -> String {
    #if canImport(AdSurgeSDK)
      return try await withCheckedThrowingContinuation { continuation in
        AdSurgeAdSdk.shared().getBidderToken { token, error in
          if let token {
            continuation.resume(returning: token)
          } else {
            let nsError: NSError
            if let error {
              nsError = Util.error(
                withDomain: AdSurgeAdapterError.domain,
                code: error.code.rawValue,
                description: error.message)
            } else {
              nsError = AdSurgeAdapterError(
                errorCode: .invalidRTBRequestParameters,
                description: "Failed to retrieve bidder token."
              ).toNSError()
            }
            continuation.resume(throwing: nsError)
          }
        }
      }
    #else
      return ""
    #endif
  }

  func version() -> String {
    #if canImport(AdSurgeSDK)
      return AdSurgeAdSdkVersion
    #else
      return "1.9.2"
    #endif
  }

  @MainActor func createBannerAdView(for adUnitId: String) -> UIView {
    #if canImport(AdSurgeSDK)
      return AdSurgeBannerAdView(adUnitIdentifier: adUnitId)
    #else
      return UIView()
    #endif
  }

  @MainActor func loadBannerAd(
    _ bannerView: UIView,
    bidPayload: String,
    viewController: UIViewController?,
    delegate: any BannerAdClientDelegate
  ) {
    #if canImport(AdSurgeSDK)
      guard let banner = bannerView as? AdSurgeBannerAdView else {
        delegate.bannerDidFailToLoad(
          with: AdSurgeAdapterError(
            errorCode: .internalError,
            description: "Invalid banner view type."
          ).toNSError()
        )
        return
      }
      banner.viewController = viewController
      let bridge = BannerDelegateBridge(delegate: delegate)
      banner.delegate = bridge
      objc_setAssociatedObject(
        banner,
        &bannerBridgeAssociatedKey,
        bridge,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
      let config = AdSurgeAdConfig(adFormat: AdSurgeAdFormat.banner)
      config.payload = bidPayload
      banner.loadAd(config)
    #endif
  }

}

#if canImport(AdSurgeSDK)
  nonisolated(unsafe) private var bannerBridgeAssociatedKey: UInt8 = 0

  private final class BannerDelegateBridge: NSObject, AdSurgeBannerAdDelegate, @unchecked Sendable {

    private weak var delegate: (any BannerAdClientDelegate)?

    init(delegate: any BannerAdClientDelegate) {
      self.delegate = delegate
    }

    func didLoad(_ ad: AdSurgeAd) {
      delegate?.bannerDidLoad()
    }

    func didFailToLoadAd(
      forAdUnitIdentifier adUnitIdentifier: String, withError error: AdSurgeError
    ) {
      let nsError = Util.error(
        withDomain: AdSurgeAdapterError.domain,
        code: error.code.rawValue,
        description: error.message
      )
      delegate?.bannerDidFailToLoad(with: nsError)
    }

    func didHide(_ ad: AdSurgeAd) {
      delegate?.bannerDidHide()
    }

    func didClick(_ ad: AdSurgeAd) {
      delegate?.bannerDidClick()
    }

    func didPayRevenue(for ad: AdSurgeAd) {
      delegate?.bannerDidPayRevenue()
    }

  }
#endif
