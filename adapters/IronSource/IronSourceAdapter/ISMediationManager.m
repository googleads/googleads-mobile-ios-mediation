// Copyright 2019 Google Inc.
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

#import "ISMediationManager.h"
#import "GADMAdapterIronSource.h"
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceUtils.h"
#import "GADMediationAdapterIronSource.h"

@interface ISMediationManager ()

@property(nonatomic)
    NSMapTable<NSString *, id<GADMAdapterIronSourceRewardedDelegate>> *rewardedAdapterDelegates;
@property(nonatomic) NSMapTable<NSString *, id<GADMAdapterIronSourceInterstitialDelegate>>
    *interstitialAdapterDelegates;

@end

@implementation ISMediationManager

+ (instancetype)sharedManager {
  static ISMediationManager *sharedMyManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedMyManager = [[self alloc] init];
  });
  return sharedMyManager;
}

- (instancetype)init {
  if (self = [super init]) {
    self.rewardedAdapterDelegates =
        [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                              valueOptions:NSPointerFunctionsWeakMemory];
    self.interstitialAdapterDelegates =
        [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                              valueOptions:NSPointerFunctionsWeakMemory];
    [IronSource
        setMediationType:[NSString
                             stringWithFormat:@"%@%@SDK%@", kGADMAdapterIronSourceMediationName,
                                              kGADMAdapterIronSourceInternalVersion,
                                              [GADMAdapterIronSourceUtils getAdMobSDKVersion]]];
  }
  return self;
}

- (void)initIronSourceSDKWithAppKey:(NSString *)appKey forAdUnits:(NSSet *)adUnits {
  if ([adUnits member:IS_INTERSTITIAL] != nil) {
    static dispatch_once_t onceTokenIS;
    dispatch_once(&onceTokenIS, ^{
      [IronSource setISDemandOnlyInterstitialDelegate:self];
      [IronSource initISDemandOnly:appKey adUnits:@[ IS_INTERSTITIAL ]];
    });
  }
  if ([adUnits member:IS_REWARDED_VIDEO] != nil) {
    static dispatch_once_t onceTokenRV;
    dispatch_once(&onceTokenRV, ^{
      [IronSource setISDemandOnlyRewardedVideoDelegate:self];
      [IronSource initISDemandOnly:appKey adUnits:@[ IS_REWARDED_VIDEO ]];
    });
  }
}

- (void)loadRewardedAdWithDelegate:(id<GADMAdapterIronSourceRewardedDelegate>)delegate
                        instanceID:(NSString *)instanceID {
  id<GADMAdapterIronSourceRewardedDelegate> adapterDelegate = delegate;

  if (adapterDelegate == nil) {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:@"loadRewardedAdWithDelegate adapterDelegate is null"]];
    return;
  }

  if ([self canLoadRewardedVideoInstance:instanceID]) {
    [self setRewardedDelegate:adapterDelegate toInstanceState:kInstanceStateLocked];
    [self addRewardedDelegate:adapterDelegate forInstanceID:instanceID];
    [GADMAdapterIronSourceUtils
        onLog:[NSString
                  stringWithFormat:@"ISMediationManager - loadRewardedVideo for instance Id %@",
                                   instanceID]];
    [IronSource loadISDemandOnlyRewardedVideo:instanceID];
  } else {
    NSError *Error =
        [GADMAdapterIronSourceUtils createErrorWith:@"instance already exists"
                                          andReason:@"couldn't load another one in the same time!"
                                      andSuggestion:nil];
    [adapterDelegate rewardedVideoDidFailToLoadWithError:Error instanceId:instanceID];
  }
}

- (void)presentRewardedAdFromViewController:(nonnull UIViewController *)viewController
                                 instanceID:(NSString *)instanceID {
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"ISMediationManager - showRewardedVideo for instance Id %@",
                                       instanceID]];
  [IronSource showISDemandOnlyRewardedVideo:viewController instanceId:instanceID];
}

- (void)loadInterstitialAdWithDelegate:(id<GADMAdapterIronSourceInterstitialDelegate>)delegate
                            instanceID:(NSString *)instanceID {
  id<GADMAdapterIronSourceInterstitialDelegate> adapterDelegate = delegate;
  if (adapterDelegate == nil) {
    [GADMAdapterIronSourceUtils
        onLog:[NSString
                  stringWithFormat:@"requestInterstitialAdWithDelegate adapterDelegate is null"]];
    return;
  }
  if ([self canLoadInterstitialInstance:instanceID]) {
    [self setInterstitialDelegate:adapterDelegate toInstanceState:kInstanceStateLocked];
    [self addInterstitialDelegate:adapterDelegate forInstanceID:instanceID];
    [GADMAdapterIronSourceUtils
        onLog:[NSString
                  stringWithFormat:@"ISMediationManager - loadInterstitial  for instance Id %@",
                                   instanceID]];
    [IronSource loadISDemandOnlyInterstitial:instanceID];
  } else {
    NSError *Error =
        [GADMAdapterIronSourceUtils createErrorWith:@"instance already exists"
                                          andReason:@"couldn't load another one in the same time!"
                                      andSuggestion:nil];
    [adapterDelegate interstitialDidFailToLoadWithError:Error instanceId:instanceID];
  }
}

- (void)presentInterstitialAdFromViewController:(nonnull UIViewController *)viewController
                                     instanceID:(NSString *)instanceID {
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"ISMediationManager - showInterstitial for instance Id %@",
                                       instanceID]];
  [IronSource showISDemandOnlyInterstitial:viewController instanceId:instanceID];
}

#pragma mark ISDemandOnlyRewardedDelegate

- (void)rewardedVideoAdRewarded:(NSString *)instanceID {
  [GADMAdapterIronSourceUtils
      onLog:[NSString
                stringWithFormat:@"ISMediationManager got rewardedVideoAdRewarded for instance %@",
                                 instanceID]];
  id<GADMAdapterIronSourceRewardedDelegate> delegate =
      [self getRewardedDelegateForInstanceID:instanceID];
  if (delegate) {
    [delegate rewardedVideoAdRewarded:instanceID];
  } else {
    [GADMAdapterIronSourceUtils
        onLog:[NSString
                  stringWithFormat:
                      @"ISMediationManager - rewardedVideoAdRewarded adapterDelegate is null"]];
  }
}

- (void)rewardedVideoDidFailToShowWithError:(NSError *)error instanceId:(NSString *)instanceID {
  [GADMAdapterIronSourceUtils
      onLog:[NSString
                stringWithFormat:@"ISMediationManager got rewardedVideoDidFailToShowWithError for "
                                 @"instance %@ with error %@",
                                 instanceID, error]];
  id<GADMAdapterIronSourceRewardedDelegate> delegate =
      [self getRewardedDelegateForInstanceID:instanceID];
  if (delegate) {
    [self setRewardedDelegate:delegate toInstanceState:kInstanceStateCanLoad];
    [delegate rewardedVideoDidFailToShowWithError:error instanceId:instanceID];
  } else {
    [GADMAdapterIronSourceUtils
        onLog:[NSString
                  stringWithFormat:@"ISMediationManager - rewardedVideoDidFailToShowWithError "
                                   @"adapterDelegate is null"]];
  }
}

- (void)rewardedVideoDidOpen:(NSString *)instanceID {
  [GADMAdapterIronSourceUtils
      onLog:[NSString
                stringWithFormat:@"ISMediationManager got rewardedVideoDidOpen for instance %@",
                                 instanceID]];
  id<GADMAdapterIronSourceRewardedDelegate> delegate =
      [self getRewardedDelegateForInstanceID:instanceID];
  if (delegate) {
    [delegate rewardedVideoDidOpen:instanceID];
  } else {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:
                            @"ISMediationManager - rewardedVideoDidOpen adapterDelegate is null"]];
  }
}

- (void)rewardedVideoDidClose:(NSString *)instanceID {
  [GADMAdapterIronSourceUtils
      onLog:[NSString
                stringWithFormat:@"ISMediationManager got rewardedVideoDidClose for instance %@",
                                 instanceID]];
  id<GADMAdapterIronSourceRewardedDelegate> delegate =
      [self getRewardedDelegateForInstanceID:instanceID];
  if (delegate) {
    [self setRewardedDelegate:delegate toInstanceState:kInstanceStateCanLoad];
    [delegate rewardedVideoDidClose:instanceID];
  } else {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:
                            @"ISMediationManager - rewardedVideoDidClose adapterDelegate is null"]];
  }
}

- (void)rewardedVideoDidClick:(NSString *)instanceID {
  [GADMAdapterIronSourceUtils
      onLog:[NSString
                stringWithFormat:@"ISMediationManager got rewardedVideoDidClick for instance %@",
                                 instanceID]];

  id<GADMAdapterIronSourceRewardedDelegate> delegate =
      [self getRewardedDelegateForInstanceID:instanceID];
  if (delegate) {
    [delegate rewardedVideoDidClick:instanceID];
  } else {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:
                            @"ISMediationManager - rewardedVideoDidClick adapterDelegate is null"]];
  }
}

- (void)rewardedVideoDidLoad:(NSString *)instanceID {
  [GADMAdapterIronSourceUtils
      onLog:[NSString
                stringWithFormat:@"ISMediationManager got rewardedVideoDidLoad for instance %@",
                                 instanceID]];

  id<GADMAdapterIronSourceRewardedDelegate> delegate =
      [self getRewardedDelegateForInstanceID:instanceID];
  if (delegate) {
    [delegate rewardedVideoDidLoad:instanceID];
  } else {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:
                            @"ISMediationManager - rewardedVideoDidLoad adapterDelegate is null"]];
  }
}

- (void)rewardedVideoDidFailToLoadWithError:(NSError *)error instanceId:(NSString *)instanceID {
  [GADMAdapterIronSourceUtils
      onLog:[NSString
                stringWithFormat:@"ISMediationManager got rewardedVideoDidFailToLoadWithError for "
                                 @"instance %@ with error %@",
                                 instanceID, error]];
  id<GADMAdapterIronSourceRewardedDelegate> delegate =
      [self getRewardedDelegateForInstanceID:instanceID];
  if (delegate) {
    [self setRewardedDelegate:delegate toInstanceState:kInstanceStateCanLoad];
    [delegate rewardedVideoDidFailToLoadWithError:error instanceId:instanceID];
  } else {
    [GADMAdapterIronSourceUtils
        onLog:[NSString
                  stringWithFormat:@"ISMediationManager - rewardedVideoDidFailToLoadWithError "
                                   @"adapterDelegate is null"]];
  }
}

#pragma mark ISDemandOnlyInterstitialDelegate

- (void)interstitialDidLoad:(NSString *)instanceID {
  id<GADMAdapterIronSourceInterstitialDelegate> delegate =
      [self getInterstitialDelegateForInstanceID:instanceID];
  if (delegate) {
    [delegate interstitialDidLoad:instanceID];
  } else {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:
                            @"ISMediationManager - interstitialDidLoad adapterDelegate is null"]];
  }
}

- (void)interstitialDidFailToLoadWithError:(NSError *)error instanceId:(NSString *)instanceID {
  id<GADMAdapterIronSourceInterstitialDelegate> delegate =
      [self getInterstitialDelegateForInstanceID:instanceID];
  if (delegate) {
    [self setInterstitialDelegate:delegate toInstanceState:kInstanceStateCanLoad];
    [delegate interstitialDidFailToLoadWithError:error instanceId:instanceID];
  } else {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:@"ISMediationManager - interstitialDidFailToLoadWithError "
                                         @"adapterDelegate is null"]];
  }
}

- (void)interstitialDidOpen:(NSString *)instanceID {
  id<GADMAdapterIronSourceInterstitialDelegate> delegate =
      [self getInterstitialDelegateForInstanceID:instanceID];
  if (delegate) {
    [delegate interstitialDidOpen:instanceID];
  } else {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:
                            @"ISMediationManager - interstitialDidOpen adapterDelegate is null"]];
  }
}

- (void)interstitialDidClose:(NSString *)instanceID {
  id<GADMAdapterIronSourceInterstitialDelegate> delegate =
      [self getInterstitialDelegateForInstanceID:instanceID];
  if (delegate) {
    [self setInterstitialDelegate:delegate toInstanceState:kInstanceStateCanLoad];
    [delegate interstitialDidClose:instanceID];
  } else {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:
                            @"ISMediationManager - interstitialDidClose adapterDelegate is null"]];
  }
}

- (void)interstitialDidFailToShowWithError:(NSError *)error instanceId:(NSString *)instanceID {
  id<GADMAdapterIronSourceInterstitialDelegate> delegate =
      [self getInterstitialDelegateForInstanceID:instanceID];
  if (delegate) {
    [self setInterstitialDelegate:delegate toInstanceState:kInstanceStateCanLoad];
    [delegate interstitialDidFailToShowWithError:error instanceId:instanceID];
  } else {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:@"ISMediationManager - interstitialDidFailToShowWithError "
                                         @"adapterDelegate is null"]];
  }
}

- (void)didClickInterstitial:(NSString *)instanceID {
  id<GADMAdapterIronSourceInterstitialDelegate> delegate =
      [self getInterstitialDelegateForInstanceID:instanceID];
  if (delegate) {
    [delegate didClickInterstitial:instanceID];
  } else {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:
                            @"ISMediationManager - didClickInterstitial adapterDelegate is null"]];
  }
}

#pragma Utils methods

- (void)addRewardedDelegate:(id<GADMAdapterIronSourceRewardedDelegate>)adapterDelegate
              forInstanceID:(NSString *)instanceID {
  @synchronized(self.rewardedAdapterDelegates) {
    [self.rewardedAdapterDelegates setObject:adapterDelegate forKey:instanceID];
  }
}

- (id<GADMAdapterIronSourceRewardedDelegate>)getRewardedDelegateForInstanceID:
    (NSString *)instanceID {
  id<GADMAdapterIronSourceRewardedDelegate> delegate;
  @synchronized(self.rewardedAdapterDelegates) {
    delegate = [self.rewardedAdapterDelegates objectForKey:instanceID];
  }
  return delegate;
}

- (void)addInterstitialDelegate:(id<GADMAdapterIronSourceInterstitialDelegate>)adapterDelegate
                  forInstanceID:(NSString *)instanceID {
  @synchronized(self.interstitialAdapterDelegates) {
    [self.interstitialAdapterDelegates setObject:adapterDelegate forKey:instanceID];
  }
}

- (id<GADMAdapterIronSourceInterstitialDelegate>)getInterstitialDelegateForInstanceID:
    (NSString *)instanceID {
  id<GADMAdapterIronSourceInterstitialDelegate> delegate;
  @synchronized(self.interstitialAdapterDelegates) {
    delegate = [self.interstitialAdapterDelegates objectForKey:instanceID];
  }
  return delegate;
}

- (BOOL)canLoadRewardedVideoInstance:(NSString *)instanceID {
  if (![self isISRewardedVideoAdapterRegistered:instanceID]) {
    return true;
  }

  if ([self isRegisteredRewardedVideoAdapterCanLoad:instanceID]) {
    return true;
  }

  return false;
}

- (BOOL)isRegisteredRewardedVideoAdapterCanLoad:(NSString *)instanceID {
  id<GADMAdapterIronSourceRewardedDelegate> adapterDelegate =
      [self getRewardedDelegateForInstanceID:instanceID];
  return adapterDelegate == nil ||
         [[adapterDelegate getState] isEqualToString:kInstanceStateCanLoad];
}

- (BOOL)isISRewardedVideoAdapterRegistered:(NSString *)instanceID {
  return [self getRewardedDelegateForInstanceID:instanceID] != nil;
}

- (void)setRewardedDelegate:(id<GADMAdapterIronSourceRewardedDelegate>)adapterDelegate
            toInstanceState:(NSString *)state {
  id<GADMAdapterIronSourceRewardedDelegate> delegate = adapterDelegate;
  if (delegate == nil) {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:@"changeInstanceState- adapterDelegate is nil"]];
    return;
  }
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"ISMediationManager change state to %@", state]];
  [delegate setState:state];
}

- (BOOL)canLoadInterstitialInstance:(NSString *)instanceID {
  if (![self isISInterstitialAdapterRegistered:instanceID]) {
    return true;
  }

  if ([self isRegisteredInterstitialAdapterCanLoad:instanceID]) {
    return true;
  }

  return false;
}

- (BOOL)isRegisteredInterstitialAdapterCanLoad:(NSString *)instanceID {
  id<GADMAdapterIronSourceInterstitialDelegate> adapterDelegate =
      [self getInterstitialDelegateForInstanceID:instanceID];
  return adapterDelegate == nil ||
         [[adapterDelegate getState] isEqualToString:kInstanceStateCanLoad];
}

- (BOOL)isISInterstitialAdapterRegistered:(NSString *)instanceID {
  return [self getInterstitialDelegateForInstanceID:instanceID] != nil;
}

- (void)setInterstitialDelegate:(id<GADMAdapterIronSourceInterstitialDelegate>)adapterDelegate
                toInstanceState:(NSString *)state {
  id<GADMAdapterIronSourceInterstitialDelegate> delegate = adapterDelegate;

  if (delegate == nil) {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:@"changeInstanceState- adapterDelegate is nil"]];
    return;
  }
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"ISMediationManager change state to %@", state]];
  [delegate setState:state];
}

@end
