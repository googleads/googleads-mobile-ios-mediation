//
// Copyright (C) 2015 Google, Inc.
//
// SampleAdapterMediatedNativeContentAd.m
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

#import "SampleAdapterMediatedNativeContentAd.h"

#import "SampleAdapterConstants.h"

// You may notice that this class and the Custom Event's
// SampleMediatedNativeContentAd class look an awful lot alike. That's not
// by accident. They're the same class, with the same methods and properties,
// but with two different names.
//
// Mediation adapters and custom events map their native ads for the
// Google Mobile Ads SDK using extensions of the same two classes:
// GADMediatedNativeAppInstallAd and GADMediatedNativeContentAd. Because both
// the adapter and custom event in this example are mediating the same Sample
// SDK, they both need the same work done: take a native ad object from the
// Sample SDK and map it to the interface the Google Mobile Ads SDK expects.
// Thus, the same classes work for both.
//
// Because we wanted this project to have a complete example of an
// adapter and a complete example of a custom event (and we didn't want to
// share code between them), they each get their own copies of these classes,
// with slightly different names.

@interface SampleAdapterMediatedNativeContentAd () <GADMediatedNativeAdDelegate>

@property(nonatomic, strong) SampleNativeContentAd *sampleAd;
@property(nonatomic, copy) NSArray *mappedImages;
@property(nonatomic, strong) GADNativeAdImage *mappedLogo;
@property(nonatomic, copy) NSDictionary *extras;
@property(nonatomic, strong) GADNativeAdViewAdOptions *nativeAdViewAdOptions;
@property(nonatomic, strong) SampleAdInfoView *adInfoView;

@end

@implementation SampleAdapterMediatedNativeContentAd

- (instancetype)initWithSampleNativeContentAd:(SampleNativeContentAd *)sampleNativeContentAd
                        nativeAdViewAdOptions:
                            (nullable GADNativeAdViewAdOptions *)nativeAdViewAdOptions {
  if (!sampleNativeContentAd) {
    return nil;
  }

  self = [super init];
  if (self) {
    _sampleAd = sampleNativeContentAd;
    _extras = @{SampleAdapterExtraKeyAwesomeness : _sampleAd.degreeOfAwesomeness};

    if (_sampleAd.image) {
      _mappedImages = @[ [[GADNativeAdImage alloc] initWithImage:_sampleAd.image] ];
    } else {
      NSURL *imageUrl = [[NSURL alloc] initFileURLWithPath:_sampleAd.imageURL];
      _mappedImages =
          @[ [[GADNativeAdImage alloc] initWithURL:imageUrl scale:_sampleAd.imageScale] ];
    }

    if (_sampleAd.logo) {
      _mappedLogo = [[GADNativeAdImage alloc] initWithImage:_sampleAd.logo];
    } else {
      NSURL *logoURL = [[NSURL alloc] initFileURLWithPath:_sampleAd.logoURL];
      _mappedLogo = [[GADNativeAdImage alloc] initWithURL:logoURL scale:_sampleAd.logoScale];
    }

    _nativeAdViewAdOptions = nativeAdViewAdOptions;

    // The sample SDK provides an AdChoices view (SampleAdInfoView). If your SDK provides image
    // and clickthrough URLs for its AdChoices icon instead of an actual UIView, the adapter is
    // responsible for downloading the icon image and creating the AdChoices icon view.
    _adInfoView = [[SampleAdInfoView alloc] init];
  }
  return self;
}

- (NSString *)headline {
  return self.sampleAd.headline;
}

- (NSString *)body {
  return self.sampleAd.body;
}

- (NSArray *)images {
  return self.mappedImages;
}

- (GADNativeAdImage *)logo {
  return self.mappedLogo;
}

- (NSString *)callToAction {
  return self.sampleAd.callToAction;
}

- (NSString *)advertiser {
  return self.sampleAd.advertiser;
}

- (NSDictionary *)extraAssets {
  return self.extras;
}

- (UIView *)adChoicesView {
  return self.adInfoView;
}

- (id<GADMediatedNativeAdDelegate>)mediatedNativeAdDelegate {
  return self;
}

#pragma mark - GADMediatedNativeAdDelegate implementation

// Because the Sample SDK handles click and impression tracking via methods on its native
// ad object, there's no need to pass it a reference to the UIView being used to display
// the native ad. So there's no need to implement mediatedNativeAd:didRenderInView:viewController
// here. If your mediated network does need a reference to the view, this method can be used to
// provide one.
- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd
         didRenderInView:(UIView *)view
          viewController:(UIViewController *)viewController {
  // This method is called when the native ad view is rendered. Here you would pass the UIView back
  // to the mediated network's SDK.
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd didUntrackView:(UIView *)view {
  // This method is called when the mediatedNativeAd is no longer rendered in the provided view.
  // Here you would remove any tracking from the view that has mediated native ad.
}

- (void)mediatedNativeAdDidRecordImpression:(id<GADMediatedNativeAd>)mediatedNativeAd {
  if (self.sampleAd) {
    [self.sampleAd recordImpression];
  }
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd
    didRecordClickOnAssetWithName:(NSString *)assetName
                             view:(UIView *)view
                   viewController:(UIViewController *)viewController {
  if (self.sampleAd) {
    [self.sampleAd handleClickOnView:view];
  }
}

@end
