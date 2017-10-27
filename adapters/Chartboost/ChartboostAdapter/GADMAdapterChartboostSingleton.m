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

#import "GADMAdapterChartboostConstants.h"
#import "GADMAdapterChartboostProtocol.h"
#import "GADMAdapterChartboostWeakReference.h"

@interface GADMAdapterChartboostSingleton () <ChartboostDelegate> {
  /// Array to hold all interstitial adapter delegates.
  NSMutableArray *_interstitialDelegates;

  /// Array to hold all rewardbased video adapter delegates.
  NSMutableArray *_rewardbasedVideoDelegates;

  /// Connector from Chartboost adapter to send Chartboost callbacks.
  __weak id<GADMAdapterChartboostDataProvider, ChartboostDelegate> _currentShowingDelegate;

  /// YES if the Chartboost SDK initialized.
  BOOL _isChartboostInitialized;

  /// Concurrent dispatch queue.
  dispatch_queue_t _queue;
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
    [Chartboost setMediation:CBMediationAdMob withVersion:GADMAdapterChartboostVersion];
    [Chartboost setAutoCacheAds:YES];
  });
}

- (void)addRewardBasedVideoAdapterDelegate:
        (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate {
  GADMAdapterChartboostWeakReference *delegateReference =
      [[GADMAdapterChartboostWeakReference alloc] initWithObject:adapterDelegate];
  dispatch_barrier_async(_queue, ^{
    if (![_rewardbasedVideoDelegates containsObject:delegateReference]) {
      [_rewardbasedVideoDelegates addObject:delegateReference];
    }
  });
}

- (void)addInterstitialAdapterDelegate:
        (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate {
  GADMAdapterChartboostWeakReference *delegateReference =
      [[GADMAdapterChartboostWeakReference alloc] initWithObject:adapterDelegate];
  dispatch_barrier_async(_queue, ^{
    if (![_interstitialDelegates containsObject:delegateReference]) {
      [_interstitialDelegates addObject:delegateReference];
    }
  });
}

#pragma mark - Rewardbased Video Ads Methods

- (void)configureRewardBasedVideoAdWithAppID:(NSString *)appID
                              adAppSignature:(NSString *)appSignature
                                    delegate:
                                        (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)
                                            adapterDelegate {
  GADMChartboostExtras *chartboostExtras = [adapterDelegate extras];
  if (chartboostExtras.frameworkVersion && chartboostExtras.framework) {
    [Chartboost setFramework:chartboostExtras.framework
                 withVersion:chartboostExtras.frameworkVersion];
  }
  if (!_isChartboostInitialized) {
    [self addRewardBasedVideoAdapterDelegate:adapterDelegate];
    [self startWithAppId:appID appSignature:appSignature];
  } else {
    [adapterDelegate didInitialize:YES];
  }
}

- (void)requestRewardBasedVideoForDelegate:
        (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate {
  NSString *adLocation = [adapterDelegate getAdLocation];
  if ([Chartboost hasRewardedVideo:adLocation]) {
    [adapterDelegate didCacheRewardedVideo:adLocation];
  } else {
    [self addRewardBasedVideoAdapterDelegate:adapterDelegate];
    [Chartboost cacheRewardedVideo:adLocation];
  }
}

- (void)presentRewardBasedVideoAdForDelegate:
        (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate {
  _currentShowingDelegate = adapterDelegate;
  [Chartboost showRewardedVideo:[adapterDelegate getAdLocation]];
}

#pragma mark - Interstitial methods

- (void)configureInterstitialAdWithAppID:(NSString *)appID
                          adAppSignature:(NSString *)appSignature
                                delegate:(id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)
                                             adapterDelegate {
  NSString *adLocation = [adapterDelegate getAdLocation];
  GADMChartboostExtras *chartboostExtras = [adapterDelegate extras];
  if (chartboostExtras.frameworkVersion && chartboostExtras.framework) {
    [Chartboost setFramework:chartboostExtras.framework
                 withVersion:chartboostExtras.frameworkVersion];
  }

  if (_isChartboostInitialized && [Chartboost hasInterstitial:adLocation]) {
    [adapterDelegate didCacheInterstitial:adLocation];
  } else {
    [self addInterstitialAdapterDelegate:adapterDelegate];
    if (!_isChartboostInitialized) {
      [self startWithAppId:appID appSignature:appSignature];
    }
    [Chartboost cacheInterstitial:adLocation];
  }
}

- (void)presentInterstitialAdForDelegate:
        (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate {
  _currentShowingDelegate = adapterDelegate;
  [Chartboost showInterstitial:[adapterDelegate getAdLocation]];
}

#pragma mark - Chartboost Delegate mathods -

- (void)didInitialize:(BOOL)status {
  _isChartboostInitialized = status;
  // We only need to send the Chartboost initialize callback to reward-based video adapter.
  [_rewardbasedVideoDelegates
      enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        GADMAdapterChartboostWeakReference *weakReference = obj;
        id<ChartboostDelegate> strongDelegate = (id<ChartboostDelegate>)weakReference.weakObject;
        [strongDelegate didInitialize:status];
      }];
}

#pragma mark - Chartboost Interstitial Delegate Methods

- (void)didDisplayInterstitial:(CBLocation)location {
  [_currentShowingDelegate didDisplayInterstitial:location];
}

- (void)didCacheInterstitial:(CBLocation)location {
  dispatch_barrier_async(_queue, ^{
    [_interstitialDelegates
        enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
          GADMAdapterChartboostWeakReference *weakReference = obj;
          id<GADMAdapterChartboostDataProvider, ChartboostDelegate> strongDelegate =
              (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)weakReference.weakObject;
          if ([location isEqual:[strongDelegate getAdLocation]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [strongDelegate didCacheInterstitial:location];
            });
            [_interstitialDelegates removeObject:obj];
          }
        }];
  });
}

- (void)didFailToLoadInterstitial:(CBLocation)location withError:(CBLoadError)error {
  if (error == CBLoadErrorInternetUnavailableAtShow) {
    // Chartboost SDK failed to present an ad. Notify the current showing adapter delegate.
    [_currentShowingDelegate didFailToLoadInterstitial:location withError:error];
    return;
  }
  dispatch_barrier_async(_queue, ^{
    [_interstitialDelegates
        enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
          GADMAdapterChartboostWeakReference *weakReference = obj;
          id<GADMAdapterChartboostDataProvider, ChartboostDelegate> strongDelegate =
              (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)weakReference.weakObject;
          if ([location isEqual:[strongDelegate getAdLocation]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [strongDelegate didFailToLoadInterstitial:location withError:error];
            });
            [_interstitialDelegates removeObject:obj];
          }
        }];
  });
}

- (void)didDismissInterstitial:(CBLocation)location {
  [_currentShowingDelegate didDismissInterstitial:location];
}

- (void)didClickInterstitial:(CBLocation)location {
  [_currentShowingDelegate didClickInterstitial:location];
}

#pragma mark - Chartboost Reward Based Video Ad Delegate Methods

- (void)didDisplayRewardedVideo:(CBLocation)location {
  [_currentShowingDelegate didDisplayRewardedVideo:location];
}

- (void)didCacheRewardedVideo:(CBLocation)location {
  dispatch_barrier_async(_queue, ^{
    [_rewardbasedVideoDelegates
        enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
          GADMAdapterChartboostWeakReference *weakReference = obj;
          id<GADMAdapterChartboostDataProvider, ChartboostDelegate> strongDelegate =
              (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)weakReference.weakObject;
          if ([location isEqual:[strongDelegate getAdLocation]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [strongDelegate didCacheRewardedVideo:location];
            });
            [_rewardbasedVideoDelegates removeObject:obj];
          }
        }];
  });
}

- (void)didFailToLoadRewardedVideo:(CBLocation)location withError:(CBLoadError)error {
  if (error == CBLoadErrorInternetUnavailableAtShow) {
    // Chartboost SDK failed to present an ad. Notify the current showing adapter delegate.
    [_currentShowingDelegate didFailToLoadRewardedVideo:location withError:error];
    return;
  }
  dispatch_barrier_async(_queue, ^{
    [_rewardbasedVideoDelegates
        enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
          GADMAdapterChartboostWeakReference *weakReference = obj;
          id<GADMAdapterChartboostDataProvider, ChartboostDelegate> strongDelegate =
              (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)weakReference.weakObject;
          if ([location isEqual:[strongDelegate getAdLocation]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [strongDelegate didFailToLoadRewardedVideo:location withError:error];
            });
            [_rewardbasedVideoDelegates removeObject:obj];
          }
        }];
  });
}

- (void)didDismissRewardedVideo:(CBLocation)location {
  [_currentShowingDelegate didDismissRewardedVideo:location];
}

- (void)didClickRewardedVideo:(CBLocation)location {
  [_currentShowingDelegate didClickRewardedVideo:location];
}

- (void)didCompleteRewardedVideo:(CBLocation)location withReward:(int)reward {
  [_currentShowingDelegate didCompleteRewardedVideo:location withReward:reward];
}

- (void)stopTrackingDelegate:
        (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate {
  GADMAdapterChartboostWeakReference *delegateReference =
      [[GADMAdapterChartboostWeakReference alloc] initWithObject:adapterDelegate];
  dispatch_barrier_async(_queue, ^{
    if ([_interstitialDelegates containsObject:delegateReference]) {
      [_interstitialDelegates removeObject:delegateReference];
    } else {
      [_rewardbasedVideoDelegates removeObject:delegateReference];
    }
  });
}

@end
