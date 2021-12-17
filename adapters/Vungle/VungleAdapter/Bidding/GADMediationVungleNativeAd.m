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
#include <stdatomic.h>
#import "GADMAdapterVungleUtils.h"
#import "GADMAdapterVungleRouter.h"
#import <VungleSDK/VungleNativeAd.h>

@interface GADMediationVungleNativeAd () <GADMediationNativeAd, VungleNativeAdDelegate, GADMAdapterVungleDelegate>

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
    
  VungleMediaView *_mediaView;
}

@synthesize desiredPlacement;

- (nonnull instancetype)initNativeAdForAdConfiguration:(nonnull GADMediationNativeAdConfiguration *)adConfiguration
                                     completionHandler:(nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;

    // Store the ad config and completion handler for later use.
    __block atomic_flag adLoadHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationNativeLoadCompletionHandler originalCompletionHandler = [completionHandler copy];

    // Ensure the original completion handler is only called once, and is deallocated once called.
    _adLoadCompletionHandler = ^id<GADMediationNativeAdEventDelegate>(_Nullable id<GADMediationNativeAd> ad, NSError *_Nullable error) {
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

- (void)requestAd {
  self.desiredPlacement = [GADMAdapterVungleUtils findPlacement:_adConfiguration.credentials.settings
                                                  networkExtras:_adConfiguration.extras];
  if (!self.desiredPlacement) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(GADMAdapterVungleErrorInvalidServerParameters, @"Placement ID not specified.");
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
  [_nativeAd loadAd];
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
    return [[GADNativeAdImage alloc] initWithImage:_nativeAd.iconImage];
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
  return nil;
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
  return YES;
}

- (void)didRenderInView:(nonnull UIView *)view
    clickableAssetViews:(nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
 nonclickableAssetViews:(nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
         viewController:(nonnull UIViewController *)viewController {
  NSArray<UIView *> *assets = clickableAssetViews.allValues;
  UIImageView *iconView = nil;
  if ([clickableAssetViews[GADNativeIconAsset] isKindOfClass:[UIImageView class]]) {
    iconView = (UIImageView *)clickableAssetViews[GADNativeIconAsset];
  }
    
  [_nativeAd registerViewForInteraction:view mediaView:_mediaView iconImageView:iconView viewController:viewController clickableViews:assets];
}

- (void)didUntrackView:(nullable UIView *)view {
  [_nativeAd unregisterView];
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
    // Native ads are object based. Don't need the Router to manage the delegates except for lazy initialization
    GADMediationVungleNativeAd __weak *weakSelf = self;
    [[GADMAdapterVungleRouter sharedInstance] removeDelegate:weakSelf];
    [self loadAd];
  } else {
    _adLoadCompletionHandler(nil, error);
  }
}

- (void)adAvailable {
    // Do nothing. Native ads utilize a different set of callbacks.
}

- (void)adNotAvailable:(nonnull NSError *)error {
    // Do nothing. Native ads utilize a different set of callbacks.
}

- (void)didCloseAd {
    // Do nothing. Native ads utilize a different set of callbacks.
}

- (void)didViewAd {
    // Do nothing. Native ads utilize a different set of callbacks.
}

- (void)rewardUser {
    // Do nothing. Native ads utilize a different set of callbacks.
}

- (void)trackClick {
    // Do nothing. Native ads utilize a different set of callbacks.
}

- (void)willCloseAd {
    // Do nothing. Native ads utilize a different set of callbacks.
}

- (void)willLeaveApplication {
    // Do nothing. Native ads utilize a different set of callbacks.
}

- (void)willShowAd {
    // Do nothing. Native ads utilize a different set of callbacks.
}

@end
