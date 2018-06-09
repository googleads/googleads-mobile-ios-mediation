//
//  GADMAdapterMyTargetNative.m
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 29.09.17.
//  Copyright © 2017 Mail.Ru Group. All rights reserved.
//

@import MyTargetSDK;

#import "GADMAdapterMyTargetNative.h"
#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtras.h"
#import "GADMAdapterMyTargetMediatedNativeAd.h"
#import "GADMAdapterMyTargetMediatedUnifiedNativeAd.h"
#import "GADMAdapterMyTargetUtils.h"

#define guard(CONDITION) \
  if (CONDITION) {       \
  }

@interface GADMAdapterMyTargetNative () <MTRGNativeAdDelegate, GADMediatedNativeAdDelegate>

@property(nonatomic, strong) MTRGNativeAd *nativeAd;

@end

@implementation GADMAdapterMyTargetNative {
  id<GADMediatedNativeAd> _mediatedNativeAd;
  id<GADMediatedUnifiedNativeAd> _mediatedUnifiedNativeAd;
  __weak id<GADMAdNetworkConnector> _connector;
  MTRGMediaAdView *_mediaAdView;
  BOOL _isUnifiedAdRequested;
  BOOL _isContentAdRequested;
  BOOL _isAppInstallAdRequested;
  BOOL _autoLoadImages;
  NSString *_adTypesRequested;
}

+ (NSString *)adapterVersion {
  return kGADMAdapterMyTargetVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterMyTargetExtras class];
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
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
  }
  return self;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  guard(strongConnector) else return;
  [strongConnector adapter:self
                 didFailAd:[GADMAdapterMyTargetUtils
                               errorWithDescription:kGADMAdapterMyTargetErrorBannersNotSupported]];
}

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  guard(strongConnector) else return;
  [strongConnector
        adapter:self
      didFailAd:[GADMAdapterMyTargetUtils
                    errorWithDescription:kGADMAdapterMyTargetErrorInterstitialNotSupported]];
}

- (void)stopBeingDelegate {
  MTRGLogInfo();
  _connector = nil;
  if (_nativeAd) {
    _nativeAd.delegate = nil;
    _nativeAd = nil;
  }
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  guard(strongConnector) else return;
  [strongConnector
        adapter:self
      didFailAd:[GADMAdapterMyTargetUtils
                    errorWithDescription:kGADMAdapterMyTargetErrorInterstitialNotSupported]];
}

- (void)getNativeAdWithAdTypes:(NSArray *)adTypes options:(NSArray *)options {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  guard(strongConnector) else return;

  NSUInteger slotId = [GADMAdapterMyTargetUtils slotIdFromCredentials:strongConnector.credentials];
  guard(slotId > 0) else {
    MTRGLogError(kGADMAdapterMyTargetErrorSlotId);
    [strongConnector
          adapter:self
        didFailAd:[GADMAdapterMyTargetUtils errorWithDescription:kGADMAdapterMyTargetErrorSlotId]];
    return;
  }

  _isUnifiedAdRequested = [adTypes containsObject:kGADAdLoaderAdTypeUnifiedNative];
  _isContentAdRequested = [adTypes containsObject:kGADAdLoaderAdTypeNativeContent];
  _isAppInstallAdRequested = [adTypes containsObject:kGADAdLoaderAdTypeNativeAppInstall];
  _adTypesRequested = [adTypes componentsJoinedByString:@", "];

  guard(_isUnifiedAdRequested || _isContentAdRequested || _isAppInstallAdRequested) else {
    NSString *description =
        [NSString stringWithFormat:kGADMAdapterMyTargetErrorInvalidNativeAdType, _adTypesRequested];
    MTRGLogError(description);
    [strongConnector adapter:self
                   didFailAd:[GADMAdapterMyTargetUtils errorWithDescription:description]];
    return;
  }

  _autoLoadImages = YES;
  for (GADAdLoaderOptions *adLoaderOptions in options) {
    guard([adLoaderOptions isKindOfClass:[GADNativeAdImageAdLoaderOptions class]]) else continue;
    GADNativeAdImageAdLoaderOptions *imageOptions =
        (GADNativeAdImageAdLoaderOptions *)adLoaderOptions;
    if (imageOptions.disableImageLoading) {
      _autoLoadImages = NO;
      break;
    }
  }

  _nativeAd = [[MTRGNativeAd alloc] initWithSlotId:slotId];
  _nativeAd.delegate = self;
  _nativeAd.autoLoadImages = _autoLoadImages;
  [GADMAdapterMyTargetUtils fillCustomParams:_nativeAd.customParams withConnector:strongConnector];
  [_nativeAd.customParams setCustomParam:kMTRGCustomParamsMediationAdmob
                                  forKey:kMTRGCustomParamsMediationKey];

  if (_isContentAdRequested && !_isAppInstallAdRequested && !_isUnifiedAdRequested) {
    [_nativeAd.customParams setCustomParam:kGADMAdapterMyTargetNativeAdTypeContent
                                    forKey:kGADMAdapterMyTargetNativeAdTypeKey];
  } else if (_isAppInstallAdRequested && !_isContentAdRequested && !_isUnifiedAdRequested) {
    [_nativeAd.customParams setCustomParam:kGADMAdapterMyTargetNativeAdTypeInstall
                                    forKey:kGADMAdapterMyTargetNativeAdTypeKey];
  }
  [_nativeAd load];
}

- (BOOL)handlesUserClicks {
  return YES;
}

- (BOOL)handlesUserImpressions {
  return YES;
}

#pragma mark - MTRGNativeAdDelegate

- (void)onLoadWithNativePromoBanner:(MTRGNativePromoBanner *)promoBanner
                           nativeAd:(MTRGNativeAd *)nativeAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  guard(strongConnector) else return;

  _mediaAdView = [MTRGNativeViewsFactory createMediaAdView];
  if (_isUnifiedAdRequested) {
    _mediatedUnifiedNativeAd = [GADMAdapterMyTargetMediatedUnifiedNativeAd
        mediatedUnifiedNativeAdWithNativePromoBanner:promoBanner
                                            nativeAd:_nativeAd
                                      autoLoadImages:_autoLoadImages
                                         mediaAdView:_mediaAdView];
    guard(_mediatedUnifiedNativeAd) else {
      MTRGLogError(kGADMAdapterMyTargetErrorMediatedAdInvalid);
      [strongConnector
            adapter:self
          didFailAd:[GADMAdapterMyTargetUtils
                        errorWithDescription:kGADMAdapterMyTargetErrorMediatedAdInvalid]];
      return;
    }
    [strongConnector adapter:self didReceiveMediatedUnifiedNativeAd:_mediatedUnifiedNativeAd];
  } else {
    _mediatedNativeAd =
        [GADMAdapterMyTargetMediatedNativeAd mediatedNativeAdWithNativePromoBanner:promoBanner
                                                                          delegate:self
                                                                    autoLoadImages:_autoLoadImages
                                                                       mediaAdView:_mediaAdView];
    guard(_mediatedNativeAd) else {
      MTRGLogError(kGADMAdapterMyTargetErrorMediatedAdInvalid);
      [strongConnector
            adapter:self
          didFailAd:[GADMAdapterMyTargetUtils
                        errorWithDescription:kGADMAdapterMyTargetErrorMediatedAdInvalid]];
      return;
    }
    Class mediatedNativeAdClass = _mediatedNativeAd.class;
    guard((_isContentAdRequested &&
           [mediatedNativeAdClass conformsToProtocol:@protocol(GADMediatedNativeContentAd)]) ||
          (_isAppInstallAdRequested &&
           [mediatedNativeAdClass
               conformsToProtocol:@protocol(GADMediatedNativeAppInstallAd)])) else {
      NSString *description =
          [NSString stringWithFormat:kGADMAdapterMyTargetErrorMediatedAdDoesNotMatch,
                                     NSStringFromClass(mediatedNativeAdClass), _adTypesRequested];
      MTRGLogError(description);
      [strongConnector adapter:self
                     didFailAd:[GADMAdapterMyTargetUtils errorWithDescription:description]];
      return;
    }
    [strongConnector adapter:self didReceiveMediatedNativeAd:_mediatedNativeAd];
  }
}

- (void)onNoAdWithReason:(NSString *)reason nativeAd:(MTRGNativeAd *)nativeAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  NSString *description = [GADMAdapterMyTargetUtils noAdWithReason:reason];
  MTRGLogError(description);
  guard(strongConnector) else return;
  NSError *error = [GADMAdapterMyTargetUtils errorWithDescription:description];
  [strongConnector adapter:self didFailAd:error];
}

- (void)onAdShowWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  if (_mediatedUnifiedNativeAd) {
    [GADMediatedUnifiedNativeAdNotificationSource
        mediatedNativeAdDidRecordImpression:_mediatedUnifiedNativeAd];
  } else if (_mediatedNativeAd) {
    [GADMediatedNativeAdNotificationSource mediatedNativeAdDidRecordImpression:_mediatedNativeAd];
  }
}

- (void)onAdClickWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  if (_mediatedUnifiedNativeAd) {
    [GADMediatedUnifiedNativeAdNotificationSource
        mediatedNativeAdDidRecordClick:_mediatedUnifiedNativeAd];
  } else if (_mediatedNativeAd) {
    [GADMediatedNativeAdNotificationSource mediatedNativeAdDidRecordClick:_mediatedNativeAd];
  }
}

- (void)onShowModalWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  if (_mediatedUnifiedNativeAd) {
    [GADMediatedUnifiedNativeAdNotificationSource
        mediatedNativeAdWillPresentScreen:_mediatedUnifiedNativeAd];
  } else if (_mediatedNativeAd) {
    [GADMediatedNativeAdNotificationSource mediatedNativeAdWillPresentScreen:_mediatedNativeAd];
  }
}

- (void)onDismissModalWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  if (_mediatedUnifiedNativeAd) {
    [GADMediatedUnifiedNativeAdNotificationSource
        mediatedNativeAdWillDismissScreen:_mediatedUnifiedNativeAd];
    [GADMediatedUnifiedNativeAdNotificationSource
        mediatedNativeAdDidDismissScreen:_mediatedUnifiedNativeAd];
  } else if (_mediatedNativeAd) {
    [GADMediatedNativeAdNotificationSource mediatedNativeAdWillDismissScreen:_mediatedNativeAd];
    [GADMediatedNativeAdNotificationSource mediatedNativeAdDidDismissScreen:_mediatedNativeAd];
  }
}

- (void)onLeaveApplicationWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  if (_mediatedUnifiedNativeAd) {
    [GADMediatedUnifiedNativeAdNotificationSource
        mediatedNativeAdWillLeaveApplication:_mediatedUnifiedNativeAd];
  } else if (_mediatedNativeAd) {
    [GADMediatedNativeAdNotificationSource mediatedNativeAdWillLeaveApplication:_mediatedNativeAd];
  }
}

- (void)onVideoPlayWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  if (_mediatedUnifiedNativeAd) {
    [GADMediatedUnifiedNativeAdNotificationSource
        mediatedNativeAdDidPlayVideo:_mediatedUnifiedNativeAd];
  } else if (_mediatedNativeAd) {
    [GADMediatedNativeAdNotificationSource mediatedNativeAdDidPlayVideo:_mediatedNativeAd];
  }
}

- (void)onVideoPauseWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  if (_mediatedUnifiedNativeAd) {
    [GADMediatedUnifiedNativeAdNotificationSource
        mediatedNativeAdDidPauseVideo:_mediatedUnifiedNativeAd];
  } else if (_mediatedNativeAd) {
    [GADMediatedNativeAdNotificationSource mediatedNativeAdDidPauseVideo:_mediatedNativeAd];
  }
}

- (void)onVideoCompleteWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  if (_mediatedUnifiedNativeAd) {
    [GADMediatedUnifiedNativeAdNotificationSource
        mediatedNativeAdDidEndVideoPlayback:_mediatedUnifiedNativeAd];
  } else if (_mediatedNativeAd) {
    [GADMediatedNativeAdNotificationSource mediatedNativeAdDidEndVideoPlayback:_mediatedNativeAd];
  }
}

#pragma mark - GADMediatedNativeAdDelegate

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd
           didRenderInView:(UIView *)view
       clickableAssetViews:(NSDictionary<NSString *, UIView *> *)clickableAssetViews
    nonclickableAssetViews:(NSDictionary<NSString *, UIView *> *)nonclickableAssetViews
            viewController:(UIViewController *)viewController {
  MTRGLogInfo();
  [self registerView:view
          withController:viewController
      withClickableViews:clickableAssetViews.allValues];
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd
         didRenderInView:(UIView *)view
          viewController:(UIViewController *)viewController {
  // Legacy
  MTRGLogInfo();
  NSArray<UIView *> *clickableViews = [self clickableViewsWithView:view];
  [self registerView:view withController:viewController withClickableViews:clickableViews];
}

- (void)mediatedNativeAdDidRecordImpression:(id<GADMediatedNativeAd>)mediatedNativeAd {
  // do nothing
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd
    didRecordClickOnAssetWithName:(NSString *)assetName
                             view:(UIView *)view
                   viewController:(UIViewController *)viewController {
  // do nothing
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd didUntrackView:(UIView *)view {
  MTRGLogInfo();
  guard(_nativeAd) else return;
  [_nativeAd unregisterView];
}

#pragma mark - helpers

- (void)registerView:(UIView *)view
        withController:(UIViewController *)viewController
    withClickableViews:(NSArray<UIView *> *)clickableViews {
  MTRGLogInfo();
  guard(_nativeAd) else return;

  // NOTE: This is a workaround. Subview GADMediaView does not contain mediaView at this moment but
  // it will appear a little bit later.
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.nativeAd registerView:view
                 withController:viewController
             withClickableViews:clickableViews];
  });
}

- (NSArray<UIView *> *)clickableViewsWithView:(UIView *)view {
  NSMutableArray<UIView *> *clickableViews = [NSMutableArray<UIView *> new];
  if (_mediaAdView) [clickableViews addObject:_mediaAdView];
  if ([view isKindOfClass:[GADNativeContentAdView class]]) {
    GADNativeContentAdView *contentAdView = (GADNativeContentAdView *)view;
    if (contentAdView.headlineView) [clickableViews addObject:contentAdView.headlineView];
    if (contentAdView.bodyView) [clickableViews addObject:contentAdView.bodyView];
    if (contentAdView.imageView) [clickableViews addObject:contentAdView.imageView];
    if (contentAdView.logoView) [clickableViews addObject:contentAdView.logoView];
    if (contentAdView.callToActionView) [clickableViews addObject:contentAdView.callToActionView];
    if (contentAdView.advertiserView) [clickableViews addObject:contentAdView.advertiserView];
    if (contentAdView.adChoicesView) [clickableViews addObject:contentAdView.adChoicesView];
  } else if ([view isKindOfClass:[GADNativeAppInstallAdView class]]) {
    GADNativeAppInstallAdView *appInstallAdView = (GADNativeAppInstallAdView *)view;
    if (appInstallAdView.headlineView) [clickableViews addObject:appInstallAdView.headlineView];
    if (appInstallAdView.callToActionView)
      [clickableViews addObject:appInstallAdView.callToActionView];
    if (appInstallAdView.iconView) [clickableViews addObject:appInstallAdView.iconView];
    if (appInstallAdView.bodyView) [clickableViews addObject:appInstallAdView.bodyView];
    if (appInstallAdView.storeView) [clickableViews addObject:appInstallAdView.storeView];
    if (appInstallAdView.priceView) [clickableViews addObject:appInstallAdView.priceView];
    if (appInstallAdView.imageView) [clickableViews addObject:appInstallAdView.imageView];
    if (appInstallAdView.starRatingView) [clickableViews addObject:appInstallAdView.starRatingView];
    if (appInstallAdView.adChoicesView) [clickableViews addObject:appInstallAdView.adChoicesView];
  }
  return clickableViews;
}

@end
