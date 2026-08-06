// Copyright 2018 Google LLC
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

/// The adapter class that Google Serving refers to for loading AppLovin Banner and Interstitial
/// Waterfall ads.
///
/// Using the function mainAdapterClass, Google Mobile Ads SDK infers that the actual
/// implementation is in GADMediationAdapterAppLovin.
@MainActor
@objc(GADMAdapterAppLovin)
public final class GADMAdapterAppLovin: NSObject {

  @objc public nonisolated static func mainAdapterClass() -> any MediationAdapter.Type {
    return GADMediationAdapterAppLovin.self
  }
}
