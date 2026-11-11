// Copyright 2026 Google LLC.
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

import AdSurgeSDK
import Foundation
import Testing

@testable import AdSurgeAdapter

/// Stands in for `AdSurgeError`, which cannot be created directly in tests.
@objc private final class FakeAdSurgeError: NSObject {
  @objc let code: Int
  @objc let message: String

  init(code: Int, message: String) {
    self.code = code
    self.message = message
  }

  /// Returns this fake as an `AdSurgeError`. Only the Objective-C `code` and `message` properties
  /// are read by the adapter, so this fake is safe to use in their place.
  var asAdSurgeError: AdSurgeError {
    return unsafeBitCast(self, to: AdSurgeError.self)
  }
}

@Suite("AdSurge client error tests")
struct ClientErrorTests {

  private let sdkError = FakeAdSurgeError(code: 3, message: "SDK error.")

  @Test("SDK errors are reported in the AdSurge SDK error domain with the SDK error code")
  func toSDKNSError_usesSDKErrorDomainAndCode() {
    let error = sdkError.asAdSurgeError.toSDKNSError()

    #expect(error.domain == "com.adsurge.adn")
    #expect(error.code == 3)
    #expect(error.localizedDescription == "SDK error.")
  }

  @Test("Initialization failure with an SDK error reports the SDK error")
  func initializationError_reportsSDKError() {
    let error = ClientImpl.initializationError(from: sdkError.asAdSurgeError)

    #expect(error.domain == "com.adsurge.adn")
    #expect(error.code == 3)
  }

  @Test("Initialization failure without an SDK error reports an internal adapter error")
  func initializationError_reportsInternalError_whenSDKErrorIsMissing() {
    let error = ClientImpl.initializationError(from: nil)

    #expect(error.domain == AdSurgeAdapterError.domain)
    #expect(error.code == AdSurgeAdapterError.ErrorCode.internalError.rawValue)
  }

  @Test("Bidder token failure with an SDK error reports the SDK error")
  func bidderTokenError_reportsSDKError() {
    let error = ClientImpl.bidderTokenError(from: sdkError.asAdSurgeError)

    #expect(error.domain == "com.adsurge.adn")
    #expect(error.code == 3)
  }

  @Test("Bidder token failure without an SDK error reports an internal adapter error")
  func bidderTokenError_reportsInternalError_whenSDKErrorIsMissing() {
    let error = ClientImpl.bidderTokenError(from: nil)

    #expect(error.domain == AdSurgeAdapterError.domain)
    #expect(error.code == AdSurgeAdapterError.ErrorCode.internalError.rawValue)
  }

}
