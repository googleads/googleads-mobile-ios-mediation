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

struct Util {

  private enum MediationConfigurationSettingKey: String {
    case publisherId = "publisher_id"
    case profileId = "profile_id"
  }

  /// Prints the message with `PubMaticAdapter` prefix.
  static func log(_ message: String) {
    print("PubMaticAdapter: \(message)")
  }

  /// Returns a NSError object with the provided information.
  static func error(withDomain domain: String, code: Int, description: String) -> NSError {
    return NSError(
      domain: domain, code: code,
      userInfo: [
        NSLocalizedDescriptionKey: description,
        NSLocalizedFailureReasonErrorKey: description,
      ])
  }

  /// Retrieves a publisher ID from the provided mediation server configuration.
  ///
  /// - Throws: PubMaticAdapterError.serverConfigurationMissingPublisherId if the configuration
  /// contains no publisher ID.
  /// - Returns: A publisher ID from the configuration. If more than one ID was found, the it returns one
  /// random ID with printed warning message.
  static func publisherId(from config: MediationServerConfiguration) throws(PubMaticAdapterError)
    -> String
  {
    let appIdSet = Set<String>(
      config.credentials.compactMap {
        $0.settings[MediationConfigurationSettingKey.publisherId.rawValue] as? String
      })

    guard let appId = appIdSet.randomElement() else {
      throw PubMaticAdapterError(
        errorCode: .serverConfigurationMissingPublisherId,
        description: "The server configuration is missing an app ID.")
    }

    if appIdSet.count > 1 {
      log("Found more than one app ID in the server configuration. Using \(appId)")
    }

    return appId
  }

  /// Retrieves profile IDs from the provided mediation signals configuration.
  ///
  /// - Returns: Profile IDs from the configuration.
  static func profileIds(from config: MediationServerConfiguration) -> [NSNumber] {
    let formatter = NumberFormatter()
    let profileIds = config.credentials.compactMap {
      if let value = $0.settings[MediationConfigurationSettingKey.profileId.rawValue] as? String {
        return formatter.number(from: value)
      }
      return nil
    }

    if profileIds.count == 0 {
      log("Found 0 profile ID.")
    }

    return profileIds
  }

}
