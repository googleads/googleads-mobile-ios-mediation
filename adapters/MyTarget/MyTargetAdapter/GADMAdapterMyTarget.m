//
//  GADMAdapterMyTarget.m
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 27.09.17.
//  Copyright © 2017 Mail.Ru Group. All rights reserved.
//

@import MyTargetSDK;

#import "GADMAdapterMyTarget.h"
#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtras.h"
#import "GADMAdapterMyTargetUtils.h"

@interface GADMAdapterMyTarget () <MTRGAdViewDelegate, MTRGInterstitialAdDelegate>

@end

/// Find closest supported ad size from a given ad size.
/// Returns nil if no supported size matches.
static GADAdSize GADSupportedAdSizeFromRequestedSize(GADAdSize gadAdSize) {
  NSArray *potentials = @[
    NSValueFromGADAdSize(kGADAdSizeBanner),
    NSValueFromGADAdSize(kGADAdSizeMediumRectangle),
    NSValueFromGADAdSize(kGADAdSizeLeaderboard),
  ];
  return GADClosestValidSizeForAdSizes(gadAdSize, potentials);
}

@implementation GADMAdapterMyTarget {
  MTRGAdView *_adView;
  MTRGInterstitialAd *_interstitialAd;
  __weak id<GADMAdNetworkConnector> _connector;
  BOOL _isInterstitialLoaded;
  BOOL _isInterstitialStarted;
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
      [GADMAdapterMyTargetUtils setLogEnabled:extras.isDebugMode];
    }

    MTRGLogInfo();
    MTRGLogDebug(@"Credentials: %@", connector.credentials);
    _connector = connector;
    _isInterstitialLoaded = NO;
    _isInterstitialStarted = NO;
  }
  return self;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  MTRGLogDebug(@"adSize: %.fx%.f", adSize.size.width, adSize.size.height);

  if (!strongConnector) {
    return;
  }

  adSize = GADSupportedAdSizeFromRequestedSize(adSize);
  MTRGAdSize adViewSize;
  if ([GADMAdapterMyTargetUtils isSize:adSize equalToSize:kGADAdSizeBanner]) {
    adViewSize = MTRGAdSize_320x50;
  } else if ([GADMAdapterMyTargetUtils isSize:adSize equalToSize:kGADAdSizeMediumRectangle]) {
    adViewSize = MTRGAdSize_300x250;
  } else if ([GADMAdapterMyTargetUtils isSize:adSize equalToSize:kGADAdSizeLeaderboard]) {
    adViewSize = MTRGAdSize_728x90;
  } else {
    [self delegateOnNoAdWithReason:kGADMAdapterMyTargetErrorInvalidSize];
    return;
  }

  NSUInteger slotId = [GADMAdapterMyTargetUtils slotIdFromCredentials:strongConnector.credentials];
  if (slotId <= 0) {
    MTRGLogError(kGADMAdapterMyTargetErrorSlotId);
    [strongConnector
          adapter:self
        didFailAd:[GADMAdapterMyTargetUtils errorWithDescription:kGADMAdapterMyTargetErrorSlotId]];
    return;
  }

  _adView = [[MTRGAdView alloc] initWithSlotId:slotId withRefreshAd:NO adSize:adViewSize];
  _adView.delegate = self;
  _adView.viewController = strongConnector.viewControllerForPresentingModalView;
  [GADMAdapterMyTargetUtils fillCustomParams:_adView.customParams withConnector:strongConnector];
  [_adView.customParams setCustomParam:kMTRGCustomParamsMediationAdmob
                                forKey:kMTRGCustomParamsMediationKey];
  [_adView load];
}

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  if (!strongConnector) {
    return;
  }

  NSUInteger slotId = [GADMAdapterMyTargetUtils slotIdFromCredentials:strongConnector.credentials];
  if (slotId <= 0) {
    MTRGLogError(kGADMAdapterMyTargetErrorSlotId);
    [strongConnector
          adapter:self
        didFailAd:[GADMAdapterMyTargetUtils errorWithDescription:kGADMAdapterMyTargetErrorSlotId]];
    return;
  }

  _isInterstitialLoaded = NO;
  _interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:slotId];
  _interstitialAd.delegate = self;
  [GADMAdapterMyTargetUtils fillCustomParams:_interstitialAd.customParams
                               withConnector:strongConnector];
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
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  if (!_isInterstitialLoaded || _isInterstitialStarted || !_interstitialAd || !strongConnector) {
    return;
  }

  [_interstitialAd showWithController:rootViewController];
  [strongConnector adapterWillPresentInterstitial:self];
}

#pragma mark - MTRGAdViewDelegate

- (void)onLoadWithAdView:(nonnull MTRGAdView *)adView {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  if (!strongConnector) {
    return;
  }

  [strongConnector adapter:self didReceiveAdView:adView];
}

- (void)onNoAdWithReason:(nonnull NSString *)reason adView:(nonnull MTRGAdView *)adView {
  [self delegateOnNoAdWithReason:reason];
}

- (void)onAdClickWithAdView:(nonnull MTRGAdView *)adView {
  [self delegateOnClick];
}

- (void)onShowModalWithAdView:(nonnull MTRGAdView *)adView {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  if (!strongConnector) {
    return;
  }

  _isInterstitialStarted = YES;
  [strongConnector adapterWillPresentFullScreenModal:self];
}

- (void)onDismissModalWithAdView:(nonnull MTRGAdView *)adView {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  if (!strongConnector) {
    return;
  }

  _isInterstitialStarted = NO;
  [strongConnector adapterWillDismissFullScreenModal:self];
  [strongConnector adapterDidDismissFullScreenModal:self];
}

- (void)onLeaveApplicationWithAdView:(nonnull MTRGAdView *)adView {
  [self delegateOnLeaveApplication];
}

#pragma mark - MTRGInterstitialAdDelegate

- (void)onLoadWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  if (!strongConnector) {
    return;
  }

  _isInterstitialLoaded = YES;
  [strongConnector adapterDidReceiveInterstitial:self];
}

- (void)onNoAdWithReason:(nonnull NSString *)reason
          interstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  [self delegateOnNoAdWithReason:reason];
}

- (void)onClickWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  [self delegateOnClick];
}

- (void)onCloseWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  if (!strongConnector) {
    return;
  }

  [strongConnector adapterWillDismissInterstitial:self];
  [strongConnector adapterDidDismissInterstitial:self];
}

- (void)onVideoCompleteWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  // do nothing
}

- (void)onDisplayWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  if (!strongConnector) {
    return;
  }

  [strongConnector adapterWillPresentInterstitial:self];
}

- (void)onLeaveApplicationWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  [self delegateOnLeaveApplication];
}

#pragma mark - delegates

- (void)delegateOnNoAdWithReason:(nonnull NSString *)reason {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  NSString *description = [GADMAdapterMyTargetUtils noAdWithReason:reason];
  MTRGLogError(description);
  if (!strongConnector) {
    return;
  }

  NSError *error = [GADMAdapterMyTargetUtils errorWithDescription:description];
  [strongConnector adapter:self didFailAd:error];
}

- (void)delegateOnClick {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  if (!strongConnector) {
    return;
  }

  [strongConnector adapterDidGetAdClick:self];
}

- (void)delegateOnLeaveApplication {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  if (!strongConnector) {
    return;
  }

  [strongConnector adapterWillLeaveApplication:self];
}

@end
