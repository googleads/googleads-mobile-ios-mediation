// Copyright 2016 Google Inc.
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

/// Constants used by the Chartboost adapter.
@objc(GADMAdapterChartboostConstants)
public final class GADMAdapterChartboostConstants: NSObject {
  /// Chartboost AdMob adapter version.
  @objc public static let adapterVersion = "9.12.0.1"

  /// Chartboost App ID.
  @objc public static let appID = "appId"

  /// Chartboost App Signature.
  @objc public static let appSignature = "appSignature"

  /// Chartboost Ad Location.
  @objc public static let adLocation = "adLocation"

  /// Chartboost adapter error domain.
  @objc public static let errorDomain = "com.google.mediation.chartboost"

  /// Minimum OS version.
  @objc public static let minimumOSVersion = "11.0"

  /// Chartboost ad technology provider ID from
  /// https://storage.googleapis.com/tcfac/additional-consent-providers.csv
  @objc public static let adTechnologyProviderID = 2898
}
