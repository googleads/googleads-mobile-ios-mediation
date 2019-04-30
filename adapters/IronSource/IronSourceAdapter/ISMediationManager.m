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
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceRewardedAd.h"
#import "GADMAdapterIronSourceUtils.h"

@interface ISMediationManager ()

@property(nonatomic)
    NSMapTable<NSString *, id<ISDemandOnlyRewardedVideoDelegate, GADMAdapterIronSourceDelegate>>
        *rewardedAdapterDelegates;
@property(nonatomic)
    NSMapTable<NSString *, id<ISDemandOnlyInterstitialDelegate, GADMAdapterIronSourceDelegate>>
        *interstitialAdapterDelegates;
@property(nonatomic) NSMutableDictionary<NSString *, NSSet<NSString *> *> *initializedAppKeys;

// Holds the instance ID of the rewarded ad that is being presented.
@property(nonatomic) NSString *currentShowingRewardedInstanceID;

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
    self.initializedAppKeys = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)initIronSourceSDKWithAppKey:(NSString *)appKey forAdUnits:(NSSet *)adUnits {
  NSSet *initializedAdUnits = self.initializedAppKeys[appKey];
  if (!initializedAdUnits) {
    initializedAdUnits = [[NSSet alloc] init];
  }

  if (![adUnits isSubsetOfSet:initializedAdUnits]) {
    NSSet *newAdUnits = [initializedAdUnits setByAddingObjectsFromSet:adUnits];
    [IronSource setMediationType:kGADMAdapterIronSourceMediationName];
    [IronSource initISDemandOnly:appKey adUnits:[newAdUnits allObjects]];
    self.initializedAppKeys[appKey] = adUnits;
  }
}

- (void)addRewardedDelegate:
            (id<ISDemandOnlyRewardedVideoDelegate, GADMAdapterIronSourceDelegate>)adapterDelegate
              forInstanceID:(NSString *)instanceID {
  @synchronized(self.rewardedAdapterDelegates) {
    [self.rewardedAdapterDelegates setObject:adapterDelegate forKey:instanceID];
  }
}

- (void)removeRewardedDelegateForInstanceID:(NSString *)InstanceID {
  @synchronized(self.rewardedAdapterDelegates) {
    [self.rewardedAdapterDelegates removeObjectForKey:InstanceID];
  }
}

- (id<ISDemandOnlyRewardedVideoDelegate, GADMAdapterIronSourceDelegate>)
    getRewardedDelegateForInstanceID:(NSString *)instanceID {
  id<ISDemandOnlyRewardedVideoDelegate, GADMAdapterIronSourceDelegate> delegate;
  @synchronized(self.rewardedAdapterDelegates) {
    delegate = [self.rewardedAdapterDelegates objectForKey:instanceID];
  }
  return delegate;
}

- (void)addInterstitialDelegate:
            (id<ISDemandOnlyInterstitialDelegate, GADMAdapterIronSourceDelegate>)adapterDelegate
                  forInstanceID:(NSString *)instanceID {
  @synchronized(self.interstitialAdapterDelegates) {
    [self.interstitialAdapterDelegates setObject:adapterDelegate forKey:instanceID];
  }
}

- (void)removeInterstitialDelegateForInstanceID:(NSString *)InstanceID {
  @synchronized(self.interstitialAdapterDelegates) {
    [self.interstitialAdapterDelegates removeObjectForKey:InstanceID];
  }
}

- (id<ISDemandOnlyInterstitialDelegate, GADMAdapterIronSourceDelegate>)
    getInterstitialDelegateForInstanceID:(NSString *)instanceID {
  id<ISDemandOnlyInterstitialDelegate, GADMAdapterIronSourceDelegate> delegate;
  @synchronized(self.interstitialAdapterDelegates) {
    delegate = [self.interstitialAdapterDelegates objectForKey:instanceID];
  }
  return delegate;
}

- (void)requestRewardedAdWithDelegate:
    (id<ISDemandOnlyRewardedVideoDelegate, GADMAdapterIronSourceDelegate>)delegate {
  NSString *instanceID = [delegate getInstanceID];
  [IronSource setISDemandOnlyRewardedVideoDelegate:self];
  id<ISDemandOnlyRewardedVideoDelegate, GADMAdapterIronSourceDelegate> adapterDelegate =
      [self getRewardedDelegateForInstanceID:instanceID];

  if (adapterDelegate) {
    NSError *availableAdsError = [GADMAdapterIronSourceUtils
        createErrorWith:@"A request is already in processing for same instance ID"
              andReason:@"Can't make a new request for the same instance ID"
          andSuggestion:nil];
    [delegate didFailToLoadAdWithError:availableAdsError];
  } else {
    [self addRewardedDelegate:delegate forInstanceID:instanceID];
  }

  if ([IronSource hasISDemandOnlyRewardedVideo:instanceID]) {
    [delegate rewardedVideoHasChangedAvailability:YES instanceId:instanceID];
  }
}

- (void)presentRewardedAdFromViewController:(nonnull UIViewController *)viewController
                                   delegate:(id<ISDemandOnlyRewardedVideoDelegate,
                                                GADMAdapterIronSourceDelegate>)delegate {
  NSString *instanceId = [delegate getInstanceID];
  [IronSource setISDemandOnlyRewardedVideoDelegate:self];

  if ([IronSource hasISDemandOnlyRewardedVideo:instanceId]) {
    // The reward based video ad is available, present the ad.
    [IronSource showISDemandOnlyRewardedVideo:viewController instanceId:instanceId];
    _currentShowingRewardedInstanceID = instanceId;
  } else {
    // Because publishers are expected to check that an ad is available before trying to show one,
    // the above conditional should always hold true. If for any reason the adapter is not ready to
    // present an ad, however, it should log an error with reason for failure.
    NSError *error =
        [GADMAdapterIronSourceUtils createErrorWith:@"No Ad to show for this instance ID"
                                          andReason:nil
                                      andSuggestion:nil];
    [self removeRewardedDelegateForInstanceID:instanceId];
    [delegate rewardedVideoDidFailToShowWithError:error instanceId:instanceId];
  }
}

- (void)requestInterstitialAdWithDelegate:
    (id<ISDemandOnlyInterstitialDelegate, GADMAdapterIronSourceDelegate>)delegate {
  NSString *instanceId = [delegate getInstanceID];
  [IronSource setISDemandOnlyInterstitialDelegate:self];
  id<ISDemandOnlyInterstitialDelegate, GADMAdapterIronSourceDelegate> adapterDelegate =
      [self getInterstitialDelegateForInstanceID:instanceId];
  if (adapterDelegate) {
    NSError *availableAdsError = [GADMAdapterIronSourceUtils
        createErrorWith:@"A request is already in processing for same instance ID"
              andReason:@"Can't make a new request for the same instance ID"
          andSuggestion:nil];
    [delegate didFailToLoadAdWithError:availableAdsError];
    return;
  } else {
    [self addInterstitialDelegate:delegate forInstanceID:instanceId];
  }

  if ([IronSource hasISDemandOnlyInterstitial:instanceId]) {
    [delegate interstitialDidLoad:instanceId];
    return;
  }

  [IronSource loadISDemandOnlyInterstitial:instanceId];
}

- (void)presentInterstitialAdFromViewController:(nonnull UIViewController *)viewController
                                       delegate:(id<ISDemandOnlyInterstitialDelegate,
                                                    GADMAdapterIronSourceDelegate>)delegate {
  NSString *instanceId = [delegate getInstanceID];
  [IronSource setISDemandOnlyInterstitialDelegate:self];

  if ([IronSource hasISDemandOnlyInterstitial:instanceId]) {
    // The reward based video ad is available, present the ad.
    [IronSource showISDemandOnlyInterstitial:viewController instanceId:instanceId];
  } else {
    // Because publishers are expected to check that an ad is available before trying to show one,
    // the above conditional should always hold true. If for any reason the adapter is not ready to
    // present an ad, however, it should log an error with reason for failure.
    NSError *error =
        [GADMAdapterIronSourceUtils createErrorWith:@"No Ad to show for this instance ID"
                                          andReason:nil
                                      andSuggestion:nil];
    [self removeInterstitialDelegateForInstanceID:instanceId];
    [delegate interstitialDidFailToShowWithError:error instanceId:instanceId];
  }
}

#pragma mark ISDemandOnlyRewardedDelegate

- (void)rewardedVideoHasChangedAvailability:(BOOL)available instanceId:(NSString *)instanceId {
  if ([_currentShowingRewardedInstanceID isEqualToString:instanceId]) {
    return;
  }

  id<ISDemandOnlyRewardedVideoDelegate, GADMAdapterIronSourceDelegate> delegate =
      [self getRewardedDelegateForInstanceID:instanceId];
  if (!available) {
    [self removeRewardedDelegateForInstanceID:instanceId];
  }

  if (delegate) {
    [delegate rewardedVideoHasChangedAvailability:available instanceId:instanceId];
  }
}

- (void)didReceiveRewardForPlacement:(ISPlacementInfo *)placementInfo
                          instanceId:(NSString *)instanceId {
  id<ISDemandOnlyRewardedVideoDelegate, GADMAdapterIronSourceDelegate> delegate =
      [self getRewardedDelegateForInstanceID:instanceId];
  if (delegate) {
    [delegate didReceiveRewardForPlacement:placementInfo instanceId:instanceId];
  }
}

- (void)rewardedVideoDidFailToShowWithError:(NSError *)error instanceId:(NSString *)instanceId {
  id<ISDemandOnlyRewardedVideoDelegate, GADMAdapterIronSourceDelegate> delegate =
      [self getRewardedDelegateForInstanceID:instanceId];
  if (delegate) {
    [delegate rewardedVideoDidFailToShowWithError:error instanceId:instanceId];
    [self removeRewardedDelegateForInstanceID:instanceId];
    _currentShowingRewardedInstanceID = @"";
  }
}

- (void)rewardedVideoDidOpen:(NSString *)instanceId {
  id<ISDemandOnlyRewardedVideoDelegate, GADMAdapterIronSourceDelegate> delegate =
      [self getRewardedDelegateForInstanceID:instanceId];
  if (delegate) {
    [delegate rewardedVideoDidOpen:instanceId];
  }
}

- (void)rewardedVideoDidClose:(NSString *)instanceId {
  id<ISDemandOnlyRewardedVideoDelegate, GADMAdapterIronSourceDelegate> delegate =
      [self getRewardedDelegateForInstanceID:instanceId];
  if (delegate) {
    [self removeRewardedDelegateForInstanceID:instanceId];
    [delegate rewardedVideoDidClose:instanceId];
    _currentShowingRewardedInstanceID = @"";
  }
}

- (void)didClickRewardedVideo:(ISPlacementInfo *)placementInfo instanceId:(NSString *)instanceId {
  id<ISDemandOnlyRewardedVideoDelegate, GADMAdapterIronSourceDelegate> delegate =
      [self getRewardedDelegateForInstanceID:instanceId];
  if (delegate) {
    [delegate didClickRewardedVideo:placementInfo instanceId:instanceId];
  }
}

#pragma mark ISDemandOnlyInterstitialDelegate

- (void)interstitialDidLoad:(NSString *)instanceId {
  id<ISDemandOnlyInterstitialDelegate, GADMAdapterIronSourceDelegate> delegate =
      [self getInterstitialDelegateForInstanceID:instanceId];
  if (delegate) {
    [delegate interstitialDidLoad:instanceId];
  }
}

- (void)interstitialDidFailToLoadWithError:(NSError *)error instanceId:(NSString *)instanceId {
  id<ISDemandOnlyInterstitialDelegate, GADMAdapterIronSourceDelegate> delegate =
      [self getInterstitialDelegateForInstanceID:instanceId];
  if (delegate) {
    [self removeInterstitialDelegateForInstanceID:instanceId];
    [delegate interstitialDidFailToLoadWithError:error instanceId:instanceId];
  }
}

- (void)interstitialDidOpen:(NSString *)instanceId {
  id<ISDemandOnlyInterstitialDelegate, GADMAdapterIronSourceDelegate> delegate =
      [self getInterstitialDelegateForInstanceID:instanceId];
  if (delegate) {
    [delegate interstitialDidOpen:instanceId];
  }
}

- (void)interstitialDidClose:(NSString *)instanceId {
  id<ISDemandOnlyInterstitialDelegate, GADMAdapterIronSourceDelegate> delegate =
      [self getInterstitialDelegateForInstanceID:instanceId];
  if (delegate) {
    [self removeInterstitialDelegateForInstanceID:instanceId];
    [delegate interstitialDidClose:instanceId];
  }
}

- (void)interstitialDidShow:(NSString *)instanceId {
  id<ISDemandOnlyInterstitialDelegate, GADMAdapterIronSourceDelegate> delegate =
      [self getInterstitialDelegateForInstanceID:instanceId];
  if (delegate) {
    [delegate interstitialDidShow:instanceId];
  }
}

- (void)interstitialDidFailToShowWithError:(NSError *)error instanceId:(NSString *)instanceId {
  id<ISDemandOnlyInterstitialDelegate, GADMAdapterIronSourceDelegate> delegate =
      [self getInterstitialDelegateForInstanceID:instanceId];
  if (delegate) {
    [self removeInterstitialDelegateForInstanceID:instanceId];
    [delegate interstitialDidFailToShowWithError:error instanceId:instanceId];
  }
}

- (void)didClickInterstitial:(NSString *)instanceId {
  id<ISDemandOnlyInterstitialDelegate, GADMAdapterIronSourceDelegate> delegate =
      [self getInterstitialDelegateForInstanceID:instanceId];
  if (delegate) {
    [delegate didClickInterstitial:instanceId];
  }
}

@end
