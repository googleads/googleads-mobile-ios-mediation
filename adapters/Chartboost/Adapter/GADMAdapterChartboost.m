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

@import GoogleMobileAds;

#import "GADMAdapterChartboost.h"

#import "GADMAdNetworkConnectorProtocol.h"
#import "GADMAdapterChartboostSingleton.h"
#import "GADMChartboostError.h"
#import "GADMChartboostExtras.h"
#import "GADMRewardBasedVideoAdNetworkConnectorProtocol.h"

NSString *const kGADMAdapterChartboostVersion = @"1.1.0";

@interface GADMAdapterChartboost () {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMRewardBasedVideoAdNetworkConnector> _rewardbasedVideoAdConnector;

  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _interstitialConnector;

  /// YES if the adapter is loading.
  BOOL _loading;

  /// YES if the adapter is initialized.
  BOOL _initialized;

  /// Chartboost ad location.
  NSString *_chartboostAdLocation;
}

@end

@implementation GADMAdapterChartboost

+ (NSString *)adapterVersion {
  return kGADMAdapterChartboostVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMChartboostExtras class];
}

#pragma mark Rewardbased video

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:
    (id<GADMRewardBasedVideoAdNetworkConnector>)connector {
  if (!connector) {
    return nil;
  }
  self = [super init];
  if (self) {
    _rewardbasedVideoAdConnector = connector;
  }
  return self;
}

- (void)setUp {
  NSString *appID = [[[_rewardbasedVideoAdConnector credentials] objectForKey:@"appId"]
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSString *appSignature =
      [[[_rewardbasedVideoAdConnector credentials] objectForKey:@"appSignature"]
          stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSString *adLocation = [[[_rewardbasedVideoAdConnector credentials] objectForKey:@"adLocation"]
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  if (adLocation) {
    _chartboostAdLocation = adLocation;
  } else {
    _chartboostAdLocation = CBLocationDefault;
  }

  if (!appID || !appSignature) {
    NSError *error = GADChartboostErrorWithDescription(@"App ID & App Signature cannot be nil.");
    [_rewardbasedVideoAdConnector adapter:self didFailToSetUpRewardBasedVideoAdWithError:error];
    return;
  }

  _initialized = NO;
  [[GADMAdapterChartboostSingleton sharedManager]
      configureRewardBasedVideoAdWithAppID:appID
                            adAppSignature:appSignature
                                adLocation:_chartboostAdLocation
                                  delegate:self];
}

- (void)requestRewardBasedVideoAd {
  NSString *adLocation = [[[_rewardbasedVideoAdConnector credentials] objectForKey:@"adLocation"]
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  if (adLocation) {
    _chartboostAdLocation = adLocation;
  } else {
    _chartboostAdLocation = CBLocationDefault;
  }
  _loading = YES;
  [[GADMAdapterChartboostSingleton sharedManager]
      requestRewardBasedVideoForDelegate:self
                              adLocation:_chartboostAdLocation];
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
  [[GADMAdapterChartboostSingleton sharedManager] presentRewardBasedVideoAdForDelegate:self];
}

- (void)stopBeingDelegate {
  [[GADMAdapterChartboostSingleton sharedManager] stopTrackingDelegate:self];
}

#pragma mark Interstitial

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  if (!connector) {
    return nil;
  }
  self = [super init];
  if (self) {
    _interstitialConnector = connector;
  }
  return self;
}

- (void)getInterstitial {
  NSString *appID = [[[_interstitialConnector credentials] objectForKey:@"appId"]
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSString *appSignature = [[[_interstitialConnector credentials] objectForKey:@"appSignature"]
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSString *adLocation = [[[_interstitialConnector credentials] objectForKey:@"adLocation"]
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  if (adLocation) {
    _chartboostAdLocation = adLocation;
  } else {
    _chartboostAdLocation = CBLocationDefault;
  }

  if (!appID || !appSignature) {
    NSError *error = GADChartboostErrorWithDescription(@"App ID & App Signature cannot be nil.");
    [_interstitialConnector adapter:self didFailAd:error];
    return;
  }
  _loading = YES;
  [[GADMAdapterChartboostSingleton sharedManager]
      configureInterstitialAdWithAppID:appID
                        adAppSignature:appSignature
                            adLocation:_chartboostAdLocation
                              delegate:self];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  [[GADMAdapterChartboostSingleton sharedManager] presentInterstitialAdForDelegate:self];
}

#pragma mark Banner

- (void)getBannerWithSize:(GADAdSize)adSize {
  // Chartboost doesn't support banner ads.
  NSError *error = GADChartboostErrorWithDescription(@"Chartboost Ads doesn't support banner ads.");
  [_interstitialConnector adapter:self didFailAd:error];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

#pragma mark - Chartboost Delegate Protocol Methods -

- (GADMChartboostExtras *)extras {
  GADMChartboostExtras *chartboostExtras;
  if (_rewardbasedVideoAdConnector) {
    chartboostExtras = [_rewardbasedVideoAdConnector networkExtras];
  } else {
    chartboostExtras = [_interstitialConnector networkExtras];
  }
  return chartboostExtras;
}

- (void)didInitialize:(BOOL)status {
  if (_initialized) {
    return;
  }
  if (status) {
    _initialized = YES;
    [_rewardbasedVideoAdConnector adapterDidSetUpRewardBasedVideoAd:self];
  } else {
    _initialized = NO;
    NSString *description = [NSString stringWithFormat:@"%@ failed to setup reward based video ad.",
                                                       NSStringFromClass([Chartboost class])];
    NSError *error = GADChartboostErrorWithDescription(description);
    [_rewardbasedVideoAdConnector adapter:self didFailToSetUpRewardBasedVideoAdWithError:error];
  }
}

#pragma mark - Chartboost Interstitial Delegate Methods

- (void)didDisplayInterstitial:(CBLocation)location {
  [_interstitialConnector adapterWillPresentInterstitial:self];
}

- (void)didCacheInterstitial:(CBLocation)location {
  if (_loading && [location isEqual:_chartboostAdLocation]) {
    [_interstitialConnector adapterDidReceiveInterstitial:self];
    _loading = NO;
  }
}

- (void)didFailToLoadInterstitial:(CBLocation)location withError:(CBLoadError)error {
  if (_loading && [location isEqual:_chartboostAdLocation]) {
    [_interstitialConnector adapter:self didFailAd:[self adRequestErrorTypeForCBLoadError:error]];
    _loading = NO;
  };
}

- (void)didDismissInterstitial:(CBLocation)location {
  [_interstitialConnector adapterDidDismissInterstitial:self];
}

- (void)didClickInterstitial:(CBLocation)location {
  [_interstitialConnector adapterDidGetAdClick:self];
  [_interstitialConnector adapterWillLeaveApplication:self];
}

#pragma mark - Chartboost Reward Based Video Ad Delegate Methods

- (void)didDisplayRewardedVideo:(CBLocation)location {
  [_rewardbasedVideoAdConnector adapterDidStartPlayingRewardBasedVideoAd:self];
}

- (void)didCacheRewardedVideo:(CBLocation)location {
  if (_loading && [location isEqual:_chartboostAdLocation]) {
    [_rewardbasedVideoAdConnector adapterDidReceiveRewardBasedVideoAd:self];
    _loading = NO;
  }
}

- (void)didFailToLoadRewardedVideo:(CBLocation)location withError:(CBLoadError)error {
  if (_loading && [location isEqual:_chartboostAdLocation]) {
    [_rewardbasedVideoAdConnector adapter:self
        didFailToLoadRewardBasedVideoAdwithError:[self adRequestErrorTypeForCBLoadError:error]];
    _loading = NO;
  }
}

- (void)didDismissRewardedVideo:(CBLocation)location {
  [_rewardbasedVideoAdConnector adapterDidCloseRewardBasedVideoAd:self];
}

- (void)didClickRewardedVideo:(CBLocation)location {
  [_rewardbasedVideoAdConnector adapterDidGetAdClick:self];
  [_rewardbasedVideoAdConnector adapterWillLeaveApplication:self];
}

- (void)didCompleteRewardedVideo:(CBLocation)location withReward:(int)reward {
  /// Chartboost doesn't provide access to the reward type.
  GADAdReward *adReward =
      [[GADAdReward alloc] initWithRewardType:@""
                                 rewardAmount:[[NSDecimalNumber alloc] initWithInt:reward]];
  [_rewardbasedVideoAdConnector adapter:self didRewardUserWithReward:adReward];
}

#pragma mark - Internal methods

- (NSError *)adRequestErrorTypeForCBLoadError:(CBLoadError)error {
  NSString *description = nil;
  switch (error) {
    case CBLoadErrorInternal:
      description = @"Internal error.";
      break;
    case CBLoadErrorInternetUnavailable:
      description = @"Internet unavailable.";
      break;
    case CBLoadErrorTooManyConnections:
      description = @"Too many connections.";
      break;
    case CBLoadErrorWrongOrientation:
      description = @"Wrong orientation.";
      break;
    case CBLoadErrorFirstSessionInterstitialsDisabled:
      description = @"Interstitial disabled.";
      break;
    case CBLoadErrorNetworkFailure:
      description = @"Network failure.";
      break;
    case CBLoadErrorNoAdFound:
      description = @"No ad found.";
      break;
    case CBLoadErrorSessionNotStarted:
      description = @"Session not started.";
      break;
    case CBLoadErrorImpressionAlreadyVisible:
      description = @"Impression already visible.";
      break;
    case CBLoadErrorUserCancellation:
      description = @"User cancellation.";
      break;
    case CBLoadErrorNoLocationFound:
      description = @"No location found.";
      break;
    case CBLoadErrorAssetDownloadFailure:
      description = @"Error downloading asset.";
      break;
    case CBLoadErrorPrefetchingIncomplete:
      description = @"Video prefetching is not finished.";
      break;
    default:
      description = @"No inventory.";
      break;
  }

  return GADChartboostErrorWithDescription(description);
}

@end
