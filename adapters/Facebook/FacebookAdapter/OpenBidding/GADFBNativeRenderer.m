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
@import FBAudienceNetwork;
@import AdSupport;

#import "GADFBError.h"
#import "GADFBExtraAssets.h"
#import "GADFBNetworkExtras.h"
#import "GADMAdapterFacebookConstants.h"
#import "GADMediationAdapterFacebook.h"

static NSString *const GADUnifiedNativeAdIconView = @"3003";

@interface GADFBNativeRenderer () <GADMediationNativeAd, FBNativeAdDelegate, FBMediaViewDelegate> {
  // The completion handler to call when the ad loading succeeds or fails.
  GADMediationNativeLoadCompletionHandler _adLoadCompletionHandler;

  // The Facebook rewarded ad.
  FBNativeAd *_nativeAd;

  // An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationNativeAdEventDelegate> _adEventDelegate;

  ///  A dictionary of asset names and object pairs for assets that are not handled by properties of
  ///  the GADMediatedNativeAd subclass
  NSDictionary *_extraAssets;

  /// Facebook AdOptions view.
  FBAdOptionsView *_adOptionsView;

  /// YES if an impression has been logged.
  BOOL _impressionLogged;

  /// Facebook media view.
  FBMediaView *_mediaView;

  /// Serializes ivar usage.
  dispatch_queue_t _lockQueue;

  BOOL _isRTBRequest;
}

@end

@implementation GADFBNativeRenderer

- (void)renderNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationNativeLoadCompletionHandler)completionHandler {
  // Store the ad config and completion handler for later use.
  _adLoadCompletionHandler = completionHandler;
  if (adConfiguration.bidResponse) {
    _isRTBRequest = YES;
  }
  _lockQueue = dispatch_queue_create("fb-native-ad", DISPATCH_QUEUE_SERIAL);

  NSString *placementID =
      adConfiguration.credentials.settings[kGADMAdapterFacebookOpenBiddingPubID];
  if (!placementID) {
    NSError *error = GADFBErrorWithDescription(@"Placement ID cannot be nil.");
    completionHandler(nil, error);
    return;
  }

  // Create the nativeAd ad.
  _nativeAd = [[FBNativeAd alloc] initWithPlacementID:placementID];
  _nativeAd.delegate = self;

  // Load ad.
  [_nativeAd loadAdWithBidPayload:adConfiguration.bidResponse];
}

- (void)loadAdOptionsView {
  if (!_adOptionsView) {
    _adOptionsView = [[FBAdOptionsView alloc] init];
    _adOptionsView.backgroundColor = [UIColor clearColor];

    NSLayoutConstraint *height =
        [NSLayoutConstraint constraintWithItem:_adOptionsView
                                     attribute:NSLayoutAttributeHeight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:0
                                      constant:FBAdOptionsViewHeight];
    NSLayoutConstraint *width =
        [NSLayoutConstraint constraintWithItem:_adOptionsView
                                     attribute:NSLayoutAttributeWidth
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:0
                                      constant:FBAdOptionsViewWidth];
    [_adOptionsView addConstraint:height];
    [_adOptionsView addConstraint:width];
    [_adOptionsView updateConstraints];
  }
  _adOptionsView.nativeAd = _nativeAd;
}

- (NSString *)advertiser {
  NSString *__block callToAction = nil;
  dispatch_sync(_lockQueue, ^{
    callToAction = [self->_nativeAd.advertiserName copy];
  });
  return callToAction;
}

- (NSString *)body {
  NSString *__block body = nil;
  dispatch_sync(_lockQueue, ^{
    body = [self->_nativeAd.bodyText copy];
  });
  return body;
}

- (NSArray<GADNativeAdImage *> *)images {
  return nil;
}

- (UIView *)mediaView {
  return _mediaView;
}

- (UIView *)adChoicesView {
  return _adOptionsView;
}

- (GADNativeAdImage *)icon {
  GADNativeAdImage *__block icon = nil;
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), NO, 0.0);
  UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  dispatch_sync(_lockQueue, ^{
    icon = [[GADNativeAdImage alloc] initWithImage:blank];
  });
  return icon;
}

- (NSString *)callToAction {
  NSString *__block callToAction = nil;
  dispatch_sync(_lockQueue, ^{
    callToAction = [self->_nativeAd.callToAction copy];
  });
  return callToAction;
}

- (NSDictionary<NSString *, id> *)extraAssets {
  NSDictionary *__block extraAssets = nil;
  dispatch_sync(_lockQueue, ^{
    if (self->_extraAssets) {
      extraAssets = [self->_extraAssets copy];
    } else {
      NSMutableDictionary *mutableExtraAssets = [[NSMutableDictionary alloc] init];
      NSString *socialContext = [self->_nativeAd.socialContext copy];
      if (socialContext) {
        mutableExtraAssets[GADFBSocialContext] = socialContext;
      }

      extraAssets = mutableExtraAssets;
      self->_extraAssets = mutableExtraAssets;
    }
  });
  return extraAssets;
}

- (NSString *)headline {
  NSString *__block headline = nil;
  dispatch_sync(_lockQueue, ^{
    headline = [self->_nativeAd.headline copy];
  });
  return headline;
}

- (NSString *)price {
  return @"";
}

- (NSDecimalNumber *)starRating {
  return 0;
}

- (NSString *)store {
  return @"";
}

- (void)didRenderInView:(UIView *)view
       clickableAssetViews:
           (NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(UIViewController *)viewController {
  NSArray *assets = clickableAssetViews.allValues;
  UIView *iconView;

  if ([view isKindOfClass:[GADUnifiedNativeAdView class]]) {
    iconView = [clickableAssetViews valueForKey:GADUnifiedNativeAdIconView];
  }

  if (assets.count > 0 && iconView) {
    [_nativeAd registerViewForInteraction:view
                                mediaView:_mediaView
                            iconImageView:iconView
                           viewController:viewController
                           clickableViews:assets];
  } else {
    [_nativeAd registerViewForInteraction:view
                                mediaView:_mediaView
                            iconImageView:iconView
                           viewController:viewController];
  }
}

- (void)didUntrackView:(UIView *)view {
  [_nativeAd unregisterView];
}

/// Returns YES if the ad has video content.
/// Because the FAN SDK doesn't offer a way to determine whether a native ad contains a
/// video asset or not, the adapter always returns a MediaView and claims to have video content.
- (BOOL)hasVideoContent {
  return YES;
}

#pragma mark - FBNativeAdDelegate

- (void)nativeAdDidLoad:(FBNativeAd *)nativeAd {
  if (_nativeAd) {
    [_nativeAd unregisterView];
  }
  _nativeAd = nativeAd;
  _mediaView = [[FBMediaView alloc] init];
  _mediaView.delegate = self;
  [self loadAdOptionsView];
  _adEventDelegate = _adLoadCompletionHandler(self, nil);
}

- (void)nativeAdDidClick:(FBNativeAd *)nativeAd {
  if (!_isRTBRequest) {
    [_adEventDelegate reportClick];
  }
}

- (void)nativeAd:(FBNativeAd *)nativeAd didFailWithError:(NSError *)error {
  _adLoadCompletionHandler(nil, error);
}

- (void)nativeAdWillLogImpression:(FBNativeAd *)nativeAd {
  if (_impressionLogged) {
    GADFB_LOG(@"FBNativeAd is trying to log an impression again. Adapter will ignore duplicate "
               "impression pings.");
    return;
  }

  _impressionLogged = YES;
  if (!_isRTBRequest) {
    [_adEventDelegate reportImpression];
  }
}

- (void)nativeAdDidFinishHandlingClick:(FBNativeAd *)nativeAd {
  // Do nothing.
}

- (void)nativeAdDidDownloadMedia:(FBNativeAd *)nativeAd {
  // Do nothing.
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
