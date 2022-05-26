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

@implementation GADMAdapterMyTarget {
  /// Google Mobile Ads SDK ad network connector.
  __weak id<GADMAdNetworkConnector> _connector;

  /// myTarget banner ad object.
  MTRGAdView *_adView;

  /// myTarget interstitial ad object.
  MTRGInterstitialAd *_interstitialAd;
}

+ (nonnull NSString *)adapterVersion {
  return GADMAdapterMyTargetVersion;
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
  MTRGLogDebug(@"getBannerWithSize: %@", NSStringFromGADAdSize(adSize));

  id<GADMAdNetworkConnector> strongConnector = _connector;

  if (!strongConnector) {
    return;
  }
  NSError *error = nil;
  MTRGAdSize *mytargetAdSize = GADMAdapterMyTargetSizeFromRequestedSize(adSize, &error);
  if (error) {
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  NSUInteger slotId = GADMAdapterMyTargetSlotIdFromCredentials(strongConnector.credentials);
  if (slotId <= 0) {
    NSError *error = GADMAdapterMyTargetErrorWithCodeAndDescription(
        GADMAdapterMyTargetErrorInvalidServerParameters, @"Slot ID cannot be nil.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  _adView = [MTRGAdView adViewWithSlotId:slotId shouldRefreshAd:NO];
  CGFloat width = mytargetAdSize.size.width;
  CGFloat height = mytargetAdSize.size.height;
  _adView.adSize = mytargetAdSize;
  _adView.frame = CGRectMake(0, 0, width, height);
  MTRGLogDebug(@"adSize: %.fx%.f", width, height);
  _adView.delegate = self;
  _adView.viewController = strongConnector.viewControllerForPresentingModalView;
  GADMAdapterMyTargetFillCustomParams(_adView.customParams, strongConnector.networkExtras);
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
    NSError *error = GADMAdapterMyTargetErrorWithCodeAndDescription(
        GADMAdapterMyTargetErrorInvalidServerParameters, @"Slot ID cannot be nil.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  _interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:slotId];
  _interstitialAd.delegate = self;
  GADMAdapterMyTargetFillCustomParams(_interstitialAd.customParams, strongConnector.networkExtras);
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
  NSError *error =
      GADMAdapterMyTargetErrorWithCodeAndDescription(GADMAdapterMyTargetErrorNoFill, reason);
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

  NSError *error =
      GADMAdapterMyTargetErrorWithCodeAndDescription(GADMAdapterMyTargetErrorNoFill, reason);
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
  MTRGLogInfo();
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
}

@end
