// Copyright 2015 Google LLC
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
//

#import "GADMAdapterInMobiInterstitialAd.h"
#include <stdatomic.h>
#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiInitializer.h"
#import "GADMAdapterInMobiUtils.h"
#import "GADMInMobiConsent.h"
#import "GADMediationAdapterInMobi.h"

@implementation GADMAdapterInMobiInterstitialAd {
  /// An ad event delegate to invoke when ad rendering events occur.
  id<GADMediationInterstitialAdEventDelegate> _interstitalAdEventDelegate;

  /// Ad Configuration for the interstitial ad to be rendered.
  GADMediationInterstitialAdConfiguration *_interstitialAdConfig;

  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationInterstitialLoadCompletionHandler _interstitialRenderCompletionHandler;

  /// InMobi interstitial ad.
  IMInterstitial *_interstitialAd;
}

- (void)loadInterstitialAdForAdConfiguration:
            (nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                           completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)
                                                 completionHandler {
  _interstitialAdConfig = adConfiguration;
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationInterstitialLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _interstitialRenderCompletionHandler = ^id<GADMediationInterstitialAdEventDelegate>(
      id<GADMediationInterstitialAd> interstitialAd, NSError *error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }
    id<GADMediationInterstitialAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(interstitialAd, error);
    }
    originalCompletionHandler = nil;
    return delegate;
  };

  GADMAdapterInMobiInterstitialAd *__weak weakSelf = self;
  NSString *accountID = _interstitialAdConfig.credentials.settings[GADMAdapterInMobiAccountID];
  [GADMAdapterInMobiInitializer.sharedInstance
      initializeWithAccountID:accountID
            completionHandler:^(NSError *_Nullable error) {
              GADMAdapterInMobiInterstitialAd *strongSelf = weakSelf;
              if (!strongSelf) {
                return;
              }

              if (error) {
                GADMAdapterInMobiLog(@"Initialization failed: %@", error.localizedDescription);
                strongSelf->_interstitialRenderCompletionHandler(nil, error);
                return;
              }

              [strongSelf requestInterstitialAd];
            }];
}

- (void)requestInterstitialAd {
  long long placementId =
      [_interstitialAdConfig.credentials.settings[GADMAdapterInMobiPlacementID] longLongValue];
  if (placementId == 0) {
    NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
        GADMAdapterInMobiErrorInvalidServerParameters,
        @"GADMediationAdapterInMobi - Error : Placement ID not specified.");
    _interstitialRenderCompletionHandler(nil, error);
    return;
  }

  if ([_interstitialAdConfig isTestRequest]) {
    GADMAdapterInMobiLog(
        @"Please enter your device ID in the InMobi console to receive test ads from "
        @"InMobi");
  }

  _interstitialAd = [[IMInterstitial alloc] initWithPlacementId:placementId];

  GADInMobiExtras *extras = _interstitialAdConfig.extras;
  if (extras && extras.keywords) {
    [_interstitialAd setKeywords:extras.keywords];
  }

  GADMAdapterInMobiSetTargetingFromAdConfiguration(_interstitialAdConfig);
  GADMAdapterInMobiSetUSPrivacyCompliance();
  NSDictionary<NSString *, id> *requestParameters =
      GADMAdapterInMobiCreateRequestParametersFromAdConfiguration(_interstitialAdConfig);
  [_interstitialAd setExtras:requestParameters];

  _interstitialAd.delegate = self;
  [_interstitialAd load];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if ([_interstitialAd isReady]) {
    [_interstitialAd showFrom:viewController with:IMInterstitialAnimationTypeCoverVertical];
  } else {
    NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
        GADMAdapterInMobiErrorAdNotReady,
        @"InMobi SDK is not ready to present an interstitial ad.");
    [_interstitalAdEventDelegate didFailToPresentWithError:error];
  }
}

- (void)stopBeingDelegate {
  _interstitialAd.delegate = nil;
}

#pragma mark IMInterstitialDelegate methods

- (void)interstitialDidFinishLoading:(nonnull IMInterstitial *)interstitial {
  GADMAdapterInMobiLog(@"InMobi SDK loaded an interstitial ad successfully.");
  _interstitalAdEventDelegate = _interstitialRenderCompletionHandler(self, nil);
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
    didFailToLoadWithError:(nonnull IMRequestStatus *)error {
  GADMAdapterInMobiLog(@"InMobi SDK failed to load interstitial ad.");
  _interstitialRenderCompletionHandler(nil, error);
}

- (void)interstitialWillPresent:(nonnull IMInterstitial *)interstitial {
  GADMAdapterInMobiLog(@"InMobi SDK will present a full screen interstitial ad.");
  [_interstitalAdEventDelegate willPresentFullScreenView];
}

- (void)interstitialDidPresent:(nonnull IMInterstitial *)interstitial {
  GADMAdapterInMobiLog(@"InMobi SDK did present a full screen interstitial ad.");
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
    didFailToPresentWithError:(nonnull IMRequestStatus *)error {
  GADMAdapterInMobiLog(@"InMobi SDK did fail to present interstitial ad.");
  [_interstitalAdEventDelegate didFailToPresentWithError:error];
}

- (void)interstitialWillDismiss:(nonnull IMInterstitial *)interstitial {
  GADMAdapterInMobiLog(@"InMobi SDK will dismiss an interstitial ad.");
  [_interstitalAdEventDelegate willDismissFullScreenView];
}

- (void)interstitialDidDismiss:(nonnull IMInterstitial *)interstitial {
  GADMAdapterInMobiLog(@"InMobi SDK did dismiss an interstitial ad.");
  [_interstitalAdEventDelegate didDismissFullScreenView];
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
    didInteractWithParams:(nullable NSDictionary<NSString *, id> *)params {
  GADMAdapterInMobiLog(@"InMobi SDK recorded a click on an interstitial ad.");
  [_interstitalAdEventDelegate reportClick];
}

- (void)userWillLeaveApplicationFromInterstitial:(nonnull IMInterstitial *)interstitial {
  GADMAdapterInMobiLog(
      @"InMobi SDK will cause the user to leave the application from an interstitial ad.");
}

- (void)interstitialDidReceiveAd:(nonnull IMInterstitial *)interstitial {
  GADMAdapterInMobiLog(@"InMobi AdServer returned a response for interstitial ad.");
}

- (void)interstitialAdImpressed:(nonnull IMInterstitial *)interstitial {
  GADMAdapterInMobiLog(@"InMobi SDK recorded an impression from interstitial ad.");
  [_interstitalAdEventDelegate reportImpression];
}

@end
