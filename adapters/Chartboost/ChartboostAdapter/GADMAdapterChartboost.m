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

#import "GADMAdapterChartboost.h"

#import "GADMAdapterChartboostConstants.h"
#import "GADMAdapterChartboostSingleton.h"
#import "GADMChartboostError.h"
#import "GADMChartboostExtras.h"
#import "GADMediationAdapterChartboost.h"

@implementation GADMAdapterChartboost {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// YES if the adapter is loading.
  BOOL _loading;

  /// Chartboost ad location.
  NSString *_chartboostAdLocation;

  /// Strong reference to loading banner to keep it in memory.
  CHBBanner *_loadingBanner;
}

+ (NSString *)adapterVersion {
  return kGADMAdapterChartboostVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMChartboostExtras class];
}

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterChartboost class];
}

- (void)stopBeingDelegate {
  GADMAdapterChartboostSingleton *sharedInstance = GADMAdapterChartboostSingleton.sharedInstance;
  [sharedInstance stopTrackingInterstitialDelegate:self];
}

#pragma mark Interstitial

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  if (!connector) {
    return nil;
  }
  self = [super init];
  if (self) {
    _connector = connector;
  }
  return self;
}

- (void)getInterstitial {
  GADMAdapterChartboost *__weak weakSelf = self;
  [self initializeChartboost:^(NSError *_Nullable error) {
    GADMAdapterChartboost *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    if (error) {
      [strongSelf->_connector adapter:strongSelf didFailAd:error];
      return;
    }

    GADMAdapterChartboostSingleton *sharedInstance = GADMAdapterChartboostSingleton.sharedInstance;
    [sharedInstance configureInterstitialAdWithDelegate:strongSelf];
  }];
}

- (void)initializeChartboost:(ChartboostInitCompletionHandler)completion {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  NSString *appID = [strongConnector.credentials[kGADMAdapterChartboostAppID]
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSString *appSignature = [strongConnector.credentials[kGADMAdapterChartboostAppSignature]
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSString *adLocation = [strongConnector.credentials[kGADMAdapterChartboostAdLocation]
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

  if (adLocation) {
    _chartboostAdLocation = [adLocation copy];
  } else {
    _chartboostAdLocation = [CBLocationDefault copy];
  }

  if (!appID || !appSignature) {
    NSError *error = GADChartboostErrorWithDescription(@"App ID & App Signature cannot be nil.");
    if (completion) {
      completion(error);
    }
    return;
  }

  _loading = YES;

  GADMAdapterChartboostSingleton *sharedInstance = [GADMAdapterChartboostSingleton sharedInstance];
  [sharedInstance startWithAppId:appID
                    appSignature:appSignature
               completionHandler:^(NSError *_Nullable error) {
                 if (completion) {
                   completion(error);
                 }
               }];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  GADMAdapterChartboostSingleton *sharedInstance = [GADMAdapterChartboostSingleton sharedInstance];
  [sharedInstance presentInterstitialAdForDelegate:self];
}

#pragma mark Banner

- (void)getBannerWithSize:(GADAdSize)adSize {
  GADMAdapterChartboost *__weak weakSelf = self;
  [self initializeChartboost:^(NSError *_Nullable error) {
      // CHBBanner is a UIView subclass so it needs to be used on the main thread.
      dispatch_async(dispatch_get_main_queue(), ^{
          GADMAdapterChartboost *strongSelf = weakSelf;
          if (!strongSelf) {
              return;
          }
          if (error) {
              [strongSelf->_connector adapter:strongSelf didFailAd:error];
              return;
          }
          UIViewController *viewController =
            [strongSelf->_connector viewControllerForPresentingModalView];
          GADMChartboostExtras *extras = [strongSelf extras];
          if (extras.frameworkVersion && extras.framework) {
              [Chartboost setFramework:extras.framework withVersion:extras.frameworkVersion];
          }
          CHBBanner *banner = [[CHBBanner alloc] initWithSize:adSize.size
                                                     location:[strongSelf getAdLocation]
                                                     delegate:self];
          banner.automaticallyRefreshesContent = NO;
          strongSelf->_loadingBanner = banner;
          [banner showFromViewController:viewController];
      });
  }];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

#pragma mark GADMAdapterChartboostDataProvider Methods

- (NSString *)getAdLocation {
  return _chartboostAdLocation;
}

- (GADMChartboostExtras *)extras {
  GADMChartboostExtras *chartboostExtras;
  chartboostExtras = [_connector networkExtras];
  return chartboostExtras;
}

- (void)didFailToLoadAdWithError:(NSError *)error {
  [_connector adapter:self didFailAd:error];
}

#pragma mark - Chartboost Interstitial Ad Delegate Methods

- (void)didDisplayInterstitial:(CBLocation)location {
  [_connector adapterWillPresentInterstitial:self];
}

- (void)didCacheInterstitial:(CBLocation)location {
  if (_loading) {
    [_connector adapterDidReceiveInterstitial:self];
    _loading = NO;
  }
}

- (void)didFailToLoadInterstitial:(CBLocation)location withError:(CBLoadError)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;

  if (_loading) {
    [strongConnector adapter:self didFailAd:adRequestErrorTypeForCBLoadError(error)];
    _loading = NO;
  } else if (error == CBLoadErrorInternetUnavailableAtShow) {
    // Chartboost sends the CBLoadErrorInternetUnavailableAtShow error when the Chartboost SDK
    // fails to present an ad for which a didCacheInterstitial event has already been sent.
    [strongConnector adapterWillPresentInterstitial:self];
    [strongConnector adapterWillDismissInterstitial:self];
    [strongConnector adapterDidDismissInterstitial:self];
  }
}

- (void)didDismissInterstitial:(CBLocation)location {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  [strongConnector adapterWillDismissInterstitial:self];
  [strongConnector adapterDidDismissInterstitial:self];
}

- (void)didClickInterstitial:(CBLocation)location {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  [strongConnector adapterDidGetAdClick:self];
  [strongConnector adapterWillLeaveApplication:self];
}

#pragma mark - Chartboost Banner Delegate Methods

- (void)didCacheAd:(nonnull CHBCacheEvent *)event error:(nullable CHBCacheError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (error) {
    [strongConnector adapter:self didFailAd:NSErrorForCHBCacheError(error)];
  } else {
    [strongConnector adapter:self didReceiveAdView:_loadingBanner];
  }
  // Nilling the chartboost banner ad after loaded.
  _loadingBanner = nil;
}

- (void)willShowAd:(nonnull CHBShowEvent *)event error:(nullable CHBShowError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (error) {
    [strongConnector adapter:self didFailAd:NSErrorForCHBShowError(error)];
  }
}

- (void)didShowAd:(nonnull CHBShowEvent *)event error:(nullable CHBShowError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (error) {
    [strongConnector adapter:self didFailAd:NSErrorForCHBShowError(error)];
  }
}

- (void)didClickAd:(nonnull CHBClickEvent *)event error:(nullable CHBClickError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!error) {
    [strongConnector adapterDidGetAdClick:self];
    [strongConnector adapterWillPresentFullScreenModal:self];
  }
}

- (void)didFinishHandlingClick:(nonnull CHBClickEvent *)event
                         error:(nullable CHBClickError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  [strongConnector adapterWillDismissFullScreenModal:self];
  [strongConnector adapterDidDismissFullScreenModal:self];
}

@end
