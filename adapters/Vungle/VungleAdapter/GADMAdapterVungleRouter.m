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
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleUtils.h"
#import "VungleRouterConsent.h"

const CGSize kVNGBannerShortSize = {300, 50};

static NSString *const _Nonnull kGADMAdapterVungleNullPubRequestID = @"null";

@implementation GADMAdapterVungleRouter {
  /// Map table to hold the interstitial or rewarded ad delegates with placement ID as a key.
  NSMapTable<NSString *, id<GADMAdapterVungleDelegate>> *_delegates;

  /// Map table to hold the Vungle SDK delegates with placement ID as a key.
  NSMapTable<NSString *, id<GADMAdapterVungleDelegate>> *_initializingDelegates;

  /// Map table to hold the banner ad delegates with placement ID as a key.
  NSMapTable<NSString *, id<GADMAdapterVungleDelegate>> *_bannerDelegates;

  /// Dictionary to hold the placement ID and uniquePubRequestID for banners are being requested
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
    [VungleSDK sharedSDK].delegate = self;
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
    NSString *version = [kGADMAdapterVungleVersion stringByReplacingOccurrencesOfString:@"."
                                                                             withString:@"_"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [[VungleSDK sharedSDK] performSelector:@selector(setPluginName:version:)
                                withObject:@"admob"
                                withObject:version];
#pragma clang diagnostic pop
  });
  VungleSDK *sdk = [VungleSDK sharedSDK];

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

  _isInitializing = YES;

  // Disable refresh functionality for all banners
  [[VungleSDK sharedSDK] disableBannerRefresh];

  // Set init options for priority placement
  NSMutableDictionary *initOptions = [NSMutableDictionary dictionary];
  if (delegate) {
    NSString *priorityPlacementID = delegate.desiredPlacement;
    [initOptions setObject:priorityPlacementID forKey:VungleSDKInitOptionKeyPriorityPlacementID];
    _prioritizedPlacementID = [priorityPlacementID copy];

    NSInteger priorityPlacementAdSize = 1;
    GADMAdapterVungleAdType adType = [delegate adapterAdType];
    if (adType == GADMAdapterVungleAdTypeBanner || adType == GADMAdapterVungleAdTypeShortBanner || adType == GADMAdapterVungleAdTypeLeaderboardBanner) {
      priorityPlacementAdSize = [self getVungleBannerAdSizeType:adType];
    }
    [initOptions setObject:[NSNumber numberWithInteger:priorityPlacementAdSize] forKey:VungleSDKInitOptionKeyPriorityPlacementAdSize];
  }
     
  NSError *err = nil;
  [sdk startWithAppId:appId options:initOptions error:&err];
  if (err) {
    [self initialized:NO error:err];
  }
}

- (BOOL)isSDKInitialized {
  return [[VungleSDK sharedSDK] isInitialized];
}

- (BOOL)isAdCachedForPlacementID:(nonnull NSString *)placementID
                    withDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  GADMAdapterVungleAdType adType = [delegate adapterAdType];
  if (adType != GADMAdapterVungleAdTypeBanner && adType != GADMAdapterVungleAdTypeShortBanner &&
      adType != GADMAdapterVungleAdTypeLeaderboardBanner) {
    return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementID];
  }

  return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementID
                                                withSize:[self getVungleBannerAdSizeType:adType]];
}

- (BOOL)addDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  if (delegate.adapterAdType == GADMAdapterVungleAdTypeInterstitial ||
      delegate.adapterAdType == GADMAdapterVungleAdTypeRewarded) {
    @synchronized(_delegates) {
      if (![_delegates objectForKey:delegate.desiredPlacement]) {
        GADMAdapterVungleMapTableSetObjectForKey(_delegates, delegate.desiredPlacement, delegate);
        return YES;
      }
    }
  } else if ([delegate respondsToSelector:@selector(isBannerAd)] && [delegate isBannerAd]) {
    @synchronized(_bannerDelegates) {
      if (![_bannerDelegates objectForKey:delegate.desiredPlacement] &&
          ![_bannerRequestingDict objectForKey:delegate.desiredPlacement]) {
        GADMAdapterVungleMapTableSetObjectForKey(_bannerDelegates, delegate.desiredPlacement,
                                                 delegate);
        GADMAdapterVungleMutableDictionarySetObjectForKey(_bannerRequestingDict, delegate.desiredPlacement,
                                                          delegate.uniquePubRequestID ? :
                                                          kGADMAdapterVungleNullPubRequestID);
        return YES;
      } else if ([_bannerDelegates objectForKey:delegate.desiredPlacement]) {
        id<GADMAdapterVungleDelegate> bannerDelegate = [_bannerDelegates objectForKey:delegate.desiredPlacement];
        if ([bannerDelegate.uniquePubRequestID isEqualToString:delegate.uniquePubRequestID]){
          /* The isRequestingBannerAdForRefresh flag is used for an edge case, when the old Banner
           * delegate is removed from _bannerDelegates and there is a refresh Banner delegate doesn't
           * construct Banner view successfully and add to _bannerDelegates yet. Adapter cannot request
           * another Banner ad with same placement Id and different uniquePubRequestID.
           */
          bannerDelegate.isRequestingBannerAdForRefresh = YES;
          delegate.isRefreshedForBannerAd = YES;
          return YES;
        }

        if (!bannerDelegate.uniquePubRequestID) {
          NSLog(@"Ad already loaded for placement ID: %@, and cannot determine if this is a refresh. Set "
          @"Vungle extras when making an ad request to support refresh on Vungle banner ads.",
          bannerDelegate.desiredPlacement);
        } else {
          NSLog(@"Ad already loaded for placement ID: %@", bannerDelegate.desiredPlacement);
        }
      }
    }
  }
  return NO;
}

- (void)replaceOldBannerDelegateWithDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  if ([delegate respondsToSelector:@selector(isBannerAd)] && [delegate isBannerAd]) {
    @synchronized(_bannerDelegates) {
      GADMAdapterVungleMapTableSetObjectForKey(_bannerDelegates, delegate.desiredPlacement, delegate);
    }
  }
}

- (nullable id<GADMAdapterVungleDelegate>)getDelegateForPlacement:(nonnull NSString *)placement {
  return [self getDelegateForPlacement:placement
         withBannerRouterDelegateState:BannerRouterDelegateStateRequesting];
}

- (nullable id<GADMAdapterVungleDelegate>)getDelegateForPlacement:(nonnull NSString *)placement
                                    withBannerRouterDelegateState:(BannerRouterDelegateState)bannerState {
  id<GADMAdapterVungleDelegate> delegate = nil;
  @synchronized(_bannerDelegates) {
    if ([_bannerDelegates objectForKey:placement]) {
      id<GADMAdapterVungleDelegate> bannerDelegate = [_bannerDelegates objectForKey:placement];
      if (bannerDelegate && bannerDelegate.bannerState == bannerState) {
        return bannerDelegate;
      }
    }
  }

  @synchronized(_delegates) {
    if ([_delegates objectForKey:placement]) {
      delegate = [_delegates objectForKey:placement];
    }
  }
  return delegate;
}

- (void)removeDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  if (delegate.adapterAdType == GADMAdapterVungleAdTypeInterstitial ||
      delegate.adapterAdType == GADMAdapterVungleAdTypeRewarded) {
    @synchronized(_delegates) {
      if (delegate && [_delegates objectForKey:delegate.desiredPlacement]) {
        GADMAdapterVungleMapTableRemoveObjectForKey(_delegates, delegate.desiredPlacement);
      }
    }
  } else if ([delegate respondsToSelector:@selector(isBannerAd)] && [delegate isBannerAd]) {
    @synchronized(_bannerDelegates) {
      if (delegate && (delegate == [_bannerDelegates objectForKey:delegate.desiredPlacement])) {
        GADMAdapterVungleMapTableRemoveObjectForKey(_bannerDelegates, delegate.desiredPlacement);
      }
      NSString *pubRequestID = [_bannerRequestingDict objectForKey:delegate.desiredPlacement];
      if ([pubRequestID isEqualToString:delegate.uniquePubRequestID] ||
          ([pubRequestID isEqualToString:kGADMAdapterVungleNullPubRequestID] &&
           !delegate.uniquePubRequestID)) {
        if (!delegate.isRequestingBannerAdForRefresh) {
          [_bannerRequestingDict removeObjectForKey:delegate.desiredPlacement];
        }
      }
    }
  }
}

- (BOOL)hasDelegateForPlacementID:(nonnull NSString *)placementID
                      adapterType:(GADMAdapterVungleAdType)adapterType {
  NSMapTable<NSString *, id<GADMAdapterVungleDelegate>> *delegates;
  if ([self isSDKInitialized]) {
    delegates = [_delegates copy];
  } else {
    delegates = [_initializingDelegates copy];
  }

  for (NSString *key in delegates) {
    id<GADMAdapterVungleDelegate> delegate = [delegates objectForKey:key];
    if (delegate.adapterAdType == adapterType &&
        [delegate.desiredPlacement isEqualToString:placementID]) {
      return YES;
    }
  }

  return NO;
}

- (nullable NSError *)loadAd:(nonnull NSString *)placement
                withDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  if (!delegate) {
    return GADMAdapterVungleErrorWithCodeAndDescription(
        kGADErrorMediationAdapterError, @"Can't load ad when try to add a nil delegate.");
  }

  id<GADMAdapterVungleDelegate> adapterDelegate = [self getDelegateForPlacement:placement];
  if (adapterDelegate) {
    return GADMAdapterVungleErrorWithCodeAndDescription(
        kGADErrorMediationAdapterError, @"Can't request ad if another request is processing.");
  }

  BOOL addSuccessed = [self addDelegate:delegate];
  if (!addSuccessed) {
    return  GADMAdapterVungleErrorWithCodeAndDescription(
        kGADErrorMediationAdapterError, [NSString stringWithFormat:
                                         @"Ad already loaded for placement ID: %@",placement]);
  }

  VungleSDK *sdk = [VungleSDK sharedSDK];
  if ([self isAdCachedForPlacementID:placement withDelegate:delegate]) {
    [delegate adAvailable];
    return nil;
  }

  // We already requested an ad for _prioritizedPlacementID,
  // so we don't need to request again.
  if ([_prioritizedPlacementID isEqualToString:placement]) {
    return nil;
  }

  NSError *loadError = nil;
  GADMAdapterVungleAdType adType = [delegate adapterAdType];
  if (adType != GADMAdapterVungleAdTypeBanner && adType != GADMAdapterVungleAdTypeShortBanner &&
      adType != GADMAdapterVungleAdTypeLeaderboardBanner) {
    [sdk loadPlacementWithID:placement error:&loadError];
  } else {
    [sdk loadPlacementWithID:placement
                    withSize:[self getVungleBannerAdSizeType:adType]
                       error:&loadError];
  }
  // For the VungleSDKResetPlacementForDifferentAdSize error, Vungle SDK currently still tries to
  // cache an ad for the new size. Adapter treats this as not an error for now.
  // TODO: Remove this error override once Vungle SDK is updated to stop returning this error.
  if (loadError.code == VungleSDKResetPlacementForDifferentAdSize) {
    loadError = nil;
  }
  return loadError;
}

- (VungleAdSize)getVungleBannerAdSizeType:(GADMAdapterVungleAdType)adType {
  switch (adType) {
    case GADMAdapterVungleAdTypeBanner:
      return VungleAdSizeBanner;
    case GADMAdapterVungleAdTypeShortBanner:
      return VungleAdSizeBannerShort;
    case GADMAdapterVungleAdTypeLeaderboardBanner:
      return VungleAdSizeBannerLeaderboard;
    default:
      return VungleAdSizeUnknown;
  }
}

- (BOOL)playAd:(nonnull UIViewController *)viewController
      delegate:(nonnull id<GADMAdapterVungleDelegate>)delegate
        extras:(nullable VungleAdNetworkExtras *)extras {
  if (!delegate || !delegate.desiredPlacement ||
      ![[VungleSDK sharedSDK] isAdCachedForPlacementID:delegate.desiredPlacement]) {
    return false;
  }
  NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
  NSError *error = nil;
  BOOL didAdStartPlaying = YES;
  [VungleSDK sharedSDK].muted = extras.muted;
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

  if (extras.orientations) {
    int appOrientation = [extras.orientations intValue];
    NSNumber *orientations = @(UIInterfaceOrientationMaskAll);
    if (appOrientation == 1) {
      orientations = @(UIInterfaceOrientationMaskLandscape);
    } else if (appOrientation == 2) {
      orientations = @(UIInterfaceOrientationMaskPortrait);
    }
    GADMAdapterVungleMutableDictionarySetObjectForKey(options, VunglePlayAdOptionKeyOrientations,
                                                      orientations);
  }

  if (![[VungleSDK sharedSDK] playAd:viewController
                             options:options
                         placementID:delegate.desiredPlacement
                               error:&error]) {
    didAdStartPlaying = NO;
  }

  if (error) {
    NSLog(@"Adapter failed to present ad, error %@", [error localizedDescription]);
    didAdStartPlaying = NO;
  }

  return didAdStartPlaying;
}

- (nullable UIView *)renderBannerAdInView:(nonnull UIView *)bannerView
                                 delegate:(nonnull id<GADMAdapterVungleDelegate>)delegate
                                   extras:(nullable VungleAdNetworkExtras *)extras
                           forPlacementID:(nonnull NSString *)placementID {
  NSError *bannerError = nil;
  NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
  if (extras != nil) {
    [VungleSDK sharedSDK].muted = extras.muted;
  } else {
    [VungleSDK sharedSDK].muted = YES;
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

  BOOL success = [[VungleSDK sharedSDK] addAdViewToView:bannerView
                                            withOptions:options
                                            placementID:placementID
                                                  error:&bannerError];
  if (success) {
    // For a refresh banner delegate, if the Banner view is constructed successfully,
    // it will replace the old banner delegate.
    if (delegate.isRefreshedForBannerAd) {
      [self replaceOldBannerDelegateWithDelegate:delegate];
    }
    return bannerView;
  }

  NSLog(@"Banner loading error: %@", bannerError.localizedDescription);
  return nil;
}

- (void)completeBannerAdViewForPlacementID:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  @synchronized(self) {
    if (!delegate) {
      return;
    }

    if (![_bannerDelegates objectForKey:delegate.desiredPlacement]) {
      return;
    }

    if (delegate.bannerState == BannerRouterDelegateStatePlaying ||
        delegate.bannerState == BannerRouterDelegateStateWillPlay) {
      NSLog(@"Vungle: Triggering an ad completion call for %@", delegate.desiredPlacement);
      [[VungleSDK sharedSDK] finishDisplayingAd:delegate.desiredPlacement];
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
  if (delegate.adapterAdType == GADMAdapterVungleAdTypeRewarded &&
      [delegate respondsToSelector:@selector(rewardUser)]) {
    [delegate rewardUser];
  }
}

- (void)vungleWillLeaveApplicationForPlacementID:(nullable NSString *)placementID {
  id<GADMAdapterVungleDelegate> delegate =
      [self getDelegateForPlacement:placementID
      withBannerRouterDelegateState:BannerRouterDelegateStatePlaying];
  if ([delegate respondsToSelector:@selector(willLeaveApplication)]) {
    [delegate willLeaveApplication];
  }
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
  if ([[VungleSDK sharedSDK] isAdCachedForPlacementID:placementID]) {
    return;
  }

  // Ad not playable. Return an error.
  if (error) {
    NSLog(@"Vungle Ad Playability returned an error: %@", error.localizedDescription);
  } else {
    error = GADMAdapterVungleErrorWithCodeAndDescription(
        kGADErrorMediationAdapterError,
        [NSString stringWithFormat:@"Ad is not available for placementID: %@.", placementID]);
  }
  [delegate adNotAvailable:error];
  [self removeDelegate:delegate];
}

- (void)vungleSDKDidInitialize {
  VungleSDK *sdk = [VungleSDK sharedSDK];
  if ([VungleRouterConsent getConsentStatus] > 0) {
    [sdk updateConsentStatus:[VungleRouterConsent getConsentStatus] consentMessageVersion:@""];
  }

  [self initialized:YES error:nil];
}

- (void)vungleSDKFailedToInitializeWithError:(nonnull NSError *)error {
  [self initialized:false error:error];
}

@end
