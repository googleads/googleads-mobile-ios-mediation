//
// Copyright (C) 2015 Google, Inc.
//
// SampleCustomEventNative.m
// Sample Ad Network Custom Event
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "SampleCustomEventNativeAd.h"
#include <stdatomic.h>
#import "SampleCustomEventConstants.h"
#import "SampleCustomEventUtils.h"

#import <Foundation/Foundation.h>
#import <SampleAdSDK/SampleAdSDK.h>

@interface SampleCustomEventNativeAd () <SampleNativeAdLoaderDelegate, GADMediationNativeAd> {
  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationNativeLoadCompletionHandler _loadCompletionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  id<GADMediationNativeAdEventDelegate> _adEventDelegate;

  /// Native ad view options.
  GADNativeAdViewAdOptions *_nativeAdViewAdOptions;

  /// The native ad object
  SampleNativeAd *_nativeAd;
}

@end

@implementation SampleCustomEventNativeAd

/// Used to store the ad's images. In order to implement the GADMediationNativeAd protocol, we use
/// this class to return the images property.
NSArray<GADNativeAdImage *> *_images;

/// Used to store the ad's icon. In order to implement the GADMediationNativeAd protocol, we use
/// this class to return the icon property.
GADNativeAdImage *_icon;

/// Used to store the ad's ad choices view. In order to implement the GADMediationNativeAd protocol,
/// we use this class to return the adChoicesView property.
UIView *_adChoicesView;

- (nullable NSString *)headline {
  return _nativeAd.headline;
}

- (nullable NSArray<GADNativeAdImage *> *)images {
  return _images;
}

- (nullable NSString *)body {
  return _nativeAd.body;
}

- (nullable GADNativeAdImage *)icon {
  return _icon;
}

- (nullable NSString *)callToAction {
  return _nativeAd.callToAction;
}

- (nullable NSDecimalNumber *)starRating {
  return _nativeAd.starRating;
}

- (nullable NSString *)store {
  return _nativeAd.store;
}

- (nullable NSString *)price {
  return _nativeAd.price;
}

- (nullable NSString *)advertiser {
  return _nativeAd.advertiser;
}

- (nullable NSDictionary<NSString *, id> *)extraAssets {
  return @{SampleCustomEventExtraKeyAwesomeness : _nativeAd.degreeOfAwesomeness};
}

- (nullable UIView *)adChoicesView {
  return _adChoicesView;
}

- (nullable UIView *)mediaView {
  return _nativeAd.mediaView;
}

- (BOOL)hasVideoContent {
  return self.mediaView != nil;
}

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationNativeLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];

  _loadCompletionHandler = ^id<GADMediationNativeAdEventDelegate>(
      _Nullable id<GADMediationNativeAd> ad, NSError *_Nullable error) {
    // Only allow completion handler to be called once.
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }

    id<GADMediationNativeAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      // Call original handler and hold on to its return value.
      delegate = originalCompletionHandler(ad, error);
    }

    // Release reference to handler. Objects retained by the handler will also be released.
    originalCompletionHandler = nil;

    return delegate;
  };

  SampleNativeAdLoader *adLoader = [[SampleNativeAdLoader alloc] init];
  SampleNativeAdRequest *sampleRequest = [[SampleNativeAdRequest alloc] init];

  // The Google Mobile Ads SDK requires the image assets to be downloaded automatically unless
  // the publisher specifies otherwise by using the GADNativeAdImageAdLoaderOptions object's
  // disableImageLoading property. If your network doesn't have an option like this and instead only
  // ever returns URLs for images (rather than the images themselves), your adapter should download
  // image assets on behalf of the publisher. This should be done after receiving the native ad
  // object from your network's SDK, and before calling the connector's
  // adapter:didReceiveMediatedNativeAd: method.
  sampleRequest.shouldDownloadImages = YES;

  sampleRequest.preferredImageOrientation = NativeAdImageOrientationAny;
  sampleRequest.shouldRequestMultipleImages = NO;
  sampleRequest.testMode = adConfiguration.isTestRequest;

  for (GADAdLoaderOptions *loaderOptions in adConfiguration.options) {
    if ([loaderOptions isKindOfClass:[GADNativeAdImageAdLoaderOptions class]]) {
      GADNativeAdImageAdLoaderOptions *imageOptions =
          (GADNativeAdImageAdLoaderOptions *)loaderOptions;
      sampleRequest.shouldRequestMultipleImages = imageOptions.shouldRequestMultipleImages;

      // If the GADNativeAdImageAdLoaderOptions' disableImageLoading property is YES, the adapter
      // should send just the URLs for the images.
      sampleRequest.shouldDownloadImages = !imageOptions.disableImageLoading;
    } else if ([loaderOptions isKindOfClass:[GADNativeAdMediaAdLoaderOptions class]]) {
      GADNativeAdMediaAdLoaderOptions *mediaOptions =
          (GADNativeAdMediaAdLoaderOptions *)loaderOptions;
      switch (mediaOptions.mediaAspectRatio) {
        case GADMediaAspectRatioLandscape:
          sampleRequest.preferredImageOrientation = NativeAdImageOrientationLandscape;
          break;
        case GADMediaAspectRatioPortrait:
          sampleRequest.preferredImageOrientation = NativeAdImageOrientationPortrait;
          break;
        default:
          sampleRequest.preferredImageOrientation = NativeAdImageOrientationAny;
          break;
      }
    } else if ([loaderOptions isKindOfClass:[GADNativeAdViewAdOptions class]]) {
      _nativeAdViewAdOptions = (GADNativeAdViewAdOptions *)loaderOptions;
    }
  }

  // This custom event uses the server parameter to carry an ad unit ID, which is the most common
  // use case.
  NSString *adUnit = adConfiguration.credentials.settings[@"parameter"];
  adLoader.adUnitID = adUnit;
  adLoader.delegate = self;

  [adLoader fetchAd:sampleRequest];
}

// Indicates if the custom event handles user clicks. Return YES if the custom event should handle
// user clicks.
- (BOOL)handlesUserClicks {
  return NO;
}

- (BOOL)handlesUserImpressions {
  return NO;
}

#pragma mark SampleNativeAdLoaderDelegate implementation

- (void)adLoader:(SampleNativeAdLoader *)adLoader didReceiveNativeAd:(SampleNativeAd *)nativeAd {
  if (nativeAd.image) {
    _images = @[ [[GADNativeAdImage alloc] initWithImage:nativeAd.image] ];
  } else {
    NSURL *imageURL = [[NSURL alloc] initFileURLWithPath:nativeAd.imageURL];
    _images = @[ [[GADNativeAdImage alloc] initWithURL:imageURL scale:nativeAd.imageScale] ];
  }

  if (nativeAd.icon) {
    _icon = [[GADNativeAdImage alloc] initWithImage:nativeAd.icon];
  } else {
    NSURL *iconURL = [[NSURL alloc] initFileURLWithPath:nativeAd.iconURL];
    _icon = [[GADNativeAdImage alloc] initWithURL:iconURL scale:nativeAd.iconScale];
  }

  // The sample SDK provides an AdChoices view (SampleAdInfoView). If your SDK provides image
  // and clickthrough URLs for its AdChoices icon instead of an actual UIView, the adapter is
  // responsible for downloading the icon image and creating the AdChoices icon view.
  _adChoicesView = [[SampleAdInfoView alloc] init];
  _nativeAd = nativeAd;

  _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void)adLoader:(SampleNativeAdLoader *)adLoader
    didFailToLoadAdWithErrorCode:(SampleErrorCode)errorCode {
  NSError *error = SampleCustomEventErrorWithCodeAndDescription(
      SampleCustomEventErrorAdLoadFailureCallback,
      [NSString
          stringWithFormat:@"Sample SDK returned an ad load failure callback with error code: %@",
                           errorCode]);
  _adEventDelegate = _loadCompletionHandler(nil, error);
}

#pragma mark GADMediatedUnifiedNativeAd implementation

// Because the Sample SDK has click and impression tracking via methods on its native ad object
// which the developer is required to call, there's no need to pass it a reference to the UIView
// being used to display the native ad. So there's no need to implement
// mediatedNativeAd:didRenderInView:viewController:clickableAssetViews:nonClickableAssetViews here.
// If your mediated network does need a reference to the view, this method can be used to provide
// one.
// You can also access the clickable and non-clickable views by asset key if the mediation network
// needs this information.
- (void)didRenderInView:(UIView *)view
       clickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(UIViewController *)viewController {
  // This method is called when the native ad view is rendered. Here you would pass the UIView back
  // to the mediated network's SDK.
  // Playing video using SampleNativeAd's playVideo method
  [_nativeAd playVideo];
}

- (void)didUntrackView:(UIView *)view {
  // This method is called when the mediatedNativeAd is no longer rendered in the provided view.
  // Here you would remove any tracking from the view that has mediated native ad.
}

- (void)didRecordImpression {
  if (_nativeAd) {
    [_nativeAd recordImpression];
  }
}

- (void)didRecordClickOnAssetWithName:(GADNativeAssetIdentifier)assetName
                                 view:(UIView *)view
                       viewController:(UIViewController *)viewController {
  if (_nativeAd) {
    [_nativeAd handleClickOnView:view];
  }
}

@end
