//
// Copyright (C) 2015 Google, Inc.
//
// SampleAdapterMediatedNativeAd.m
// Sample Ad Network Adapter
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

#import "SampleAdapterMediatedNativeAd.h"

#import "SampleAdapterConstants.h"

@interface SampleAdapterMediatedNativeAd () <GADMediatedNativeAdDelegate>

@property(nonatomic, strong) SampleNativeAd *sampleAd;
@property(nonatomic, copy) NSArray *mappedImages;
@property(nonatomic, strong) GADNativeAdImage *mappedIcon;
@property(nonatomic, copy) NSDictionary *extras;
@property(nonatomic, strong) GADNativeAdViewAdOptions *nativeAdViewAdOptions;
@property(nonatomic, strong) SampleAdInfoView *adInfoView;
@property(nonatomic, strong) SampleMediaView *mediaView;

@end

@implementation SampleAdapterMediatedNativeAd

- (instancetype)initWithSampleNativeAd:(SampleNativeAd *)sampleNativeAd
                 nativeAdViewAdOptions:(nullable GADNativeAdViewAdOptions *)nativeAdViewAdOptions {
  if (!sampleNativeAd) {
    return nil;
  }

  self = [super init];
  if (self) {
    _sampleAd = sampleNativeAd;
    _extras = @{SampleAdapterExtraKeyAwesomeness : _sampleAd.degreeOfAwesomeness};

    if (_sampleAd.image) {
      _mappedImages = @[ [[GADNativeAdImage alloc] initWithImage:_sampleAd.image] ];
    } else {
      NSURL *imageURL = [[NSURL alloc] initFileURLWithPath:_sampleAd.imageURL];
      _mappedImages =
          @[ [[GADNativeAdImage alloc] initWithURL:imageURL scale:_sampleAd.imageScale] ];
    }

    if (_sampleAd.icon) {
      _mappedIcon = [[GADNativeAdImage alloc] initWithImage:_sampleAd.icon];
    } else {
      NSURL *iconURL = [[NSURL alloc] initFileURLWithPath:_sampleAd.iconURL];
      _mappedIcon = [[GADNativeAdImage alloc] initWithURL:iconURL scale:_sampleAd.iconScale];
    }
    _mediaView = _sampleAd.mediaView;
    _nativeAdViewAdOptions = nativeAdViewAdOptions;

    // The sample SDK provides an AdChoices view (SampleAdInfoView). If your SDK provides image
    // and clickthrough URLs for its AdChoices icon instead of an actual UIView, the adapter is
    // responsible for downloading the icon image and creating the AdChoices icon view.
    _adInfoView = [[SampleAdInfoView alloc] init];
  }
  return self;
}

- (BOOL)hasVideoContent {
  return self.sampleAd.mediaView != nil;
}

- (UIView *)mediaView {
  return _mediaView;
}

- (NSString *)advertiser {
  return self.sampleAd.advertiser;
}

- (NSString *)headline {
  return self.sampleAd.headline;
}

- (NSArray *)images {
  return self.mappedImages;
}

- (NSString *)body {
  return self.sampleAd.body;
}

- (GADNativeAdImage *)icon {
  return self.mappedIcon;
}

- (NSString *)callToAction {
  return self.sampleAd.callToAction;
}

- (NSDecimalNumber *)starRating {
  return self.sampleAd.starRating;
}

- (NSString *)store {
  return self.sampleAd.store;
}

- (NSString *)price {
  return self.sampleAd.price;
}

- (NSDictionary *)extraAssets {
  return self.extras;
}

- (UIView *)adChoicesView {
  return self.adInfoView;
}

#pragma mark - GADMediatedNativeAd requirement

- (nullable id<GADMediatedNativeAdDelegate>)mediatedNativeAdDelegate {
  return self;
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd didUntrackView:(UIView *)view {
  [self didUntrackView:view];
}

- (void)mediatedNativeAdDidRecordImpression:(id<GADMediatedNativeAd>)mediatedNativeAd {
  [self didRecordImpression];
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd
    didRecordClickOnAssetWithName:(NSString *)assetName
                             view:(UIView *)view
                   viewController:(UIViewController *)viewController {
  [self didRecordClickOnAssetWithName:assetName view:view viewController:viewController];
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd
           didRenderInView:(UIView *)view
       clickableAssetViews:(NSDictionary<NSString *, UIView *> *)clickableAssetViews
    nonclickableAssetViews:(NSDictionary<NSString *, UIView *> *)nonclickableAssetViews
            viewController:(UIViewController *)viewController {
  [self didRenderInView:view
         clickableAssetViews:clickableAssetViews
      nonclickableAssetViews:nonclickableAssetViews
              viewController:viewController];
}

// Because the Sample SDK has click and impression tracking via methods on its native ad object
// which the developer is required to call, there's no need to pass it a reference to the UIView
// being used to display the native ad. So there's no need to implement
// mediatedNativeAd:didRenderInView:viewController:clickableAssetViews:nonClickableAssetViews here.
// If your mediated network does need a reference to the view, this method can be used to provide
// one.
// You can also access the clickable and non-clickable views by asset key if the mediation network
// needs this information.
- (void)didRenderInView:(UIView *)view
       clickableAssetViews:
           (NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(UIViewController *)viewController {
  // This method is called when the native ad view is rendered. Here you would pass the UIView back
  // to the mediated network's SDK.

  // Playing video using SampleMediaView's playVideo method
  [_sampleAd playVideo];
}

- (void)didUntrackView:(UIView *)view {
  // This method is called when the mediatedNativeAd is no longer rendered in the provided view.
  // Here you would remove any tracking from the view that has mediated native ad.
}

- (void)didRecordImpression {
  if (self.sampleAd) {
    [self.sampleAd recordImpression];
  }
}

- (void)didRecordClickOnAssetWithName:(NSString *)assetName
                                 view:(UIView *)view
                       viewController:(UIViewController *)viewController {
  if (self.sampleAd) {
    [self.sampleAd handleClickOnView:view];
  }
}

@end
