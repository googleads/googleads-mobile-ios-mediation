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
#import "GADMAdapterUnityWeakReference.h"

@interface GADMAdapterUnitySingleton () <UnityAdsDelegate> {
  /// Array to hold all adapter delegates.
  NSMutableArray *_adapterDelegates;

  /// Connector from unity adapter to send Unity callbacks.
  __weak id<GADMAdapterUnityDataProvider, UnityAdsDelegate> _currentShowingUnityDelegate;
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
    _adapterDelegates = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)initializeWithGameID:(NSString *)gameID {
  // Metadata needed by Unity Ads SDK before initialization.
  UADSMediationMetaData *mediationMetaData = [[UADSMediationMetaData alloc] init];
  [mediationMetaData setName:GADMAdapterUnityMediationNetworkName];
  [mediationMetaData setVersion:GADMAdapterUnityVersion];
  [mediationMetaData commit];
  // Initializing Unity Ads with |gameID|.
  [UnityAds initialize:gameID delegate:self];
}

- (void)addAdapterDelegate:(id<GADMAdapterUnityDataProvider, UnityAdsDelegate>)adapterDelegate {
  GADMAdapterUnityWeakReference *delegateReference =
      [[GADMAdapterUnityWeakReference alloc] initWithObject:adapterDelegate];
  // Removes duplicate delegate references.
  [self removeAdapterDelegate:delegateReference];
  [_adapterDelegates addObject:delegateReference];
}

- (void)removeAdapterDelegate:(GADMAdapterUnityWeakReference *)adapterDelegate {
  // Removes duplicate mediation adapter delegate references.
  NSMutableArray *delegatesToRemove = [NSMutableArray array];
  [_adapterDelegates
      enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        GADMAdapterUnityWeakReference *weakReference = obj;
        if ([weakReference isEqual:adapterDelegate]) {
          [delegatesToRemove addObject:obj];
        }
      }];
  [_adapterDelegates removeObjectsInArray:delegatesToRemove];
}

#pragma mark - Rewardbased video ad methods

- (BOOL)configureRewardBasedVideoAdWithGameID:(NSString *)gameID
                                     delegate:(id<GADMAdapterUnityDataProvider, UnityAdsDelegate>)
                                                  adapterDelegate {
  if ([UnityAds isSupported]) {
    if (![UnityAds isInitialized]) {
      // Add delegate reference in adapterDelegate list only if Unity Ads is not initialized.
      [self addAdapterDelegate:adapterDelegate];
      [self initializeWithGameID:gameID];
    }
    return YES;
  }
  return NO;
}

- (void)requestRewardBasedVideoAdWithDelegate:
        (id<GADMAdapterUnityDataProvider, UnityAdsDelegate>)adapterDelegate {
  if ([UnityAds isInitialized]) {
    NSString *placementID = [adapterDelegate getPlacementID];
    if ([UnityAds isReady:placementID]) {
      [adapterDelegate unityAdsReady:placementID];
    } else {
      NSString *description =
          [[NSString alloc] initWithFormat:@"%@ failed to receive reward based video ad.",
                                           NSStringFromClass([UnityAds class])];
      [adapterDelegate unityAdsDidError:kUnityAdsErrorShowError withMessage:description];
    }
  }
}

- (void)presentRewardBasedVideoAdForViewController:(UIViewController *)viewController
                                          delegate:
                                              (id<GADMAdapterUnityDataProvider, UnityAdsDelegate>)
                                                  adapterDelegate {
  _currentShowingUnityDelegate = adapterDelegate;
  // The Unity Ads show method checks whether an ad is available.
  [UnityAds show:viewController placementId:[adapterDelegate getPlacementID]];
}

#pragma mark - Interstitial ad methods

- (void)configureInterstitialAdWithGameID:(NSString *)gameID
                                 delegate:(id<GADMAdapterUnityDataProvider, UnityAdsDelegate>)
                                              adapterDelegate {
  if ([UnityAds isSupported]) {
    if ([UnityAds isInitialized]) {
      NSString *placementID = [adapterDelegate getPlacementID];
      if ([UnityAds isReady:placementID]) {
        [adapterDelegate unityAdsReady:placementID];
      } else {
        NSString *description =
            [[NSString alloc] initWithFormat:@"%@ failed to receive interstitial ad.",
                                             NSStringFromClass([UnityAds class])];
        [adapterDelegate unityAdsDidError:kUnityAdsErrorShowError withMessage:description];
      }
    } else {
      // Add delegate reference in adapterDelegate list only if Unity Ads is not initialized.
      [self addAdapterDelegate:adapterDelegate];
      [self initializeWithGameID:gameID];
    }
  } else {
    NSString *description =
        [[NSString alloc] initWithFormat:@"%@ is not supported for this device.",
                                         NSStringFromClass([UnityAds class])];
    [adapterDelegate unityAdsDidError:kUnityAdsErrorNotInitialized withMessage:description];
  }
}

- (void)presentInterstitialAdForViewController:(UIViewController *)viewController
                                      delegate:(id<GADMAdapterUnityDataProvider, UnityAdsDelegate>)
                                                   adapterDelegate {
  _currentShowingUnityDelegate = adapterDelegate;
  // The Unity Ads show method checks whether an ad is available.
  [UnityAds show:viewController placementId:[adapterDelegate getPlacementID]];
}

#pragma mark - Unity Delegate Methods

- (void)unityAdsDidFinish:(NSString *)placementID withFinishState:(UnityAdsFinishState)state {
  [_currentShowingUnityDelegate unityAdsDidFinish:placementID withFinishState:state];
}

- (void)unityAdsDidStart:(NSString *)placementID {
  [_currentShowingUnityDelegate unityAdsDidStart:placementID];
}

- (void)unityAdsReady:(NSString *)placementID {
  NSMutableArray *delegatesToRemove = [NSMutableArray array];
  [_adapterDelegates
      enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        GADMAdapterUnityWeakReference *weakReference = obj;
        if ([[(id<GADMAdapterUnityDataProvider>)weakReference.weakObject getPlacementID]
                isEqualToString:placementID]) {
          [(id<UnityAdsDelegate>)weakReference.weakObject unityAdsReady:placementID];
          [delegatesToRemove addObject:obj];
        }
      }];
  [_adapterDelegates removeObjectsInArray:delegatesToRemove];
}

- (void)unityAdsDidError:(UnityAdsError)error withMessage:(NSString *)message {
  // If the error is of type show, we will not have it's delegate reference in our adapterDelegate
  // list. Delegate instances are being removed when we get unityAdsReady callback.
  if (error == kUnityAdsErrorShowError) {
    [_currentShowingUnityDelegate unityAdsDidError:error withMessage:message];
    return;
  }
  NSMutableArray *delegatesToRemove = [NSMutableArray array];
  [_adapterDelegates
      enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        GADMAdapterUnityWeakReference *weakReference = obj;
        [(id<UnityAdsDelegate>)weakReference.weakObject unityAdsDidError:error withMessage:message];
        [delegatesToRemove addObject:obj];
      }];
  [_adapterDelegates removeObjectsInArray:delegatesToRemove];
}

- (void)stopTrackingDelegate:(id<GADMAdapterUnityDataProvider, UnityAdsDelegate>)adapterDelegate {
  GADMAdapterUnityWeakReference *delegateReference =
      [[GADMAdapterUnityWeakReference alloc] initWithObject:adapterDelegate];
  [self removeAdapterDelegate:delegateReference];
}

@end
