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

#import "GADMAdapterChartboostSingleton.h"

#import "GADMAdapterChartboostDelegateProtocol.h"
#import "GADMAdapterChartboostWeakReference.h"

@interface GADMAdapterChartboostSingleton ()<ChartboostDelegate> {
  /// Array to hold all  interstitial adapter delegates.
  NSMutableArray *_interstitialDelegates;

  /// Array to hold all rewardbased video adapter delegates.
  NSMutableArray *_rewardbasedVideoDelegates;

  /// Connector from Chartboost adapter to send Chartboost callbacks.
  __weak id<GADMAdapterChartboostDelegateProtocol> _currentShowingDelegate;

  /// YES if the Chartboost SDK initialized.
  BOOL _isChartboostInitialized;

  /// Concurrent dispatch queue.
  dispatch_queue_t _queue;

  /// Chartboost ad location.
  NSString *_chartboostAdLocation;
}

@end

@implementation GADMAdapterChartboostSingleton

#pragma mark - Singleton Initializers

+ (instancetype)sharedManager {
  static GADMAdapterChartboostSingleton *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (id)init {
  self = [super init];
  if (self) {
    _interstitialDelegates = [[NSMutableArray alloc] init];
    _rewardbasedVideoDelegates = [[NSMutableArray alloc] init];
    _queue = dispatch_queue_create("com.google.admob.chartboost_adapter_singleton",
                                   DISPATCH_QUEUE_CONCURRENT);
  }
  return self;
}

- (void)startWithAppId:(NSString *)appId appSignature:(NSString *)appSignature {
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    [Chartboost startWithAppId:appId appSignature:appSignature delegate:self];
    [Chartboost setMediation:CBMediationAdMob withVersion:kGADMAdapterChartboostVersion];
  });
}

#pragma mark - Rewardbased Video Ads Methods

- (void)configureRewardBasedVideoAdWithAppID:(NSString *)appID
                              adAppSignature:(NSString *)appSignature
                                  adLocation:(NSString *)adLocation
                                    delegate:
                                        (id<GADMAdapterChartboostDelegateProtocol>)adapterDelegate {
  _chartboostAdLocation = adLocation;
  id<GADMAdapterChartboostDelegateProtocol> strongDelegate = adapterDelegate;
  dispatch_barrier_async(_queue, ^{
    [_rewardbasedVideoDelegates
        addObject:[[GADMAdapterChartboostWeakReference alloc] initWithObject:adapterDelegate]];
  });
  GADMChartboostExtras *chartboostExtras = [adapterDelegate extras];
  if (chartboostExtras.frameworkVersion && chartboostExtras.framework) {
    [Chartboost setFramework:chartboostExtras.framework
                 withVersion:chartboostExtras.frameworkVersion];
  }

  if (!_isChartboostInitialized) {
    [self startWithAppId:appID appSignature:appSignature];
  } else {
    [strongDelegate didInitialize:YES];
  }
  [Chartboost setAutoCacheAds:YES];
  [Chartboost cacheRewardedVideo:adLocation];
}

- (void)requestRewardBasedVideoForDelegate:
            (id<GADMAdapterChartboostDelegateProtocol>)adapterDelegate
                                adLocation:(NSString *)adLocation {
  id<GADMAdapterChartboostDelegateProtocol> strongDelegate = adapterDelegate;
  _chartboostAdLocation = adLocation;
  if ([Chartboost hasRewardedVideo:adLocation]) {
    [strongDelegate didCacheRewardedVideo:adLocation];
  } else {
    [Chartboost cacheRewardedVideo:adLocation];
  }
}

- (void)presentRewardBasedVideoAdForDelegate:
    (id<GADMAdapterChartboostDelegateProtocol>)adapterDelegate {
  _currentShowingDelegate = adapterDelegate;
  [Chartboost showRewardedVideo:_chartboostAdLocation];
}

#pragma mark - Interstitial methods

- (void)configureInterstitialAdWithAppID:(NSString *)appID
                          adAppSignature:(NSString *)appSignature
                              adLocation:(NSString *)adLocation
                                delegate:
                                    (id<GADMAdapterChartboostDelegateProtocol>)adapterDelegate {
  _chartboostAdLocation = adLocation;
  id<GADMAdapterChartboostDelegateProtocol> strongDelegate = adapterDelegate;
  dispatch_barrier_async(_queue, ^{
    [_interstitialDelegates
        addObject:[[GADMAdapterChartboostWeakReference alloc] initWithObject:adapterDelegate]];
  });

  GADMChartboostExtras *chartboostExtras = [strongDelegate extras];
  if (chartboostExtras.frameworkVersion && chartboostExtras.framework) {
    [Chartboost setFramework:chartboostExtras.framework
                 withVersion:chartboostExtras.frameworkVersion];
  }

  if (!_isChartboostInitialized) {
    [self startWithAppId:appID appSignature:appSignature];
  }
  [Chartboost setAutoCacheAds:YES];
  if ([Chartboost hasInterstitial:adLocation]) {
    [strongDelegate didCacheInterstitial:adLocation];
  } else {
    [Chartboost cacheInterstitial:adLocation];
  }
}

- (void)presentInterstitialAdForDelegate:
    (id<GADMAdapterChartboostDelegateProtocol>)adapterDelegate {
  _currentShowingDelegate = adapterDelegate;
  [Chartboost showInterstitial:_chartboostAdLocation];
}

#pragma mark - Chartboost Delegate mathods -

- (void)didInitialize:(BOOL)status {
  _isChartboostInitialized = status;
  [_rewardbasedVideoDelegates
      enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        GADMAdapterChartboostWeakReference *weakReference = obj;
        id<GADMAdapterChartboostDelegateProtocol> strongDelegate =
            (id<GADMAdapterChartboostDelegateProtocol>)weakReference.weakObject;
        [strongDelegate didInitialize:status];
      }];
}

#pragma mark - Chartboost Interstitial Delegate Methods

- (void)didDisplayInterstitial:(CBLocation)location {
  id<GADMAdapterChartboostDelegateProtocol> strongDelegate = _currentShowingDelegate;
  [strongDelegate didDisplayInterstitial:location];
}

- (void)didCacheInterstitial:(CBLocation)location {
  dispatch_barrier_async(_queue, ^{
    [_interstitialDelegates
        enumerateObjectsWithOptions:NSEnumerationReverse
                         usingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                           GADMAdapterChartboostWeakReference *weakReference = obj;
                           id<GADMAdapterChartboostDelegateProtocol> strongDelegate =
                               (id<GADMAdapterChartboostDelegateProtocol>)weakReference.weakObject;
                           if ([location isEqual:_chartboostAdLocation]) {
                             dispatch_async(dispatch_get_main_queue(), ^{
                               [strongDelegate didCacheInterstitial:location];
                             });
                             [_interstitialDelegates removeObjectAtIndex:idx];
                           }
                         }];
  });
}

- (void)didFailToLoadInterstitial:(CBLocation)location withError:(CBLoadError)error {
  dispatch_barrier_async(_queue, ^{
    [_interstitialDelegates
        enumerateObjectsWithOptions:NSEnumerationReverse
                         usingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                           GADMAdapterChartboostWeakReference *weakReference = obj;
                           id<GADMAdapterChartboostDelegateProtocol> strongDelegate =
                               (id<GADMAdapterChartboostDelegateProtocol>)weakReference.weakObject;
                           if ([location isEqual:_chartboostAdLocation]) {
                             dispatch_async(dispatch_get_main_queue(), ^{
                               [strongDelegate didFailToLoadInterstitial:location withError:error];
                             });
                             [_interstitialDelegates removeObjectAtIndex:idx];
                           }
                         }];
  });
}

- (void)didDismissInterstitial:(CBLocation)location {
  id<GADMAdapterChartboostDelegateProtocol> strongDelegate = _currentShowingDelegate;
  [strongDelegate didDismissInterstitial:location];
}

- (void)didClickInterstitial:(CBLocation)location {
  id<GADMAdapterChartboostDelegateProtocol> strongDelegate = _currentShowingDelegate;
  [strongDelegate didClickInterstitial:location];
}

#pragma mark - Chartboost Reward Based Video Ad Delegate Methods

- (void)didDisplayRewardedVideo:(CBLocation)location {
  id<GADMAdapterChartboostDelegateProtocol> strongDelegate = _currentShowingDelegate;
  [strongDelegate didDisplayRewardedVideo:location];
}

- (void)didCacheRewardedVideo:(CBLocation)location {
  dispatch_barrier_async(_queue, ^{
    [_rewardbasedVideoDelegates
        enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
          GADMAdapterChartboostWeakReference *weakReference = obj;
          id<GADMAdapterChartboostDelegateProtocol> strongDelegate =
              (id<GADMAdapterChartboostDelegateProtocol>)weakReference.weakObject;
          if ([location isEqual:_chartboostAdLocation]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [strongDelegate didCacheRewardedVideo:location];
            });
          }
        }];
  });
}

- (void)didFailToLoadRewardedVideo:(CBLocation)location withError:(CBLoadError)error {
  dispatch_barrier_async(_queue, ^{
    [_rewardbasedVideoDelegates
        enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
          GADMAdapterChartboostWeakReference *weakReference = obj;
          id<GADMAdapterChartboostDelegateProtocol> strongDelegate =
              (id<GADMAdapterChartboostDelegateProtocol>)weakReference.weakObject;
          if ([location isEqual:_chartboostAdLocation]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [strongDelegate didFailToLoadRewardedVideo:location withError:error];
            });
          }
        }];
  });
}

- (void)didDismissRewardedVideo:(CBLocation)location {
  id<GADMAdapterChartboostDelegateProtocol> strongDelegate = _currentShowingDelegate;
  [strongDelegate didDismissRewardedVideo:location];
}

- (void)didClickRewardedVideo:(CBLocation)location {
  id<GADMAdapterChartboostDelegateProtocol> strongDelegate = _currentShowingDelegate;
  [strongDelegate didClickRewardedVideo:location];
}

- (void)didCompleteRewardedVideo:(CBLocation)location withReward:(int)reward {
  id<GADMAdapterChartboostDelegateProtocol> strongDelegate = _currentShowingDelegate;
  [strongDelegate didCompleteRewardedVideo:location withReward:reward];
}

- (void)stopTrackingDelegate:(id<GADMAdapterChartboostDelegateProtocol>)adapterDelegate {
  dispatch_barrier_async(_queue, ^{
    if ([_interstitialDelegates containsObject:adapterDelegate]) {
      [_interstitialDelegates removeObject:adapterDelegate];
    } else {
      [_rewardbasedVideoDelegates removeObject:adapterDelegate];
    }
  });
}

@end
