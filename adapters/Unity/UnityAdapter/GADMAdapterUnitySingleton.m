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
#import "GADMAdapterUnityUtils.h"

@interface GADMAdapterUnitySingleton () <UnityAdsExtendedDelegate> {
  /// Array to hold all adapter delegates.
  NSMapTable *_adapterDelegates;

  /// Connector from unity adapter to send Unity callbacks.
  __weak id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate> _currentShowingUnityDelegate;
}

@end

@implementation GADMAdapterUnitySingleton

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
  if ([UnityAds isInitialized]) {
    return;
  }

  // Metadata needed by Unity Ads SDK before initialization.
  UADSMediationMetaData *mediationMetaData = [[UADSMediationMetaData alloc] init];
  [mediationMetaData setName:kGADMAdapterUnityMediationNetworkName];
  [mediationMetaData setVersion:kGADMAdapterUnityVersion];
  [mediationMetaData set:@"adapter_version" value:[UnityAds getVersion]];
  [mediationMetaData commit];

  // Initializing Unity Ads with |gameID|.
  [UnityAds addDelegate:self];
  [UnityAds initialize:gameID testMode:NO enablePerPlacementLoad:YES];
}

- (void)addAdapterDelegate:
    (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)adapterDelegate {
  @synchronized(_adapterDelegates) {
    GADMAdapterUnityMapTableSetObjectForKey(_adapterDelegates, [adapterDelegate getPlacementID],
                                            adapterDelegate);
  }
}

#pragma mark - Rewardbased video ad methods

- (void)requestRewardedAdWithDelegate:
    (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)adapterDelegate {
  NSString *gameID = [adapterDelegate getGameID];
  NSString *placementID = [adapterDelegate getPlacementID];

  @synchronized(_adapterDelegates) {
    if ([_adapterDelegates objectForKey:placementID]) {
      NSString *message = @"An ad is already loading for placement ID %@";
      [adapterDelegate unityAdsDidError:kUnityAdsErrorInternalError
                            withMessage:[NSString stringWithFormat:message, placementID]];
      return;
    }
  }

  [self addAdapterDelegate:adapterDelegate];

  if (![UnityAds isInitialized]) {
    [self initializeWithGameID:gameID];
  }

  [UnityAds load:placementID];
}

- (void)presentRewardedAdForViewController:(UIViewController *)viewController
                                  delegate:
                                      (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)
                                          adapterDelegate {
  _currentShowingUnityDelegate = adapterDelegate;

  NSString *placementID = [adapterDelegate getPlacementID];
  [UnityAds show:viewController placementId:placementID];
}

#pragma mark - Interstitial ad methods

- (void)requestInterstitialAdWithDelegate:
    (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)adapterDelegate {
  NSString *gameID = [adapterDelegate getGameID];
  NSString *placementID = [adapterDelegate getPlacementID];

  @synchronized(_adapterDelegates) {
    if ([_adapterDelegates objectForKey:placementID]) {
      NSString *message = @"An ad is already loading for placement ID %@";
      [adapterDelegate unityAdsDidError:kUnityAdsErrorInternalError
                            withMessage:[NSString stringWithFormat:message, placementID]];
      return;
    }
  }

  [self addAdapterDelegate:adapterDelegate];
  if (![UnityAds isInitialized]) {
    [self initializeWithGameID:gameID];
  }

  [UnityAds load:placementID];
}

- (void)presentInterstitialAdForViewController:(UIViewController *)viewController
                                      delegate:(id<GADMAdapterUnityDataProvider,
                                                   UnityAdsExtendedDelegate>)adapterDelegate {
  _currentShowingUnityDelegate = adapterDelegate;

  NSString *placementID = [adapterDelegate getPlacementID];
  [UnityAds show:viewController placementId:placementID];
}

#pragma mark - Unity Delegate Methods

- (void)unityAdsPlacementStateChanged:(NSString *)placementId
                             oldState:(UnityAdsPlacementState)oldState
                             newState:(UnityAdsPlacementState)newState {
  id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate> adapterDelegate;
  @synchronized(_adapterDelegates) {
    adapterDelegate = [_adapterDelegates objectForKey:placementId];
  }

  if (adapterDelegate) {
    [adapterDelegate unityAdsPlacementStateChanged:placementId oldState:oldState newState:newState];
  }
}

- (void)unityAdsDidFinish:(NSString *)placementID withFinishState:(UnityAdsFinishState)state {
  @synchronized(_adapterDelegates) {
    GADMAdapterUnityMapTableRemoveObjectForKey(_adapterDelegates, placementID);
  }
  [_currentShowingUnityDelegate unityAdsDidFinish:placementID withFinishState:state];
}

- (void)unityAdsDidStart:(NSString *)placementID {
  [_currentShowingUnityDelegate unityAdsDidStart:placementID];
}

- (void)unityAdsReady:(NSString *)placementID {
  id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate> adapterDelegate;
  @synchronized(_adapterDelegates) {
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
  if (error == kUnityAdsErrorInitSanityCheckFail || error == kUnityAdsErrorNotInitialized ||
      error == kUnityAdsErrorInvalidArgument || error == kUnityAdsErrorInitializedFailed ||
      error == kUnityAdsErrorAdBlockerDetected) {
    NSArray<id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>> *delegates;
    @synchronized(_adapterDelegates) {
      delegates = _adapterDelegates.objectEnumerator.allObjects;
    }

    for (id<UnityAdsExtendedDelegate, UnityAdsExtendedDelegate> delegate in delegates) {
      [delegate unityAdsDidError:kUnityAdsErrorNotInitialized withMessage:message];
    }

    @synchronized(_adapterDelegates) {
      [_adapterDelegates removeAllObjects];
    }
  } else {
    [_currentShowingUnityDelegate unityAdsDidError:error withMessage:message];
  }
}

- (void)stopTrackingDelegate:
    (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)adapterDelegate {
  GADMAdapterUnityMapTableRemoveObjectForKey(_adapterDelegates, [adapterDelegate getPlacementID]);
}

@end
