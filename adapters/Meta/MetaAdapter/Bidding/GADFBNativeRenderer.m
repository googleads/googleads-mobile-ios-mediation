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

#import "GADFBNativeRenderer.h"
#import <AdSupport/AdSupport.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

#include <stdatomic.h>
#import "GADFBExtraAssets.h"
#import "GADFBNetworkExtras.h"
#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"
#import "GADMediationAdapterFacebook.h"

@interface GADFBNativeRenderer () <GADMediationNativeAd,
                                   FBNativeAdDelegate,
                                   FBNativeBannerAdDelegate,
                                   FBMediaViewDelegate>

@end

@implementation GADFBNativeRenderer {
  // The completion handler to call when the ad loading succeeds or fails.
  GADMediationNativeLoadCompletionHandler _adLoadCompletionHandler;

  // The Meta Audience Network native ad.
  FBNativeAdBase *_nativeAd;

  // An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationNativeAdEventDelegate> _adEventDelegate;

  ///  A dictionary of asset names and object pairs for assets that are not handled by properties of
  ///  the GADMediatedUnifiedNativeAd subclass
  NSDictionary *_extraAssets;

  /// Meta Audience Network AdOptions view.
  FBAdOptionsView *_adOptionsView;

  /// Holds the state for impression being logged.
  atomic_flag _impressionLogged;

  /// Meta Audience Network media view.
  FBMediaView *_mediaView;
}

- (void)renderNativeAdForAdConfiguration:
            (nonnull GADMediationNativeAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
  // Store the ad config and completion handler for later use.
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationNativeLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _adLoadCompletionHandler = ^id<GADMediationNativeAdEventDelegate>(
      _Nullable id<GADMediationNativeAd> ad, NSError *_Nullable error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }
    id<GADMediationNativeAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(ad, error);
    }
    originalCompletionHandler = nil;
    return delegate;
  };

  NSString *placementID = adConfiguration.credentials.settings[GADMAdapterFacebookBiddingPubID];
  if (!placementID) {
    NSError *error =
        GADFBErrorWithCodeAndDescription(GADFBErrorInvalidRequest, @"Placement ID cannot be nil.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  // Create the native ad.
  if (adConfiguration.bidResponse) {
    _nativeAd = [FBNativeAdBase nativeAdWithPlacementId:placementID
                                             bidPayload:adConfiguration.bidResponse
                                                  error:nil];
  } else {
    _nativeAd = [[FBNativeAd alloc] initWithPlacementID:placementID];
  }
  if ([_nativeAd isKindOfClass:[FBNativeAd class]]) {
    ((FBNativeAd *)_nativeAd).delegate = self;
  } else if ([_nativeAd isKindOfClass:[FBNativeBannerAd class]]) {
    ((FBNativeBannerAd *)_nativeAd).delegate = self;
  }

  // Adds a watermark to the ad.
  FBAdExtraHint *watermarkHint = [[FBAdExtraHint alloc] init];
  watermarkHint.mediationData = [adConfiguration.watermark base64EncodedStringWithOptions:0];
  _nativeAd.extraHint = watermarkHint;

  // Load ad.
  [_nativeAd loadAdWithBidPayload:adConfiguration.bidResponse];
}

- (void)loadAdOptionsView {
  if (!_adOptionsView) {
    _adOptionsView = [[FBAdOptionsView alloc] init];
    _adOptionsView.backgroundColor = [UIColor clearColor];
    [NSLayoutConstraint activateConstraints:@[
      [_adOptionsView.heightAnchor constraintEqualToConstant:FBAdOptionsViewHeight],
      [_adOptionsView.widthAnchor constraintEqualToConstant:FBAdOptionsViewWidth],
    ]];
  }
  _adOptionsView.nativeAd = _nativeAd;
}

- (nullable NSString *)advertiser {
  return _nativeAd.advertiserName;
}

- (nullable NSString *)body {
  return _nativeAd.bodyText;
}

- (nullable NSArray<GADNativeAdImage *> *)images {
  return nil;
}

- (nullable UIView *)mediaView {
  return _mediaView;
}

- (nullable UIView *)adChoicesView {
  return _adOptionsView;
}

- (nullable GADNativeAdImage *)icon {
  return [[GADNativeAdImage alloc] initWithImage:_nativeAd.iconImage];
}

- (nullable NSString *)callToAction {
  return _nativeAd.callToAction;
}

- (nullable NSDictionary<NSString *, id> *)extraAssets {
  NSString *socialContext = [_nativeAd.socialContext copy];
  if (socialContext) {
    return @{GADFBSocialContext : socialContext};
  }
  return nil;
}

- (nullable NSString *)headline {
  return _nativeAd.headline;
}

- (nullable NSString *)price {
  return nil;
}

- (nullable NSDecimalNumber *)starRating {
  return nil;
}

- (nullable NSString *)store {
  return nil;
}

- (void)didRenderInView:(UIView *)view
       clickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(UIViewController *)viewController {
  NSArray *assets = clickableAssetViews.allValues;
  UIImageView *iconView = nil;
  if ([clickableAssetViews[GADNativeIconAsset] isKindOfClass:[UIImageView class]]) {
    iconView = (UIImageView *)clickableAssetViews[GADNativeIconAsset];
  }

  if ([_nativeAd isKindOfClass:[FBNativeAd class]]) {
    [(FBNativeAd *)_nativeAd registerViewForInteraction:view
                                              mediaView:_mediaView
                                          iconImageView:iconView
                                         viewController:viewController
                                         clickableViews:assets];
  } else if ([_nativeAd isKindOfClass:[FBNativeBannerAd class]]) {
    [(FBNativeBannerAd *)_nativeAd registerViewForInteraction:view
                                                iconImageView:iconView
                                               viewController:viewController
                                               clickableViews:assets];
  }
}

- (void)didUntrackView:(UIView *)view {
  [_nativeAd unregisterView];
}

/// Returns YES if the ad has video content.
/// Because the Meta Audience Network SDK doesn't offer a way to determine whether a native ad
/// contains a video asset or not, the adapter always returns a MediaView and claims to have video
/// content.
- (BOOL)hasVideoContent {
  return YES;
}

#pragma mark - FBNativeAdDelegate

- (void)nativeAdDidLoad:(FBNativeAd *)nativeAd {
  [self nativeAdBaseDidLoad:nativeAd];
}

- (void)nativeAdDidClick:(FBNativeAd *)nativeAd {
  [self nativeAdBaseDidClick:nativeAd];
}

- (void)nativeAd:(FBNativeAd *)nativeAd didFailWithError:(NSError *)error {
  [self nativeAdBase:nativeAd didFailWithError:error];
}

- (void)nativeAdWillLogImpression:(FBNativeAd *)nativeAd {
  [self nativeAdBaseWillLogImpression:nativeAd];
}

- (void)nativeAdDidFinishHandlingClick:(FBNativeAd *)nativeAd {
  // Do nothing.
}

- (void)nativeAdDidDownloadMedia:(FBNativeAd *)nativeAd {
  // Do nothing.
}

#pragma mark - FBNativeBannerAdDelegate

- (void)nativeBannerAdDidLoad:(FBNativeBannerAd *)nativeBannerAd {
  [self nativeAdBaseDidLoad:nativeBannerAd];
}

- (void)nativeBannerAdDidClick:(FBNativeBannerAd *)nativeBannerAd {
  [self nativeAdBaseDidClick:nativeBannerAd];
}

- (void)nativeBannerAd:(FBNativeBannerAd *)nativeBannerAd didFailWithError:(NSError *)error {
  [self nativeAdBase:nativeBannerAd didFailWithError:error];
}

- (void)nativeBannerAdWillLogImpression:(FBNativeBannerAd *)nativeBannerAd {
  [self nativeAdBaseWillLogImpression:nativeBannerAd];
}

#pragma mark - Common delegate methods

- (void)nativeAdBaseDidLoad:(FBNativeAdBase *)nativeAd {
  if (_nativeAd) {
    [_nativeAd unregisterView];
  }
  _nativeAd = nativeAd;
  if ([nativeAd isKindOfClass:[FBNativeAd class]]) {
    _mediaView = [[FBMediaView alloc] init];
    _mediaView.delegate = self;
  }
  [self loadAdOptionsView];
  _adEventDelegate = _adLoadCompletionHandler(self, nil);
}

- (void)nativeAdBaseDidClick:(FBNativeAdBase *)nativeAd {
  [_adEventDelegate reportClick];
}

- (void)nativeAdBase:(FBNativeAdBase *)nativeAd didFailWithError:(NSError *)error {
  _adLoadCompletionHandler(nil, error);
}

- (void)nativeAdBaseWillLogImpression:(FBNativeAdBase *)nativeAd {
  if (atomic_flag_test_and_set(&_impressionLogged)) {
    GADFB_LOG(@"FBNativeAd is trying to log an impression again. Adapter will ignore "
              @"duplicate impression pings.");
    return;
  }
  [_adEventDelegate reportImpression];
}

#pragma mark - FBMediaViewDelegate

- (void)mediaViewVideoDidComplete:(FBMediaView *)mediaView {
  [_adEventDelegate didEndVideo];
}

- (void)mediaViewVideoDidPlay:(FBMediaView *)mediaView {
  [_adEventDelegate didPlayVideo];
}

- (void)mediaViewVideoDidPause:(FBMediaView *)mediaView {
  [_adEventDelegate didPauseVideo];
}

- (void)mediaViewWillEnterFullscreen:(FBMediaView *)mediaView {
  [_adEventDelegate willPresentFullScreenView];
}

- (void)mediaViewDidExitFullscreen:(FBMediaView *)mediaView {
  [_adEventDelegate didDismissFullScreenView];
}

- (void)mediaView:(FBMediaView *)mediaView videoVolumeDidChange:(float)volume {
  // Do nothing.
}

- (void)mediaViewDidLoad:(FBMediaView *)mediaView {
  // Do nothing.
}

@end
