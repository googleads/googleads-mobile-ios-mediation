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
#import "GADChartboostSingleton.h"
#import "GADMChartboostExtras.h"
#import "GADMediationAdapterChartboost.h"
#import "GADCHBInterstitial.h"
#import "GADCHBBanner.h"
#if __has_include(<Chartboost/Chartboost+Mediation.h>)
#import <Chartboost/Chartboost+Mediation.h>
#else
#import "Chartboost+Mediation.h"
#endif

// TODO: Is only one GADMAdNetworkAdapter subclass ever instantiated for a mediated SDK and it receives all the ad requests? Or can it be deallocated and instantiated again, having only one instance alive at the time that receives all the ad requests? Or is it instantiated multiple times, once for each ad request?
// TODO: Do the GADMAdNetworkConnector credentials change before an ad request to inform of the ad unit for that ad request (ad location in Chartboost terminology)? If so when exactly does this credentials information change?
@implementation GADMAdapterChartboost {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;
  /// Chartboost interstitial ad wrapper.
  GADCHBInterstitial *_interstitial;
  /// Chartboost banner ad wrapper.
  GADCHBBanner *_banner;
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
  [_interstitial destroy];
  _interstitial = nil;
  [_banner destroy];
  _banner = nil;
}

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

// MARK: - Interstitial

// TODO: Can getInterstitial and getBannerWithSize: be called multiple times before the last ad is dismissed? In that case we'll want to keep references to mutliple ads of the same type. Should we deallocate them once dismissed?
// TODO: Can they be called with the same connector credentials (same ad unit id)?
// TODO: Does Google's SDK expect one call to adapterDidReceiveInterstitial: and adapter:didReceiveAdView: for every ad request if multiple requests where made while in the process of loading the ad?
// TODO: What if those requests loaded an ad with the same ad unit id? How does the connector know which of the ads is done loading?
- (void)getInterstitial {
  GADMAdapterChartboost * __weak weakSelf = self;
  [self initializeChartboost:^(NSError * _Nullable error) {
    GADMAdapterChartboost *strongSelf = weakSelf;
    id<GADMAdNetworkConnector> strongConnector = strongSelf->_connector;
    if (!strongSelf || !strongConnector) {
      return;
    }
    if (error) {
      [strongConnector adapter:strongSelf didFailAd:error];
      return;
    }
    GADChartboostSingleton *chartboost = [GADChartboostSingleton sharedInstance];
    [chartboost setFrameworkWithExtras:[strongConnector networkExtras]];
    
    // TODO: Want to destroy the current interstitial ad? Depends on the previous questions.
    [strongSelf->_interstitial destroy];
    strongSelf->_interstitial =
    [[GADCHBInterstitial alloc] initWithLocation:[strongSelf locationFromConnector]
                                       mediation:[chartboost mediation]
                                  networkAdapter:strongSelf
                                       connector:strongConnector];
    [strongSelf->_interstitial load];
  }];
}

// TODO: If getInterstitial can be called multiple times before the last ad is dismissed, how do we know which interstitial ad we want to show here?
- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  if (_interstitial) {
    [_interstitial showFromViewController:rootViewController];
  } else {
    NSLog(@"GADMAdapterChartboost error: trying to present interstitial before it is loaded.");
  }
}

// MARK: - Banner

- (void)getBannerWithSize:(GADAdSize)adSize {
  GADMAdapterChartboost *__weak weakSelf = self;
  [self initializeChartboost:^(NSError *_Nullable error) {
    GADMAdapterChartboost *strongSelf = weakSelf;
    id<GADMAdNetworkConnector> strongConnector = strongSelf->_connector;
    if (!strongSelf || !strongConnector) {
      return;
    }
    if (error) {
      [strongConnector adapter:strongSelf didFailAd:error];
      return;
    }
    GADChartboostSingleton *chartboost = [GADChartboostSingleton sharedInstance];
    [chartboost setFrameworkWithExtras:[strongConnector networkExtras]];
    
    // CHBBanner is a UIView subclass so it needs to be used on the main thread.
    dispatch_async(dispatch_get_main_queue(), ^{
      // TODO: Want to destroy the current banner ad? Depends on the previous questions.
      [strongSelf->_banner destroy];
      strongSelf->_banner =
      [[GADCHBBanner alloc] initWithSize:adSize.size
                                location:[strongSelf locationFromConnector]
                               mediation:[chartboost mediation]
                          networkAdapter:strongSelf
                               connector:strongConnector];
      UIViewController *viewController = [strongConnector viewControllerForPresentingModalView];
      [strongSelf->_banner showFromViewController:viewController];
    });
  }];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

// MARK: - Helpers

- (void)initializeChartboost:(ChartboostInitCompletionHandler)completion {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  GADChartboostSingleton *chartboost = [GADChartboostSingleton sharedInstance];
  [chartboost startWithAppId:strongConnector.credentials[kGADMAdapterChartboostAppID]
                appSignature:strongConnector.credentials[kGADMAdapterChartboostAppSignature]
           completionHandler:completion];
}

- (NSString *)locationFromConnector {
  NSString *location = _connector.credentials[kGADMAdapterChartboostAdLocation];
  if ([location isKindOfClass:NSString.class]) {
    location = [location stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  }
  location = location.length > 0 ? location : CBLocationDefault;
  return location;
}

@end
