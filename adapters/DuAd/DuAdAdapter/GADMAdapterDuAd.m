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

#import "GADMAdapterDuAd.h"

@import DUModuleSDK;

#import "GADDuAdAdapterDelegate.h"
#import "GADDuAdInitializer.h"
#import "GADDuAdInterstitialAd.h"
#import "GADDuAdNetworkExtras.h"
#import "GADMAdapterDuAdConstants.h"

@interface GADMAdapterDuAd () {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// DuAd Audience Network interstitial ad wrapper.
  GADDuAdInterstitialAd *_interstitialAd;
}
@end

@implementation GADMAdapterDuAd

+ (NSString *)adapterVersion {
  return kGADMAdapterDuAdVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADDuAdNetworkExtras class];
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [self init];
  if (self) {
    _interstitialAd = [[GADDuAdInterstitialAd alloc] initWithGADMAdNetworkConnector:connector
                                                                            adapter:self];
    _connector = connector;
  }
  return self;
}

- (void)getInterstitial {
  [[GADDuAdInitializer sharedInstance] initializeWithConnector:_connector];
  [_interstitialAd getInterstitial];
}

- (void)stopBeingDelegate {
  [_interstitialAd stopBeingDelegate];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  [_interstitialAd presentInterstitialFromRootViewController:rootViewController];
}

- (BOOL)handlesUserClicks {
  return YES;
}

- (BOOL)handlesUserImpressions {
  return YES;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  return;
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}
@end
