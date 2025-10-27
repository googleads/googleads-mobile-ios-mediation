// Copyright 2025 Google LLC.
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

#import "GADFBAppOpenRenderer.h"

#import <AdSupport/AdSupport.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

#include <stdatomic.h>
#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"
#import "GADMediationAdapterFacebook.h"

@interface GADFBAppOpenRenderer () <GADMediationAppOpenAd, FBInterstitialAdDelegate>
@end

@implementation GADFBAppOpenRenderer {
  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationAppOpenLoadCompletionHandler _adLoadCompletionHandler;

  /// The Meta Audience Network interstitial ad.
  FBInterstitialAd *_interstitialAd;

  /// An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationAppOpenAdEventDelegate> _adEventDelegate;

  /// Indicates whether presentFromViewController: was called on this renderer.
  BOOL _presentCalled;
}

- (void)renderAppOpenForAdConfiguration:
  (nonnull GADMediationAppOpenAdConfiguration *)adConfiguration
                           completionHandler:(nonnull GADMediationAppOpenLoadCompletionHandler)completionHandler {
  // Store the completion handler for later use.
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationAppOpenLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _adLoadCompletionHandler = ^id<GADMediationAppOpenAdEventDelegate>(
      _Nullable id<GADMediationAppOpenAd> ad, NSError *_Nullable error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }
    id<GADMediationAppOpenAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(ad, error);
    }
    originalCompletionHandler = nil;
    return delegate;
  };

  // -[FBInterstitialAd initWithPlacementID:adSize:rootViewController:] throws an
  // NSInvalidArgumentException if the placement ID is nil.
  NSString *placementID = adConfiguration.credentials.settings[GADMAdapterFacebookBiddingPubID];
  if (!placementID) {
    NSError *error =
        GADFBErrorWithCodeAndDescription(GADFBErrorInvalidRequest, @"Placement ID cannot be nil.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  // The app open ad uses the interstitial. Create the interstitial.
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
  if (_presentCalled) {
    NSLog(@"Received a Meta Audience Network SDK error during presentation: %@",
          error.localizedDescription);
    [_adEventDelegate didFailToPresentWithError:error];
    return;
  }
  _adLoadCompletionHandler(nil, error);
}

- (void)interstitialAdWillLogImpression:(FBInterstitialAd *)interstitialAd {
  [_adEventDelegate reportImpression];
}

- (void)interstitialAdDidClick:(FBInterstitialAd *)interstitialAd {
  [_adEventDelegate reportClick];
}

- (void)interstitialAdWillClose:(FBInterstitialAd *)interstitialAd {
  id<GADMediationAppOpenAdEventDelegate> strongDelegate = _adEventDelegate;
  if (strongDelegate) {
    [strongDelegate willDismissFullScreenView];
  }
}

- (void)interstitialAdDidClose:(FBInterstitialAd *)interstitialAd {
  id<GADMediationAppOpenAdEventDelegate> strongDelegate = _adEventDelegate;
  if (strongDelegate) {
    [strongDelegate didDismissFullScreenView];
  }
}

#pragma mark GADMediationAppOpenAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  // The Meta Audience Network SDK doesn't have a callback for an interstitial presenting a full
  // screen view. Invoke this callback on the Google Mobile Ads SDK within this method instead.
  id<GADMediationAppOpenAdEventDelegate> strongDelegate = _adEventDelegate;
  _presentCalled = YES;

  if (![_interstitialAd showAdFromRootViewController:viewController]) {
    NSString *description = [NSString
        stringWithFormat:@"%@ failed to present.", NSStringFromClass([FBInterstitialAd class])];
    NSError *error = GADFBErrorWithCodeAndDescription(GADFBErrorAdNotValid, description);
    [strongDelegate didFailToPresentWithError:error];
    return;
  }

  [strongDelegate willPresentFullScreenView];
}

@end
