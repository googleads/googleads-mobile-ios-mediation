// Copyright 2019 Google Inc.
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

#import "GADFBUnifiedNativeAd.h"

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#include <stdatomic.h>
#import "GADFBAdapterDelegate.h"
#import "GADFBExtraAssets.h"
#import "GADFBNetworkExtras.h"
#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"
#import "GADMediationAdapterFacebook.h"

@interface GADFBUnifiedNativeAd () <GADMediatedUnifiedNativeAd,
                                    FBNativeAdDelegate,
                                    FBMediaViewDelegate>

@end

@implementation GADFBUnifiedNativeAd {
  /// Connector from the Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// Native ad obtained from Facebook's Audience Network.
  FBNativeAd *_nativeAd;

  ///  A dictionary of asset names and object pairs for assets that are not handled by properties of
  ///  the GADMediatedUnifiedNativeAd subclass
  NSDictionary<NSString *, id> *_extraAssets;

  /// Holds the state for impression being logged.
  atomic_flag _impressionLogged;

  /// Facebook media view.
  FBMediaView *_mediaView;
}

/// Empty method to bypass Apple's private method checking since
/// GADMediatedUnifiedNativeAdNotificationSource's mediatedNativeAdDidRecordImpression method is
/// dynamically called by this class's instances.
+ (void)mediatedNativeAdDidRecordImpression:(id<GADMediatedNativeAd>)mediatedNativeAd {
}

- (instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                       adapter:(nonnull id<GADMAdNetworkAdapter>)adapter {
  self = [super initWithGADMAdNetworkConnector:connector adapter:adapter];
  if (self) {
    _adapter = adapter;
    _connector = connector;
  }
  return self;
}

- (void)requestNativeAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;

  if (!strongConnector || !strongAdapter) {
    return;
  }

  // -[FBNativeAd initWithPlacementID:] throws an NSInvalidArgumentException if the placement ID is
  // nil.
  NSString *placementID = [strongConnector publisherId];
  if (!placementID) {
    NSError *error = GADFBErrorWithDescription(@"Placement ID cannot be nil.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  GADFBConfigureMediationService();

  _nativeAd = [[FBNativeAd alloc] initWithPlacementID:placementID];

  if (!_nativeAd) {
    NSString *description = [[NSString alloc]
        initWithFormat:@"Failed to initialize %@.", NSStringFromClass([FBNativeAd class])];
    NSError *error = GADFBErrorWithDescription(description);
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }
  _nativeAd.delegate = self;
  [_nativeAd loadAd];
}

- (void)stopBeingDelegate {
  _nativeAd.delegate = nil;
  _mediaView.delegate = nil;
}

- (nullable NSDictionary *)extraAssets {
  NSString *socialContext = [_nativeAd.socialContext copy];
  if (socialContext) {
    return @{GADFBSocialContext : socialContext};
  }
  return nil;
}

- (nullable NSString *)headline {
  return _nativeAd.headline;
}

- (nullable NSString *)advertiser {
  return _nativeAd.advertiserName;
}

- (nullable NSString *)body {
  return _nativeAd.bodyText;
}

- (nullable NSString *)callToAction {
  return _nativeAd.callToAction;
}

/// Media view.
- (nullable UIView *)mediaView {
  return _mediaView;
}

/// Returns YES if the ad has video content.
/// Because the Facebook Audience Network SDK doesn't offer a way to determine whether a native ad
/// contains a video asset or not, the adapter always returns a MediaView and claims to have video
/// content.
- (BOOL)hasVideoContent {
  return YES;
}

#pragma mark - GADMediatedUnifiedNativeAd

- (void)didRenderInView:(UIView *)view
       clickableAssetViews:
           (NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(UIViewController *)viewController {
  NSArray *assets = clickableAssetViews.allValues;
  UIImageView *iconView = nil;
  if ([clickableAssetViews[GADUnifiedNativeIconAsset] isKindOfClass:[UIImageView class]]) {
    iconView = (UIImageView *)clickableAssetViews[GADUnifiedNativeIconAsset];
  }

  [_nativeAd registerViewForInteraction:view
                              mediaView:_mediaView
                          iconImageView:iconView
                         viewController:viewController
                         clickableViews:assets];
}

- (void)didUntrackView:(UIView *)view {
  [_nativeAd unregisterView];
}

#pragma mark - FBNativeAdDelegate

- (void)nativeAdDidLoad:(nonnull FBNativeAd *)nativeAd {
  if (_nativeAd) {
    [_nativeAd unregisterView];
  }
  _nativeAd = nativeAd;
  _mediaView = [[FBMediaView alloc] init];
  _mediaView.delegate = self;
  [self loadAdOptionsView];
  self.adOptionsView.nativeAd = _nativeAd;
  id<GADMAdNetworkAdapter> strongAdapter = self->_adapter;
  id<GADMAdNetworkConnector> strongConnector = self->_connector;
  [strongConnector adapter:strongAdapter didReceiveMediatedUnifiedNativeAd:self];
}

- (void)nativeAdWillLogImpression:(nonnull FBNativeAd *)nativeAd {
  if (atomic_flag_test_and_set(&_impressionLogged)) {
    GADFB_LOG(@"FBNativeAd is trying to log an impression again. Adapter will ignore "
              @"duplicate impression pings.");
    return;
  }
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordImpression:self];
}

- (void)nativeAd:(nonnull FBNativeAd *)nativeAd didFailWithError:(nonnull NSError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  [strongConnector adapter:strongAdapter didFailAd:error];
}

- (void)nativeAdDidClick:(nonnull FBNativeAd *)nativeAd {
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordClick:self];
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillLeaveApplication:self];
}

- (void)nativeAdDidFinishHandlingClick:(nonnull FBNativeAd *)nativeAd {
  // Do nothing.
}

#pragma mark - FBMediaViewDelegate

- (void)mediaViewVideoDidComplete:(nonnull FBMediaView *)mediaView {
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidEndVideoPlayback:self];
}

- (void)mediaViewVideoDidPlay:(nonnull FBMediaView *)mediaView {
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidPlayVideo:self];
}

- (void)mediaViewVideoDidPause:(nonnull FBMediaView *)mediaView {
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidPauseVideo:self];
}

- (void)mediaViewDidLoad:(nonnull FBMediaView *)mediaView {
  // Do nothing.
}

@end
