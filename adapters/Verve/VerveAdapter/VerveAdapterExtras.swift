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

@objc(GADMediationAdapterVerveExtras)
public final class VerveAdapterExtras: NSObject, AdNetworkExtras {

  /// Indicates whether HyBid SDK needs to be initialized with the test mode configuration. When
  /// `isTestMode`is set  to true, enable its test mode along with its logging mode to debug mode. Default
  /// value is false.
  ///
  /// - Important: This must be set before initializing `GoogleMobileAds`.
  nonisolated(unsafe) public static var isTestMode: Bool = false

}
