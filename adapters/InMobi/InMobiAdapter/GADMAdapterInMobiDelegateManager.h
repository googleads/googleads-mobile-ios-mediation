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
#import <InMobiSDK/IMInterstitialDelegate.h>

/// Manages rewarded ad delegates.
@interface GADMAdapterInMobiDelegateManager : NSObject

/// The shared GADMAdapterInMobiDelegateManager instance.
@property(class, atomic, readonly, nonnull) GADMAdapterInMobiDelegateManager *sharedInstance;

/// Stores a weak reference to the delegate, keyed by placementIdentifier.
- (void)addDelegate:(nonnull id<IMInterstitialDelegate>)delegate
    forPlacementIdentifier:(nonnull NSNumber *)placementIdentifier;

/// Removes the weak reference to the delegate with placementIdentifier as a key.
- (void)removeDelegateForPlacementIdentifier:(nonnull NSNumber *)placementIdentifier;

/// Returns whether the weak reference to the delegate with placement identifier as key is present
/// or not.
- (BOOL)containsDelegateForPlacementIdentifier:(nonnull NSNumber *)placementIdentifier;

@end
