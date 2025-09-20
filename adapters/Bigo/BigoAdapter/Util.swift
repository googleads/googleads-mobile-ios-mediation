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

  static func adSize(for adSize: AdSize) throws(BigoAdapterError) -> BigoAdSize {
    if isAdSizeEqualToSize(size1: adSize, size2: AdSizeBanner) {
      return BigoAdSize.banner()
    } else if isAdSizeEqualToSize(size1: adSize, size2: AdSizeMediumRectangle) {
      return BigoAdSize.medium_RECTANGLE()
    } else if isAdSizeEqualToSize(size1: adSize, size2: AdSizeLargeBanner) {
      return BigoAdSize.mobile_LARGE_LEADERBOARD()
    } else if isAdSizeEqualToSize(size1: adSize, size2: AdSizeLeaderboard) {
      return BigoAdSize.leaderboard()
    } else if adSize.size.height == 0 {
      return BigoAdSize.getAdaptiveAdSize(withWidth: adSize.size.width)
    }

    throw BigoAdapterError(
      errorCode: .unsupportedBannerSize,
      description:
        "Unsupported banner size. Requested banner ad size width: \(adSize.size.width) height: \(adSize.size.height)"
    )
  }

}
