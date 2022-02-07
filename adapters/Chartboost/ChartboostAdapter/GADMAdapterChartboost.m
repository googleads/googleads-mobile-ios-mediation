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

#import "GADMAdapterChartboostBannerAd.h"
#import "GADMAdapterChartboostConstants.h"
#import "GADMAdapterChartboostInterstitialAd.h"
#import "GADMChartboostError.h"
#import "GADMChartboostExtras.h"
#import "GADMediationAdapterChartboost.h"

@implementation GADMAdapterChartboost {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Chartboost banner ad wrapper.
  GADMAdapterChartboostBannerAd *_bannerAd;

  /// Chartboost interstitial ad wrapper.
  GADMAdapterChartboostInterstitialAd *_interstitialAd;
}

- (nonnull instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    _connector = connector;
  }
  return self;
}

+ (nonnull NSString *)adapterVersion {
  return GADMAdapterChartboostVersion;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMChartboostExtras class];
}

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterChartboost class];
}

- (void)stopBeingDelegate {
}

#pragma mark Interstitial

- (void)getInterstitial {
  _interstitialAd =
      [[GADMAdapterChartboostInterstitialAd alloc] initWithGADMAdNetworkConnector:_connector
                                                                          adapter:self];
  [_interstitialAd loadInterstitialAd];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  [_interstitialAd presentInterstitialFromRootViewController:rootViewController];
}

#pragma mark Banner

- (void)getBannerWithSize:(GADAdSize)adSize {
  _bannerAd = [[GADMAdapterChartboostBannerAd alloc] initWithGADMAdNetworkConnector:_connector
                                                                            adapter:self];
  [_bannerAd getBannerWithSize:adSize];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

@end
