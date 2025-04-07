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

import Foundation
import MolocoAdapter

final class FakeMolocoBidTokenGetter: MolocoBidTokenGetter {

  let error: NSError?

  let bidToken: String?

  /// If this initializer is called, this fake returns the passed-in bidToken on getBidToken().
  init(bidToken: String) {
    self.bidToken = bidToken
    self.error = nil
  }

  /// If this initializer is called, this fake returns the passed-in error on getBidToken().
  init(error: NSError) {
    self.bidToken = nil
    self.error = error
  }

  func getBidToken(completion: @escaping (String?, (any Error)?) -> Void) {
    if bidToken != nil {
      completion(bidToken, nil)
    } else {
      completion(nil, error)
    }
  }
}
