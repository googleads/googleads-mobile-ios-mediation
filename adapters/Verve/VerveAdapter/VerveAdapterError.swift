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

public final class VerveAdapterError: Error {

  public enum ErrorCode: Int, Sendable {
    /// Server configuration missing a required app token.
    case serverConfigurationMissingAppToken = 101

    /// User is a child.
    case childUser = 102

    /// HyBid SDK fails to initialize.
    case failedToInitializeHyBidSDK = 103

    /// Invalid ad configuration for loading an ad.
    case invalidAdConfiguration = 104

    /// Unsupported banner size.
    case unsupportedBannerSize = 105

    /// The full screen is not ready for presentation.
    case notReadyForPresentation = 106
  }

  public static let domain = "com.google.mediation.verve"

  /// The error code of this error.
  public let errorCode: ErrorCode

  /// The description of this error.
  public let description: String

  init(errorCode: ErrorCode, description: String) {
    self.errorCode = errorCode
    self.description = description
  }

  public func toNSError() -> NSError {
    return Util.error(withDomain: Self.domain, code: errorCode.rawValue, description: description)
  }

}
