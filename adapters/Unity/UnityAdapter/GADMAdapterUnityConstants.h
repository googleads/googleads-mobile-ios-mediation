// Copyright 2020 Google LLC.
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

#import <Foundation/Foundation.h>

/// Unity adapter error domain.
static NSString *const GADMAdapterUnityErrorDomain = @"com.google.mediation.unity";

/// Unity SDK error domain.
static NSString *const GADMAdapterUnitySDKErrorDomain = @"com.google.mediation.unitySDK";

/// Unity Ads game ID.
static NSString *const GADMAdapterUnityGameID = @"gameId";

/// Unity Ads placement ID.
/// Unity Ads has moved from zoneId to placementId, but to keep backward compatibility, we are still
/// using zoneId as a value.
static NSString *const GADMAdapterUnityPlacementID = @"zoneId";

/// Ad mediation network adapter version.
static NSString *const GADMAdapterUnityVersion = @"4.2.1.0";

/// Ad mediation network name.
static NSString *const GADMAdapterUnityMediationNetworkName = @"AdMob";
