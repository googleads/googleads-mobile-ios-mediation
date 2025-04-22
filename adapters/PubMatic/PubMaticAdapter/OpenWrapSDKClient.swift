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

import OpenWrapSDK

/// Factory that creates OpenWrapSDKClient.
struct OpenWrapSDKClientFactory {

  private init() {}

  #if DEBUG
    /// This property will be returned by |createClient| function if set in Debug mode.
    nonisolated(unsafe) static var debugClient: OpenWrapSDKClient?
  #endif

  static func createClient() -> OpenWrapSDKClient {
    #if DEBUG
      return debugClient ?? OpenWrapSDKClientImpl()
    #else
      return OpenWrapSDKClientImpl()
    #endif
  }

}

/// A client for interacting with OpenWrapSDK.
protocol OpenWrapSDKClient {

  /// Enable the OpenWrapSDK's COPPA configuration based on the provided boolean value. It enables if
  /// the passed boolean value is true. Otherwise disable the COPPA configuration.
  func enableCOPPA(_ enable: Bool)

  /// Returns a version of OpenWrapSDK.
  func version() -> String

  /// Set up the OpenWrapSDK using the publisher ID and the profile IDs.
  func setUp(
    publisherId: String, profileIds: [NSNumber], completionHandler: @escaping ((any Error)?) -> Void
  )

  /// Collect signals for bidding.
  func collectSignals(for adFormat: POBAdFormat) -> String

}

struct OpenWrapSDKClientImpl: OpenWrapSDKClient {

  func version() -> String {
    return OpenWrapSDK.version()
  }

  func setUp(
    publisherId: String,
    profileIds: [NSNumber],
    completionHandler: @escaping ((any Error)?) -> Void
  ) {
    let config = OpenWrapSDKConfig(publisherId: publisherId, andProfileIds: profileIds)
    OpenWrapSDK.initialize(with: config) { _, error in
      completionHandler(error)
    }
  }

  func enableCOPPA(_ enable: Bool) {
    OpenWrapSDK.setCoppaEnabled(enable)
  }

  func collectSignals(for adFormat: POBAdFormat) -> String {
    let config = POBSignalConfig(adFormat: adFormat)
    return POBSignalGenerator.generateSignal(for: .adMob, andConfig: config)
  }

}
