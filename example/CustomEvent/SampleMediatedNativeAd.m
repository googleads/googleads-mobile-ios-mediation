//
// Copyright (C) 2015 Google, Inc.
//
// SampleMediatedNativeAd.m
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

#import "SampleMediatedNativeAd.h"

#import "SampleCustomEventConstants.h"

// You may notice that this class and the Mediation Adapter's
// SampleAdapterMediatedNativeAd class look an awful lot alike. That's not
// by accident. They're the same class, with the same methods and properties,
// but with two different names.
//
// Mediation adapters and custom events map their native ads for the
// Google Mobile Ads SDK using an extension of GADMediatedUnifiedNativeAd. Because both
// the adapter and custom event in this example are mediating the same Sample
// SDK, they both need the same work done: take a native ad object from the
// Sample SDK and map it to the interface the Google Mobile Ads SDK expects.
// Thus, the same classes work for both.
//
// Because we wanted this project to have a complete example of an
// adapter and a complete example of a custom event (and we didn't want to
// share code between them), they each get their own copies of this class,
// with slightly different names.

@interface SampleMediatedNativeAd ()
@property(nonatomic, strong) SampleNativeAd *sampleAd;
@property(nonatomic, copy) NSArray *mappedImages;
@property(nonatomic, strong) GADNativeAdImage *mappedIcon;
@property(nonatomic, copy) NSDictionary *extras;
@property(nonatomic, strong) GADNativeAdViewAdOptions *nativeAdViewAdOptions;
@property(nonatomic, strong) SampleAdInfoView *adInfoView;
@property(nonatomic, strong) SampleMediaView *mediaView;

@end

@implementation SampleMediatedNativeAd

- (instancetype)initWithSampleNativeAd:(SampleNativeAd *)sampleNativeAd
                 nativeAdViewAdOptions:(nullable GADNativeAdViewAdOptions *)nativeAdViewAdOptions {
  if (!sampleNativeAd) {
    return nil;
  }

  self = [super init];
  if (self) {
    _sampleAd = sampleNativeAd;
    _extras = @{SampleCustomEventExtraKeyAwesomeness : _sampleAd.degreeOfAwesomeness};

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
  // Playing video using SampleNativeAd's playVideo method
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

- (void)didRecordClickOnAssetWithName:(GADUnifiedNativeAssetIdentifier)assetName
                                 view:(UIView *)view
                       viewController:(UIViewController *)viewController {
  if (self.sampleAd) {
    [self.sampleAd handleClickOnView:view];
  }
}

@end
