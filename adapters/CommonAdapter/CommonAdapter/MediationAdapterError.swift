// Copyright 2026 Google LLC
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

/// Error that can be thrown by Google Mobile Ads Mediation Adapters.
public final class MediationAdapterError: Error {

  /// Mediation Adapter error code definitions.
  ///
  /// All adapters are expected to use the error codes defined here and not define their own error.
  ///
  /// See go/unified-adapter-error-codes for the design.
  public enum ErrorCode: Int, Sendable {
    /// Missing/invalid account key.
    case invalidAccountKey = 130

    /// Missing/invalid application key.
    case invalidAppKey = 131

    /// The request had age-restricted treatment, but the 3P SDK cannot receive age-restricted
    /// signals.
    case ageRestricted = 132
  }

  /// The domain for error codes defined in the common library.
  public static let domain = "com.google.ads.mediation.common"

  /// The error code of this error.
  public let errorCode: ErrorCode

  /// The description of this error.
  public let description: String

  init(errorCode: ErrorCode, description: String) {
    self.errorCode = errorCode
    self.description = description
  }

  /// Returns a NSError object with the provided information.
  func error(withDomain domain: String, code: Int, description: String) -> NSError {
    return NSError(
      domain: domain, code: code,
      userInfo: [
        NSLocalizedDescriptionKey: description,
        NSLocalizedFailureReasonErrorKey: description,
      ])
  }

  public func toNSError() -> NSError {
    return error(withDomain: Self.domain, code: errorCode.rawValue, description: description)
  }

}
