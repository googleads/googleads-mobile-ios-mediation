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

import BidMachine
import GoogleMobileAds
import UIKit

@testable import GoogleBidMachineAdapter

final class FakeBidMachineClient: NSObject, BidMachineClient {

  private static let supportedFormats: [AdFormat] = [
    .banner, .interstitial, .rewarded, .native,
  ]

  var sourceId: String?
  var isTestMode: Bool?
  var isCOPPA: Bool?

  func version() -> String {
    return BidMachineSdk.sdkVersion
  }

  func initialize(with sourceId: String, isTestMode: Bool, isCOPPA: Bool?) {
    self.sourceId = sourceId
    self.isTestMode = isTestMode
    self.isCOPPA = isCOPPA
  }

  func collectSignals(for adFormat: AdFormat, completionHandler: @escaping (String?) -> Void)
    throws(BidMachineAdapterError)
  {
    if !Self.supportedFormats.contains(adFormat) {
      throw BidMachineAdapterError(
        errorCode: .invalidRTBRequestParameters, description: "test description.")
    }
    completionHandler("Test signals")
  }

}
