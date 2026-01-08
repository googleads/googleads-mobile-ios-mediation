// Copyright 2015 Google LLC
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
//

#import "GADMAdapterInMobiUnifiedNativeAd.h"

#import <Foundation/Foundation.h>
#include <stdatomic.h>

#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiInitializer.h"
#import "GADMAdapterInMobiUtils.h"
#import "GADMediationAdapterInMobi.h"
#import "NativeAdKeys.h"

static CGFloat const DefaultIconScale = 1.0;

@interface GADMAdapterInMobiUnifiedNativeAd () <IMNativeDelegate>
@end

@implementation GADMAdapterInMobiUnifiedNativeAd {
  /// An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationNativeAdEventDelegate> _nativeAdEventDelegate;

  /// Ad Configuration for the native ad to be rendered.
  GADMediationNativeAdConfiguration *_nativeAdConfig;

  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationNativeLoadCompletionHandler _nativeRenderCompletionHandler;

  /// InMobi native ad object.
  IMNative *_native;
}

- (nonnull instancetype)init {
  return self;
}


- (void)loadNativeAdForAdConfiguration:(nonnull GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:
                         (nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
  _nativeAdConfig = adConfiguration;
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationNativeLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _nativeRenderCompletionHandler =
      ^id<GADMediationNativeAdEventDelegate>(id<GADMediationNativeAd> nativeAd, NSError *error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }
    id<GADMediationNativeAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(nativeAd, error);
    }
    originalCompletionHandler = nil;
    return delegate;
  };

  GADMAdapterInMobiUnifiedNativeAd *__weak weakSelf = self;
  NSString *accountID = _nativeAdConfig.credentials.settings[GADMAdapterInMobiAccountID];
  [GADMAdapterInMobiInitializer.sharedInstance
      initializeWithAccountID:accountID
            completionHandler:^(NSError *_Nullable error) {
              GADMAdapterInMobiUnifiedNativeAd *strongSelf = weakSelf;
              if (!strongSelf) {
                return;
              }

              if (error) {
                GADMAdapterInMobiLog(@"InMobi SDK failed to initialize with error: %@",
                                     error.localizedDescription);
                strongSelf->_nativeRenderCompletionHandler(nil, error);
                return;
              }

              [strongSelf requestNativeAd];
            }];
}

- (void)requestNativeAd {
  long long placementId =
      [_nativeAdConfig.credentials.settings[GADMAdapterInMobiPlacementID] longLongValue];
  // Skip the placement ID checking for bidding.
  if (!_nativeAdConfig.bidResponse && placementId == 0) {
    NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
        GADMAdapterInMobiErrorInvalidServerParameters,
        @"GADMediationAdapterInMobi -  Error : Placement ID not specified.");
    _nativeRenderCompletionHandler(nil, error);
    return;
  }

  if ([_nativeAdConfig isTestRequest]) {
    GADMAdapterInMobiLog(
        @"Please enter your device ID in the InMobi console to recieve test ads from "
        @"Inmobi");
  }

  GADMAdapterInMobiLog(@"Requesting native ad from InMobi.");
  _native = [[IMNative alloc] initWithPlacementId:placementId delegate:self];

  GADInMobiExtras *extras = [_nativeAdConfig extras];
  if (extras && extras.keywords) {
    [_native setKeywords:extras.keywords];
  }

  GADMAdapterInMobiSetTargetingFromAdConfiguration(_nativeAdConfig);
  GADMAdapterInMobiSetUSPrivacyCompliance();

  NSData *bidResponseData = GADMAdapterInMobiBidResponseDataFromAdConfigration(_nativeAdConfig);
  GADMAdapterInMobiRequestParametersMediationType mediationType =
      bidResponseData ? GADMAdapterInMobiRequestParametersMediationTypeRTB
                      : GADMAdapterInMobiRequestParametersMediationTypeWaterfall;
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      extras, mediationType,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment,
      GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent);
  [_native setExtras:requestParameters];

  if (bidResponseData) {
    [_native load:bidResponseData];
  } else {
    [_native load];
  }
}

- (BOOL)handlesUserImpressions {
  return YES;
}

- (BOOL) handlesUserClicks {
    return YES;
}

#pragma mark - IMNativeDelegate

- (void)nativeDidFinishLoading:(nonnull IMNative *)native {
  GADMAdapterInMobiLog(@"InMobi SDK loaded a native ad successfully.");
    [self notifyCompletion];
}

- (void)native:(nonnull IMNative *)native didFailToLoadWithError:(nonnull IMRequestStatus *)error {
  GADMAdapterInMobiLog(@"InMobi SDK failed to load native ad");
  _nativeRenderCompletionHandler(nil, error);
}

- (void)nativeWillPresentScreen:(nonnull IMNative *)native {
  GADMAdapterInMobiLog(@"InMobi SDK will present a screen from a native ad.");
  [_nativeAdEventDelegate willPresentFullScreenView];
}

- (void)nativeDidPresentScreen:(nonnull IMNative *)native {
  GADMAdapterInMobiLog(@"InMobi SDK did present a screen from a native ad.");
}

- (void)nativeWillDismissScreen:(nonnull IMNative *)native {
  GADMAdapterInMobiLog(@"InMobi SDK will dismiss a screen from a native ad.");
  [_nativeAdEventDelegate willDismissFullScreenView];
}

- (void)nativeDidDismissScreen:(nonnull IMNative *)native {
  GADMAdapterInMobiLog(@"InMobi SDK did dismiss a screen from a native ad.");
  [_nativeAdEventDelegate didDismissFullScreenView];
}

- (void)userWillLeaveApplicationFromNative:(nonnull IMNative *)native {
  GADMAdapterInMobiLog(
      @"InMobi SDK will cause the user to leave the application from a native ad.");
}


- (void)nativeAdImpressed:(IMNative *)native {
    GADMAdapterInMobiLog(@"InMobi SDK recorded an impression from a native ad.");
    id<GADMediationNativeAdEventDelegate> nativeAdEventDelegate = _nativeAdEventDelegate;
    if (!nativeAdEventDelegate) {
      return;
    }
    
    if ([self hasVideoContent]) {
        [nativeAdEventDelegate didPlayVideo];
    }
    
    [nativeAdEventDelegate reportImpression];
}


- (void)native:(nonnull IMNative *)native
    didInteractWithParams:(nullable NSDictionary<NSString *, id> *)params {
  GADMAdapterInMobiLog(@"InMobi SDK recorded a click on a native ad.");
  [_nativeAdEventDelegate reportClick];
}

- (void)nativeDidFinishPlayingMedia:(nonnull IMNative *)native {
  GADMAdapterInMobiLog(@"InMobi SDK finished playing media on native ad.");
  [_nativeAdEventDelegate didEndVideo];
}

- (void)userDidSkipPlayingMediaFromNative:(nonnull IMNative *)native {
  GADMAdapterInMobiLog(@"InMobi SDK User did skip playing media from native ad.");
}

- (void)native:(nonnull IMNative *)native adAudioStateChanged:(BOOL)audioStateMuted {
  id<GADMediationNativeAdEventDelegate> nativeAdEventDelegate = _nativeAdEventDelegate;
  if (!nativeAdEventDelegate) {
    return;
  }

  if (audioStateMuted) {
    [nativeAdEventDelegate didMuteVideo];
    GADMAdapterInMobiLog(@"InMobi SDK audio state changed to mute for native ad.");
  } else {
    [nativeAdEventDelegate didUnmuteVideo];
    GADMAdapterInMobiLog(@"InMobi SDK audio state changed to unmute for native ad.");
  }
}

#pragma mark - Completion

- (void)notifyCompletion {
  _nativeAdEventDelegate = _nativeRenderCompletionHandler(self, nil);
}

#pragma mark - Helpers

- (BOOL)isValidWithNativeAd:(nonnull IMNative *)native imageURL:(nonnull NSString *)imageURL {
  if (!native.adTitle.length || !native.adDescription.length || !native.adCtaText.length ||
      !native.adIcon || !imageURL.length) {
    return NO;
  }
  return YES;
}

#pragma mark - GADMediatedUnifiedNativeAd

- (nullable NSString *)advertiser {
  return _native.advertiserName;
}

- (nullable NSString *)headline {
  return _native.adTitle;
}

- (nullable NSString *)body {
  return _native.adDescription;
}

- (nullable GADNativeAdImage *)icon {
    if (_native.adIcon.imageview.image == nil) {
        return nil;
    }
    GADNativeAdImage *iconImage = [[GADNativeAdImage alloc] initWithImage:_native.adIcon.imageview.image];
    return iconImage;
}

- (nullable NSString *)callToAction {
  return _native.adCtaText;
}

- (nullable NSDecimalNumber *)starRating {
  if (_native.adRating != nil) {
    return (NSDecimalNumber *)_native.adRating;
  }
  return 0;
}

/// InMobi SDK doesn't have an AdChoices view.
- (nullable UIView *)adChoicesView {
    return nil;
}

- (nullable NSString *)store {
  return nil;
}

- (nullable NSString *)price {
  return @"";
}

- (nullable NSArray<GADNativeAdImage *> *)images {
  return nil;
}

- (nullable NSDictionary<NSString *, id> *)extraAssets {
  return nil;
}

- (nullable UIView *)mediaView {
    return _native.getMediaView;
}

- (BOOL)hasVideoContent {
  return _native.isVideoAd;
}

- (void)didRenderInView:(nonnull UIView *)view
       clickableAssetViews:
           (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(nonnull UIViewController *)viewController {

    // 1) Validate that 'view' really is a GADNativeAdView
    if (![view isKindOfClass:[GADNativeAdView class]] || !_native) {
        // Either it's not the expected type, or our InMobi native object is missing
        return;
    }
    GADNativeAdView *adView = (GADNativeAdView *)view;

    // 2) Layout the InMobi media view inside the Google MediaView (if both exist)
    GADMediaView *googleMediaView = adView.mediaView;
    UIView *inMobiMediaView = _native.getMediaView;  // assuming 'mediaView' is the correct property
    if (googleMediaView && inMobiMediaView) {
        // Disable autoresizing mask, so Auto Layout constraints work
        inMobiMediaView.translatesAutoresizingMaskIntoConstraints = NO;
        [googleMediaView addSubview:inMobiMediaView];

        [NSLayoutConstraint activateConstraints:@[
            [inMobiMediaView.topAnchor constraintEqualToAnchor:googleMediaView.topAnchor],
            [inMobiMediaView.bottomAnchor constraintEqualToAnchor:googleMediaView.bottomAnchor],
            [inMobiMediaView.leadingAnchor constraintEqualToAnchor:googleMediaView.leadingAnchor],
            [inMobiMediaView.trailingAnchor constraintEqualToAnchor:googleMediaView.trailingAnchor]
        ]];
    }

    // 3) Build the IMNativeViewData with only the non-nil asset views
    IMNativeViewDataBuilder *builder = [[IMNativeViewDataBuilder alloc] initWithParentView:view];

    // ⭐️ Headline
    UIView *headlineView = clickableAssetViews[GADNativeHeadlineAsset];
    if (headlineView) {
        [builder setDescriptionView:headlineView];
    }

    // ⭐️ Call To Action
    UIView *callToActionView = clickableAssetViews[GADNativeCallToActionAsset];
    if (callToActionView) {
        [builder setCTAView:callToActionView];
    }

    // ⭐️ Icon
    UIView *iconView = clickableAssetViews[GADNativeIconAsset];
    if (iconView && [iconView isKindOfClass:[UIImageView class]]) {
        [builder setIconView:(UIImageView *)iconView];
    }
    
    // Collect remaining “extra” asset views into an array
    NSMutableArray<UIView *> *extraViews = [NSMutableArray array];
    UIView *bodyView       = clickableAssetViews[GADNativeBodyAsset];
    UIView *storeView      = clickableAssetViews[GADNativeStoreAsset];
    UIView *priceView      = clickableAssetViews[GADNativePriceAsset];
    UIView *imageView      = clickableAssetViews[GADNativeImageAsset];
    UIView *starRatingView = clickableAssetViews[GADNativeStarRatingAsset];

    if (bodyView)       [extraViews addObject:bodyView];
    if (storeView)      [extraViews addObject:storeView];
    if (priceView)      [extraViews addObject:priceView];
    if (imageView)      [extraViews addObject:imageView];
    if (starRatingView) [extraViews addObject:starRatingView];

    if (extraViews.count > 0) {
        [builder setExtraViews:extraViews];
    }

    // 4) Finally, build and register for tracking
    IMNativeViewData *viewData = [builder build];
    [_native registerViewForTracking:viewData];
}

- (void)didUntrackView:(nullable UIView *)view { }

@end
