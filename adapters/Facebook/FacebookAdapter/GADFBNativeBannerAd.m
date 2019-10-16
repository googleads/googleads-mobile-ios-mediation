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

#import "GADFBNativeBannerAd.h"
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#include <stdatomic.h>
#import "GADFBExtraAssets.h"
#import "GADFBNetworkExtras.h"
#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"
#import "GADMediationAdapterFacebook.h"

@interface GADFBNativeBannerAd () <GADMediatedUnifiedNativeAd, FBNativeBannerAdDelegate>

@end

@implementation GADFBNativeBannerAd {
  /// Connector from the Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// Native banner ad obtained from Facebook's Audience Network.
  FBNativeBannerAd *_nativeBannerAd;

  /// A dictionary of asset names and object pairs for assets that are not handled by properties of
  /// the GADMediatedUnifiedNativeAd subclass
  NSDictionary<NSString *, id> *_extraAssets;

  /// Holds the state for impression being logged.
  atomic_flag _impressionLogged;
}

/// Empty method to bypass Apple's private method checking since
/// GADMediatedUnifiedNativeAdNotificationSource's mediatedNativeAdDidRecordImpression method is
/// dynamically called by this class's instances.
+ (void)mediatedNativeAdDidRecordImpression:(id<GADMediatedNativeAd>)mediatedNativeAd {
}

- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                               adapter:(nonnull id<GADMAdNetworkAdapter>)adapter {
  self = [super initWithGADMAdNetworkConnector:connector adapter:adapter];
  if (self) {
    _adapter = adapter;
    _connector = connector;
  }
  return self;
}

- (void)requestNativeBannerAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;

  if (!strongConnector || !strongAdapter) {
    return;
  }

  // -[FBNativeBannerAd initWithPlacementID:] throws an NSInvalidArgumentException if the placement
  // ID is nil.
  NSString *placementID = [strongConnector publisherId];
  if (!placementID) {
    NSError *error = GADFBErrorWithDescription(@"Placement ID cannot be nil.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  GADFBConfigureMediationService();

  _nativeBannerAd = [[FBNativeBannerAd alloc] initWithPlacementID:placementID];

  if (!_nativeBannerAd) {
    NSString *description = [[NSString alloc]
        initWithFormat:@"Failed to initialize %@.", NSStringFromClass([FBNativeBannerAd class])];
    NSError *error = GADFBErrorWithDescription(description);
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  _nativeBannerAd.delegate = self;
  [_nativeBannerAd loadAd];
}

- (void)stopBeingDelegate {
  _nativeBannerAd.delegate = nil;
}

- (nullable NSDictionary<NSString *, id> *)extraAssets {
  NSString *socialContext = [_nativeBannerAd.socialContext copy];
  if (socialContext) {
    return @{GADFBSocialContext : socialContext};
  }
  return nil;
}

- (nullable NSString *)headline {
  return _nativeBannerAd.headline;
}

- (nullable NSString *)advertiser {
  return _nativeBannerAd.advertiserName;
}

- (nullable NSString *)body {
  return _nativeBannerAd.bodyText;
}

- (nullable NSString *)callToAction {
  return _nativeBannerAd.callToAction;
}

/// Media view.
- (nullable UIView *)mediaView {
  return nil;
}

- (BOOL)hasVideoContent {
  return NO;
}

- (CGFloat)mediaContentAspectRatio {
  return 0.0f;
}

#pragma mark - GADMediatedUnifiedNativeAd

- (void)didRenderInView:(UIView *)view
       clickableAssetViews:
           (NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(UIViewController *)viewController {
  NSArray<UIView *> *assets = clickableAssetViews.allValues;
  UIImageView *iconView = nil;
  if ([clickableAssetViews[GADUnifiedNativeIconAsset] isKindOfClass:[UIImageView class]]) {
    iconView = (UIImageView *)clickableAssetViews[GADUnifiedNativeIconAsset];
  }

  [_nativeBannerAd registerViewForInteraction:view
                                iconImageView:iconView
                               viewController:viewController
                               clickableViews:assets];
}

- (void)didUntrackView:(UIView *)view {
  [_nativeBannerAd unregisterView];
}

#pragma mark - FBNativeBannerAdDelegate

- (void)nativeBannerAdDidLoad:(nonnull FBNativeBannerAd *)nativeBannerAd {
  [self loadAdOptionsView];
  self.adOptionsView.nativeAd = _nativeBannerAd;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  id<GADMAdNetworkConnector> strongConnector = _connector;
  [strongConnector adapter:strongAdapter didReceiveMediatedUnifiedNativeAd:self];
}

- (void)nativeBannerAdWillLogImpression:(nonnull FBNativeBannerAd *)nativeBannerAd {
  if (atomic_flag_test_and_set(&_impressionLogged)) {
    GADFB_LOG(@"FBNativeBannerAd is trying to log an impression again. Adapter will ignore "
              @"duplicate impression pings.");
    return;
  }

  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordImpression:self];
}

- (void)nativeBannerAd:(nonnull FBNativeBannerAd *)nativeBannerAd
      didFailWithError:(nonnull NSError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  [strongConnector adapter:strongAdapter didFailAd:error];
}

- (void)nativeBannerAdDidClick:(nonnull FBNativeBannerAd *)nativeBannerAd {
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordClick:self];
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillLeaveApplication:self];
}

- (void)nativeBannerAdDidFinishHandlingClick:(nonnull FBNativeBannerAd *)nativeBannerAd {
  // Do nothing.
}

@end
