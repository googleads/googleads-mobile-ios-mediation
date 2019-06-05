// Copyright 2016 Google Inc.
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

@import Foundation;

/// The purpose of the GADMAdapterUnityDataProvider protocol is to allow the singleton to interact
/// with the adapter.
@protocol GADMAdapterUnityDataProvider <NSObject>

/// Returns the game ID to use for initializing the Unity Ads SDK.
- (NSString *)getGameID;

/// Returns placement ID for either reward-based video ad or interstitial ad of Unity Ads network.
- (NSString *)getPlacementID;

@end
