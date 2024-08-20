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

/// Error codes for different possible errors that can occur in Moloco adapter.
///
/// Make sure the adapter error code does not conflict with partner's error code.
public enum MolocoAdapterErrorCode: Int {
  case adServingNotSupported = 101
  case invalidAppID = 102
  case invalidAdUnitId = 103
  case adNotReadyForShow = 104
  case adFailedToShow = 105
}
