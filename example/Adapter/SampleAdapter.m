//
// Copyright (C) 2015 Google, Inc.
//
// SampleAdapter.m
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
@import SampleAdSDK;

#import "SampleAdapter.h"
#import "SampleAdapterDelegate.h"
#import "SampleAdapterMediatedNativeAd.h"

@interface SampleAdapter () {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Connector from Google Mobile Ads SDK to receive reward-based video ad configurations.
  __weak id<GADMRewardBasedVideoAdNetworkConnector> _rewardBasedVideoAdConnector;

  /// Handles delegate notifications.
  SampleAdapterDelegate *_adapterDelegate;

  /// Handle banner ads from Sample SDK.
  SampleBanner *_bannerAd;

  /// Handle interstitial ads from Sample SDK.
  SampleInterstitial *_interstitialAd;

  /// Handle reward-based video ads from Sample SDK.
  SampleRewardBasedVideo *_rewardBasedVideoAd;

  /// An ad loader to use in loading native ads from Sample SDK.
  SampleNativeAdLoader *_nativeAdLoader;

  /// Native ad view options.
  GADNativeAdViewAdOptions *_nativeAdViewAdOptions;

  /// Native ad types requested.
  NSArray<GADAdLoaderAdType> *_nativeAdTypes;
}

@end

@implementation SampleAdapter

+ (NSString *)adapterVersion {
  return @"1.0";
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  // OPTIONAL: Create your own class implementing GADAdNetworkExtras and return that class type
  // here for your publishers to use. This class does not use extras.
  return Nil;
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  if (!connector) {
    return nil;
  }

  self = [super init];
  if (self) {
    _connector = connector;
    _adapterDelegate = [[SampleAdapterDelegate alloc] initWithAdapter:self connector:_connector];
  }
  return self;
}

- (void)getInterstitial {
  _interstitialAd = [[SampleInterstitial alloc] init];
  _interstitialAd.delegate = _adapterDelegate;
  _interstitialAd.adUnit = [_connector credentials][@"ad_unit"];

  SampleAdRequest *request = [[SampleAdRequest alloc] init];
  // Set up request parameters.
  request.testMode = _connector.testMode;
  request.keywords = _connector.userKeywords;

  [_interstitialAd fetchAd:request];
  NSLog(@"Requesting interstitial from Sample Ad Network");
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  _bannerAd =
      [[SampleBanner alloc] initWithFrame:CGRectMake(0, 0, adSize.size.width, adSize.size.height)];

  _bannerAd.delegate = _adapterDelegate;
  _bannerAd.adUnit = [_connector credentials][@"ad_unit"];

  // Set up request parameters.
  SampleAdRequest *request = [[SampleAdRequest alloc] init];
  request.testMode = _connector.testMode;
  request.keywords = _connector.userKeywords;
  [_bannerAd fetchAd:request];
  NSLog(@"Requesting banner from Sample Ad Network");
}

- (void)getNativeAdWithAdTypes:(NSArray *)adTypes options:(NSArray *)options {
  _nativeAdLoader = [[SampleNativeAdLoader alloc] init];
  _nativeAdLoader.adUnitID = [_connector credentials][@"ad_unit"];
  _nativeAdLoader.delegate = _adapterDelegate;

  SampleNativeAdRequest *sampleRequest = [[SampleNativeAdRequest alloc] init];

  // Part of the adapter's job is to examine the ad types and options, and then create a request for
  // the mediated network's SDK that matches them.
  //
  // Care needs to be taken to make sure the adapter respects the publisher's wishes in regard to
  // native ad formats. For example, if your ad network only provides app install ads, and the
  // publisher requests content ads alone, the adapter must report an error by calling the
  // connector's adapter:didFailAd: method with an error code set to kGADErrorInvalidRequest. It
  // should *not* request an app install ad anyway, and then attempt to map it to the content ad
  // format.
  //
  // In the case where an SDK doesn't distinguish between these ad types, this is not relevant.
  // For example, the Admob SDK now supports the unified native ad type, which covers both the app
  // install and content ad ad types.
  BOOL requestedUnified = [adTypes containsObject:kGADAdLoaderAdTypeUnifiedNative];

  if (!requestedUnified) {
    NSString *description = @"You must request a unified native ad.";
    NSDictionary *userInfo =
        @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
    NSError *error =
        [NSError errorWithDomain:@"com.google.mediation.sample" code:0 userInfo:userInfo];
    [_connector adapter:self didFailAd:error];
    return;
  }
  _nativeAdTypes = adTypes;

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

  for (GADAdLoaderOptions *loaderOptions in options) {
    if ([loaderOptions isKindOfClass:[GADNativeAdImageAdLoaderOptions class]]) {
      GADNativeAdImageAdLoaderOptions *imageOptions =
          (GADNativeAdImageAdLoaderOptions *)loaderOptions;
      switch (imageOptions.preferredImageOrientation) {
        case GADNativeAdImageAdLoaderOptionsOrientationLandscape:
          sampleRequest.preferredImageOrientation = NativeAdImageOrientationLandscape;
          break;
        case GADNativeAdImageAdLoaderOptionsOrientationPortrait:
          sampleRequest.preferredImageOrientation = NativeAdImageOrientationPortrait;
          break;
        case GADNativeAdImageAdLoaderOptionsOrientationAny:
        default:
          sampleRequest.preferredImageOrientation = NativeAdImageOrientationAny;
          break;
      }

      sampleRequest.shouldRequestMultipleImages = imageOptions.shouldRequestMultipleImages;

      // If the GADNativeAdImageAdLoaderOptions' disableImageLoading property is YES, the adapter
      // should send just the URLs for the images.
      sampleRequest.shouldDownloadImages = !imageOptions.disableImageLoading;
    } else if ([loaderOptions isKindOfClass:[GADNativeAdViewAdOptions class]]) {
      _nativeAdViewAdOptions = (GADNativeAdViewAdOptions *)loaderOptions;
    }
  }

  [_nativeAdLoader fetchAd:sampleRequest];
  NSLog(@"Requesting native ad from Sample Ad Network");
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  if ([_interstitialAd isInterstitialLoaded]) {
    [_interstitialAd show];
  }
}

- (void)stopBeingDelegate {
  _bannerAd.delegate = nil;
  _interstitialAd.delegate = nil;
  _nativeAdLoader.delegate = nil;
  _rewardBasedVideoAd.delegate = nil;
}

#pragma mark SampleAdapterDataProvider Methods

- (GADNativeAdViewAdOptions *)nativeAdViewAdOptions {
  return _nativeAdViewAdOptions;
}

- (NSArray<GADAdLoaderAdType> *)adTypes {
  return _nativeAdTypes;
}

#pragma mark Reward-based Video Ad Methods

/// Initializes and returns a sample adapter with a reward based video ad connector.
- (instancetype)initWithRewardBasedVideoAdNetworkConnector:
    (id<GADMRewardBasedVideoAdNetworkConnector>)connector {
  if (!connector) {
    return nil;
  }

  self = [super init];
  if (self) {
    _rewardBasedVideoAdConnector = connector;
    _adapterDelegate = [[SampleAdapterDelegate alloc] initWithRewardBasedVideoAdAdapter:self
                                                            rewardBasedVideoAdconnector:connector];
  }
  return self;
}

/// Tells the adapter to set up reward based video ads. When set up fails, the Sample SDK may try to
/// set up the adapter again.
- (void)setUp {
  _rewardBasedVideoAd = [SampleRewardBasedVideo sharedInstance];
  _rewardBasedVideoAd.delegate = _adapterDelegate;
  NSString *adUnit = [_rewardBasedVideoAdConnector credentials][@"ad_unit"];
  _rewardBasedVideoAd.adUnitID = adUnit;

  SampleAdRequest *request = [[SampleAdRequest alloc] init];
  // Set up request parameters.
  request.testMode = _connector.testMode;
  request.keywords = _connector.userKeywords;

  [_rewardBasedVideoAd initializeWithAdRequest:request adUnitID:adUnit];
}

/// Tells the adapter to request a reward based video ad, if checkAdAvailability is true. Otherwise,
/// the connector notifies the adapter that the reward based video ad failed to load.
- (void)requestRewardBasedVideoAd {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardBasedVideoAdConnector;
  if ([_rewardBasedVideoAd checkAdAvailability]) {
    [strongConnector adapterDidReceiveRewardBasedVideoAd:self];
  } else {
    NSString *description = @"Failed to load ad.";
    NSDictionary *userInfo =
        @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
    NSError *error =
        [NSError errorWithDomain:@"com.google.mediation.sample" code:0 userInfo:userInfo];
    [strongConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:error];
  }
}

/// Tells the adapter to present the reward based video ad with the provided view controller, if the
/// ad is available. Otherwise, logs a message with the reason for failure.
- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
  if ([_rewardBasedVideoAd checkAdAvailability]) {
    // The reward based video ad is available, present the ad.
    [_rewardBasedVideoAd presentFromRootViewController:viewController];
  } else {
    // Because publishers are expected to check that an ad is available before trying to show one,
    // the above conditional should always hold true. If for any reason the adapter is not ready to
    // present an ad, however, it should log an error with reason for failure.
    NSLog(@"No ads to show.");
  }
}

@end
