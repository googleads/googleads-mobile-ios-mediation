// Copyright 2016 Google Inc.
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

#import "GADMAdapterUnitySingleton.h"
#import "GADMAdapterUnityConstants.h"

@interface GADMAdapterUnitySingleton () <UnityAdsExtendedDelegate, UnityAdsBannerDelegate> {
  /// Array to hold all adapter delegates.
  NSMapTable *_adapterDelegates;

  /// Connector from unity adapter to send Unity callbacks.
  __weak id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate> _currentShowingUnityDelegate;

  /// Connector from unity adapter to send Banner callbacks
  __weak id<GADMAdapterUnityDataProvider, UnityAdsBannerDelegate> _currentBannerDelegate;
}

@end

@implementation GADMAdapterUnitySingleton

NSString *_bannerPlacementID = nil;
bool _bannerRequested = false;

+ (instancetype)sharedInstance {
  static GADMAdapterUnitySingleton *sharedManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedManager = [[self alloc] init];
  });
  return sharedManager;
}

- (id)init {
  self = [super init];
  if (self) {
    _adapterDelegates = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
                                              valueOptions:NSMapTableWeakMemory];
  }
  return self;
}

- (void)initializeWithGameID:(NSString *)gameID {

  if([UnityAds isInitialized]){
    return;
  }

  // Metadata needed by Unity Ads SDK before initialization.
  UADSMediationMetaData *mediationMetaData = [[UADSMediationMetaData alloc] init];
  [mediationMetaData setName:kGADMAdapterUnityMediationNetworkName];
  [mediationMetaData setVersion:kGADMAdapterUnityVersion];
  [mediationMetaData commit];
  // Initializing Unity Ads with |gameID|.

  [UnityAds initialize:gameID delegate:self];
}

- (void)addAdapterDelegate:
    (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)adapterDelegate {
  @synchronized (_adapterDelegates) {
    [_adapterDelegates setObject:adapterDelegate forKey:[adapterDelegate getPlacementID]];
  }
}

#pragma mark - Rewardbased video ad methods

- (void)requestRewardedAdWithDelegate:
    (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)adapterDelegate {
  
  NSString *placementID = [adapterDelegate getPlacementID];
  
  @synchronized (_adapterDelegates) {
    if ([_adapterDelegates objectForKey:placementID]) {
      NSString *message = @"An ad is already loading for placement ID %@";
      [adapterDelegate
       unityAdsDidError:kUnityAdsErrorInternalError
       withMessage:[NSString stringWithFormat:message, placementID]];
      return;
    }
  }

  [self addAdapterDelegate:adapterDelegate];
  
  //Call metadata load API
  NSString *uniqueEventId = [[NSUUID UUID] UUIDString];
  UADSMetaData *loadMetaData = [[UADSMetaData alloc] initWithCategory:@"load"];
  [loadMetaData setRaw:uniqueEventId value:placementID];
  [loadMetaData commit];
  
  if ([UnityAds isReady:placementID]) {
    [adapterDelegate unityAdsReady:placementID];
  } else if ([UnityAds getPlacementState:placementID] == kUnityAdsPlacementStateNoFill ){
      NSString *description = [[NSString alloc]
          initWithFormat:@"%@ failed to receive rewarded ad - NO FILL.", NSStringFromClass([UnityAds class])];
      [adapterDelegate unityAdsDidError:kUnityAdsErrorShowError withMessage:description];
  }
}

- (void)presentRewardedAdForViewController:(UIViewController *)viewController
                                  delegate:
                                      (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)
                                          adapterDelegate {
  _currentShowingUnityDelegate = adapterDelegate;
  // The Unity Ads show method checks whether an ad is available.
  NSString *placementID = [adapterDelegate getPlacementID];
  [UnityAds show:viewController placementId:placementID];
}

#pragma mark - Interstitial ad methods

- (void)requestInterstitialAdWithDelegate:
                                     (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)
                                         adapterDelegate {

  NSString *placementID = [adapterDelegate getPlacementID];
  
  @synchronized (_adapterDelegates) {
    if ([_adapterDelegates objectForKey:placementID]) {
      NSString *message = @"An ad is already loading for placement ID %@";
      [adapterDelegate
       unityAdsDidError:kUnityAdsErrorInternalError
       withMessage:[NSString stringWithFormat:message, placementID]];
      return;
    }
  }
  
  [self addAdapterDelegate:adapterDelegate];
  
  //Call metadata load API
  NSString *uniqueEventId = [[NSUUID UUID] UUIDString];
  UADSMetaData *loadMetaData = [[UADSMetaData alloc] initWithCategory:@"load"];
  [loadMetaData setRaw:uniqueEventId value:placementID];
  [loadMetaData commit];
    
  if ([UnityAds isReady:placementID]) {
      [adapterDelegate unityAdsReady:placementID];
  } else if ([UnityAds getPlacementState:placementID] == kUnityAdsPlacementStateNoFill){
      NSString *description = [[NSString alloc] initWithFormat:
                               @"%@ failed to receive interstitial ad - NO FILL.",
                               NSStringFromClass([UnityAds class])];
      [adapterDelegate unityAdsDidError:kUnityAdsErrorShowError withMessage:description];
  }
}

- (void)presentInterstitialAdForViewController:(UIViewController *)viewController
                                      delegate:(id<GADMAdapterUnityDataProvider,
                                                   UnityAdsExtendedDelegate>)adapterDelegate {
  _currentShowingUnityDelegate = adapterDelegate;
  // The Unity Ads show method checks whether an ad is available.
  [UnityAds show:viewController placementId:[adapterDelegate getPlacementID]];
}

#pragma mark - Banner ad methods

- (void)presentBannerAd:(NSString *)gameID
               delegate:(id<GADMAdapterUnityDataProvider, UnityAdsBannerDelegate>)adapterDelegate {
  _currentBannerDelegate = adapterDelegate;

  if ([UnityAds isSupported]) {
    NSString *placementID = [_currentBannerDelegate getPlacementID];
    if (placementID == nil) {
      NSString *description =
          [[NSString alloc] initWithFormat:@"Tried to show banners with a nil placement ID"];
      [_currentBannerDelegate unityAdsBannerDidError:description];
      return;
    } else {
      _bannerPlacementID = placementID;
    }

    if (![UnityAds isInitialized]) {
      [self initializeWithGameID:gameID];
      _bannerRequested = true;
    } else {
      [UnityAdsBanner setDelegate:self];
      [UnityAdsBanner loadBanner:_bannerPlacementID];
    }
  } else {
    NSString *description =
        [[NSString alloc] initWithFormat:@"Unity Ads is not supported for this device."];
    [_currentBannerDelegate unityAdsBannerDidError:description];
  }
}

#pragma mark - Unity Banner Delegate Methods

- (void)unityAdsBannerDidLoad:(NSString *)placementId view:(UIView *)view {
  [_currentBannerDelegate unityAdsBannerDidLoad:_bannerPlacementID view:view];
}

- (void)unityAdsBannerDidUnload:(NSString *)placementId {
  [_currentBannerDelegate unityAdsBannerDidUnload:_bannerPlacementID];
}

- (void)unityAdsBannerDidShow:(NSString *)placementId {
  [_currentBannerDelegate unityAdsBannerDidShow:_bannerPlacementID];
}

- (void)unityAdsBannerDidHide:(NSString *)placementId {
  [_currentBannerDelegate unityAdsBannerDidHide:_bannerPlacementID];
}

- (void)unityAdsBannerDidClick:(NSString *)placementId {
  [_currentBannerDelegate unityAdsBannerDidClick:_bannerPlacementID];
}

- (void)unityAdsBannerDidError:(NSString *)message {
  NSString *description = [[NSString alloc] initWithFormat:@"Internal Unity Ads banner error"];
  [_currentBannerDelegate unityAdsBannerDidError:description];
}

#pragma mark - Unity Delegate Methods

- (void)unityAdsPlacementStateChanged:(NSString *)placementId
                             oldState:(UnityAdsPlacementState)oldState
                             newState:(UnityAdsPlacementState)newState {
  // The unityAdsReady: and unityAdsDidError: callback methods are used to forward Unity Ads SDK
  // states to the adapters. No need to forward this callback to the adapters.
}

- (void)unityAdsDidFinish:(NSString *)placementID withFinishState:(UnityAdsFinishState)state {

  @synchronized (_adapterDelegates) {
    [_adapterDelegates removeObjectForKey:placementID];
  }
  [_currentShowingUnityDelegate unityAdsDidFinish:placementID withFinishState:state];
}

- (void)unityAdsDidStart:(NSString *)placementID {
  [_currentShowingUnityDelegate unityAdsDidStart:placementID];
}

- (void)unityAdsReady:(NSString *)placementID {
  id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate> adapterDelegate;
  @synchronized (_adapterDelegates) {
    adapterDelegate = [_adapterDelegates objectForKey:placementID];
  }

  if (adapterDelegate) {
    [adapterDelegate unityAdsReady:placementID];
  }
}

- (void)unityAdsDidClick:(NSString *)placementID {
  [_currentShowingUnityDelegate unityAdsDidClick:placementID];
}

- (void)unityAdsDidError:(UnityAdsError)error withMessage:(NSString *)message {
  if (error == kUnityAdsErrorShowError) {
    [_currentShowingUnityDelegate unityAdsDidError:error withMessage:message];
    return;
  }

  NSArray *delegates;
  @synchronized (_adapterDelegates) {
    delegates = _adapterDelegates.objectEnumerator.allObjects;
  }

  for (id<UnityAdsExtendedDelegate, UnityAdsExtendedDelegate> delegate in delegates) {
    [delegate unityAdsDidError:error withMessage:message];
  }

  @synchronized (_adapterDelegates) {
    [_adapterDelegates removeAllObjects];
  }
}

- (void)stopTrackingDelegate:
    (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)adapterDelegate {
  [_adapterDelegates removeObjectForKey:[adapterDelegate getPlacementID]];
}

@end
