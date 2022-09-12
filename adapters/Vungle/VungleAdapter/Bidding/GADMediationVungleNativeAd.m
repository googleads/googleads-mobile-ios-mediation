// Copyright 2021 Google LLC
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

#import "GADMediationVungleNativeAd.h"
#import <VungleSDK/VungleNativeAd.h>
#include <stdatomic.h>
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"

@interface GADMediationVungleNativeAd () <GADMediationNativeAd,
                                          VungleNativeAdDelegate,
                                          GADMAdapterVungleDelegate>

@end

@implementation GADMediationVungleNativeAd {
  /// Ad configuration for the ad to be loaded.
  GADMediationNativeAdConfiguration *_adConfiguration;

  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationNativeLoadCompletionHandler _adLoadCompletionHandler;

  /// The Vungle native ad.
  VungleNativeAd *_nativeAd;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  id<GADMediationNativeAdEventDelegate> _delegate;

  /// The Vungle container to display the media (image/video).
  VungleMediaView *_mediaView;
}

@synthesize desiredPlacement;
@synthesize isAdLoaded;

- (nonnull instancetype)
    initNativeAdForAdConfiguration:(nonnull GADMediationNativeAdConfiguration *)adConfiguration
                 completionHandler:
                     (nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;

    // Store the ad config and completion handler for later use.
    __block atomic_flag adLoadHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationNativeLoadCompletionHandler originalCompletionHandler =
        [completionHandler copy];

    // Ensure the original completion handler is only called once, and is deallocated once called.
    _adLoadCompletionHandler = ^id<GADMediationNativeAdEventDelegate>(
        _Nullable id<GADMediationNativeAd> ad, NSError *_Nullable error) {
      if (atomic_flag_test_and_set(&adLoadHandlerCalled)) {
        return nil;
      }
      id<GADMediationNativeAdEventDelegate> delegate = nil;
      if (originalCompletionHandler) {
        delegate = originalCompletionHandler(ad, error);
      }
      originalCompletionHandler = nil;
      return delegate;
    };
  }
  return self;
}

- (void)requestNativeAd {
  self.desiredPlacement =
      [GADMAdapterVungleUtils findPlacement:_adConfiguration.credentials.settings
                              networkExtras:_adConfiguration.extras];
  if (!self.desiredPlacement) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        GADMAdapterVungleErrorInvalidServerParameters, @"Placement ID not specified.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  if (![[VungleSDK sharedSDK] isInitialized]) {
    NSString *appID = [GADMAdapterVungleUtils findAppID:_adConfiguration.credentials.settings];
    [[GADMAdapterVungleRouter sharedInstance] initWithAppId:appID delegate:self];
    return;
  }

  [self loadAd];
}

- (void)loadAd {
  _nativeAd = [[VungleNativeAd alloc] initWithPlacementID:self.desiredPlacement];
  _nativeAd.delegate = self;
  VungleAdNetworkExtras *networkExtras = _adConfiguration.extras;
  switch (networkExtras.nativeAdOptionPosition) {
    case 1:
      _nativeAd.adOptionsPosition = NativeAdOptionsPositionTopLeft;
      break;
    case 2:
      _nativeAd.adOptionsPosition = NativeAdOptionsPositionTopRight;
      break;
    case 3:
      _nativeAd.adOptionsPosition = NativeAdOptionsPositionBottomLeft;
      break;
    case 4:
      _nativeAd.adOptionsPosition = NativeAdOptionsPositionBottomRight;
      break;
    default:
      _nativeAd.adOptionsPosition = NativeAdOptionsPositionTopRight;
      break;
  }
  [_nativeAd loadAdWithAdMarkup:[self bidResponse]];
}

#pragma mark - GADMediatedUnifiedNativeAd

- (nullable NSString *)headline {
  return _nativeAd.title;
}

- (nullable NSArray<GADNativeAdImage *> *)images {
  return nil;
}

- (nullable NSString *)body {
  return _nativeAd.bodyText;
}

- (nullable GADNativeAdImage *)icon {
  if (_nativeAd.iconImage) {
    return [[GADNativeAdImage alloc] initWithImage:_nativeAd.iconImage];
  }
  return nil;
}

- (nullable NSString *)callToAction {
  return _nativeAd.callToAction;
}

- (nullable NSDecimalNumber *)starRating {
  return [[NSDecimalNumber alloc] initWithDouble:_nativeAd.adStarRating];
}

- (nullable NSString *)store {
  return nil;
}

- (nullable NSString *)price {
  return nil;
}

- (nullable NSString *)advertiser {
  return _nativeAd.sponsoredText;
}

- (nullable NSDictionary<NSString *, id> *)extraAssets {
  return nil;
}

- (nullable UIView *)adChoicesView {
  return nil;
}

- (nullable UIView *)mediaView {
  return _mediaView;
}

- (BOOL)hasVideoContent {
  // Vungle requires to return YES for both video and non-video content to render the media view.
  return YES;
}

- (void)didRenderInView:(nonnull UIView *)view
       clickableAssetViews:
           (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(nonnull UIViewController *)viewController {
  NSArray<UIView *> *assets = clickableAssetViews.allValues;
  UIImageView *iconView = nil;
  if ([clickableAssetViews[GADNativeIconAsset] isKindOfClass:[UIImageView class]]) {
    iconView = (UIImageView *)clickableAssetViews[GADNativeIconAsset];
  }

  [_nativeAd registerViewForInteraction:view
                              mediaView:_mediaView
                          iconImageView:iconView
                         viewController:viewController
                         clickableViews:assets];
}

- (void)didUntrackView:(nullable UIView *)view {
  [_nativeAd unregisterView];
}

- (BOOL)handlesUserClicks {
  return YES;
}

- (BOOL)handlesUserImpressions {
  return YES;
}

#pragma mark - VungleNativeAdDelegate

- (void)nativeAdDidLoad:(VungleNativeAd *)nativeAd {
  if (_delegate) {
    // Already invoked an ad load callback.
    return;
  }

  _mediaView = [[VungleMediaView alloc] init];
  _delegate = _adLoadCompletionHandler(self, nil);
}

- (void)nativeAd:(VungleNativeAd *)nativeAd didFailWithError:(NSError *)error {
  _adLoadCompletionHandler(nil, error);
}

- (void)nativeAdDidClick:(VungleNativeAd *)nativeAd {
  [_delegate reportClick];
}

- (void)nativeAdDidTrackImpression:(VungleNativeAd *)nativeAd {
  [_delegate reportImpression];
}

#pragma mark - GADMAdapterVungleDelegate

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error {
  if (isSuccess) {
    [self loadAd];
  } else {
    _adLoadCompletionHandler(nil, error);
  }
}

- (void)adAvailable {
  // No-op, Vungle native ads utilize callbacks from VungleNativeAdDelegate.
}

- (void)adNotAvailable:(nonnull NSError *)error {
  // No-op, Vungle native ads utilize callbacks from VungleNativeAdDelegate.
}

- (void)willShowAd {
  // No-op, Vungle native ads utilize callbacks from VungleNativeAdDelegate.
}

- (void)didShowAd {
  // No-op, Vungle native ads utilize callbacks from VungleNativeAdDelegate.
}

- (void)didViewAd {
  // No-op, Vungle native ads utilize callbacks from VungleNativeAdDelegate.
}

- (void)rewardUser {
  // No-op, Vungle native ads utilize callbacks from VungleNativeAdDelegate.
}

- (void)trackClick {
  // No-op, Vungle native ads utilize callbacks from VungleNativeAdDelegate.
}

- (void)willCloseAd {
  // No-op, Vungle native ads utilize callbacks from VungleNativeAdDelegate.
}

- (void)didCloseAd {
  // No-op, Vungle native ads utilize callbacks from VungleNativeAdDelegate.
}

- (void)willLeaveApplication {
  // No-op, Vungle native ads utilize callbacks from VungleNativeAdDelegate.
}

- (nullable NSString *)bidResponse {
  return _adConfiguration.bidResponse;
}

@end
