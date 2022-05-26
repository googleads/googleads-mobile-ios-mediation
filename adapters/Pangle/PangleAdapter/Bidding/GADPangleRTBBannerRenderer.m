// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADPangleRTBBannerRenderer.h"
#import <BUAdSDK/BUAdSDK.h>
#include <stdatomic.h>
#import "GADMAdapterPangleUtils.h"
#import "GADMediationAdapterPangleConstants.h"

static CGSize const pangleBannerAdSize320x50 = (CGSize){320, 50};
static CGSize const pangleBannerAdSize300x250 = (CGSize){300, 250};
static CGSize const pangleBannerAdSize728x90 = (CGSize){728, 90};

@interface GADPangleRTBBannerRenderer () <BUNativeExpressBannerViewDelegate>

@end

@implementation GADPangleRTBBannerRenderer {
  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationBannerLoadCompletionHandler _loadCompletionHandler;
  /// The Pangle banner ad.
  BUNativeExpressBannerView *_nativeExpressBannerView;
  /// An ad event delegate to invoke when ad rendering events occur.
  id<GADMediationBannerAdEventDelegate> _delegate;
  /// The requested ad size.
  CGSize _bannerSize;
}

- (void)renderBannerForAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
                     completionHandler:
                         (nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationBannerLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _loadCompletionHandler = ^id<GADMediationBannerAdEventDelegate>(
      _Nullable id<GADMediationBannerAd> ad, NSError *_Nullable error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }
    id<GADMediationBannerAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(ad, error);
    }
    originalCompletionHandler = nil;
    return delegate;
  };

  NSString *placementId = adConfiguration.credentials.settings[GADMAdapterPanglePlacementID] ?: @"";
  if (!placementId.length) {
    NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(
        GADPangleErrorInvalidServerParameters,
        [NSString stringWithFormat:@"%@ cannot be nil.", GADMAdapterPanglePlacementID]);
    _loadCompletionHandler(nil, error);
    return;
  }

  NSError *error = nil;
  _bannerSize = [self bannerSizeFormGADAdSize:adConfiguration.adSize error:&error];
  if (error) {
    _loadCompletionHandler(nil, error);
    return;
  }

  _nativeExpressBannerView =
      [[BUNativeExpressBannerView alloc] initWithSlotID:placementId
                                     rootViewController:adConfiguration.topViewController
                                                 adSize:_bannerSize];
  _nativeExpressBannerView.delegate = self;
  [_nativeExpressBannerView setAdMarkup:adConfiguration.bidResponse];
}

- (CGSize)bannerSizeFormGADAdSize:(GADAdSize)gadAdSize error:(NSError **)error {
  CGSize gadAdCGSize = CGSizeFromGADAdSize(gadAdSize);
  GADAdSize banner50 = GADAdSizeFromCGSize(
      CGSizeMake(gadAdCGSize.width, pangleBannerAdSize320x50.height));  // 320*50
  GADAdSize banner90 = GADAdSizeFromCGSize(
      CGSizeMake(gadAdCGSize.width, pangleBannerAdSize728x90.height));  // 728*90
  GADAdSize banner250 = GADAdSizeFromCGSize(
      CGSizeMake(gadAdCGSize.width, pangleBannerAdSize300x250.height));  // 300*250
  NSArray *potentials = @[
    NSValueFromGADAdSize(banner50), NSValueFromGADAdSize(banner90), NSValueFromGADAdSize(banner250)
  ];
  GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentials);
  CGSize size = CGSizeFromGADAdSize(closestSize);
  if (size.height == pangleBannerAdSize320x50.height) {
    return pangleBannerAdSize320x50;
  } else if (size.height == pangleBannerAdSize728x90.height) {
    return pangleBannerAdSize728x90;
  } else if (size.height == pangleBannerAdSize300x250.height) {
    return pangleBannerAdSize300x250;
  }

  if (error) {
    *error = GADMAdapterPangleErrorWithCodeAndDescription(
        GADPangleErrorBannerSizeMismatch,
        [NSString stringWithFormat:@"Invalid size for Pangle mediation adapter. Size: %@",
                                   NSStringFromGADAdSize(gadAdSize)]);
  }
  return CGSizeZero;
}

#pragma mark - GADMediationBannerAd
- (nonnull UIView *)view {
  return _nativeExpressBannerView;
}

#pragma mark - BUNativeExpressBannerViewDelegate
- (void)nativeExpressBannerAdViewDidLoad:(BUNativeExpressBannerView *)bannerAdView {
  if (_loadCompletionHandler) {
    _delegate = _loadCompletionHandler(self, nil);
  }
  CGRect frame = bannerAdView.frame;
  frame.size = _bannerSize;
  bannerAdView.frame = frame;
}

- (void)nativeExpressBannerAdView:(BUNativeExpressBannerView *)bannerAdView
             didLoadFailWithError:(NSError *)error {
  if (_loadCompletionHandler) {
    _loadCompletionHandler(nil, error);
  }
}

- (void)nativeExpressBannerAdViewRenderSuccess:(BUNativeExpressBannerView *)bannerAdView {
  id<GADMediationBannerAdEventDelegate> delegate = _delegate;
  [delegate reportImpression];
}

- (void)nativeExpressBannerAdViewRenderFail:(BUNativeExpressBannerView *)bannerAdView
                                      error:(NSError *)error {
  if (_loadCompletionHandler) {
    _loadCompletionHandler(nil, error);
  }
}

- (void)nativeExpressBannerAdViewDidClick:(BUNativeExpressBannerView *)bannerAdView {
  id<GADMediationBannerAdEventDelegate> delegate = _delegate;
  [delegate reportClick];
}

@end
