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
    case sourceId = "source_id"
    case placementId = "placement_id"
  }

  /// Prints the message with `BidMachineAdapter` prefix.
  static func log(_ message: String) {
    #if DEBUG
      print("BidMachineAdapter: \(message)")
    #endif
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
  /// - Throws: BidMachineAdapterError.serverConfigurationMissingPublisherId if the configuration
  /// contains no publisher ID.
  /// - Returns: A publisher ID from the configuration. If more than one ID was found, the it
  /// returns one random ID with printed warning message.
  static func sourceId(from config: MediationServerConfiguration) throws(BidMachineAdapterError)
    -> String
  {
    let sourceIdSet = Set<String>(
      config.credentials.compactMap {
        $0.settings[MediationConfigurationSettingKey.sourceId.rawValue] as? String
      })

    guard let sourceId = sourceIdSet.randomElement() else {
      throw BidMachineAdapterError(
        errorCode: .serverConfigurationMissingPublisherId,
        description: "The server configuration is missing an source ID.")
    }

    if sourceIdSet.count > 1 {
      log("Found more than one source ID in the server configuration. Using \(sourceId)")
    }

    return sourceId
  }

  /// Retrieves an ad format from the provided mediation signals configuration.
  ///
  /// - Throws: BidMachineAdapterError.invalidRTBRequestParameters if the configuration
  /// contains no ad format.
  /// - Returns: An ad format from the configuration.
  static func adFormat(
    from params: RTBRequestParameters
  ) throws(BidMachineAdapterError) -> AdFormat {
    // Returns the first ad format found because the other crendentials should
    // have the same ad format.
    guard let adFormat = params.configuration.credentials.first?.format else {
      throw BidMachineAdapterError(
        errorCode: .invalidRTBRequestParameters,
        description:
          "Failed to collect signals because the configuration is missing the crendentials.")
    }

    return adFormat
  }

}
