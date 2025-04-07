// Copyright 2024 Google LLC.
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

import MolocoAdapter

final class FakeMolocoSdkVersionProvider: MolocoSdkVersionProviding {

  // Note: Suffix "String" is attached here to keep this name distinct from the function name
  // "sdkVersion()". Otherwise, we get "invalid redeclaration" compilation error.
  private let sdkVersionString: String

  /// - Parameter sdkVersion: The SDK version that this fake should return.
  init(sdkVersion: String) {
    sdkVersionString = sdkVersion
  }

  func sdkVersion() -> String {
    return sdkVersionString
  }

}
