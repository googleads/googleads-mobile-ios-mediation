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

@import GoogleMobileAds;

#import "../SDK/SampleNativeAdLoader.h"
#import "../SDK/SampleNativeAdRequest.h"
#import "SampleCustomEventNativeAd.h"
#import "SampleMediatedNativeAppInstallAd.h"
#import "SampleMediatedNativeContentAd.h"

/// Constant for Sample Ad Network custom event error domain.
static NSString *const customEventErrorDomain = @"com.google.CustomEvent";

@interface SampleCustomEventNativeAd () <SampleNativeAdLoaderDelegate>
@end

@implementation SampleCustomEventNativeAd

@synthesize delegate;

- (void)requestNativeAdWithParameter:(NSString *)serverParameter
                             request:(GADCustomEventRequest *)request
                             adTypes:(NSArray *)adTypes
                             options:(NSArray *)options
                  rootViewController:(UIViewController *)rootViewController {
  SampleNativeAdLoader *adLoader = [[SampleNativeAdLoader alloc] init];
  SampleNativeAdRequest *sampleRequest = [[SampleNativeAdRequest alloc] init];

  // Part of the custom event's job is to examine the properties of the GADCustomEventRequest and
  // create a request for the mediated network's SDK that matches them.
  for (NSString *adType in adTypes) {
    if ([adType isEqual:kGADAdLoaderAdTypeNativeContent]) {
      sampleRequest.contentAdsRequested = YES;
    } else if ([adType isEqual:kGADAdLoaderAdTypeNativeAppInstall]) {
      sampleRequest.appInstallAdsRequested = YES;
    }
  }

  for (GADNativeAdImageAdLoaderOptions *imageOptions in options) {
    if (![imageOptions isKindOfClass:[GADNativeAdImageAdLoaderOptions class]]) {
      continue;
    }

    sampleRequest.shouldRequestPortraitImages = imageOptions.preferredImageOrientation ==
                                                GADNativeAdImageAdLoaderOptionsOrientationPortrait;
    sampleRequest.shouldDownloadImages = !imageOptions.disableImageLoading;
    sampleRequest.shouldRequestMultipleImages = imageOptions.shouldRequestMultipleImages;
  }

  // This custom event uses the server parameter to carry an ad unit ID, which is the most common
  // use case.
  adLoader.adUnitID = serverParameter;
  adLoader.delegate = self;

  [adLoader fetchAd:sampleRequest];
}

#pragma mark SampleNativeAdLoaderDelegate implementation

- (void)adLoader:(SampleNativeAdLoader *)adLoader
    didReceiveNativeAppInstallAd:(SampleNativeAppInstallAd *)nativeAppInstallAd {
  SampleMediatedNativeAppInstallAd *mediatedAd = [[SampleMediatedNativeAppInstallAd alloc]
      initWithSampleNativeAppInstallAd:nativeAppInstallAd];
  [self.delegate customEventNativeAd:self didReceiveMediatedNativeAd:mediatedAd];
}

- (void)adLoader:(SampleNativeAdLoader *)adLoader
    didReceiveNativeContentAd:(SampleNativeContentAd *)nativeContentAd {
  SampleMediatedNativeContentAd *mediatedAd =
      [[SampleMediatedNativeContentAd alloc] initWithSampleNativeContentAd:nativeContentAd];
  [self.delegate customEventNativeAd:self didReceiveMediatedNativeAd:mediatedAd];
}

- (void)adLoader:(SampleNativeAdLoader *)adLoader
    didFailToLoadAdWithErrorCode:(SampleErrorCode)errorCode {
  NSError *error = [NSError errorWithDomain:customEventErrorDomain code:errorCode userInfo:nil];
  [self.delegate customEventNativeAd:self didFailToLoadWithError:error];
}

@end
