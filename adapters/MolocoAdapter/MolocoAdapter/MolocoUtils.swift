// Copyright 2024 Google LLC.
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

/// Contains utility methods for Moloco adapter.
final class MolocoUtils {

  static func error(
    code: MolocoAdapterErrorCode, description: String
  ) -> NSError {
    let userInfo = ["description": description]
    return NSError(
      domain: MolocoConstants.adapterErrorDomain, code: code.rawValue, userInfo: userInfo)
  }

  static func log(_ logMessage: String) {
    NSLog("GADMediationAdapterMoloco - \(logMessage)")
  }

  static func getAdUnitId(from adConfiguration: GADMediationAdConfiguration) -> String? {
    adConfiguration.isTestRequest
      ? MolocoConstants.molocoTestAdUnitName
      : adConfiguration.credentials.settings[MolocoConstants.adUnitIdKey] as? String
  }
}
