// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterMintegralRTBNativeAdLoader.h"
#import "GADMAdapterMintegralExtras.h"
#import "GADMAdapterMintegralUtils.h"
#import "GADMediationAdapterMintegralConstants.h"

#import <MTGSDK/MTGBidNativeAdManager.h>
#import <MTGSDK/MTGSDK.h>
#include <stdatomic.h>

@interface GADMAdapterMintegralRTBNativeAdLoader () <MTGBidNativeAdManagerDelegate,
                                                     MTGMediaViewDelegate>

@end

@implementation GADMAdapterMintegralRTBNativeAdLoader {
  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationNativeLoadCompletionHandler _adLoadCompletionHandler;

  /// Ad configuration for the ad to be loaded.
  GADMediationNativeAdConfiguration *_adConfiguration;

  /// The Mintegral native ad.
  MTGBidNativeAdManager *_nativeManager;

  /// The Mintegral media view.
  MTGMediaView *_mediaView;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  id<GADMediationNativeAdEventDelegate> _adEventDelegate;

  /// The Mintegral ad unit ID.
  NSString *_adUnitId;

  /// The Mintegral native ad data.
  MTGCampaign *_campaign;

  /// Icon image.
  GADNativeAdImage *_icon;

  /// Array of GADNativeAdImage objects.
  NSArray<GADNativeAdImage *> *_images;

  /// The Mintegral ad choices view.
  MTGAdChoicesView *_adChoicesView;
}

- (void)loadRTBNativeAdForAdConfiguration:
            (nonnull GADMediationNativeAdConfiguration *)adConfiguration
                        completionHandler:
                            (nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
  _adConfiguration = adConfiguration;
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

  UIViewController *rootViewController = adConfiguration.topViewController;
  NSString *adUnitId = adConfiguration.credentials.settings[GADMAdapterMintegralAdUnitID];
  NSString *placementId = adConfiguration.credentials.settings[GADMAdapterMintegralPlacementID];
  if (!adUnitId.length || !placementId.length) {
    NSError *error = GADMAdapterMintegralErrorWithCodeAndDescription(
        GADMintegralErrorInvalidServerParameters, @"Ad Unit ID or Placement ID cannot be nil.");
    _adLoadCompletionHandler(nil, error);
    return;
  }
  _adUnitId = adUnitId;
  _nativeManager = [[MTGBidNativeAdManager alloc] initWithPlacementId:placementId
                                                               unitID:adUnitId
                                             presentingViewController:rootViewController];
  _nativeManager.delegate = self;
  [_nativeManager loadWithBidToken:adConfiguration.bidResponse];
}

- (MTGMediaView *)createMediaView {
  if (_mediaView) {
    return _mediaView;
  }
  _mediaView = [[MTGMediaView alloc] initWithFrame:CGRectZero];
  _mediaView.delegate = self;
  return _mediaView;
}

- (MTGAdChoicesView *)createAdChoicesView {
  if (_adChoicesView) {
    return _adChoicesView;
  }
  _adChoicesView = [[MTGAdChoicesView alloc] initWithFrame:CGRectZero];
  return _adChoicesView;
}

#pragma mark - MTGBidNativeAdManagerDelegate
- (void)nativeAdsLoaded:(nullable NSArray *)nativeAds
       bidNativeManager:(nonnull MTGBidNativeAdManager *)bidNativeManager {
  if ([nativeAds isKindOfClass:NSArray.class] && nativeAds.count > 0) {
    _campaign = nativeAds.firstObject;

    MTGMediaView *mediaView = [self createMediaView];
    GADMAdapterMintegralExtras *extras = _adConfiguration.extras;
    if (extras) {
      mediaView.mute = extras.muteVideoAudio;
    }

    MTGAdChoicesView *adChoicesView = [self createAdChoicesView];
    adChoicesView.campaign = _campaign;

    [self loadRequiredNativeData];
  } else {
    NSError *error = GADMAdapterMintegralErrorWithCodeAndDescription(
        GADMintegralErrorAdNotAvailable, @"Mintegral SDK failed to return a bidding native ad.");
    if (_adLoadCompletionHandler) {
      _adLoadCompletionHandler(nil, error);
    }
  }
}

- (void)nativeAdsFailedToLoadWithError:(nonnull NSError *)error
                      bidNativeManager:(nonnull MTGBidNativeAdManager *)bidNativeManager {
  if (_adLoadCompletionHandler) {
    _adLoadCompletionHandler(nil, error);
  }
}

- (void)nativeAdDidClick:(nonnull MTGCampaign *)nativeAd
        bidNativeManager:(nonnull MTGBidNativeAdManager *)bidNativeManager {
  [_adEventDelegate reportClick];
}

- (void)nativeAdImpressionWithType:(MTGAdSourceType)type
                  bidNativeManager:(nonnull MTGBidNativeAdManager *)bidNativeManager {
  [_adEventDelegate reportImpression];
}

#pragma mark - MTGMediaViewDelegate
- (void)MTGMediaViewWillEnterFullscreen:(MTGMediaView *)mediaView {
  [_adEventDelegate willPresentFullScreenView];
}

- (void)MTGMediaViewDidExitFullscreen:(MTGMediaView *)mediaView {
  [_adEventDelegate didDismissFullScreenView];
}

- (void)MTGMediaViewVideoDidStart:(MTGMediaView *)mediaView {
  [_adEventDelegate didPlayVideo];
}

- (void)MTGMediaViewVideoPlayCompleted:(MTGMediaView *)mediaView {
  [_adEventDelegate didEndVideo];
}

- (void)nativeAdDidClick:(nonnull MTGCampaign *)nativeAd mediaView:(MTGMediaView *)mediaView {
  [_adEventDelegate reportClick];
}

- (void)nativeAdImpressionWithType:(MTGAdSourceType)type mediaView:(MTGMediaView *)mediaView {
  [_adEventDelegate reportImpression];
}

#pragma mark - GADMediatedUnifiedNativeAd
- (NSString *)headline {
  return _campaign.appName;
}

- (NSArray *)images {
  return nil;
}

- (NSString *)body {
  return _campaign.appDesc;
}

- (GADNativeAdImage *)icon {
  return _icon;
}

- (NSString *)callToAction {
  return _campaign.adCall;
}

- (NSDecimalNumber *)starRating {
  NSString *star = [NSString stringWithFormat:@"%@", [_campaign valueForKey:@"star"]];
  return [NSDecimalNumber decimalNumberWithString:star];
}

- (NSString *)store {
  return nil;
}

- (NSString *)price {
  return nil;
}

- (NSString *)advertiser {
  return nil;
}

- (NSDictionary *)extraAssets {
  return nil;
}

- (BOOL)hasVideoContent {
  return YES;
}

- (UIView *)mediaView {
  [_mediaView setMediaSourceWithCampaign:_campaign unitId:_adUnitId];
  return _mediaView;
}

- (UIView *)adChoicesView {
  return _adChoicesView;
}

#pragma mark - GADMediationNativeAd
- (BOOL)handlesUserClicks {
  return YES;
}

- (BOOL)handlesUserImpressions {
  return YES;
}

#pragma mark - GADMediatedUnifiedNativeAd
- (void)didRenderInView:(UIView *)view
       clickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(UIViewController *)viewController {
  [_nativeManager registerViewForInteraction:view
                          withClickableViews:clickableAssetViews.allValues
                                withCampaign:_campaign];
}

- (void)loadRequiredNativeData {
  GADMAdapterMintegralRTBNativeAdLoader *__weak weakSelf = self;
  [GADMAdapterMintegralUtils
      downLoadNativeAdImageWithURLString:_campaign.iconUrl
                       completionHandler:^(GADNativeAdImage *_Nullable nativeAdImage) {
                         GADMAdapterMintegralRTBNativeAdLoader *strongSelf = weakSelf;
                         if (!strongSelf) {
                           return;
                         }
                         strongSelf->_icon = nativeAdImage;

                         if (strongSelf && strongSelf->_adLoadCompletionHandler) {
                           strongSelf->_adEventDelegate =
                               strongSelf->_adLoadCompletionHandler(strongSelf, nil);
                         }
                       }];
}
@end
