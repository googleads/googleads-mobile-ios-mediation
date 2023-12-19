// Copyright 2023 Google LLC
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

#import "GADMAdapterMyTargetInterstitialAd.h"

#import <MyTargetSDK/MyTargetSDK.h>

#import <stdatomic.h>

#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtras.h"
#import "GADMAdapterMyTargetUtils.h"

@interface GADMAdapterMyTargetInterstitialAd () <MTRGInterstitialAdDelegate>
@end

@implementation GADMAdapterMyTargetInterstitialAd {
  /// Completion handler to forward ad load events to the Google Mobile Ads SDK.
  GADMediationInterstitialLoadCompletionHandler _completionHandler;

  /// Interstitial ad configuration of the ad request.
  GADMediationInterstitialAdConfiguration *_adConfiguration;

  /// Ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  __weak id<GADMediationInterstitialAdEventDelegate> _adEventDelegate;

  /// myTarget interstitial ad object.
  MTRGInterstitialAd *_interstitialAd;
}

BOOL _isInterstitialAdLoaded;

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
          completionHandler:
              (nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationInterstitialLoadCompletionHandler originalCompletionHandler =
        [completionHandler copy];

    _completionHandler = ^id<GADMediationInterstitialAdEventDelegate>(
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

    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)loadInterstitialAd {
  MTRGLogInfo();
  id<GADAdNetworkExtras> networkExtras = _adConfiguration.extras;
  if (networkExtras && [networkExtras isKindOfClass:[GADMAdapterMyTargetExtras class]]) {
    GADMAdapterMyTargetExtras *extras = (GADMAdapterMyTargetExtras *)networkExtras;
    GADMAdapterMyTargetUtils.logEnabled = extras.isDebugMode;
  }

  NSDictionary<NSString *, id> *credentials = _adConfiguration.credentials.settings;
  MTRGLogDebug(@"Credentials: %@", credentials);

  NSUInteger slotId = GADMAdapterMyTargetSlotIdFromCredentials(credentials);
  if (slotId <= 0) {
    NSError *error = GADMAdapterMyTargetErrorWithCodeAndDescription(
        GADMAdapterMyTargetErrorInvalidServerParameters, @"Slot ID cannot be nil.");
    _completionHandler(nil, error);
    return;
  }

  _isInterstitialAdLoaded = NO;
  _interstitialAd = [MTRGInterstitialAd interstitialAdWithSlotId:slotId];
  _interstitialAd.delegate = self;
  GADMAdapterMyTargetFillCustomParams(_interstitialAd.customParams, _adConfiguration.extras);
  [_interstitialAd load];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  MTRGLogInfo();
  id<GADMediationInterstitialAdEventDelegate> adEventDelegate = _adEventDelegate;
  if (!_isInterstitialAdLoaded || !_interstitialAd) {
    MTRGLogError(@"Interstitial ad hasn't been loaded to present.");
    return;
  }
  [adEventDelegate willPresentFullScreenView];
  [_interstitialAd showWithController:viewController];
}

#pragma mark - MTRGInterstitialAdDelegate

- (void)onLoadWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  MTRGLogInfo();
  _isInterstitialAdLoaded = YES;
  _adEventDelegate = _completionHandler(self, nil);
}

- (void)onLoadFailedWithError:(NSError *)error interstitialAd:(MTRGInterstitialAd *)interstitialAd {
  MTRGLogInfo();
  MTRGLogError(error.localizedDescription);
  NSError *noFillError = GADMAdapterMyTargetErrorWithCodeAndDescription(
      GADMAdapterMyTargetErrorNoFill, error.localizedDescription);
  _completionHandler(nil, noFillError);
}

- (void)onDisplayWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  MTRGLogInfo();
  [_adEventDelegate reportImpression];
}

- (void)onClickWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  MTRGLogInfo();
  [_adEventDelegate reportClick];
}

- (void)onCloseWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  MTRGLogInfo();
  [_adEventDelegate didDismissFullScreenView];
}

- (void)onLeaveApplicationWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  // Do nothing. The Google Mobile Ads SDK does not have an equivalent callback.
}

@end
