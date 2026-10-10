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
import UIKit

@testable import AdSurgeAdapter

final class FakeClient: NSObject, Client, @unchecked Sendable {

  var ageRestrictedUser: NSNumber?
  var applicationId: String?
  var initializeShouldSucceed: Bool = true
  var bidderTokenToReturn: String? = "mock_bidder_token"
  var sdkVersionString: String = "1.9.2"

  func setAgeRestrictedUser(_ ageRestrictedUser: NSNumber?) {
    self.ageRestrictedUser = ageRestrictedUser
  }

  func initialize(with appId: String) async throws {
    self.applicationId = appId
    guard initializeShouldSucceed else {
      throw AdSurgeAdapterError(
        errorCode: .serverConfigurationMissingApplicationId,
        description: "Fake initialization failed.")
    }
  }

  func getBidderToken() async throws -> String {
    guard let token = bidderTokenToReturn else {
      throw AdSurgeAdapterError(
        errorCode: .invalidRTBRequestParameters,
        description: "Fake bidder token retrieval failed.")
    }
    return token
  }

  func version() -> String {
    return sdkVersionString
  }

}
