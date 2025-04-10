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
import UIKit

/// Factory that creates Client.
final class BidMachineClientFactory {

  private init() {}

  #if DEBUG
    /// This property will be returned by |createClient| function if set in Debug mode.
    nonisolated(unsafe) static var debugClient: BidMachineClient?
  #endif

  static func createClient() -> BidMachineClient {
    #if DEBUG
      return debugClient ?? BidMachineClientImpl()
    #else
      return ClientImpl()
    #endif
  }

}

protocol BidMachineClient: NSObject {

  /// Returns a version string of BidMachine SDK.
  func version() -> String

  /// Initializes the BidMachine SDK.
  func initialize(with sourceId: String, isTestMode: Bool, isCOPPA: Bool?)

}

final class BidMachineClientImpl: NSObject, BidMachineClient {

  func version() -> String {
    return BidMachineSdk.sdkVersion
  }

  func initialize(with sourceId: String, isTestMode: Bool, isCOPPA: Bool?) {
    BidMachineSdk.shared.populate {
      $0.withTestMode(isTestMode)
        .withBidLoggingMode(isTestMode)
        .withEventLoggingMode(isTestMode)
        .withLoggingMode(isTestMode)
    }

    if let isCOPPA {
      BidMachineSdk.shared.regulationInfo.populate {
        $0.withCOPPA(isCOPPA)
      }
    }

    BidMachineSdk.shared.initializeSdk(sourceId)
  }

}
