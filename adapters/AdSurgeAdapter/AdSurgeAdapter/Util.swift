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
      domain: domain, code: code,
      userInfo: [
        NSLocalizedDescriptionKey: description,
        NSLocalizedFailureReasonErrorKey: description,
      ])
  }

}
