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
#import "GADFBError.h"
#import "GADMAdapterFacebookConstants.h"
#import "GADMediationAdapterFacebook.h"
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <AdSupport/AdSupport.h>

@interface GADFBBannerRenderer () <GADMediationBannerAd, FBAdViewDelegate> {
  // The completion handler to call when the ad loading succeeds or fails.
  GADMediationBannerLoadCompletionHandler _adLoadCompletionHandler;

  // Ad Configuration for the ad to be rendered.
  GADMediationAdConfiguration *_adConfig;

  // The Facebook banner ad.
  FBAdView *_adView;

  // An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationBannerAdEventDelegate> _adEventDelegate;

  // FAN banner views can have flexible width. Set this property to the desired banner view's size.
  // Set to CGSizeZero if resizing is not desired.
  CGSize _finalBannerSize;

  BOOL _isRTBRequest;
}

@end

@implementation GADFBBannerRenderer

- (void)renderBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  _adConfig = adConfiguration;
  _adLoadCompletionHandler = completionHandler;
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
    completionHandler(nil, error);
    return;
  }

  // -[FBAdView initWithPlacementID:adSize:rootViewController:] throws an NSInvalidArgumentException
  // if the root view controller is nil.
  UIViewController *rootViewController = adConfiguration.topViewController;
  if (!rootViewController) {
    NSError *error = GADFBErrorWithDescription(@"Root view controller cannot be nil.");
    completionHandler(nil, error);
    return;
  }

  NSError *__autoreleasing error = nil;
  // Create the Facebook banner view.
  _adView = [[FBAdView alloc] initWithPlacementID:placementID
                                       bidPayload:adConfiguration.bidResponse
                               rootViewController:adConfiguration.topViewController
                                            error:&error];
  _adView.delegate = self;

  if (error) {
    completionHandler(nil, error);
  } else {
    // Load ad.
    [_adView loadAdWithBidPayload:adConfiguration.bidResponse];
  }
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
