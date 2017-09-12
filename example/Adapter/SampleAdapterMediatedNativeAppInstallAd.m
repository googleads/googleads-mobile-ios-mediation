//
// Copyright (C) 2015 Google, Inc.
//
// SampleAdapterMediatedNativeAppInstallAd.m
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

#import "SampleAdapterMediatedNativeAppInstallAd.h"

#import "SampleAdapterConstants.h"

// You may notice that this class and the Custom Event's
// SampleMediatedNativeAppInstallAd class look an awful lot alike. That's not
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

@interface SampleAdapterMediatedNativeAppInstallAd () <GADMediatedNativeAdDelegate>

@property(nonatomic, strong) SampleNativeAppInstallAd *sampleAd;
@property(nonatomic, copy) NSArray *mappedImages;
@property(nonatomic, strong) GADNativeAdImage *mappedIcon;
@property(nonatomic, copy) NSDictionary *extras;
@property(nonatomic, strong) GADNativeAdViewAdOptions *nativeAdViewAdOptions;
@property(nonatomic, strong) SampleAdInfoView *adInfoView;

@end

@implementation SampleAdapterMediatedNativeAppInstallAd

- (instancetype)
    initWithSampleNativeAppInstallAd:(SampleNativeAppInstallAd *)sampleNativeAppInstallAd
               nativeAdViewAdOptions:(nullable GADNativeAdViewAdOptions *)nativeAdViewAdOptions {
  if (!sampleNativeAppInstallAd) {
    return nil;
  }

  self = [super init];
  if (self) {
    _sampleAd = sampleNativeAppInstallAd;
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

    _nativeAdViewAdOptions = nativeAdViewAdOptions;
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
// the native ad. So there's no need to implement mediatedNativeAd:didRenderInView:viewController
// here. If your mediated network does need a reference to the view, this method can be used to
// provide one.
- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd
         didRenderInView:(UIView *)view
          viewController:(UIViewController *)viewController {
  // This method is called when the native ad view is rendered. Here you would pass the UIView back
  // to the mediated network's SDK.

  // Your adapter is responsible for placing the AdChoices icon in Google's native ad view.
  // You should use the mediatedNativeAd:didRenderInView:viewController: and
  // mediatedNativeAd:didUntrackView: APIs provided in GADMediatedNativeAdDelegate to add and remove
  // your AdChoices view.

  // The adapter must also respect the publisher’s preference of AdChoices location by
  // checking the preferredAdChoicesPosition in GADNativeAdViewAdOptions and render the ad in the
  // publisher’s preferred corner. If a preferred corner is not set, AdChoices should be rendered in
  // the top right corner.

  // The sample SDK provides an AdChoices view(SampleAdInfoView). If your SDK provides image
  // and click through URLs instead of the view asset, the adapter is responsible for downloading
  // the icon image and creating the AdChoices icon view.
  if (!_adInfoView) {
    _adInfoView = [[SampleAdInfoView alloc] init];
  }

  [view addSubview:_adInfoView];
  [self updateAdInfoViewPositionInSuperView:view];
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd didUntrackView:(UIView *)view {
  // This method is called when the mediatedNativeAd is no longer rendered in the provided view.
  // Here you would remove any tracking from the view that has mediated native ad.

  // Remove the previously added AdChoices view from the ad view.
  if (_adInfoView) {
    [_adInfoView removeFromSuperview];
  }
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

#pragma mark Convenience Methods

/// Updates the _adInfoView position inside the |superView|.
- (void)updateAdInfoViewPositionInSuperView:(UIView *)superView {
  CGSize viewSize = CGRectStandardize(_adInfoView.frame).size;
  NSDictionary *viewDictionary = NSDictionaryOfVariableBindings(_adInfoView);
  _adInfoView.translatesAutoresizingMaskIntoConstraints = NO;

  NSString *horizontalFormat, *verticalFormat;
  switch (_nativeAdViewAdOptions.preferredAdChoicesPosition) {
    case GADAdChoicesPositionTopLeftCorner:
      verticalFormat = [[NSString alloc] initWithFormat:@"V:|[_adInfoView(%f)]", viewSize.height];
      horizontalFormat = [[NSString alloc] initWithFormat:@"H:|[_adInfoView(%f)]", viewSize.width];
      break;
    case GADAdChoicesPositionBottomLeftCorner:
      verticalFormat = [[NSString alloc] initWithFormat:@"V:[_adInfoView(%f)]|", viewSize.height];
      horizontalFormat = [[NSString alloc] initWithFormat:@"H:|[_adInfoView(%f)]", viewSize.width];
      break;
    case GADAdChoicesPositionBottomRightCorner:
      verticalFormat = [[NSString alloc] initWithFormat:@"V:[_adInfoView(%f)]|", viewSize.height];
      horizontalFormat = [[NSString alloc] initWithFormat:@"H:[_adInfoView(%f)]|", viewSize.width];
      break;
    case GADAdChoicesPositionTopRightCorner:
      // Fall through.
    default:
      verticalFormat = [[NSString alloc] initWithFormat:@"V:|[_adInfoView(%f)]", viewSize.height];
      horizontalFormat = [[NSString alloc] initWithFormat:@"H:[_adInfoView(%f)]|", viewSize.width];
      break;
  }

  // Adding vertical layout constraints.
  [superView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:verticalFormat
                                                                    options:0
                                                                    metrics:nil
                                                                      views:viewDictionary]];
  // Adding horizontal layout constraints.
  [superView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:horizontalFormat
                                                                    options:0
                                                                    metrics:nil
                                                                      views:viewDictionary]];
}

@end
