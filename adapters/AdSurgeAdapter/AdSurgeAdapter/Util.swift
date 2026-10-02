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

final class Util {

  private enum MediationConfigurationSettingKey: String {
    case applicationId = "application_id"
    case adUnitId = "ad_unit_id"
  }

  /// Prints the message with `AdSurgeAdapter` prefix.
  static func log(_ message: String) {
    #if DEBUG
      print("AdSurgeAdapter: \(message)")
    #endif
  }

  /// Returns a NSError object with the provided information.
  static func error(withDomain domain: String, code: Int, description: String) -> NSError {
    return NSError(
      domain: domain,
      code: code,
      userInfo: [
        NSLocalizedDescriptionKey: description,
        NSLocalizedFailureReasonErrorKey: description,
      ])
  }

  /// Retrieves an application ID from the provided mediation server configuration.
  ///
  /// - Throws: `AdSurgeAdapterError.serverConfigurationMissingApplicationId` if the configuration
  ///   contains no application ID.
  /// - Returns: An application ID from the configuration. If more than one ID is found, returns
  ///   one and logs a warning.
  static func applicationID(
    from config: MediationServerConfiguration
  ) throws(AdSurgeAdapterError) -> String {
    let appIdSet = Set<String>(
      config.credentials.compactMap {
        $0.settings[MediationConfigurationSettingKey.applicationId.rawValue] as? String
      })

    guard let appId = appIdSet.first else {
      throw AdSurgeAdapterError(
        errorCode: .serverConfigurationMissingApplicationId,
        description: "The server configuration is missing an application ID.")
    }

    if appIdSet.count > 1 {
      log("Found more than one application ID in the server configuration. Using \(appId)")
    }

    return appId
  }

  /// Retrieves an ad unit ID from the provided mediation ad configuration.
  ///
  /// - Throws: `AdSurgeAdapterError.invalidAdConfiguration` if the configuration is missing an
  ///   ad unit ID.
  /// - Returns: An ad unit ID from the configuration.
  static func adUnitID(
    from config: MediationAdConfiguration
  ) throws(AdSurgeAdapterError) -> String {
    guard
      let adUnitId = config.credentials.settings[
        MediationConfigurationSettingKey.adUnitId.rawValue] as? String,
      !adUnitId.isEmpty
    else {
      throw AdSurgeAdapterError(
        errorCode: .invalidAdConfiguration,
        description: "The ad configuration is missing an ad unit ID.")
    }
    return adUnitId
  }

  /// Retrieves a bid response from the provided mediation ad configuration.
  ///
  /// - Throws: `AdSurgeAdapterError.invalidAdConfiguration` if the configuration is missing a
  ///   bid response.
  /// - Returns: A bid response string from the configuration.
  static func bidResponse(
    from config: MediationAdConfiguration
  ) throws(AdSurgeAdapterError) -> String {
    guard let bidResponse = config.bidResponse, !bidResponse.isEmpty else {
      throw AdSurgeAdapterError(
        errorCode: .invalidAdConfiguration,
        description: "The ad configuration is missing a bid response.")
    }
    return bidResponse
  }

  /// Maps a requested `AdSize` to a supported `CGSize`.
  ///
  /// - Throws: `AdSurgeAdapterError.unsupportedBannerSize` if the size cannot be mapped to a
  ///   supported AdSurge banner size.
  /// - Returns: The resolved `CGSize`.
  static func bannerSize(for requestedSize: AdSize) throws(AdSurgeAdapterError) -> CGSize {
    let potentials = [
      nsValue(for: AdSizeBanner),
      nsValue(for: AdSizeMediumRectangle),
    ]
    let closestSize = closestValidSizeForAdSizes(
      original: requestedSize, possibleAdSizes: potentials)
    if isAdSizeEqualToSize(size1: closestSize, size2: AdSizeBanner) {
      return AdSizeBanner.size
    } else if isAdSizeEqualToSize(size1: closestSize, size2: AdSizeMediumRectangle) {
      return AdSizeMediumRectangle.size
    } else {
      throw AdSurgeAdapterError(
        errorCode: .unsupportedBannerSize,
        description:
          "AdSurge does not support the requested banner size: \(string(for: requestedSize))")
    }
  }

  /// Evaluates age-restricted treatment based on `MobileAds.shared.requestConfiguration`.
  ///
  /// - Returns: `@(1)` if child or under age, `@(0)` if explicitly not child/under age, or `nil`
  ///   if unspecified.
  static func isAgeRestrictedUser() -> NSNumber? {
    let requestConfiguration = MobileAds.shared.requestConfiguration
    let isChild = requestConfiguration.tagForChildDirectedTreatment?.boolValue
    let isUnderAge = requestConfiguration.tagForUnderAgeOfConsent?.boolValue
    let ageRestrictedTreatment = requestConfiguration.ageRestrictedTreatment
    if isChild == true || isUnderAge == true || ageRestrictedTreatment == .child {
      return NSNumber(value: 1)
    } else if isChild == false || isUnderAge == false {
      return NSNumber(value: 0)
    }
    return nil
  }

}
