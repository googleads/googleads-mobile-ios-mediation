// Copyright 2022 Google LLC
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

#import "GADMAdapterVungleBiddingRouter.h"
#import <VungleSDK/VungleSDKHeaderBidding.h>
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"
#import "VungleRouterConsent.h"

static NSString *const _Nonnull GADMAdapterVungleNullPubRequestID = @"null";

@implementation GADMAdapterVungleBiddingRouter {
  /// Map table to hold the bidding ad delegates with ad markup as a key.
  NSMapTable<NSString *, id<GADMAdapterVungleDelegate>> *_delegates;

  /// Map table to hold the Vungle SDK delegates with ad markup as a key.
  NSMapTable<NSString *, id<GADMAdapterVungleDelegate>> *_initializingDelegates;

  /// Indicates whether the Vungle SDK is initializing.
  BOOL _isInitializing;
}

+ (nonnull GADMAdapterVungleBiddingRouter *)sharedInstance {
  static GADMAdapterVungleBiddingRouter *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[GADMAdapterVungleBiddingRouter alloc] init];
  });
  return instance;
}

- (id)init {
  self = [super init];
  if (self) {
    VungleSDK.sharedSDK.sdkHBDelegate = self;
    _delegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                       valueOptions:NSPointerFunctionsWeakMemory];
    _initializingDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                   valueOptions:NSPointerFunctionsWeakMemory];
  }
  return self;
}

- (void)initWithAppId:(nonnull NSString *)appId
             delegate:(nullable id<GADMAdapterVungleDelegate>)delegate {
  if (delegate) {
    GADMAdapterVungleMapTableSetObjectForKey(_initializingDelegates, delegate.bidResponse,
                                             delegate);
  }

  // Call the init method in GADMAdapterVungleRouter as that class implements the Vungle SDK init
  // delegates. Need to pass delegate as nil to avoid adding bidding ad delegate to
  // GADMAdapterVungleRouter map table.
  [GADMAdapterVungleRouter.sharedInstance initWithAppId:appId delegate:nil];
}

- (BOOL)isSDKInitialized {
  return [VungleSDK.sharedSDK isInitialized];
}

- (BOOL)addDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  @synchronized(_delegates) {
    if (![_delegates objectForKey:delegate.bidResponse]) {
      GADMAdapterVungleMapTableSetObjectForKey(_delegates, delegate.bidResponse, delegate);
      return YES;
    }
  }
  return NO;
}

- (nullable id<GADMAdapterVungleDelegate>)getDelegateForAdMarkup:(nonnull NSString *)adMarkup {
  @synchronized(_delegates) {
    return [_delegates objectForKey:adMarkup];
  }
  return nil;
}

- (void)removeDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  @synchronized(_delegates) {
    GADMAdapterVungleMapTableRemoveObjectForKey(_delegates, delegate.bidResponse);
  }
}

- (nullable NSError *)loadAdWithDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  BOOL addSuccessed = [self addDelegate:delegate];
  if (!addSuccessed) {
    return GADMAdapterVungleErrorWithCodeAndDescription(
        GADMAdapterVungleErrorAdAlreadyLoaded,
        @"An ad with the same ad markup has already been loaded.");
  }

  VungleSDK *sdk = VungleSDK.sharedSDK;
  if ([VungleSDK.sharedSDK isAdCachedForPlacementID:delegate.desiredPlacement
                                           adMarkup:[delegate bidResponse]]) {
    [delegate adAvailable];
    return nil;
  }

  NSError *loadError = nil;

  [sdk loadPlacementWithID:delegate.desiredPlacement
                  adMarkup:[delegate bidResponse]
                     error:&loadError];

  return loadError;
}

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error {
  _isInitializing = NO;
  NSMapTable<NSString *, id<GADMAdapterVungleDelegate>> *delegates = [_initializingDelegates copy];
  for (NSString *key in delegates) {
    id<GADMAdapterVungleDelegate> delegate = [delegates objectForKey:key];
    [delegate initialized:isSuccess error:error];
  }

  [_initializingDelegates removeAllObjects];
}

- (NSString *)getSuperToken {
  return [VungleSDK.sharedSDK currentSuperToken];
}

#pragma mark - VungleSDKHBDelegate methods

- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable
                      placementID:(nullable NSString *)placementID
                         adMarkup:(nullable NSString *)adMarkup
                            error:(nullable NSError *)error {
  id<GADMAdapterVungleDelegate> delegate = [self getDelegateForAdMarkup:adMarkup];
  if (!delegate) {
    return;
  }

  if (isAdPlayable) {
    [delegate adAvailable];
    return;
  }

  // Vungle SDK calls this method with isAdPlayable NO just after an ad is presented. These events
  // should be ignored as they aren't related to a load call. Assume that this method is called with
  // isAdPlayable NO due to an ad being presented if Vungle SDK has an ad cached for this placement.
  if ([VungleSDK.sharedSDK isAdCachedForPlacementID:placementID adMarkup:[delegate bidResponse]]) {
    return;
  }

  // Vungle SDK calls this method for auto-cached placements after playing the ad.
  // If the next placement fails to download the ad, then the SDK would call this method
  // with isAdPlayable NO. If the delegate is already loaded, do not remove it from the
  // tracker because the call is for the next ad.
  if ([delegate isAdLoaded]) {
    return;
  }

  // Ad not playable. Return an error.
  if (error) {
    NSLog(@"Vungle Ad Playability returned an error: %@", error.localizedDescription);
  } else {
    error = GADMAdapterVungleErrorWithCodeAndDescription(
        GADMAdapterVungleErrorAdNotPlayable,
        [NSString stringWithFormat:@"Ad is not available for placementID: %@.", placementID]);
  }
  [delegate adNotAvailable:error];
  [self removeDelegate:delegate];
}

- (void)vungleWillShowAdForPlacementID:(nullable NSString *)placementID
                              adMarkup:(nullable NSString *)adMarkup {
  id<GADMAdapterVungleDelegate> delegate = [self getDelegateForAdMarkup:adMarkup];
  [delegate willShowAd];
}

- (void)vungleDidShowAdForPlacementID:(nullable NSString *)placementID
                             adMarkup:(nullable NSString *)adMarkup {
  NSLog(@"Vungle: Did show Ad for placement ID: %@, markup: %@", placementID, adMarkup);
}

- (void)vungleAdViewedForPlacementID:(nullable NSString *)placementID
                            adMarkup:(nullable NSString *)adMarkup {
  id<GADMAdapterVungleDelegate> delegate = [self getDelegateForAdMarkup:adMarkup];
  [delegate didViewAd];
}

- (void)vungleWillCloseAdForPlacementID:(nullable NSString *)placementID
                               adMarkup:(nullable NSString *)adMarkup {
  id<GADMAdapterVungleDelegate> delegate = [self getDelegateForAdMarkup:adMarkup];
  [delegate willCloseAd];
}

- (void)vungleDidCloseAdForPlacementID:(nullable NSString *)placementID
                              adMarkup:(nullable NSString *)adMarkup {
  id<GADMAdapterVungleDelegate> delegate = [self getDelegateForAdMarkup:adMarkup];

  if (!delegate) {
    return;
  }

  [delegate didCloseAd];
  [self removeDelegate:delegate];
}

- (void)vungleTrackClickForPlacementID:(nullable NSString *)placementID
                              adMarkup:(nullable NSString *)adMarkup {
  id<GADMAdapterVungleDelegate> delegate = [self getDelegateForAdMarkup:adMarkup];
  [delegate trackClick];
}

- (void)vungleWillLeaveApplicationForPlacementID:(nullable NSString *)placementID
                                        adMarkup:(nullable NSString *)adMarkup {
  id<GADMAdapterVungleDelegate> delegate = [self getDelegateForAdMarkup:adMarkup];
  [delegate willLeaveApplication];
}

- (void)vungleRewardUserForPlacementID:(nullable NSString *)placementID
                              adMarkup:(nullable NSString *)adMarkup {
  id<GADMAdapterVungleDelegate> delegate = [self getDelegateForAdMarkup:adMarkup];
  [delegate rewardUser];
}

@end
