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

import HyBid
import UIKit

/// Factory that creates Client.
final class HybidClientFactory {

  private init() {}

  #if DEBUG
    /// This property will be returned by |createClient| function if set in Debug mode.
    nonisolated(unsafe) static var debugClient: HybidClient?
  #endif

  static func createClient() -> HybidClient {
    #if DEBUG
      return debugClient ?? HybidClientImpl()
    #else
      return HybidClientImpl()
    #endif
  }

}

protocol HybidClient: NSObject {

  /// Returns a version string of HyBid SDK.
  func version() -> String

  /// Initializes the HyBid SDK. The completion handle is called without an error object if HyBid
  /// SDK was initialized successfully.
  func initialize(
    with appToken: String, testMode: Bool, COPPA: Bool?, TFUA: Bool?,
    completionHandler: @escaping (VerveAdapterError?) -> Void)

}

final class HybidClientImpl: NSObject, HybidClient {

  func version() -> String {
    return HyBid.sdkVersion()
  }

  func initialize(
    with appToken: String,
    testMode: Bool,
    COPPA: Bool?,
    TFUA: Bool?,
    completionHandler: @escaping (VerveAdapterError?) -> Void
  ) {
    if let COPPA {
      guard !COPPA else {
        HyBid.setCoppa(true)
        completionHandler(
          VerveAdapterError(errorCode: .childUser, description: "Verve does not serve child user."))
        return
      }
      HyBid.setCoppa(false)
    }

    if let TFUA {
      guard !TFUA else {
        completionHandler(
          VerveAdapterError(errorCode: .childUser, description: "Verve does not serve child user."))
        return
      }
    }

    if testMode {
      HyBid.setTestMode(true)
    }

    HyBid.initWithAppToken(appToken) { success in
      guard success else {
        completionHandler(
          VerveAdapterError(
            errorCode: .failedToInitializeHyBidSDK, description: "Verve SDK failed to initialize."))
        return
      }
      completionHandler(nil)
    }
  }

}
