// Copyright 2026 Google LLC
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

/// AppLovin adapter constants.
@objc(GADMAdapterAppLovinConstant)
public final class GADMAdapterAppLovinConstant: NSObject {
  private override init() {
    super.init()
  }

  /// AppLovin adapter error domain.
  @objc public static let errorDomain = "com.google.mediation.applovin"

  /// AppLovin SDK error domain.
  @objc public static let sdkErrorDomain = "com.google.mediation.applovinSDK"

  /// AppLovin adapter version number.
  @objc public static let adapterVersion = "13.6.3.0"

  /// AppLovin SDK parameter key.
  @objc public static let sdkKey = "sdkKey"

  /// AppLovin zone identifier parameter key.
  @objc public static let zoneIdentifierKey = "zone_id"

  /// AppLovin ad unit ID parameter key.
  @objc public static let adUnitID = "ad_unit_id"

  /// AppLovin bundle identifier parameter key.
  @objc public static let bundleIdentifierKey = "bundleId"

  /// AppLovin default zone identifier.
  @objc public static let defaultZoneIdentifier = ""
}
