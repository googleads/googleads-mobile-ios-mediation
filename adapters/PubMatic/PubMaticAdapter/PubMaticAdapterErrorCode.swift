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

public struct PubMaticAdapterError: Error {

  public enum ErrorCode: Int, Sendable {
    /// Missing server parameters.
    case invalidServerParameters = 101
  }

  public static let domain = "com.google.mediation.pubmatic"

  /// The error code of this error.
  let errorCode: ErrorCode

  /// The description of this error.
  let description: String

  func toNSError() -> NSError {
    return Util.error(withDomain: Self.domain, code: errorCode.rawValue, description: description)
  }

}
