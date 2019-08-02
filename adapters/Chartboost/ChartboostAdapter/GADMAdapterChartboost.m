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
#import "GADMAdapterChartboostBanner.h"

@interface GADMAdapterChartboost () {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _interstitialConnector;

  /// YES if the adapter is loading.
  BOOL _loading;

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

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterChartboost class];
}

- (void)stopBeingDelegate {
  [[GADMAdapterChartboostSingleton sharedManager] stopTrackingInterstitialDelegate:self];
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

- (void)getInterstitial
{
    __weak typeof(self) weakSelf = self;
    [self initializeChartboost:^(BOOL success) {
        if (success) {
            [[GADMAdapterChartboostSingleton sharedManager] configureInterstitialAdWithDelegate:weakSelf];
        }
    }];
}

- (void)initializeChartboost:(void(^)(BOOL))completion
{
    id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
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
        [strongConnector adapter:self didFailAd:error];
        if (completion) completion(NO);
    } else {
        _loading = YES;
    }
    
    __weak typeof(self) weakSelf = self;
    GADMAdapterChartboostSingleton *shared = [GADMAdapterChartboostSingleton sharedManager];
    [shared startWithAppId:appID appSignature:appSignature completionHandler:^(NSError *error) {
        if (error) {
            GADMAdapterChartboost *strongSelf = weakSelf;
            [strongSelf->_interstitialConnector adapter:strongSelf didFailAd:error];
        }
        if (completion) completion(error == nil);
    }];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  [[GADMAdapterChartboostSingleton sharedManager] presentInterstitialAdForDelegate:self];
}

#pragma mark Banner

- (void)getBannerWithSize:(GADAdSize)adSize
{
    __weak typeof(self) weakSelf = self;
    [self initializeChartboost:^(BOOL success) {
        if (success) {
            GADMAdapterChartboost *strongSelf = weakSelf;
            UIViewController *viewController = [strongSelf->_interstitialConnector viewControllerForPresentingModalView];
            [[GADMAdapterChartboostBanner sharedInstance] loadBannerWithSize:adSize
                                                                    location:[strongSelf getAdLocation]
                                                                    delegate:strongSelf
                                                              viewController:viewController
                                                                      extras:[strongSelf extras]];
        }
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
  chartboostExtras = [_interstitialConnector networkExtras];
  return chartboostExtras;
}

- (void)didFailToLoadAdWithError:(NSError *)error {
  [_interstitialConnector adapter:self didFailAd:error];
}

#pragma mark - Chartboost Interstitial Ad Delegate Methods

- (void)didDisplayInterstitial:(CBLocation)location {
  [_interstitialConnector adapterWillPresentInterstitial:self];
}

- (void)didCacheInterstitial:(CBLocation)location {
  if (_loading) {
    [_interstitialConnector adapterDidReceiveInterstitial:self];
    _loading = NO;
  }
}

- (void)didFailToLoadInterstitial:(CBLocation)location withError:(CBLoadError)error {
  id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;

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
  id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
  [strongConnector adapterWillDismissInterstitial:self];
  [strongConnector adapterDidDismissInterstitial:self];
}

- (void)didClickInterstitial:(CBLocation)location {
  id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
  [strongConnector adapterDidGetAdClick:self];
  [strongConnector adapterWillLeaveApplication:self];
}

#pragma mark - Chartboost Banner Delegate Methods

- (void)didCacheAd:(CHBCacheEvent *)event error:(nullable CHBCacheError *)error
{
    id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
    if (error) {
        [strongConnector adapter:self didFailAd:NSErrorWithCHBCacheError(error)];
    } else {
        [strongConnector adapter:self didReceiveAdView:(UIView *)event.ad];
    }
}

- (void)willShowAd:(CHBShowEvent *)event error:(nullable CHBShowError *)error
{
    
}

- (void)didShowAd:(CHBShowEvent *)event error:(nullable CHBShowError *)error
{

}

- (void)didClickAd:(CHBClickEvent *)event error:(nullable CHBClickError *)error
{
    id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
    if (error == nil) {
        [strongConnector adapterDidGetAdClick:self];
        [strongConnector adapterWillPresentFullScreenModal:self];
    }
}

- (void)didFinishHandlingClick:(CHBClickEvent *)event error:(nullable CHBClickError *)error
{
    id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
    [strongConnector adapterWillDismissFullScreenModal:self];
    [strongConnector adapterDidDismissFullScreenModal:self];
}

@end
