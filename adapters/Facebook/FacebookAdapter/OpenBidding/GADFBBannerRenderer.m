// Copyright 2019 Google LLC.
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

#import "GADFBBannerRenderer.h"
#import <AdSupport/AdSupport.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#include <stdatomic.h>
#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"
#import "GADMediationAdapterFacebook.h"

@interface GADFBBannerRenderer () <GADMediationBannerAd, FBAdViewDelegate>

@end

@implementation GADFBBannerRenderer {
  // The completion handler to call when the ad loading succeeds or fails.
  GADMediationBannerLoadCompletionHandler _adLoadCompletionHandler;

  // Ad Configuration for the ad to be rendered.
  GADMediationAdConfiguration *_adConfig;

  // The Facebook banner ad.
  FBAdView *_adView;

  // An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationBannerAdEventDelegate> _adEventDelegate;

  // Facebook Audience Network banner views can have flexible width. Set this property to the
  // desired banner view's size. Set to CGSizeZero if resizing is not desired.
  CGSize _finalBannerSize;

  BOOL _isRTBRequest;
}

- (void)renderBannerForAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
                     completionHandler:
                         (nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
  _adConfig = adConfiguration;
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationBannerLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _adLoadCompletionHandler = ^id<GADMediationBannerAdEventDelegate>(
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

  _finalBannerSize = adConfiguration.adSize.size;
  if (adConfiguration.bidResponse) {
    _isRTBRequest = YES;
  }

  // -[FBAdView initWithPlacementID:adSize:rootViewController:] throws an NSInvalidArgumentException
  // if the placement ID is nil.
  NSString *placementID =
      adConfiguration.credentials.settings[kGADMAdapterFacebookOpenBiddingPubID];
  if (!placementID) {
    NSError *error = GADFBErrorWithDescription(@"Placement ID cannot be nil.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  // -[FBAdView initWithPlacementID:adSize:rootViewController:] throws an NSInvalidArgumentException
  // if the root view controller is nil.
  UIViewController *rootViewController = adConfiguration.topViewController;
  if (!rootViewController) {
    NSError *error = GADFBErrorWithDescription(@"Root view controller cannot be nil.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  // Create the Facebook banner view.
  NSError *error = nil;
  _adView = [[FBAdView alloc] initWithPlacementID:placementID
                                       bidPayload:adConfiguration.bidResponse
                               rootViewController:adConfiguration.topViewController
                                            error:&error];

  if (error) {
    _adLoadCompletionHandler(nil, error);
    return;
  }

  // Adds a watermark to the ad.
  FBAdExtraHint *watermarkHint = [[FBAdExtraHint alloc] init];
  watermarkHint.mediationData = [adConfiguration.watermark base64EncodedStringWithOptions:0];
  _adView.extraHint = watermarkHint;

  // Load ad.
  _adView.delegate = self;
  [_adView loadAdWithBidPayload:adConfiguration.bidResponse];
}

#pragma mark FBAdViewDelegate

- (void)adViewDidLoad:(FBAdView *)adView {
  if (!CGSizeEqualToSize(_finalBannerSize, CGSizeZero)) {
    CGRect frame = adView.frame;
    frame.size = _finalBannerSize;
    adView.frame = frame;
    _finalBannerSize = CGSizeZero;
  }
  _adEventDelegate = _adLoadCompletionHandler(self, nil);
}

- (void)adView:(FBAdView *)adView didFailWithError:(NSError *)error {
  _adLoadCompletionHandler(nil, error);
}

- (void)adViewDidClick:(FBAdView *)adView {
  id<GADMediationBannerAdEventDelegate> strongDelegate = _adEventDelegate;
  if (strongDelegate) {
    if (!_isRTBRequest) {
      [strongDelegate reportClick];
    }
    [strongDelegate willBackgroundApplication];
  }
}

- (void)adViewDidFinishHandlingClick:(FBAdView *)adView {
  // Do nothing
}

- (UIViewController *)viewControllerForPresentingModalView {
  return _adConfig.topViewController;
}

#pragma mark GADMediationBannerAd

// Rendered banner ad. Called after the adapter has successfully loaded and ad invoked
// the GADBannerRenderCompletionHandler.
- (UIView *)view {
  return _adView;
}

@end
