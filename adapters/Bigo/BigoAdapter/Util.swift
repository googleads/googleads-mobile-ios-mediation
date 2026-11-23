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

import BigoADS
import Foundation
import GoogleMobileAds

final class Util {

  private enum MediationConfigurationSettingKey: String {
    case applicationId = "application_id"
    case slotId = "slot_id"
  }

  /// Prints the message with `BigoAdapter` prefix.
  static func log(_ message: String) {
    print("BigoAdapter: \(message)")
  }

  /// Returns a NSError object with the provided information.
  static func error(withDomain domain: String, code: Int, description: String) -> NSError {
    return Foundation.NSError(
      domain: domain,
      code: code,
      userInfo: [
        NSLocalizedDescriptionKey: description,
        NSLocalizedFailureReasonErrorKey: description,
      ])
  }

  /// Retrieves am application ID from the provided mediation server configuration.
  ///
  /// - Throws: BigoAdapterError.serverConfigurationMissingApplicationID if the configuration
  /// contains no publisher ID.
  /// - Returns: A application ID from the configuration. If more than one ID was found, the it returns one
  /// random ID with printed warning message.
  static func applicationId(from config: MediationServerConfiguration) throws(BigoAdapterError)
    -> String
  {
    let applicationIdSet = Set<String>(
      config.credentials.compactMap {
        $0.settings[MediationConfigurationSettingKey.applicationId.rawValue] as? String
      })

    guard let appId = applicationIdSet.randomElement() else {
      throw BigoAdapterError(
        errorCode: .serverConfigurationMissingApplicationID,
        description: "The server configuration is missing an application ID.")
    }

    if applicationIdSet.count > 1 {
      log("Found more than one app ID in the server configuration. Using \(appId)")
    }

    return appId
  }

  /// Retrieves the application ID from the provided ad configuration.
  ///
  /// - Throws: BigoAdapterError.serverConfigurationMissingApplicationID if the ad configuration
  ///   contains no application ID.
  static func applicationId(from config: MediationAdConfiguration) throws(BigoAdapterError)
    -> String
  {
    guard
      let applicationId = config.credentials.settings[
        MediationConfigurationSettingKey.applicationId.rawValue] as? String,
      !applicationId.isEmpty
    else {
      throw BigoAdapterError(
        errorCode: .serverConfigurationMissingApplicationID,
        description: "The ad configuration is missing an application ID.")
    }
    return applicationId
  }

  /// Prepares the BigoADS SDK for a waterfall ad load.
  ///
  /// Applies the publisher's COPPA settings, since Bigo requires privacy settings to be set before
  /// each ad request. Then, if the BigoADS SDK isn't initialized yet, initializes it using the
  /// application ID in the ad configuration.
  ///
  /// Calls `completion` with `nil` once the SDK is ready to load an ad, or with an error if the ad
  /// configuration is invalid (such as a missing application ID).
  static func prepareBigoSdkForWaterfallAdLoad(
    adConfiguration: MediationAdConfiguration,
    client: BigoClient,
    completion: @escaping (NSError?) -> Void
  ) {
    let requestConfiguration = MobileAds.shared.requestConfiguration
    client.setUserConsent(
      with: requestConfiguration.tagForChildDirectedTreatment,
      tagForUnderAgeOfConsent: requestConfiguration.tagForUnderAgeOfConsent,
      ageRestrictedTreatment: requestConfiguration.ageRestrictedTreatment)

    if client.isInitialized() {
      completion(nil)
      return
    }

    do {
      let applicationId = try Self.applicationId(from: adConfiguration)
      client.initialize(with: applicationId, testMode: BigoAdapterExtras.testMode) {
        // The BigoADS SDK may call this completion off the main thread.
        guard !Thread.isMainThread else {
          completion(nil)
          return
        }
        nonisolated(unsafe) let completion = completion
        DispatchQueue.main.async { completion(nil) }
      }
    } catch {
      completion(error.toNSError())
    }
  }

  static func slotId(from config: MediationAdConfiguration) throws(BigoAdapterError) -> String {
    guard
      let slotId = config.credentials.settings[MediationConfigurationSettingKey.slotId.rawValue]
        as? String
    else {
      throw BigoAdapterError(
        errorCode: .invalidAdConfiguration,
        description: "The ad configuration is missing a slot ID.")
    }
    return slotId
  }

  static func NSError(from error: BigoAdError) -> NSError {
    return Self.error(
      withDomain: "com.google.mediation.bigo", code: Int(error.errorCode),
      description: error.errorMsg)
  }

  /// Maps the publisher-requested banner size to the closest Bigo banner size. Falls back to a Bigo
  /// adaptive size if the requested size isn't close to any standard size.
  ///
  /// Used for bidding ad loads, which must not reject banner sizes (go/dont-check-size).
  static func adSize(for adSize: AdSize) -> BigoAdSize {
    // Fall back to adaptive size if size doesn't match any standard size.
    return closestStandardAdSize(for: adSize)
      ?? BigoAdSize.getAdaptiveAdSize(withWidth: adSize.size.width)
  }

  /// Maps the publisher-requested banner size to the closest Bigo banner size for waterfall ad
  /// loads.
  ///
  /// - Throws: BigoAdapterError.unsupportedBannerSize if the requested size isn't close to any
  ///   banner size supported by Bigo.
  static func waterfallAdSize(for adSize: AdSize) throws(BigoAdapterError) -> BigoAdSize {
    guard let bigoAdSize = closestStandardAdSize(for: adSize) else {
      throw BigoAdapterError(
        errorCode: .unsupportedBannerSize,
        description:
          "The requested banner size \(string(for: adSize)) isn't close to any banner "
          + "size supported by Bigo.")
    }
    return bigoAdSize
  }

  /// Returns the standard Bigo banner size closest to `adSize`, or `nil` if `adSize` isn't close to
  /// any standard size.
  private static func closestStandardAdSize(for adSize: AdSize) -> BigoAdSize? {
    let potentials = [
      nsValue(for: AdSizeBanner),
      nsValue(for: AdSizeMediumRectangle),
      nsValue(for: AdSizeLargeBanner),
      nsValue(for: AdSizeLeaderboard),
    ]
    let closestSize = closestValidSizeForAdSizes(original: adSize, possibleAdSizes: potentials)
    if isAdSizeEqualToSize(size1: closestSize, size2: AdSizeBanner) {
      return BigoAdSize.banner()
    } else if isAdSizeEqualToSize(size1: closestSize, size2: AdSizeMediumRectangle) {
      return BigoAdSize.medium_RECTANGLE()
    } else if isAdSizeEqualToSize(size1: closestSize, size2: AdSizeLargeBanner) {
      return BigoAdSize.mobile_LARGE_LEADERBOARD()
    } else if isAdSizeEqualToSize(size1: closestSize, size2: AdSizeLeaderboard) {
      return BigoAdSize.leaderboard()
    }
    return nil
  }

}
