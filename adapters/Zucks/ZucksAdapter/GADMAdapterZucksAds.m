// Copyright 2021 Google LLC
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

#import "GADMAdapterZucksAds.h"

#import "GADMediationAdapterZucksBannerAd.h"
#import "GADMediationAdapterZucksConstants.h"
#import "GADMediationAdapterZucksInterstitialAd.h"

@implementation GADMAdapterZucksAds {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Zucks banner ad wrapper.
  GADMediationAdapterZucksBannerAd *_bannerAd;

  /// Zucks interstitial ad wrapper.
  GADMediationAdapterZucksInterstitialAd *_interstitialAd;
}

- (nonnull instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [self init];
  if (self) {
    _connector = connector;
  }
  return self;
}

+ (nonnull NSString *)adapterVersion {
  return kGADMAdapterZucksVersion;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  // TODO: Return the class for passng in mediation extras (if any). Else, return `Nil`.
  return Nil;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  _bannerAd =
      [[GADMediationAdapterZucksBannerAd alloc] initWithGADMAdNetworkConnector:strongConnector
                                                                       adapter:self];
  [_bannerAd getBannerWithSize:adSize];
}

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  _interstitialAd =
      [[GADMediationAdapterZucksInterstitialAd alloc] initWithGADMAdNetworkConnector:strongConnector
                                                                             adapter:self];
  [_interstitialAd getInterstitial];
}

- (void)presentInterstitialFromRootViewController:(nonnull UIViewController *)rootViewController {
  [_interstitialAd presentInterstitialFromRootViewController:rootViewController];
}

- (void)stopBeingDelegate {
  if (_bannerAd) {
    [_bannerAd stopBeingDelegate];
  }

  if (_interstitialAd) {
    [_interstitialAd stopBeingDelegate];
  }
}

@end
