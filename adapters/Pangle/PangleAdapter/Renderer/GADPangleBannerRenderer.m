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

#import "GADPangleBannerRenderer.h"
#import <PAGAdSDK/PAGAdSDK.h>
#include <stdatomic.h>
#import "GADMAdapterPangleUtils.h"
#import "GADMediationAdapterPangleConstants.h"
#import "GADPangleNetworkExtras.h"

@interface GADPangleBannerRenderer () <PAGBannerAdDelegate>

@end

@implementation GADPangleBannerRenderer {
  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationBannerLoadCompletionHandler _loadCompletionHandler;
  /// The Pangle banner ad.
  PAGBannerAd *_bannerAd;
  /// An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationBannerAdEventDelegate> _delegate;
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

  NSString *placementId = adConfiguration.credentials.settings[GADMAdapterPanglePlacementID];
  if (!placementId.length) {
    NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(
        GADPangleErrorInvalidServerParameters,
        [NSString stringWithFormat:@"%@ cannot be nil.", GADMAdapterPanglePlacementID]);
    _loadCompletionHandler(nil, error);
    return;
  }

  PAGBannerAdSize bannerSize = [self bannerSizeFormGADAdSize:adConfiguration.adSize];

  PAGBannerRequest *request = [PAGBannerRequest requestWithBannerSize:bannerSize];
  request.adString = adConfiguration.bidResponse;
  if (adConfiguration.watermark) {
    request.extraInfo = @{@"admob_watermark":adConfiguration.watermark?:@""};
  }
  GADPangleBannerRenderer *__weak weakSelf = self;
  [PAGBannerAd loadAdWithSlotID:placementId
                        request:request
              completionHandler:^(PAGBannerAd *_Nullable bannerAd, NSError *_Nullable loadError) {
                GADPangleBannerRenderer *strongSelf = weakSelf;
                if (!strongSelf) {
                  return;
                }

                if (loadError) {
                  strongSelf->_loadCompletionHandler(nil, loadError);
                  return;
                }

                CGRect frame = bannerAd.bannerView.frame;
                frame.size = bannerAd.adSize.size;
                bannerAd.bannerView.frame = frame;
                bannerAd.rootViewController = adConfiguration.topViewController;

                strongSelf->_bannerAd = bannerAd;
                strongSelf->_bannerAd.delegate = strongSelf;

                if (strongSelf->_loadCompletionHandler) {
                  strongSelf->_delegate = strongSelf->_loadCompletionHandler(strongSelf, nil);
                }
              }];
}

- (PAGBannerAdSize)bannerSizeFormGADAdSize:(GADAdSize)gadAdSize {
  CGSize gadAdCGSize = CGSizeFromGADAdSize(gadAdSize);
  
  PAGBannerAdSize pagBanner50 = kPAGBannerSize320x50;
  PAGBannerAdSize pagBanner90 = kPAGBannerSize728x90;
  PAGBannerAdSize pagBanner250 = kPAGBannerSize300x250;
  PAGBannerAdSize pagAnchored = PAGCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(gadAdCGSize.width);
    
  GADAdSize banner50 = GADAdSizeFromCGSize(
      CGSizeMake(pagBanner50.size.width, pagBanner50.size.height));  // 320*50
  GADAdSize banner90 = GADAdSizeFromCGSize(
      CGSizeMake(pagBanner90.size.width, pagBanner90.size.height));  // 728*90
  GADAdSize banner250 = GADAdSizeFromCGSize(
      CGSizeMake(pagBanner250.size.width, pagBanner250.size.height));  // 300*250
  GADAdSize bannerAnchored = GADAdSizeFromCGSize(pagAnchored.size);
  NSArray *potentials = @[
    NSValueFromGADAdSize(banner50),
    NSValueFromGADAdSize(banner90),
    NSValueFromGADAdSize(banner250),
    NSValueFromGADAdSize(bannerAnchored)
  ];

  GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentials);
  CGSize size = CGSizeFromGADAdSize(closestSize);
  if (size.width == pagBanner50.size.width && size.height == pagBanner50.size.height) {
    return pagBanner50;
  } else if (size.width == pagBanner90.size.width && size.height == pagBanner90.size.height) {
    return pagBanner90;
  } else if (size.width == pagBanner250.size.width && size.height == pagBanner250.size.height) {
    return pagBanner250;
  } else if (size.width == pagAnchored.size.width && size.height == pagAnchored.size.height) {
    return pagAnchored;
  }
    
  if (gadAdSize.size.height > 0) {
        return PAGInlineAdaptiveBannerAdSizeWithWidthAndMaxHeight(gadAdCGSize.width,gadAdCGSize.height);
  }
    return PAGCurrentOrientationInlineAdaptiveBannerAdSizeWithWidth(gadAdCGSize.width);
}

#pragma mark - GADMediationBannerAd

- (nonnull UIView *)view {
  return _bannerAd.bannerView;
}

#pragma mark - PAGBannerAdDelegate

- (void)adDidShow:(PAGBannerAd *)ad {
  id<GADMediationBannerAdEventDelegate> delegate = _delegate;
  [delegate reportImpression];
}

- (void)adDidClick:(PAGBannerAd *)ad {
  id<GADMediationBannerAdEventDelegate> delegate = _delegate;
  [delegate reportClick];
}

@end
