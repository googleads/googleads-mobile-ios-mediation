//
// Copyright (C) 2015 Google, Inc.
//
// SampleForwardingNativeAppInstallAd.m
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

@import GoogleMobileAds;

#import "../SDK/SampleNativeAppInstallAd.h"
#import "SampleCustomEventConstants.h"
#import "SampleMediatedNativeAppInstallAd.h"

// You may notice that this class and the Mediation Adapter's
// SampleAdapterMediatedNativeAppInstallAd class look an awful lot alike. That's not
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

@interface SampleMediatedNativeAppInstallAd () <GADMediatedNativeAdDelegate>

@property(nonatomic, strong) SampleNativeAppInstallAd *sampleAd;
@property(nonatomic, copy) NSArray *mappedImages;
@property(nonatomic, strong) GADNativeAdImage *mappedIcon;
@property(nonatomic, copy) NSDictionary *extras;

@end

@implementation SampleMediatedNativeAppInstallAd

- (instancetype)initWithSampleNativeAppInstallAd:
        (nonnull SampleNativeAppInstallAd *)sampleNativeAppInstallAd {
  if (!sampleNativeAppInstallAd) {
    return nil;
  }

  self = [super init];
  if (self) {
    _sampleAd = sampleNativeAppInstallAd;
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
  }
  return self;
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

- (id<GADMediatedNativeAdDelegate>)mediatedNativeAdDelegate {
  return self;
}

#pragma mark - GADMediatedNativeAdDelegate implementation

// Because the Sample SDK handles click and impression tracking via methods on its native
// ad object, there's no need to pass it a reference to the UIView being used to display
// the native ad. So there's no need to implement mediatedNativeAd:didRenderInView here.
// If your mediated network does need a reference to the view, this method can be used to
// provide one.

//- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd
//         didRenderInView:(UIView *)view {
//  Here you would pass the UIView back to the mediated network's SDK.
//}

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
