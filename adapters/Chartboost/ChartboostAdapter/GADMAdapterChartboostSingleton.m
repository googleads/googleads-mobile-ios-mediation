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
#import "GADMAdapterChartboostDataProvider.h"
#import "GADMChartboostError.h"

@interface GADMAdapterChartboostSingleton () <ChartboostDelegate, CHBBannerDelegate> {
  /// Hash Map to hold all interstitial adapter delegates.
  NSMapTable<NSString *, id<GADMAdapterChartboostDataProvider, ChartboostDelegate>>
      *_interstitialAdapterDelegates;

  /// Hash Map to hold all rewarded adapter delegates.
  NSMapTable<NSString *, id<GADMAdapterChartboostDataProvider, ChartboostDelegate>>
      *_rewardedAdapterDelegates;

  /// Concurrent dispatch queue.
  dispatch_queue_t _queue;

  ChartboostInitState _initState;

  NSMutableArray<ChartboostInitCompletionHandler> *_completionHandlers;
}

@property (nonatomic) NSMapTable<CHBBanner *, id<CHBBannerDelegate>> *bannersToDelegates;
@property (nonatomic) NSMutableArray<CHBBanner *> *loadingBanners;

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
    _interstitialAdapterDelegates =
        [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                              valueOptions:NSPointerFunctionsWeakMemory];
    _rewardedAdapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                      valueOptions:NSPointerFunctionsWeakMemory];
    _queue = dispatch_queue_create("com.google.admob.chartboost_adapter_singleton",
                                   DISPATCH_QUEUE_CONCURRENT);
    _completionHandlers = [[NSMutableArray alloc] init];
    _initState = UNINITIALIZED;
    _bannersToDelegates = [NSMapTable weakToWeakObjectsMapTable];
    _loadingBanners = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)startWithAppId:(NSString *)appId
          appSignature:(NSString *)appSignature
     completionHandler:(ChartboostInitCompletionHandler)completionHandler {
  if (_initState == INITIALIZED) {
    completionHandler(nil);
    return;
  }

  static dispatch_once_t once;
  dispatch_once(&once, ^{
    [Chartboost startWithAppId:appId appSignature:appSignature delegate:self];
    [Chartboost setMediation:CBMediationAdMob
          withLibraryVersion:[GADRequest sdkVersion]
              adapterVersion:kGADMAdapterChartboostVersion];
    [Chartboost setAutoCacheAds:YES];
  });
  _initState = INITIALIZING;
  [_completionHandlers addObject:completionHandler];
}

- (void)addRewardedAdAdapterDelegate:
    (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate {
  @synchronized(_rewardedAdapterDelegates) {
    [_rewardedAdapterDelegates setObject:adapterDelegate forKey:[adapterDelegate getAdLocation]];
  }
}

- (void)removeRewardedAdAdapterDelegate:
    (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate {
  @synchronized(_rewardedAdapterDelegates) {
    [_rewardedAdapterDelegates removeObjectForKey:[adapterDelegate getAdLocation]];
  }
}

- (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)
    getInterstitialAdapterDelegateForAdLocation:(NSString *)adLocation {
  @synchronized(_interstitialAdapterDelegates) {
    return [_interstitialAdapterDelegates objectForKey:adLocation];
  }
}

- (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)
    getRewardedAdapterDelegateForAdLocation:(NSString *)adLocation {
  @synchronized(_rewardedAdapterDelegates) {
    return [_rewardedAdapterDelegates objectForKey:adLocation];
  }
}

- (void)addInterstitialAdapterDelegate:
    (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate {
  @synchronized(_interstitialAdapterDelegates) {
    [_interstitialAdapterDelegates setObject:adapterDelegate
                                      forKey:[adapterDelegate getAdLocation]];
  }
}

- (void)removeInterstitialAdapterDelegate:
    (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate {
  @synchronized(_interstitialAdapterDelegates) {
    [_interstitialAdapterDelegates removeObjectForKey:[adapterDelegate getAdLocation]];
  }
}

#pragma mark - Rewarded Ads Methods

- (void)configureRewardedAdWithAppID:(NSString *)appID
                        appSignature:(NSString *)appSignature
                            delegate:(id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)
                                         adapterDelegate {
  GADMChartboostExtras *chartboostExtras = [adapterDelegate extras];
  if (chartboostExtras.frameworkVersion && chartboostExtras.framework) {
    [Chartboost setFramework:chartboostExtras.framework
                 withVersion:chartboostExtras.frameworkVersion];
  }

  NSString *adLocation = [adapterDelegate getAdLocation];
  id<GADMAdapterChartboostDataProvider, ChartboostDelegate> existingDelegate =
      [self getRewardedAdapterDelegateForAdLocation:adLocation];

  if (existingDelegate) {
    NSError *error = GADChartboostErrorWithDescription(
        @"Already requested an ad for this ad location. Can't make another request.");
    [adapterDelegate didFailToLoadAdWithError:error];
    return;
  }

  [self addRewardedAdAdapterDelegate:adapterDelegate];

  if ([Chartboost hasRewardedVideo:adLocation]) {
    [adapterDelegate didCacheRewardedVideo:adLocation];
  } else {
    [Chartboost cacheRewardedVideo:adLocation];
  }
}

- (void)presentRewardedAdForDelegate:
    (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate {
  [Chartboost showRewardedVideo:[adapterDelegate getAdLocation]];
}

#pragma mark - Interstitial methods

- (void)configureInterstitialAdWithAppID:(NSString *)appID
                            appSignature:(NSString *)appSignature
                                delegate:(id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)
                                             adapterDelegate {
  GADMChartboostExtras *chartboostExtras = [adapterDelegate extras];
  if (chartboostExtras.frameworkVersion && chartboostExtras.framework) {
    [Chartboost setFramework:chartboostExtras.framework
                 withVersion:chartboostExtras.frameworkVersion];
  }

  NSString *adLocation = [adapterDelegate getAdLocation];
  id<GADMAdapterChartboostDataProvider, ChartboostDelegate> existingDelegate =
      [self getInterstitialAdapterDelegateForAdLocation:adLocation];

  if (existingDelegate) {
    NSError *error = GADChartboostErrorWithDescription(
        @"Already requested an ad for this ad location. Can't make another request.");
    [adapterDelegate didFailToLoadAdWithError:error];
    return;
  }

  [self addInterstitialAdapterDelegate:adapterDelegate];

  if ([Chartboost hasInterstitial:adLocation]) {
    [adapterDelegate didCacheInterstitial:adLocation];
  } else {
    [Chartboost cacheInterstitial:adLocation];
  }
}

- (void)presentInterstitialAdForDelegate:
    (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate {
  [Chartboost showInterstitial:[adapterDelegate getAdLocation]];
}

#pragma mark - Banner methods

- (void)configureBannerWithSize:(GADAdSize)adSize
                       location:(nonnull NSString *)location
                       delegate:(nullable id<CHBBannerDelegate>)delegate
                 viewController:(nullable UIViewController *)viewController
                         extras:(nullable GADMChartboostExtras *)extras
{
    if (extras.frameworkVersion && extras.framework) {
        [Chartboost setFramework:extras.framework
                     withVersion:extras.frameworkVersion];
    }
    
    CHBBanner *banner = [[CHBBanner alloc] initWithSize:adSize.size location:location delegate:self];
    banner.automaticallyRefreshesContent = NO;
    [self.loadingBanners addObject:banner];
    [self.bannersToDelegates setObject:delegate forKey:banner];
    [banner showFromViewController:viewController];
}

#pragma mark - Chartboost Delegate mathods -

- (void)didInitialize:(BOOL)status {
  if (status) {
    _initState = INITIALIZED;
    for (ChartboostInitCompletionHandler completionHandler in _completionHandlers) {
      completionHandler(nil);
    }
  } else {
    _initState = UNINITIALIZED;
    NSError *error = GADChartboostErrorWithDescription(@"Failed to initialize Chartboost SDK.");
    for (ChartboostInitCompletionHandler completionHandler in _completionHandlers) {
      completionHandler(error);
    }
  }
  [_completionHandlers removeAllObjects];
}

#pragma mark - Chartboost Interstitial Delegate Methods

- (void)didDisplayInterstitial:(CBLocation)location {
  id<GADMAdapterChartboostDataProvider, ChartboostDelegate> delegate =
      [self getInterstitialAdapterDelegateForAdLocation:location];
  [delegate didDisplayInterstitial:location];
}

- (void)didCacheInterstitial:(CBLocation)location {
  id<GADMAdapterChartboostDataProvider, ChartboostDelegate> delegate =
      [self getInterstitialAdapterDelegateForAdLocation:location];
  [delegate didCacheInterstitial:location];
}

- (void)didFailToLoadInterstitial:(CBLocation)location withError:(CBLoadError)error {
  id<GADMAdapterChartboostDataProvider, ChartboostDelegate> delegate =
      [self getInterstitialAdapterDelegateForAdLocation:location];
  [delegate didFailToLoadInterstitial:location withError:error];
}

- (void)didDismissInterstitial:(CBLocation)location {
  id<GADMAdapterChartboostDataProvider, ChartboostDelegate> delegate =
      [self getInterstitialAdapterDelegateForAdLocation:location];
  [delegate didDismissInterstitial:location];
}

- (void)didClickInterstitial:(CBLocation)location {
  id<GADMAdapterChartboostDataProvider, ChartboostDelegate> delegate =
      [self getInterstitialAdapterDelegateForAdLocation:location];
  [delegate didClickInterstitial:location];
}

#pragma mark - Chartboost Reward Based Video Ad Delegate Methods

- (void)didDisplayRewardedVideo:(CBLocation)location {
  id<GADMAdapterChartboostDataProvider, ChartboostDelegate> delegate =
      [self getRewardedAdapterDelegateForAdLocation:location];
  [delegate didDisplayRewardedVideo:location];
}

- (void)didCacheRewardedVideo:(CBLocation)location {
  id<GADMAdapterChartboostDataProvider, ChartboostDelegate> delegate =
      [self getRewardedAdapterDelegateForAdLocation:location];
  [delegate didCacheRewardedVideo:location];
}

- (void)didFailToLoadRewardedVideo:(CBLocation)location withError:(CBLoadError)error {
  id<GADMAdapterChartboostDataProvider, ChartboostDelegate> delegate =
      [self getRewardedAdapterDelegateForAdLocation:location];
  [delegate didFailToLoadRewardedVideo:location withError:error];
}

- (void)didDismissRewardedVideo:(CBLocation)location {
  id<GADMAdapterChartboostDataProvider, ChartboostDelegate> delegate =
      [self getRewardedAdapterDelegateForAdLocation:location];
  [delegate didDismissRewardedVideo:location];
}

- (void)didClickRewardedVideo:(CBLocation)location {
  id<GADMAdapterChartboostDataProvider, ChartboostDelegate> delegate =
      [self getRewardedAdapterDelegateForAdLocation:location];
  [delegate didClickRewardedVideo:location];
}

- (void)didCompleteRewardedVideo:(CBLocation)location withReward:(int)reward {
  id<GADMAdapterChartboostDataProvider, ChartboostDelegate> delegate =
      [self getRewardedAdapterDelegateForAdLocation:location];
  [delegate didCompleteRewardedVideo:location withReward:reward];
}

- (void)stopTrackingInterstitialDelegate:
    (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate {
  [self removeInterstitialAdapterDelegate:adapterDelegate];
}

#pragma mark - Chartboost Banner Delegate Methods

- (void)didCacheAd:(CHBCacheEvent *)event error:(nullable CHBCacheError *)error
{
    // We keep a strong reference to the banner only until it is loaded, since at that point the view is sent to GMA (as a parameter in a delegate call) and it is its responsibility to retain it.
    [[self.bannersToDelegates objectForKey:(CHBBanner *)event.ad] didCacheAd:event error:error];
    [self.loadingBanners removeObject:(CHBBanner *)event.ad];
}

- (void)willShowAd:(CHBShowEvent *)event error:(nullable CHBShowError *)error
{
    [[self.bannersToDelegates objectForKey:(CHBBanner *)event.ad] willShowAd:event error:error];
}

- (void)didShowAd:(CHBShowEvent *)event error:(nullable CHBShowError *)error
{
    [[self.bannersToDelegates objectForKey:(CHBBanner *)event.ad] didShowAd:event error:error];
}

- (void)didClickAd:(CHBClickEvent *)event error:(nullable CHBClickError *)error
{
    [[self.bannersToDelegates objectForKey:(CHBBanner *)event.ad] didClickAd:event error:error];
}

- (void)didFinishHandlingClick:(CHBClickEvent *)event error:(nullable CHBClickError *)error
{
    [[self.bannersToDelegates objectForKey:(CHBBanner *)event.ad] didFinishHandlingClick:event error:error];
}


@end
