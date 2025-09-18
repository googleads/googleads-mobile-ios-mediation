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
  }

  /// Prints the message with `BigoAdapter` prefix.
  static func log(_ message: String) {
    print("BigoAdapter: \(message)")
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

}
