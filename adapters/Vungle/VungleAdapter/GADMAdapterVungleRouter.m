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
#import "GADMAdapterVungleBannerRequest.h"

const CGSize kVNGBannerShortSize = {300, 50};

@implementation GADMAdapterVungleRouter {
  /// Map table to hold the interstitial or rewarded ad delegates with placement ID as a key.
  NSMapTable<NSString *, id<GADMAdapterVungleDelegate>> *_delegates;

  /// Map table to hold the Vungle SDK delegates with placement ID as a key.
  NSMapTable<NSString *, id<GADMAdapterVungleDelegate>> *_initializingDelegates;

  /// Map table to hold the banner ad delegates with placement ID as a key.
  NSMapTable<GADMAdapterVungleBannerRequest *, id<GADMAdapterVungleDelegate>> *_bannerDelegates;

  /// Indicates whether a banner ad is presenting.
  BOOL _isBannerPresenting;

  /// Vungle's BannerRequest which inclues banner placementID and banner uniquePubRequestID.
  GADMAdapterVungleBannerRequest *_bannerRequest;

  /// Indicates whether the Vungle SDK is initializing.
  BOOL _isInitializing;
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
  _isBannerPresenting = NO;

  //Disable refresh functionality for all banners
  [[VungleSDK sharedSDK] disableBannerRefresh];

  NSError *err = nil;
  [sdk startWithAppId:appId error:&err];
  if (err) {
    [self initialized:NO error:err];
  }
}

- (BOOL)isSDKInitialized {
  return [[VungleSDK sharedSDK] isInitialized];
}

- (BOOL)isAdCachedForPlacementID:(nonnull NSString *)placementID withDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  GADMAdapterVungleAdType adType = [delegate adapterAdType];
  if (adType != GADMAdapterVungleAdTypeBanner && adType != GADMAdapterVungleAdTypeShortBanner && adType != GADMAdapterVungleAdTypeLeaderboardBanner) {
    return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementID];
  }

  return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementID withSize:[self getVungleBannerAdSizeType:adType]];
}

- (BOOL)addDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  if (!delegate) {
    return NO;
  }

  if (delegate.adapterAdType == GADMAdapterVungleAdTypeInterstitial ||
      delegate.adapterAdType == GADMAdapterVungleAdTypeRewarded) {
    @synchronized(_delegates) {
      if (![_delegates objectForKey:delegate.desiredPlacement]) {
        GADMAdapterVungleMapTableSetObjectForKey(_delegates, delegate.desiredPlacement, delegate);
      }
    }
  } else if ([delegate respondsToSelector:@selector(isBannerAd)] && [delegate isBannerAd]) {
    @synchronized(_bannerDelegates) {
      // We only support displaying one Vungle Banner Ad at the same time currently
      if (_bannerRequest != nil && ![_bannerRequest isEqualToBannerRequest:delegate.bannerRequest]) {
        return NO;
      }

      if (![_bannerDelegates objectForKey:delegate.bannerRequest]) {
        NSEnumerator *enumerator = _bannerDelegates.keyEnumerator;
        GADMAdapterVungleBannerRequest *vungleBannerRequest = nil;
        while (vungleBannerRequest = [enumerator nextObject]) {
          // There is already a banner delegate with same placementID
          // but different uniquePubRequestID in _bannerDelegates.
          if ([vungleBannerRequest.placementID isEqualToString:delegate.bannerRequest.placementID]) {
            return NO;
          } else if (vungleBannerRequest.placementID.length > 0 && ![vungleBannerRequest.placementID isEqualToString:delegate.bannerRequest.placementID]) {
            // There is already a banner delegate with different placementID in _bannerDelegates.
            if (!_bannerRequest) {
              _bannerRequest = [vungleBannerRequest copy];
            }
            return NO;
          }
        }

        GADMAdapterVungleMapTableSetObjectForKey(_bannerDelegates, delegate.bannerRequest, delegate);
        _bannerRequest = [delegate.bannerRequest copy];
      } else {
        id<GADMAdapterVungleDelegate> bannerDelegate = [_bannerDelegates objectForKey:delegate.bannerRequest];

        /* The isRequestingBannerAdForRefresh flag is used for an edge case, when the old Banner
         * delegate is removed from _bannerDelegates and there is a refresh Banner delegate doesn't
         * construct Banner view successfully and add to _bannerDelegates yet. Adapter cannot set
         * _bannerRequest to nil to prevent requesting another Banner ad with different bannerRequest.
         */
        bannerDelegate.isRequestingBannerAdForRefresh = YES;
        delegate.isRefreshedForBannerAd = YES;
      }
    }
  }
  return YES;
}

- (void)replaceOldBannerDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  if (!delegate) {
    return;
  }

  if ([delegate respondsToSelector:@selector(isBannerAd)] && [delegate isBannerAd]) {
    @synchronized(_bannerDelegates) {
      // We only support displaying one Vungle Banner Ad at the same time currently
      if (_bannerRequest != nil && ![_bannerRequest isEqualToBannerRequest:delegate.bannerRequest]) {
        return;
      }

      GADMAdapterVungleMapTableSetObjectForKey(_bannerDelegates, delegate.bannerRequest, delegate);
      if (!_bannerRequest) {
        _bannerRequest = [delegate.bannerRequest copy];
      }
    }
  }
}

- (nullable id<GADMAdapterVungleDelegate>)getDelegateForPlacement:(nonnull NSString *)placement {
  return [self getDelegateForPlacement:placement withBannerRouterDelegateState:BannerRouterDelegateStateRequesting];
}

- (nullable id<GADMAdapterVungleDelegate>)getDelegateForPlacement:(nonnull NSString *)placement withBannerRouterDelegateState:(BannerRouterDelegateState)bannerState {
  id<GADMAdapterVungleDelegate> delegate = nil;
  if ([placement isEqualToString:_bannerRequest.placementID]) {
    @synchronized(_bannerDelegates) {
      NSEnumerator *enumerator = _bannerDelegates.keyEnumerator;
      GADMAdapterVungleBannerRequest *vungleBannerRequest = nil;
      while (vungleBannerRequest = [enumerator nextObject]) {
        if ([vungleBannerRequest.placementID isEqualToString:placement]) {
          id<GADMAdapterVungleDelegate> bannerDelegate = [_bannerDelegates objectForKey:vungleBannerRequest];
          if (bannerDelegate.bannerState == bannerState) {
            return bannerDelegate;
          }
        }
      }
    }
  } else {
    @synchronized(_delegates) {
      if ([_delegates objectForKey:placement]) {
        delegate = [_delegates objectForKey:placement];
      }
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
      if (delegate && (delegate == [_bannerDelegates objectForKey:delegate.bannerRequest])) {
        if ([delegate.bannerRequest isEqualToBannerRequest:_bannerRequest]) {
          if (!_isBannerPresenting && !delegate.isRequestingBannerAdForRefresh) {
            _bannerRequest = nil;
          }
        }
        GADMAdapterVungleMapTableRemoveObjectForKey(_bannerDelegates, delegate.bannerRequest);
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

- (BOOL)canRequestBannerAdForPlacementID:(nonnull GADMAdapterVungleBannerRequest *)bannerRequest {
  @synchronized(_bannerDelegates) {
    if (_bannerDelegates.count > 0) {
      return _bannerRequest == nil || [_bannerRequest isEqualToBannerRequest:bannerRequest];
    }
    return YES;
  }
}

- (nullable NSError *)loadAd:(nonnull NSString *)placement
                withDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate {
  id<GADMAdapterVungleDelegate> adapterDelegate = [self getDelegateForPlacement:placement];
  if (adapterDelegate) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        kGADErrorMediationAdapterError, @"Can't request ad if another request is processing.");
    return error;
  }
  BOOL addSuccessed = [self addDelegate:delegate];
  if (!addSuccessed) {
    NSError *error = nil;
    if (delegate) {
      error = GADMAdapterVungleErrorWithCodeAndDescription(
                                                           kGADErrorMediationAdapterError, @"A banner ad type has already been "
                                                           @"instantiated. Multiple banner ads are not "
                                                           @"supported with Vungle iOS SDK.");
    } else {
      error = GADMAdapterVungleErrorWithCodeAndDescription(
                                                           kGADErrorMediationAdapterError, @"Can't load ad when try to add a nil delegate.");
    }
    return error;
  }

  VungleSDK *sdk = [VungleSDK sharedSDK];
  if ([self isAdCachedForPlacementID:placement withDelegate:delegate]) {
    [delegate adAvailable];
  } else {
    NSError *loadError;
    GADMAdapterVungleAdType adType = [delegate adapterAdType];
    if (adType != GADMAdapterVungleAdTypeBanner && adType != GADMAdapterVungleAdTypeShortBanner && adType != GADMAdapterVungleAdTypeLeaderboardBanner) {
        if (![sdk loadPlacementWithID:placement error:&loadError]) {
              if (loadError) {
                  return loadError;
              }
          }
    } else {
        if (![sdk loadPlacementWithID:placement withSize:[self getVungleBannerAdSizeType:adType] error:&loadError]) {
            if ((loadError) && (loadError.code != VungleSDKResetPlacementForDifferentAdSize)) {
                return loadError;
            }
        }
    }
  }

  return nil;
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
    GADMAdapterVungleMutableDictionarySetObjectForKey(
        options, VunglePlayAdOptionKeyOrientations,
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
      [self replaceOldBannerDelegate:delegate];
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

    if (![_bannerDelegates objectForKey:delegate.bannerRequest]) {
      return;
    }

    if ((_isBannerPresenting && delegate.bannerState == BannerRouterDelegateStatePlaying) || delegate.bannerState == BannerRouterDelegateStateWillPlay) {
      NSLog(@"Vungle: Triggering an ad completion call for %@", delegate.desiredPlacement);

      [[VungleSDK sharedSDK] finishedDisplayingAd];
      _isBannerPresenting = NO;
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
}

#pragma mark - VungleSDKDelegate methods

- (void)vungleWillShowAdForPlacementID:(nullable NSString *)placementID {
  if (!placementID.length) {
    return;
  }

  id<GADMAdapterVungleDelegate> delegate = [self getDelegateForPlacement:placementID withBannerRouterDelegateState:BannerRouterDelegateStateWillPlay];

  [delegate willShowAd];
}

- (void)vungleDidShowAdForPlacementID:(nullable NSString *)placementID {
  if ([placementID isEqualToString:_bannerRequest.placementID]) {
    _isBannerPresenting = YES;
  } else if (!_bannerRequest) {
    id<GADMAdapterVungleDelegate> delegate = [self getDelegateForPlacement:placementID withBannerRouterDelegateState:BannerRouterDelegateStatePlaying];
    // The delegate is not Interstitial or Rewarded Video Ad
    if (!delegate) {
      _isBannerPresenting = YES;
    }
  }
}

- (void)vungleWillCloseAdWithViewInfo:(nonnull VungleViewInfo *)info
                          placementID:(nonnull NSString *)placementID {
  id<GADMAdapterVungleDelegate> delegate = [self getDelegateForPlacement:placementID withBannerRouterDelegateState:BannerRouterDelegateStatePlaying];
  [delegate willCloseAd:[info.completedView boolValue] didDownload:[info.didDownload boolValue]];
}

- (void)vungleDidCloseAdWithViewInfo:(nonnull VungleViewInfo *)info
                         placementID:(nonnull NSString *)placementID {
  id<GADMAdapterVungleDelegate> delegate = [self getDelegateForPlacement:placementID withBannerRouterDelegateState:BannerRouterDelegateStateClosing];

  if (!delegate) {
    return;
  }

  [delegate didCloseAd:[info.completedView boolValue] didDownload:[info.didDownload boolValue]];
  [self removeDelegate:delegate];
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
  } else if (!isAdPlayable && ![[VungleSDK sharedSDK] isAdCachedForPlacementID:placementID]) {
    if (error) {
      NSLog(@"Vungle Ad Playability returned an error: %@", error.localizedDescription);
    } else {
      error = GADMAdapterVungleErrorWithCodeAndDescription(kGADErrorMediationAdapterError, [NSString stringWithFormat:@"Ad is not available for placementID: %@.", placementID]);
    }
    [delegate adNotAvailable:error];
    [self removeDelegate:delegate];
  }
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
