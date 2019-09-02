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

#import "GADFBInterstitialRenderer.h"

#import <AdSupport/AdSupport.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

#include <stdatomic.h>
#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"
#import "GADMediationAdapterFacebook.h"

@interface GADFBInterstitialRenderer () <GADMediationInterstitialAd, FBInterstitialAdDelegate>
@end

@implementation GADFBInterstitialRenderer {
  // The completion handler to call when the ad loading succeeds or fails.
  GADMediationInterstitialLoadCompletionHandler _adLoadCompletionHandler;

  // The Facebook interstitial ad.
  FBInterstitialAd *_interstitialAd;

  // An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationInterstitialAdEventDelegate> _adEventDelegate;

  BOOL _isRTBRequest;
}

- (void)renderInterstitialForAdConfiguration:
            (nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                           completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)
                                                 completionHandler {
  // Store the completion handler for later use.
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationInterstitialLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
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

  if (adConfiguration.bidResponse) {
    _isRTBRequest = YES;
  }

  // -[FBInterstitialAd initWithPlacementID:adSize:rootViewController:] throws an
  // NSInvalidArgumentException if the placement ID is nil.
  NSString *placementID =
      adConfiguration.credentials.settings[kGADMAdapterFacebookOpenBiddingPubID];
  if (!placementID) {
    NSError *error = GADFBErrorWithDescription(@"Placement ID cannot be nil.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  // Create the interstitial.
  _interstitialAd = [[FBInterstitialAd alloc] initWithPlacementID:placementID];
  _interstitialAd.delegate = self;

  // Adds a watermark to the ad.
  FBAdExtraHint *watermarkHint = [[FBAdExtraHint alloc] init];
  watermarkHint.mediationData = [adConfiguration.watermark base64EncodedStringWithOptions:0];
  _interstitialAd.extraHint = watermarkHint;

  // Load ad.
  [_interstitialAd loadAdWithBidPayload:adConfiguration.bidResponse];
}

#pragma mark FBInterstitialAdDelegate

- (void)interstitialAdDidLoad:(FBInterstitialAd *)interstitialAd {
  _adEventDelegate = _adLoadCompletionHandler(self, nil);
}

- (void)interstitialAd:(FBInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
  _adLoadCompletionHandler(nil, error);
}

- (void)interstitialAdWillLogImpression:(FBInterstitialAd *)interstitialAd {
  if (!_isRTBRequest) {
    [_adEventDelegate reportImpression];
  }
}

- (void)interstitialAdDidClick:(FBInterstitialAd *)interstitialAd {
  id<GADMediationInterstitialAdEventDelegate> strongDelegate = _adEventDelegate;
  if (strongDelegate) {
    if (!_isRTBRequest) {
      [strongDelegate reportClick];
    }
    [strongDelegate willBackgroundApplication];
  }
}

- (void)interstitialAdWillClose:(FBInterstitialAd *)interstitialAd {
  id<GADMediationInterstitialAdEventDelegate> strongDelegate = _adEventDelegate;
  if (strongDelegate) {
    [strongDelegate willDismissFullScreenView];
  }
}

- (void)interstitialAdDidClose:(FBInterstitialAd *)interstitialAd {
  id<GADMediationInterstitialAdEventDelegate> strongDelegate = _adEventDelegate;
  if (strongDelegate) {
    [strongDelegate didDismissFullScreenView];
  }
}

#pragma mark GADMediationInterstitialAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  // The Facebook Audience Network SDK doesn't have a callback for an interstitial presenting a full
  // screen view. Invoke this callback on the Google Mobile Ads SDK within this method instead.
  id<GADMediationInterstitialAdEventDelegate> strongDelegate = _adEventDelegate;
  if (strongDelegate) {
    [strongDelegate willPresentFullScreenView];
  }
  [_interstitialAd showAdFromRootViewController:viewController];
}

@end
