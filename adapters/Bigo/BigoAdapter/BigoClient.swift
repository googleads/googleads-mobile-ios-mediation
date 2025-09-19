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

import BigoADS
import UIKit

/// Factory that creates Bigo client.
final class BigoClientFactory {

  private init() {}

  #if DEBUG
    /// This property will be returned by |createClient| function if set in Debug mode.
    nonisolated(unsafe) static var debugClient: BigoClient?
  #endif

  static func createClient() -> BigoClient {
    #if DEBUG
      return debugClient ?? BigoClientImpl()
    #else
      return BigoClientImpl()
    #endif
  }

}

protocol BigoClient: NSObject {

  /// Initializes the BigoADS SDK.
  func initialize(with applicationId: String, testMode: Bool, completion: @escaping () -> Void)

}

final class BigoClientImpl: NSObject, BigoClient {

  func initialize(
    with applicationId: String,
    testMode: Bool,
    completion: @escaping () -> Void
  ) {
    let adConfig = BigoAdConfig(appId: applicationId)
    adConfig.testMode = testMode
    BigoAdSdk.sharedInstance().initializeSdk(with: adConfig) {
      completion()
    }
  }

}
