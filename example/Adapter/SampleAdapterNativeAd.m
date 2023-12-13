// Copyright 2023 Google LLC
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

#import "SampleAdapterNativeAd.h"
#include <stdatomic.h>
#import "SampleAdapter.h"
#import "SampleAdapterConstants.h"
#import "SampleExtras.h"

@implementation SampleAdapterNativeAd {
  /// The completion handler to call ad loading events.
  GADMediationNativeLoadCompletionHandler _adLoadCompletionHandler;

  /// An ad event delegate to forward ad rendering events.
  __weak id<GADMediationNativeAdEventDelegate> _adEventDelegate;

  /// The native ad configuration.
  GADMediationNativeAdConfiguration *_adConfiguration;

  /// An ad loader to use in loading native ads from Sample SDK.
  SampleNativeAdLoader *_nativeAdLoader;

  /// Native ad object from Sample SDK.
  SampleNativeAd *_nativeAd;

  /// Native ad view options.
  GADNativeAdViewAdOptions *_nativeAdViewAdOptions;

  /// Native ad images.
  NSArray<GADNativeAdImage *> *_mappedImages;

  /// Native ad icon.
  GADNativeAdImage *_mappedIcon;

  /// Native ad choices view.
  SampleAdInfoView *_adInfoView;

  /// Native ad media view.
  SampleMediaView *_mediaView;

  /// Native ad extra assets.
  NSDictionary<NSString *, NSString *> *_extras;
}

- (nonnull instancetype)initWithAdConfiguration:
    (nonnull GADMediationNativeAdConfiguration *)adConfiguration {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)renderNativeAdWithCompletionHandler:
    (nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationNativeLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _adLoadCompletionHandler =
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

  NSString *adUnit = _adConfiguration.credentials.settings[SampleSDKAdUnitIDKey];
  if (!adUnit.length) {
    NSError *parameterError =
        [NSError errorWithDomain:kAdapterErrorDomain
                            code:SampleAdapterErrorCodeInvalidServerParameters
                        userInfo:@{NSLocalizedDescriptionKey : @"Missing or invalid ad unit."}];
    _adLoadCompletionHandler(nil, parameterError);
    return;
  }

  _nativeAdLoader = [[SampleNativeAdLoader alloc] init];
  _nativeAdLoader.adUnitID = adUnit;
  _nativeAdLoader.delegate = self;

  SampleNativeAdRequest *sampleRequest = [[SampleNativeAdRequest alloc] init];

  // The Google Mobile Ads SDK requires the image assets to be downloaded automatically unless the
  // publisher specifies otherwise by using the GADNativeAdImageAdLoaderOptions object's
  // disableImageLoading property. If your network doesn't have an option like this and instead only
  // ever returns URLs for images (rather than the images themselves), your adapter should download
  // image assets on behalf of the publisher. This should be done after receiving the native ad
  // object from your network's SDK, and before calling the connector's
  // adapter:didReceiveMediatedNativeAd: method.
  sampleRequest.shouldDownloadImages = YES;

  sampleRequest.preferredImageOrientation = NativeAdImageOrientationAny;
  sampleRequest.shouldRequestMultipleImages = NO;

  for (GADAdLoaderOptions *loaderOptions in _adConfiguration.options) {
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

  NSLog(@"Requesting a native ad from Sample Ad Network.");
  [_nativeAdLoader fetchAd:sampleRequest];
}

#pragma mark - SampleAdapterDataProvider Methods

- (GADNativeAdViewAdOptions *)nativeAdViewAdOptions {
  return _nativeAdViewAdOptions;
}

#pragma mark - GADMediationNativeAd methods

- (BOOL)hasVideoContent {
  return _nativeAd.mediaView != nil;
}

- (UIView *)mediaView {
  return _mediaView;
}

- (NSString *)advertiser {
  return _nativeAd.advertiser;
}

- (NSString *)headline {
  return _nativeAd.headline;
}

- (NSArray *)images {
  return _mappedImages;
}

- (NSString *)body {
  return _nativeAd.body;
}

- (GADNativeAdImage *)icon {
  return _mappedIcon;
}

- (NSString *)callToAction {
  return _nativeAd.callToAction;
}

- (NSDecimalNumber *)starRating {
  return _nativeAd.starRating;
}

- (NSString *)store {
  return _nativeAd.store;
}

- (NSString *)price {
  return _nativeAd.price;
}

- (NSDictionary *)extraAssets {
  return _extras;
}

- (UIView *)adChoicesView {
  return _adInfoView;
}

// Because the Sample SDK has click and impression tracking via methods on its native ad object
// which the developer is required to call, there's no need to pass it a reference to the UIView
// being used to display the native ad. So there's no need to implement
// didRenderInView:viewController:clickableAssetViews:nonClickableAssetViews
// here. If your mediated network does need a reference to the view, this method can be used to
// provide one. You can also access the clickable and non-clickable views by asset key if the
// mediation network needs this information.
- (void)didRenderInView:(UIView *)view
       clickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(UIViewController *)viewController {
  // This method is called when the native ad view is rendered. Here you would pass the UIView back
  // to the mediated network's SDK.

  // Playing video using SampleMediaView's playVideo method
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

- (void)didRecordClickOnAssetWithName:(NSString *)assetName
                                 view:(UIView *)view
                       viewController:(UIViewController *)viewController {
  if (_nativeAd) {
    [_nativeAd handleClickOnView:view];
  }
}

#pragma mark - SampleNativeAdLoaderDelegate implementation

- (void)adLoader:(SampleNativeAdLoader *)adLoader didReceiveNativeAd:(SampleNativeAd *)nativeAd {
  _nativeAd = nativeAd;
  [self mapNativeAd];
  _adEventDelegate = _adLoadCompletionHandler(self, nil);
}

- (void)adLoader:(SampleNativeAdLoader *)adLoader
    didFailToLoadAdWithErrorCode:(SampleErrorCode)errorCode {
  NSError *loadError = [NSError
      errorWithDomain:kAdapterErrorDomain
                 code:errorCode
             userInfo:@{NSLocalizedDescriptionKey : @"Sample SDK returned an error callback."}];
  _adLoadCompletionHandler(nil, loadError);
}

- (void)mapNativeAd {
  _extras = @{SampleAdapterExtraKeyAwesomeness : _nativeAd.degreeOfAwesomeness};

  if (_nativeAd.image) {
    _mappedImages = @[ [[GADNativeAdImage alloc] initWithImage:_nativeAd.image] ];
  } else {
    NSURL *imageURL = [[NSURL alloc] initFileURLWithPath:_nativeAd.imageURL];
    _mappedImages = @[ [[GADNativeAdImage alloc] initWithURL:imageURL scale:_nativeAd.imageScale] ];
  }

  if (_nativeAd.icon) {
    _mappedIcon = [[GADNativeAdImage alloc] initWithImage:_nativeAd.icon];
  } else {
    NSURL *iconURL = [[NSURL alloc] initFileURLWithPath:_nativeAd.iconURL];
    _mappedIcon = [[GADNativeAdImage alloc] initWithURL:iconURL scale:_nativeAd.iconScale];
  }
  _mediaView = _nativeAd.mediaView;

  // The sample SDK provides an AdChoices view (SampleAdInfoView). If your SDK provides image
  // and clickthrough URLs for its AdChoices icon instead of an actual UIView, the adapter is
  // responsible for downloading the icon image and creating the AdChoices icon view.
  _adInfoView = [[SampleAdInfoView alloc] init];
}

@end
