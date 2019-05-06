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

@import FBAudienceNetwork;
@import AdSupport;

#import "GADFBError.h"
#import "GADMAdapterFacebookConstants.h"
#import "GADMediationAdapterFacebook.h"

@interface GADFBInterstitialRenderer () <GADMediationInterstitialAd, FBInterstitialAdDelegate> {
  // The completion handler to call when the ad loading succeeds or fails.
  GADMediationInterstitialLoadCompletionHandler _adLoadCompletionHandler;

  // The Facebook interstitial ad.
  FBInterstitialAd *_interstitialAd;

  // An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationInterstitialAdEventDelegate> _adEventDelegate;

  BOOL _isRTBRequest;
}

@end

@implementation GADFBInterstitialRenderer

- (void)renderInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                           completionHandler:
                               (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  // Store the completion handler for later use.
  _adLoadCompletionHandler = completionHandler;
  if (adConfiguration.bidResponse) {
    _isRTBRequest = YES;
  }

  // -[FBInterstitialAd initWithPlacementID:adSize:rootViewController:] throws an
  // NSInvalidArgumentException if the placement ID is nil.
  NSString *placementID =
      adConfiguration.credentials.settings[kGADMAdapterFacebookOpenBiddingPubID];
  if (!placementID) {
    NSError *error = GADFBErrorWithDescription(@"Placement ID cannot be nil.");
    completionHandler(nil, error);
    return;
  }

  // Create the interstitial.
  _interstitialAd = [[FBInterstitialAd alloc] initWithPlacementID:placementID];
  _interstitialAd.delegate = self;

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
  // The FAN SDK doesn't have a callback for an interstitial presenting a full screen view. Invoke
  // this callback on the Google Mobile Ads SDK within this method instead.
  id<GADMediationInterstitialAdEventDelegate> strongDelegate = _adEventDelegate;
  if (strongDelegate) {
    [strongDelegate willPresentFullScreenView];
  }
  [_interstitialAd showAdFromRootViewController:viewController];
}

@end
