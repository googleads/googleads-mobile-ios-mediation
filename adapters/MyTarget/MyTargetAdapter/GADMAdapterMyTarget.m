// Copyright 2017 Google LLC
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

#import "GADMAdapterMyTarget.h"

#import <MyTargetSDK/MyTargetSDK.h>

#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtras.h"
#import "GADMAdapterMyTargetUtils.h"

@interface GADMAdapterMyTarget () <MTRGAdViewDelegate, MTRGInterstitialAdDelegate>
@end

/// Find closest supported ad size from a given ad size.
/// Returns nil if no supported size matches.
static GADAdSize GADSupportedAdSizeFromRequestedSize(GADAdSize gadAdSize) {
  NSArray<NSValue *> *potentials = @[
    NSValueFromGADAdSize(kGADAdSizeBanner),
    NSValueFromGADAdSize(kGADAdSizeMediumRectangle),
    NSValueFromGADAdSize(kGADAdSizeLeaderboard),
  ];
  return GADClosestValidSizeForAdSizes(gadAdSize, potentials);
}

@implementation GADMAdapterMyTarget {
  /// Google Mobile Ads SDK ad network connector.
  __weak id<GADMAdNetworkConnector> _connector;

  /// myTarget banner ad object.
  MTRGAdView *_adView;

  /// myTarget interstitial ad object.
  MTRGInterstitialAd *_interstitialAd;
}

+ (nonnull NSString *)adapterVersion {
  return kGADMAdapterMyTargetVersion;
}

+ (nonnull Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterMyTargetExtras class];
}

- (nonnull instancetype)initWithGADMAdNetworkConnector:
    (nonnull id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    id<GADAdNetworkExtras> networkExtras = connector.networkExtras;
    if (networkExtras && [networkExtras isKindOfClass:[GADMAdapterMyTargetExtras class]]) {
      GADMAdapterMyTargetExtras *extras = (GADMAdapterMyTargetExtras *)networkExtras;
      GADMAdapterMyTargetUtils.logEnabled = extras.isDebugMode;
    }

    MTRGLogInfo();
    MTRGLogDebug(@"Credentials: %@", connector.credentials);
    _connector = connector;
  }
  return self;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  MTRGLogInfo();
  MTRGLogDebug(@"adSize: %.fx%.f", adSize.size.width, adSize.size.height);

  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  adSize = GADSupportedAdSizeFromRequestedSize(adSize);
  MTRGAdSize adViewSize;
  if (GADAdSizeEqualToSize(adSize, kGADAdSizeBanner)) {
    adViewSize = MTRGAdSize_320x50;
  } else if (GADAdSizeEqualToSize(adSize, kGADAdSizeMediumRectangle)) {
    adViewSize = MTRGAdSize_300x250;
  } else if (GADAdSizeEqualToSize(adSize, kGADAdSizeLeaderboard)) {
    adViewSize = MTRGAdSize_728x90;
  } else {
    MTRGLogError(kGADMAdapterMyTargetErrorInvalidSize);
    [strongConnector adapter:self
                   didFailAd:GADMAdapterMyTargetAdapterErrorWithDescription(
                                 kGADMAdapterMyTargetErrorInvalidSize)];
    return;
  }

  NSUInteger slotId = GADMAdapterMyTargetSlotIdFromCredentials(strongConnector.credentials);
  if (slotId <= 0) {
    MTRGLogError(kGADMAdapterMyTargetErrorSlotId);
    [strongConnector
          adapter:self
        didFailAd:GADMAdapterMyTargetAdapterErrorWithDescription(kGADMAdapterMyTargetErrorSlotId)];
    return;
  }

  _adView = [[MTRGAdView alloc] initWithSlotId:slotId withRefreshAd:NO adSize:adViewSize];
  _adView.delegate = self;
  _adView.viewController = strongConnector.viewControllerForPresentingModalView;
  GADMAdapterMyTargetFillCustomParams(_adView.customParams, strongConnector);
  [_adView.customParams setCustomParam:kMTRGCustomParamsMediationAdmob
                                forKey:kMTRGCustomParamsMediationKey];
  [_adView load];
}

- (void)getInterstitial {
  MTRGLogInfo();
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  NSUInteger slotId = GADMAdapterMyTargetSlotIdFromCredentials(strongConnector.credentials);
  if (slotId <= 0) {
    MTRGLogError(kGADMAdapterMyTargetErrorSlotId);
    [strongConnector
          adapter:self
        didFailAd:GADMAdapterMyTargetAdapterErrorWithDescription(kGADMAdapterMyTargetErrorSlotId)];
    return;
  }

  _interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:slotId];
  _interstitialAd.delegate = self;
  GADMAdapterMyTargetFillCustomParams(_interstitialAd.customParams, strongConnector);
  [_interstitialAd.customParams setCustomParam:kMTRGCustomParamsMediationAdmob
                                        forKey:kMTRGCustomParamsMediationKey];
  [_interstitialAd load];
}

- (void)stopBeingDelegate {
  MTRGLogInfo();
  _connector = nil;
  if (_adView) {
    _adView.delegate = nil;
    _adView = nil;
  }
  if (_interstitialAd) {
    _interstitialAd.delegate = nil;
    _interstitialAd = nil;
  }
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

- (void)presentInterstitialFromRootViewController:(nonnull UIViewController *)rootViewController {
  MTRGLogInfo();
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector || !_interstitialAd) {
    return;
  }

  [_interstitialAd showWithController:rootViewController];
  [strongConnector adapterWillPresentInterstitial:self];
}

#pragma mark - MTRGAdViewDelegate

- (void)onLoadWithAdView:(nonnull MTRGAdView *)adView {
  MTRGLogInfo();
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  [strongConnector adapter:self didReceiveAdView:adView];
}

- (void)onNoAdWithReason:(nonnull NSString *)reason adView:(nonnull MTRGAdView *)adView {
  MTRGLogError(reason);
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  NSError *error = GADMAdapterMyTargetSDKErrorWithDescription(reason);
  [strongConnector adapter:self didFailAd:error];
}

- (void)onAdClickWithAdView:(nonnull MTRGAdView *)adView {
  MTRGLogInfo();
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  [strongConnector adapterDidGetAdClick:self];
}

- (void)onShowModalWithAdView:(nonnull MTRGAdView *)adView {
  MTRGLogInfo();
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  [strongConnector adapterWillPresentFullScreenModal:self];
}

- (void)onDismissModalWithAdView:(nonnull MTRGAdView *)adView {
  MTRGLogInfo();
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  [strongConnector adapterWillDismissFullScreenModal:self];
  [strongConnector adapterDidDismissFullScreenModal:self];
}

- (void)onLeaveApplicationWithAdView:(nonnull MTRGAdView *)adView {
  MTRGLogInfo();
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  [strongConnector adapterWillLeaveApplication:self];
}

#pragma mark - MTRGInterstitialAdDelegate

- (void)onLoadWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  MTRGLogInfo();
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  [strongConnector adapterDidReceiveInterstitial:self];
}

- (void)onNoAdWithReason:(nonnull NSString *)reason
          interstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  MTRGLogError(reason);
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  NSError *error = GADMAdapterMyTargetSDKErrorWithDescription(reason);
  [strongConnector adapter:self didFailAd:error];
}

- (void)onClickWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  MTRGLogInfo();
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  [strongConnector adapterDidGetAdClick:self];
}

- (void)onCloseWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  MTRGLogInfo();
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  [strongConnector adapterWillDismissInterstitial:self];
  [strongConnector adapterDidDismissInterstitial:self];
}

- (void)onVideoCompleteWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  // Do nothing.
}

- (void)onDisplayWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  MTRGLogInfo();
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  [strongConnector adapterWillPresentInterstitial:self];
}

- (void)onLeaveApplicationWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  MTRGLogInfo();
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  [strongConnector adapterWillLeaveApplication:self];
}

@end
