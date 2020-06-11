//
//  GADMAdapterUnityRouter.m
//  AdMob-TestApp-Local
//
//  Created by Kavya Katooru on 6/10/20.
//  Copyright © 2020 Unity Ads. All rights reserved.
//

#import "GADMAdapterUnityRouter.h"
#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnityUtils.h"

@interface GADMAdapterUnityRouter () <UnityAdsExtendedDelegate> {
    int impressionOrdinal;
    int missedImpressionOrdinal;
    /// Connector from unity adapter to send Unity callbacks.
    __weak id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate> _currentShowingUnityDelegate;
}

@end
@implementation GADMAdapterUnityRouter

- (id)initializeWithGameID:(NSString *)gameID {
  if ([UnityAds isInitialized]) {
    return self;
  }

  // Metadata needed by Unity Ads SDK before initialization.
  UADSMediationMetaData *mediationMetaData = [[UADSMediationMetaData alloc] init];
  [mediationMetaData setName:kGADMAdapterUnityMediationNetworkName];
  [mediationMetaData setVersion:kGADMAdapterUnityVersion];
  [mediationMetaData set:@"adapter_version" value:[UnityAds getVersion]];
  [mediationMetaData commit];

  // Initializing Unity Ads with |gameID|.
  [UnityAds initialize:gameID testMode:NO];
    [UnityAds addDelegate:self];
  return self;
}

#pragma mark - Rewardbased video ad methods

- (void)requestRewardedAdWithDelegate:
    (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)adapterDelegate {
  NSString *gameID = [adapterDelegate getGameID];
  NSString *placementID = [adapterDelegate getPlacementID];

//  @synchronized(_adapterDelegates) {
//    if ([_adapterDelegates objectForKey:placementID]) {
//      NSString *message = @"An ad is already loading for placement ID %@";
//      [adapterDelegate unityAdsDidError:kUnityAdsErrorInternalError
//                            withMessage:[NSString stringWithFormat:message, placementID]];
//      return;
//    }
//  }

//  [self addAdapterDelegate:adapterDelegate];

  if (![UnityAds isInitialized]) {
    [self initializeWithGameID:gameID];
  }

  [UnityAds load:placementID];
  if ([UnityAds isReady:placementID]) {
    [adapterDelegate unityAdsReady:placementID];
  }
}

- (void)presentRewardedAdForViewController:(UIViewController *)viewController
                                  delegate:
                                      (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)
                                          adapterDelegate {
    _currentShowingUnityDelegate = adapterDelegate;
  NSString *placementID = [adapterDelegate getPlacementID];
  if ([UnityAds isReady:placementID]) {
    UADSMediationMetaData *mediationMetaData = [[UADSMediationMetaData alloc] init];
    [mediationMetaData setOrdinal:impressionOrdinal++];
    [mediationMetaData commit];
    [UnityAds show:viewController placementId:placementID];
  } else {
    UADSMediationMetaData *mediationMetaData = [[UADSMediationMetaData alloc] init];
    [mediationMetaData setMissedImpressionOrdinal:missedImpressionOrdinal++];
    [mediationMetaData commit];
  }
}


#pragma mark - Interstitial ad methods

- (void)requestInterstitialAdWithDelegate:
    (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)adapterDelegate {
  NSString *gameID = [adapterDelegate getGameID];
  NSString *placementID = [adapterDelegate getPlacementID];

//  @synchronized(_adapterDelegates) {
//    if ([_adapterDelegates objectForKey:placementID]) {
//      NSString *message = @"An ad is already loading for placement ID %@";
//      [adapterDelegate unityAdsDidError:kUnityAdsErrorInternalError
//                            withMessage:[NSString stringWithFormat:message, placementID]];
//      return;
//    }
//  }
//
//  [self addAdapterDelegate:adapterDelegate];

  if (![UnityAds isInitialized]) {
    [self initializeWithGameID:gameID];
  }

  [UnityAds load:placementID];
  if ([UnityAds isReady:placementID]) {
    [adapterDelegate unityAdsReady:placementID];
  }
}

- (void)presentInterstitialAdForViewController:(UIViewController *)viewController
                                      delegate:(id<GADMAdapterUnityDataProvider,
                                                   UnityAdsExtendedDelegate>)adapterDelegate {
    _currentShowingUnityDelegate = adapterDelegate;
  NSString *placementID = [adapterDelegate getPlacementID];
  if ([UnityAds isReady:placementID]) {
    UADSMediationMetaData *mediationMetaData = [[UADSMediationMetaData alloc] init];
    [mediationMetaData setOrdinal:impressionOrdinal++];
    [mediationMetaData commit];
    [UnityAds show:viewController placementId:placementID];
  } else {
    UADSMediationMetaData *mediationMetaData = [[UADSMediationMetaData alloc] init];
    [mediationMetaData setMissedImpressionOrdinal:missedImpressionOrdinal++];
    [mediationMetaData commit];
  }
}

#pragma mark - Unity Delegate Methods

- (void)unityAdsPlacementStateChanged:(NSString *)placementId
                             oldState:(UnityAdsPlacementState)oldState
                             newState:(UnityAdsPlacementState)newState {
  // This callback is not forwarded to the adapter by the GADMAdapterUnitySingleton and the adapter
  // should use the unityAdsReady: and unityAdsDidError: callbacks to forward Unity Ads SDK state to
  // Google Mobile Ads SDK.
}

- (void)unityAdsDidFinish:(NSString *)placementID withFinishState:(UnityAdsFinishState)state {
  
  [_currentShowingUnityDelegate unityAdsDidFinish:placementID withFinishState:state];
}

- (void)unityAdsDidStart:(NSString *)placementID {
  [_currentShowingUnityDelegate unityAdsDidStart:placementID];
}

- (void)unityAdsReady:(NSString *)placementID {
  id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate> adapterDelegate;
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
}

@end


