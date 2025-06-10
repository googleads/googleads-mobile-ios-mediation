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
    case appToken = "AppToken"
  }

  /// Prints the message with `VerveAdapter` prefix.
  static func log(_ message: String) {
    print("VerveAdapter: \(message)")
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

  /// Retrieves an app token from the provided mediation server configuration.
  ///
  /// - Throws: VerveAdapterError.serverConfigurationMissingPublisherId if the configuration
  /// contains no app token.
  /// - Returns: An app token from the configuration. If more than one app token was found, the it
  /// returns one random ID with printed warning message.
  static func appToken(from config: MediationServerConfiguration) throws(VerveAdapterError)
    -> String
  {
    let appTokenSet = Set<String>(
      config.credentials.compactMap {
        $0.settings[MediationConfigurationSettingKey.appToken.rawValue] as? String
      })

    guard let appToken = appTokenSet.randomElement() else {
      throw VerveAdapterError(
        errorCode: .serverConfigurationMissingAppToken,
        description: "The server configuration is missing an app token.")
    }

    if appTokenSet.count > 1 {
      log("Found more than one app token in the server configuration. Using \(appToken)")
    }

    return appToken
  }

  /// Retrieves an ad format from the provided mediation signals configuration.
  ///
  /// - Throws: VerveAdapterError.unsupportedBiddingAdFormat if the configuration
  /// contains no ad format.
  /// - Returns: An ad format from the configuration.
  // static func adFormat(
  //   from params: RTBRequestParameters
  // ) throws(VerveAdapterError) -> AdFormat {
  //   // Returns the first ad format found because the other crendentials should
  //   // have the same ad format.
  //   guard let adFormat = params.configuration.credentials.first?.format else {
  //     throw VerveAdapterError(
  //       errorCode: .invalidRTBRequestParameters,
  //       description:
  //         "Failed to collect signals because the configuration is missing the crendentials.")
  //   }

  //   return adFormat
  // }

}
