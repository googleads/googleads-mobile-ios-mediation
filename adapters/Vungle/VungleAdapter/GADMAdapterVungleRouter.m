// Copyright 2019 Google LLC
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

#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleBiddingRouter.h"
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleUtils.h"
#import "VungleRouterConsent.h"

const CGSize kVNGBannerShortSize = {300, 50};

static NSString *const _Nonnull GADMAdapterVungleNullPubRequestID = @"null";

@implementation GADMAdapterVungleRouter {
  /// Map table to hold the interstitial or rewarded ad delegates with placement ID as a key.
  NSMapTable<NSString *, id<GADMAdapterVungleDelegate>> *_delegates;

  /// Map table to hold the Vungle SDK delegates with placement ID as a key.
  NSMapTable<NSString *, id<GADMAdapterVungleDelegate>> *_initializingDelegates;

  /// Map table to hold the banner ad delegates with placement ID as a key.
  NSMapTable<NSString *, id<GADMAdapterVungleDelegate>> *_bannerDelegates;

  /// Dictionary to hold the key: uniquePubRequestID and value: placement ID for requested banners.
  NSMutableDictionary<NSString *, NSString *> *_bannerRequestingDict;

  /// Indicates whether the Vungle SDK is initializing.
  BOOL _isInitializing;

  /// Vungle's prioritized placementID
  NSString *_prioritizedPlacementID;
}

+ (nonnull GADMAdapterVungleRouter *)sharedInstance {
  static GADMAdapterVungleRouter *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[GADMAdapterVungleRouter alloc] init];
  });
  return instance;
}

- (id)init {
  self = [super init];
  if (self) {
    VungleSDK.sharedSDK.delegate = self;
    _delegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                       valueOptions:NSPointerFunctionsWeakMemory];
    _initializingDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                   valueOptions:NSPointerFunctionsWeakMemory];
    _bannerDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                             valueOptions:NSPointerFunctionsWeakMemory];
    _bannerRequestingDict = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)initWithAppId:(nonnull NSString *)appId
             delegate:(nullable id<GADMAdapterVungleDelegate>)delegate {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSString *version = [GADMAdapterVungleVersion stringByReplacingOccurrencesOfString:@"."
                                                                             withString:@"_"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [VungleSDK.sharedSDK performSelector:@selector(setPluginName:version:)
                              withObject:@"admob"
                              withObject:version];
#pragma clang diagnostic pop
  });
  VungleSDK *sdk = VungleSDK.sharedSDK;

  if (delegate) {
    GADMAdapterVungleMapTableSetObjectForKey(_initializingDelegates, delegate.desiredPlacement,
                                             delegate);
  }

  if ([sdk isInitialized]) {
    [self initialized:YES error:nil];
    return;
  }

  if (_isInitializing) {
    return;
  }

  if (!appId) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        GADMAdapterVungleErrorInvalidServerParameters, @"Vungle app ID not specified.");
    [delegate initialized:NO error:error];
    return;
  }

  _isInitializing = YES;

  // Disable refresh functionality for all banners
  [sdk disableBannerRefresh];

  // Enable background downloading
  [VungleSDK enableBackgroundDownload:YES];

  // Set init options for priority placement
  NSMutableDictionary *initOptions = [NSMutableDictionary dictionary];
  if (delegate) {
    NSString *priorityPlacementID = delegate.desiredPlacement;
    GADMAdapterVungleMutableDictionarySetObjectForKey(
        initOptions, VungleSDKInitOptionKeyPriorityPlacementID, priorityPlacementID);
    _prioritizedPlacementID = delegate.desiredPlacement;

    VungleAdSize priorityPlacementAdSize = VungleAdSizeUnknown;
    if ([delegate respondsToSelector:@selector(bannerAdSize)]) {
      GADAdSize adSize = [delegate bannerAdSize];

      // Vungle's MREC ads are a special case where doesn't need to set Banner size
      // since they have fixed size(300x250).
      if (!GADAdSizeEqualToSize(adSize, GADAdSizeMediumRectangle)) {
        priorityPlacementAdSize = GADMAdapterVungleAdSizeForCGSize(adSize.size);
      }
    }
    GADMAdapterVungleMutableDictionarySetObjectForKey(
        initOptions, VungleSDKInitOptionKeyPriorityPlacementAdSize,
        [NSNumber numberWithInteger:priorityPlacementAdSize]);
  }

  NSError *err = nil;
  [sdk startWithAppId:appId options:initOptions error:&err];
  if (err) {
    [self initialized:NO error:err];
  }
}

- (BOOL)isSDKInitialized {
  return [VungleSDK.sharedSDK isInitialized];
}

- (BOOL)isAdCachedForPlacementID:(nonnull NSString *)placementID
                    withDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  if ([delegate respondsToSelector:@selector(bannerAdSize)]) {
    GADAdSize adSize = [delegate bannerAdSize];

    // Vungle's MREC ads are a special case where Vungle prefers using isAdCachedForPlacementID:
    // as opposed to isAdCachedForPlacementID:withSize:.
    if (!GADAdSizeEqualToSize(adSize, GADAdSizeMediumRectangle)) {
      VungleAdSize vungleAdSize = GADMAdapterVungleAdSizeForCGSize(adSize.size);
      return [VungleSDK.sharedSDK isAdCachedForPlacementID:placementID withSize:vungleAdSize];
    }
  }

  return [VungleSDK.sharedSDK isAdCachedForPlacementID:placementID];
}

- (BOOL)addDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  if ([delegate respondsToSelector:@selector(bannerAdSize)]) {
    @synchronized(_bannerDelegates) {
      if (![_bannerDelegates objectForKey:delegate.desiredPlacement] &&
          ![_bannerRequestingDict objectForKey:delegate.desiredPlacement]) {
        GADMAdapterVungleMapTableSetObjectForKey(_bannerDelegates, delegate.desiredPlacement,
                                                 delegate);
        GADMAdapterVungleMutableDictionarySetObjectForKey(
            _bannerRequestingDict, delegate.desiredPlacement,
            delegate.uniquePubRequestID ?: GADMAdapterVungleNullPubRequestID);
        return YES;
      } else if ([_bannerDelegates objectForKey:delegate.desiredPlacement]) {
        id<GADMAdapterVungleDelegate> bannerDelegate =
            [_bannerDelegates objectForKey:delegate.desiredPlacement];
        if ([bannerDelegate.uniquePubRequestID isEqualToString:delegate.uniquePubRequestID]) {
          /* The isRequestingBannerAdForRefresh flag is used for an edge case, when the old Banner
           * delegate is removed from _bannerDelegates and there is a refresh Banner delegate
           * doesn't construct Banner view successfully and add to _bannerDelegates yet. Adapter
           * cannot request another Banner ad with same placement Id and different
           * uniquePubRequestID.
           */
          bannerDelegate.isRequestingBannerAdForRefresh = YES;
          delegate.isRefreshedForBannerAd = YES;
          return YES;
        }

        if (!bannerDelegate.uniquePubRequestID) {
          NSLog(
              @"Vungle: Ad already loaded for placement ID: %@, and cannot determine if this is a "
              @"refresh. Set Vungle extras when making an ad request to support refresh on "
              @"Vungle banner ads.",
              bannerDelegate.desiredPlacement);
        } else {
          NSLog(@"Vungle: Ad already loaded for placement ID: %@", bannerDelegate.desiredPlacement);
        }
      }
    }
  } else {
    @synchronized(_delegates) {
      if (![_delegates objectForKey:delegate.desiredPlacement]) {
        GADMAdapterVungleMapTableSetObjectForKey(_delegates, delegate.desiredPlacement, delegate);
        return YES;
      }
    }
  }
  return NO;
}

- (void)replaceOldBannerDelegateWithDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  if ([delegate respondsToSelector:@selector(bannerAdSize)]) {
    @synchronized(_bannerDelegates) {
      GADMAdapterVungleMapTableSetObjectForKey(_bannerDelegates, delegate.desiredPlacement,
                                               delegate);
    }
  }
}

- (nullable id<GADMAdapterVungleDelegate>)getDelegateForPlacement:(nonnull NSString *)placement {
  return [self getDelegateForPlacement:placement
         withBannerRouterDelegateState:BannerRouterDelegateStateRequesting];
}

- (nullable id<GADMAdapterVungleDelegate>)getDelegateForPlacement:(nonnull NSString *)placement
                                    withBannerRouterDelegateState:
                                        (BannerRouterDelegateState)bannerState {
  @synchronized(_bannerDelegates) {
    if ([_bannerDelegates objectForKey:placement]) {
      id<GADMAdapterVungleDelegate> bannerDelegate = [_bannerDelegates objectForKey:placement];
      if (bannerDelegate && bannerDelegate.bannerState == bannerState) {
        return bannerDelegate;
      }
    }
  }

  @synchronized(_delegates) {
    return [_delegates objectForKey:placement];
  }
  return nil;
}

- (void)removeDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  if ([delegate respondsToSelector:@selector(bannerAdSize)]) {
    @synchronized(_bannerDelegates) {
      if (delegate && (delegate == [_bannerDelegates objectForKey:delegate.desiredPlacement])) {
        GADMAdapterVungleMapTableRemoveObjectForKey(_bannerDelegates, delegate.desiredPlacement);
      }
      NSString *pubRequestID = [_bannerRequestingDict objectForKey:delegate.desiredPlacement];
      if ([pubRequestID isEqualToString:delegate.uniquePubRequestID] ||
          ([pubRequestID isEqualToString:GADMAdapterVungleNullPubRequestID] &&
           !delegate.uniquePubRequestID)) {
        if (!delegate.isRequestingBannerAdForRefresh) {
          GADMAdapterVungleMutableDictionaryRemoveObjectForKey(_bannerRequestingDict,
                                                               delegate.desiredPlacement);
        }
      }
    }
  } else {
    @synchronized(_delegates) {
      GADMAdapterVungleMapTableRemoveObjectForKey(_delegates, delegate.desiredPlacement);
    }
  }
}

- (BOOL)hasDelegateForPlacementID:(nonnull NSString *)placementID {
  NSMapTable<NSString *, id<GADMAdapterVungleDelegate>> *delegates;
  if ([self isSDKInitialized]) {
    delegates = [_delegates copy];
  } else {
    delegates = [_initializingDelegates copy];
  }

  for (NSString *key in delegates) {
    id<GADMAdapterVungleDelegate> delegate = [delegates objectForKey:key];
    if ([delegate.desiredPlacement isEqualToString:placementID]) {
      return YES;
    }
  }

  return NO;
}

- (nullable NSError *)loadAd:(nonnull NSString *)placement
                withDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  id<GADMAdapterVungleDelegate> adapterDelegate = [self getDelegateForPlacement:placement];
  if (adapterDelegate) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        GADMAdapterVungleErrorAdAlreadyLoaded,
        @"Can't request ad because another request is processing.");
    return error;
  }

  BOOL addSuccessed = [self addDelegate:delegate];
  if (!addSuccessed) {
    return GADMAdapterVungleErrorWithCodeAndDescription(
        GADMAdapterVungleErrorMultipleBanners, @"A banner ad type has already been "
                                               @"instantiated. Multiple banner ads are not "
                                               @"supported with Vungle iOS SDK.");
  }

  VungleSDK *sdk = VungleSDK.sharedSDK;
  if ([self isAdCachedForPlacementID:placement withDelegate:delegate]) {
    [delegate adAvailable];
    return nil;
  }

  // Vungle 6.7.0 SDK cannot handle a second loadPlacementWithID: call while the first ad load is in
  // progress. Work around this behavior by explicitly avoiding calling loadPlacementWithID: on the
  // first request for this placement, as the priority placement has already started loading at
  // initialization time.
  if ([_prioritizedPlacementID isEqualToString:placement]) {
    return nil;
  }

  NSError *loadError = nil;

  if ([delegate respondsToSelector:@selector(bannerAdSize)]) {
    GADAdSize adSize = [delegate bannerAdSize];

    // Vungle's MREC ads are a special case where Vungle prefers using isAdCachedForPlacementID:
    // as opposed to isAdCachedForPlacementID:withSize:.
    if (!GADAdSizeEqualToSize(adSize, GADAdSizeMediumRectangle)) {
      VungleAdSize vungleAdSize = GADMAdapterVungleAdSizeForCGSize(adSize.size);
      [sdk loadPlacementWithID:placement
                      adMarkup:[delegate bidResponse]
                      withSize:vungleAdSize
                         error:&loadError];
    } else {
      [sdk loadPlacementWithID:placement adMarkup:[delegate bidResponse] error:&loadError];
    }
  } else {
    [sdk loadPlacementWithID:placement adMarkup:[delegate bidResponse] error:&loadError];
  }

  return loadError;
}

- (BOOL)playAd:(nonnull UIViewController *)viewController
      delegate:(nonnull id<GADMAdapterVungleDelegate>)delegate
        extras:(nullable VungleAdNetworkExtras *)extras
         error:(NSError *_Nullable __autoreleasing *_Nullable)error {
  return [VungleSDK.sharedSDK playAd:viewController
                             options:GADMAdapterVunglePlaybackOptionsDictionaryForExtras(extras)
                         placementID:delegate.desiredPlacement
                               error:error];
}

- (nullable NSError *)renderBannerAdInView:(nonnull UIView *)bannerView
                                  delegate:(nonnull id<GADMAdapterVungleDelegate>)delegate
                                    extras:(nullable VungleAdNetworkExtras *)extras
                            forPlacementID:(nonnull NSString *)placementID {
  NSMutableDictionary *options = nil;
  if (extras) {
    options = [[NSMutableDictionary alloc] init];
    if (extras.muteIsSet) {
      GADMAdapterVungleMutableDictionarySetObjectForKey(options, VunglePlayAdOptionKeyStartMuted,
                                                        @(extras.muted));
    }
    if (extras.userId) {
      GADMAdapterVungleMutableDictionarySetObjectForKey(options, VunglePlayAdOptionKeyUser,
                                                        extras.userId);
    }
    if (extras.ordinal) {
      GADMAdapterVungleMutableDictionarySetObjectForKey(options, VunglePlayAdOptionKeyOrdinal,
                                                        @(extras.ordinal));
    }
    if (extras.flexViewAutoDismissSeconds) {
      GADMAdapterVungleMutableDictionarySetObjectForKey(
          options, VunglePlayAdOptionKeyFlexViewAutoDismissSeconds,
          @(extras.flexViewAutoDismissSeconds));
    }
  }

  NSError *bannerError = nil;

  BOOL success = [VungleSDK.sharedSDK addAdViewToView:bannerView
                                          withOptions:options
                                          placementID:placementID
                                                error:&bannerError];

  if (success) {
    // For a refresh banner delegate, if the Banner view is constructed successfully,
    // it will replace the old banner delegate.
    if (delegate.isRefreshedForBannerAd) {
      [self replaceOldBannerDelegateWithDelegate:delegate];
    }
  }
  return bannerError;
}

- (void)completeBannerAdViewForPlacementID:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  @synchronized(self) {
    if (!delegate || ![delegate respondsToSelector:@selector(bannerAdSize)]) {
      return;
    }

    if (delegate.bannerState == BannerRouterDelegateStatePlaying ||
        delegate.bannerState == BannerRouterDelegateStateWillPlay) {
      NSLog(@"Vungle: Triggering an ad completion call for %@", delegate.desiredPlacement);
      [VungleSDK.sharedSDK finishDisplayingAd:delegate.desiredPlacement];
    }
  }
}

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error {
  _isInitializing = NO;
  NSMapTable<NSString *, id<GADMAdapterVungleDelegate>> *delegates = [_initializingDelegates copy];
  for (NSString *key in delegates) {
    id<GADMAdapterVungleDelegate> delegate = [delegates objectForKey:key];
    [delegate initialized:isSuccess error:error];
  }

  [_initializingDelegates removeAllObjects];
  _prioritizedPlacementID = nil;
}

- (NSString *)getSuperToken {
  return [VungleSDK.sharedSDK currentSuperToken];
}

#pragma mark - VungleSDKDelegate methods

- (void)vungleWillShowAdForPlacementID:(nullable NSString *)placementID {
  if (!placementID.length) {
    return;
  }

  id<GADMAdapterVungleDelegate> delegate =
      [self getDelegateForPlacement:placementID
          withBannerRouterDelegateState:BannerRouterDelegateStateWillPlay];
  [delegate willShowAd];
}

- (void)vungleDidShowAdForPlacementID:(nullable NSString *)placementID {
  NSLog(@"Vungle: Did show Ad for placement ID:%@", placementID);
}

- (void)vungleAdViewedForPlacement:(NSString *)placementID {
  id<GADMAdapterVungleDelegate> delegate =
      [self getDelegateForPlacement:placementID
          withBannerRouterDelegateState:BannerRouterDelegateStatePlaying];
  [delegate didViewAd];
}

- (void)vungleWillCloseAdForPlacementID:(nonnull NSString *)placementID {
  id<GADMAdapterVungleDelegate> delegate =
      [self getDelegateForPlacement:placementID
          withBannerRouterDelegateState:BannerRouterDelegateStatePlaying];
  [delegate willCloseAd];
}

- (void)vungleDidCloseAdForPlacementID:(nonnull NSString *)placementID {
  id<GADMAdapterVungleDelegate> delegate =
      [self getDelegateForPlacement:placementID
          withBannerRouterDelegateState:BannerRouterDelegateStateClosing];

  if (!delegate) {
    return;
  }

  [delegate didCloseAd];
  [self removeDelegate:delegate];
}

- (void)vungleTrackClickForPlacementID:(nullable NSString *)placementID {
  id<GADMAdapterVungleDelegate> delegate =
      [self getDelegateForPlacement:placementID
          withBannerRouterDelegateState:BannerRouterDelegateStatePlaying];
  [delegate trackClick];
}

- (void)vungleRewardUserForPlacementID:(nullable NSString *)placementID {
  id<GADMAdapterVungleDelegate> delegate = [self getDelegateForPlacement:placementID];
  [delegate rewardUser];
}

- (void)vungleWillLeaveApplicationForPlacementID:(nullable NSString *)placementID {
  id<GADMAdapterVungleDelegate> delegate =
      [self getDelegateForPlacement:placementID
          withBannerRouterDelegateState:BannerRouterDelegateStatePlaying];
  [delegate willLeaveApplication];
}

- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable
                      placementID:(nullable NSString *)placementID
                            error:(nullable NSError *)error {
  id<GADMAdapterVungleDelegate> delegate = [self getDelegateForPlacement:placementID];
  if (!delegate) {
    return;
  }

  if (isAdPlayable) {
    [delegate adAvailable];
    return;
  }

  // Vungle SDK calls this method with isAdPlayable NO just after an ad is presented. These events
  // should be ignored as they aren't related to a load call. Assume an ad is presented if Vungle
  // SDK has an ad cached for this placement.
  if ([VungleSDK.sharedSDK isAdCachedForPlacementID:placementID]) {
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

- (void)vungleSDKDidInitialize {
  VungleSDK *sdk = VungleSDK.sharedSDK;
  if ([VungleRouterConsent getConsentStatus] > 0) {
    [sdk updateConsentStatus:[VungleRouterConsent getConsentStatus] consentMessageVersion:@""];
  }

  [self initialized:YES error:nil];
  [GADMAdapterVungleBiddingRouter.sharedInstance initialized:YES error:nil];
}

- (void)vungleSDKFailedToInitializeWithError:(nonnull NSError *)error {
  [self initialized:NO error:error];
  [GADMAdapterVungleBiddingRouter.sharedInstance initialized:NO error:error];
}

@end
