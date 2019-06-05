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

/// Unity Ads game ID.
static NSString *const kGADMAdapterUnityGameID = @"gameId";

/// Unity Ads placement ID.
/// Unity Ads has moved from zoneId to placementId, but to keep backward compatibility, we are still
/// using zoneId as a value.
static NSString *const kGADMAdapterUnityPlacementID = @"zoneId";

/// Ad mediation network adapter version.
static NSString *const kGADMAdapterUnityVersion = @"3.1.0.0";

/// Ad mediation network name.
static NSString *const kGADMAdapterUnityMediationNetworkName = @"AdMob";
