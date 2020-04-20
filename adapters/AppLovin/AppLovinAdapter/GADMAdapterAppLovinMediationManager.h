// Copyright 2019 Google LLC.
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
#import <GoogleMobileAds/GoogleMobileAds.h>

/// Manages zone identifiers of the requested rewarded and interstitial ads. AppLovin can only load
/// one ad per zone identifier at a time.
@interface GADMAdapterAppLovinMediationManager : NSObject

/// The shared GADMAdapterAppLovinMediationManager instance.
@property(class, atomic, readonly, nonnull) GADMAdapterAppLovinMediationManager *sharedInstance;

/// Adds the interstitial zoneIdentifier to the mediation manager. Returns YES if the manager
/// already contained the zoneIdentifier.
- (BOOL)containsAndAddInterstitialZoneIdentifier:(nonnull NSString *)zoneIdentifier;

/// Removes the interstitial zoneIdentifier from the mediation manager.
- (void)removeInterstitialZoneIdentifier:(nonnull NSString *)zoneIdentifier;

/// Removes the rewarded zoneIdentifier from the mediation manager.
- (void)removeRewardedZoneIdentifier:(nonnull NSString *)zoneIdentifier;

/// Adds the rewarded zoneIdentifier to the mediation manager. Returns YES if the manager already
/// contained the zoneIdentifier.
- (BOOL)containsAndAddRewardedZoneIdentifier:(nonnull NSString *)zoneIdentifier;

@end
