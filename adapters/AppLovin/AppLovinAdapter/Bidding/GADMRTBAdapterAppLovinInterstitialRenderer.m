// Copyright 2018 Google LLC
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

#import "GADMRTBAdapterAppLovinInterstitialRenderer.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinExtras.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMAppLovinRTBInterstitialDelegate.h"
#import "GADMediationAdapterAppLovin.h"

#import <AppLovinSDK/AppLovinSDK.h>
#include <GoogleMobileAds/GoogleMobileAds.h>
#include <stdatomic.h>

@implementation GADMRTBAdapterAppLovinInterstitialRenderer {
  /// Data used to render an interstitial ad.
  GADMediationInterstitialAdConfiguration *_adConfiguration;

  /// AppLovin interstitial object used to load an ad.
  ALInterstitialAd *_interstitialAd;
}

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)handler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    // Store the completion handler for later use.
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationInterstitialLoadCompletionHandler originalCompletionHandler =
        [handler copy];
    _adLoadCompletionHandler = ^id<GADMediationInterstitialAdEventDelegate>(
        _Nullable id<GADMediationInterstitialAd> ad, NSError *_Nullable error) {
      if (atomic_flag_test_and_set(&completionHandlerCalled)) {
        return nil;
      }
      id<GADMediationInterstitialAdEventDelegate> delegate = nil;
      if (originalCompletionHandler) {
        delegate = originalCompletionHandler(ad, error);
      }
      originalCompletionHandler = nil;
      return delegate;
    };
  }
  return self;
}

- (void)loadAd {
  if (!ALSdk.shared) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorAppLovinSDKNotInitialized,
        @"Failed to retrieve ALSdk shared instance. ");
    _adLoadCompletionHandler(nil, error);
    return;
  }
  ALSdk.shared.settings.muted = GADMobileAds.sharedInstance.applicationMuted;

  // Create interstitial object.
  _interstitialAd = [[ALInterstitialAd alloc] initWithSdk:ALSdk.shared];
  [_interstitialAd setExtraInfoForKey:@"google_watermark" value:_adConfiguration.watermark];

  GADMAppLovinRTBInterstitialDelegate *delegate =
      [[GADMAppLovinRTBInterstitialDelegate alloc] initWithParentRenderer:self];
  _interstitialAd.adDisplayDelegate = delegate;
  _interstitialAd.adVideoPlaybackDelegate = delegate;

  // Load ad.
  [ALSdk.shared.adService loadNextAdForAdToken:_adConfiguration.bidResponse andNotify:delegate];
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(UIViewController *)viewController {
  [_interstitialAd showAd:_ad];
}

- (void)dealloc {
  _interstitialAd.adDisplayDelegate = nil;
  _interstitialAd.adVideoPlaybackDelegate = nil;
}

@end
