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

@implementation GADMAdapterVungleRouter {
  /// Map table to hold the interstitial or rewarded ad delegates with placement ID as a key.
  NSMapTable<NSString *, id<VungleDelegate>> *_delegates;

  /// Map table to hold the Vungle SDK delegates with placement ID as a key.
  NSMapTable<NSString *, id<VungleDelegate>> *_initializingDelegates;

  /// Map table to hold the banner ad delegates with placement ID as a key.
  NSMapTable<NSString *, id<VungleDelegate>> *_bannerDelegates;

  /// Indicates whether a banner ad is presenting.
  BOOL _isBannerPresenting;

  /// Vungle's banner placement ID.
  NSString *_bannerPlacementID;

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

- (void)initWithAppId:(nonnull NSString *)appId delegate:(nullable id<VungleDelegate>)delegate {
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
    [self initialized:true error:nil];
    return;
  }

  if (_isInitializing) {
    return;
  }

  _isInitializing = YES;
  _isBannerPresenting = NO;

  NSError *err = nil;
  [sdk startWithAppId:appId error:&err];
  if (err) {
    [self initialized:false error:err];
  }
}

- (BOOL)isSDKInitialized {
  return [[VungleSDK sharedSDK] isInitialized];
}

- (BOOL)isAdCachedForPlacementID:(nonnull NSString *)placementID {
  return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementID];
}

- (void)addDelegate:(nonnull id<VungleDelegate>)delegate {
  if (delegate.adapterAdType == GADMAdapterVungleAdTypeInterstitial ||
      delegate.adapterAdType == GADMAdapterVungleAdTypeRewarded) {
    @synchronized(_delegates) {
      if (delegate && ![_delegates objectForKey:delegate.desiredPlacement]) {
        GADMAdapterVungleMapTableSetObjectForKey(_delegates, delegate.desiredPlacement, delegate);
      }
    }
  } else if (delegate.adapterAdType == GADMAdapterVungleAdTypeBanner) {
    @synchronized(_bannerDelegates) {
      _bannerPlacementID = [delegate.desiredPlacement copy];
      if (delegate && ![_bannerDelegates objectForKey:delegate.desiredPlacement]) {
        GADMAdapterVungleMapTableSetObjectForKey(_bannerDelegates, delegate.desiredPlacement,
                                                 delegate);
      }
    }
  }
}

- (nullable id<VungleDelegate>)getDelegateForPlacement:(nonnull NSString *)placement {
  id<VungleDelegate> delegate;
  if ([placement isEqualToString:_bannerPlacementID]) {
    @synchronized(_bannerDelegates) {
      if ([_bannerDelegates objectForKey:placement]) {
        delegate = [_bannerDelegates objectForKey:placement];
        if (delegate.bannerState != BannerRouterDelegateStateRequesting) {
          delegate = nil;
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

- (void)removeDelegate:(nonnull id<VungleDelegate>)delegate {
  if (delegate.adapterAdType == GADMAdapterVungleAdTypeInterstitial ||
      delegate.adapterAdType == GADMAdapterVungleAdTypeRewarded) {
    @synchronized(_delegates) {
      if (delegate && [_delegates objectForKey:delegate.desiredPlacement]) {
        GADMAdapterVungleMapTableRemoveObjectForKey(_delegates, delegate.desiredPlacement);
      }
    }
  } else if (delegate.adapterAdType == GADMAdapterVungleAdTypeBanner) {
    @synchronized(_bannerDelegates) {
      if (delegate && [_bannerDelegates objectForKey:delegate.desiredPlacement]) {
        GADMAdapterVungleMapTableRemoveObjectForKey(_bannerDelegates, delegate.desiredPlacement);
      }
    }
  }
}

- (BOOL)hasDelegateForPlacementID:(nonnull NSString *)placementID
                      adapterType:(GADMAdapterVungleAdType)adapterType {
  NSMapTable<NSString *, id<VungleDelegate>> *delegates;
  if ([self isSDKInitialized]) {
    delegates = [_delegates copy];
  } else {
    delegates = [_initializingDelegates copy];
  }

  for (NSString *key in delegates) {
    id<VungleDelegate> delegate = [delegates objectForKey:key];
    if (delegate.adapterAdType == adapterType &&
        [delegate.desiredPlacement isEqualToString:placementID]) {
      return YES;
    }
  }

  return NO;
}

- (BOOL)canRequestBannerAdForPlacementID:(nonnull NSString *)placmentID {
  return _bannerPlacementID == nil || [_bannerPlacementID isEqualToString:placmentID];
}

- (nullable NSError *)loadAd:(nonnull NSString *)placement
                withDelegate:(nonnull id<VungleDelegate>)delegate {
  id<VungleDelegate> adapterDelegate = [self getDelegateForPlacement:placement];
  if (adapterDelegate) {
    NSError *error = [NSError errorWithDomain:kGADMAdapterVungleErrorDomain
                                         code:0
                                     userInfo:@{
                                       NSLocalizedDescriptionKey :
                                           @"Can't request ad if another request is in processing."
                                     }];
    return error;
  } else {
    [self addDelegate:delegate];
  }

  VungleSDK *sdk = [VungleSDK sharedSDK];
  if ([sdk isAdCachedForPlacementID:placement]) {
    [delegate adAvailable];
  } else {
    NSError *loadError;
    if (![sdk loadPlacementWithID:placement error:&loadError]) {
      if (loadError) {
        return loadError;
      }
    }
  }

  return nil;
}

- (BOOL)playAd:(nonnull UIViewController *)viewController
      delegate:(nonnull id<VungleDelegate>)delegate
        extras:(nullable VungleAdNetworkExtras *)extras {
  if (!delegate || !delegate.desiredPlacement ||
      ![[VungleSDK sharedSDK] isAdCachedForPlacementID:delegate.desiredPlacement]) {
    return false;
  }
  NSMutableDictionary *options = [[NSMutableDictionary alloc] init];  //
  NSError *error = nil;
  bool didAdStartPlaying = true;
  [VungleSDK sharedSDK].muted = extras.muted;
  if (extras.userId) [options setObject:extras.userId forKey:VunglePlayAdOptionKeyUser];
  if (extras.ordinal) [options setObject:@(extras.ordinal) forKey:VunglePlayAdOptionKeyOrdinal];
  if (extras.flexViewAutoDismissSeconds)
    [options setObject:@(extras.flexViewAutoDismissSeconds)
                forKey:VunglePlayAdOptionKeyFlexViewAutoDismissSeconds];
  if (![[VungleSDK sharedSDK] playAd:viewController
                             options:options
                         placementID:delegate.desiredPlacement
                               error:&error]) {
    didAdStartPlaying = false;
  }
  if (error) {
    NSLog(@"Adapter failed to present ad, error %@", [error localizedDescription]);
    didAdStartPlaying = false;
  }

  return didAdStartPlaying;
}

- (nullable UIView *)renderBannerAdInView:(nonnull UIView *)bannerView
                                 delegate:(nonnull id<VungleDelegate>)delegate
                                   extras:(nullable VungleAdNetworkExtras *)extras
                           forPlacementID:(nonnull NSString *)placementID {
  NSError *bannerError = nil;
  NSMutableDictionary *options = [[NSMutableDictionary alloc] init];  ///
  if (extras.muted) {
    [VungleSDK sharedSDK].muted = extras.muted;
  } else {
    [VungleSDK sharedSDK].muted = YES;
  }
  if (extras.userId) [options setObject:extras.userId forKey:VunglePlayAdOptionKeyUser];
  if (extras.ordinal) [options setObject:@(extras.ordinal) forKey:VunglePlayAdOptionKeyOrdinal];
  if (extras.flexViewAutoDismissSeconds)
    [options setObject:@(extras.flexViewAutoDismissSeconds)
                forKey:VunglePlayAdOptionKeyFlexViewAutoDismissSeconds];

  BOOL success = [[VungleSDK sharedSDK] addAdViewToView:bannerView
                                            withOptions:options
                                            placementID:placementID
                                                  error:&bannerError];
  if (success) {
    return bannerView;
  } else {
    NSLog(@"Banner loading error: %@", bannerError.localizedDescription);
    return nil;
  }

  return nil;
}

- (void)completeBannerAdViewForPlacementID:(nullable NSString *)placementID {
  if (_isBannerPresenting) {
    NSLog(@"Vungle: Triggering an ad completion call for %@", placementID);
    _isBannerPresenting = NO;

    [[VungleSDK sharedSDK] finishedDisplayingAd];
  }
}

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error {
  _isInitializing = NO;
  NSMapTable<NSString *, id<VungleDelegate>> *delegates = [_initializingDelegates copy];
  for (NSString *key in delegates) {
    id<VungleDelegate> delegate = [delegates objectForKey:key];
    [delegate initialized:isSuccess error:error];
  }

  [_initializingDelegates removeAllObjects];
}

#pragma mark - VungleSDKDelegate methods

- (void)vungleWillShowAdForPlacementID:(nullable NSString *)placementID {
  if (!placementID.length) {
    return;
  }
  id<VungleDelegate> delegate = [self getDelegateForPlacement:placementID];
  if (delegate) {
    [delegate willShowAd];
  }
}

- (void)vungleDidShowAdForPlacementID:(nullable NSString *)placementID {
  if ([placementID isEqualToString:_bannerPlacementID]) {
    _isBannerPresenting = YES;
  }
}

- (void)vungleWillCloseAdWithViewInfo:(nonnull VungleViewInfo *)info
                          placementID:(nonnull NSString *)placementID {
  id<VungleDelegate> delegate = [self getDelegateForPlacement:placementID];
  if (delegate) {
    [delegate willCloseAd:[info.completedView boolValue] didDownload:[info.didDownload boolValue]];
  }
}

- (void)vungleDidCloseAdWithViewInfo:(nonnull VungleViewInfo *)info
                         placementID:(nonnull NSString *)placementID {
  id<VungleDelegate> delegate = [self getDelegateForPlacement:placementID];
  if (delegate) {
    [delegate didCloseAd:[info.completedView boolValue] didDownload:[info.didDownload boolValue]];
    [self removeDelegate:delegate];
  }
}

- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable
                      placementID:(nullable NSString *)placementID
                            error:(nullable NSError *)error {
  id<VungleDelegate> delegate = [self getDelegateForPlacement:placementID];
  if (!delegate) {
    return;
  }
  if (isAdPlayable) {
    [delegate adAvailable];
  } else if (error) {
    NSLog(@"Vungle Ad Playability returned an error: %@", error.localizedDescription);
    [delegate adNotAvailable:error];
    [self removeDelegate:delegate];
  }
}

- (void)vungleSDKDidInitialize {
  VungleSDK *sdk = [VungleSDK sharedSDK];
  if ([VungleRouterConsent getConsentStatus] > 0) {
    [sdk updateConsentStatus:[VungleRouterConsent getConsentStatus] consentMessageVersion:@""];
  }

  [self initialized:true error:nil];
}

- (void)vungleSDKFailedToInitializeWithError:(nonnull NSError *)error {
  [self initialized:false error:error];
}

@end
