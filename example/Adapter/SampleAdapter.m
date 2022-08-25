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

#import "SampleAdapter.h"
#import <SampleAdSDK/SampleAdSDK.h>
#import "SampleAdapterConstants.h"
#import "SampleAdapterDelegate.h"
#import "SampleExtras.h"

@interface SampleAdapter () <SampleRewardedAdDelegate, GADMediationRewardedAd> {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Handles delegate notifications.
  SampleAdapterDelegate *_adapterDelegate;

  /// Handle banner ads from Sample SDK.
  SampleBanner *_bannerAd;

  /// Handle interstitial ads from Sample SDK.
  SampleInterstitial *_interstitialAd;

  /// Handle rewarded ads from Sample SDK.
  SampleRewardedAd *_rewardedAd;

  /// An ad loader to use in loading native ads from Sample SDK.
  SampleNativeAdLoader *_nativeAdLoader;

  /// Native ad view options.
  GADNativeAdViewAdOptions *_nativeAdViewAdOptions;

  /// Handles any callback when the sample rewarded ad finishes loading.
  GADMediationRewardedLoadCompletionHandler _loadCompletionHandler;

  /// Delegate for receiving rewarded ad notifications.
  __weak id<GADMediationRewardedAdEventDelegate> _rewardedAdDelegate;
}

@end

@implementation SampleAdapter

+ (NSString *)adapterVersion {
  return @"1.0";
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
  _interstitialAd =
      [[SampleInterstitial alloc] initWithAdUnitID:[_connector credentials][@"ad_unit"]];
  _interstitialAd.delegate = _adapterDelegate;

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
}

#pragma mark SampleAdapterDataProvider Methods

- (GADNativeAdViewAdOptions *)nativeAdViewAdOptions {
  return _nativeAdViewAdOptions;
}

#pragma mark GADMediationAdapter implementation

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [SampleExtras class];
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = SampleSDKVersion;
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 3) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion = [versionComponents[2] integerValue];
  }
  return version;
}

+ (GADVersionNumber)version {
  NSString *versionString = SampleAdapterVersion;
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    // Adapter versions have 2 patch versions. Multiply the first patch by 100.
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  // Since the Sample SDK doesn't need to initialize, the completion handler is called directly
  // here.
  completionHandler(nil);
}

- (void)dealloc {
  _rewardedAd = nil;
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  _loadCompletionHandler = completionHandler;

  NSString *adUnit = adConfiguration.credentials.settings[SampleSDKAdUnitIDKey];
  SampleExtras *extras = adConfiguration.extras;

  _rewardedAd = [[SampleRewardedAd alloc] initWithAdUnitID:adUnit];
  _rewardedAd.enableDebugLogging = extras.enableDebugLogging;

  // Check the extras to see if the request should be customized.
  SampleAdRequest *request = [[SampleAdRequest alloc] init];
  request.mute = extras.muteAudio;

  // Set the delegate on the rewarded ad to listen for callbacks from the Sample SDK.
  _rewardedAd.delegate = self;
  [_rewardedAd fetchAd:request];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if (!_rewardedAd.isReady) {
    NSError *error =
        [NSError errorWithDomain:kAdapterErrorDomain
                            code:0
                        userInfo:@{NSLocalizedDescriptionKey : @"Unable to display ad."}];
    [_rewardedAdDelegate didFailToPresentWithError:error];
    return;
  }
  [_rewardedAd presentFromRootViewController:viewController];
}

#pragma mark SampleRewardedAdDelegate methods

- (void)rewardedAdDidReceiveAd:(nonnull SampleRewardedAd *)rewardedAd {
  _rewardedAdDelegate = _loadCompletionHandler(self, nil);
}

- (void)rewardedAdDidDismiss:(nonnull SampleRewardedAd *)rewardedAd {
  [_rewardedAdDelegate willDismissFullScreenView];
  [_rewardedAdDelegate didEndVideo];
  [_rewardedAdDelegate didDismissFullScreenView];
}

- (void)rewardedAdDidFailToLoadWithError:(SampleErrorCode)errorCode {
  _loadCompletionHandler(nil, [NSError errorWithDomain:kAdapterErrorDomain
                                                  code:GADErrorNoFill
                                              userInfo:nil]);
}

- (void)rewardedAdDidPresent:(nonnull SampleRewardedAd *)rewardedAd {
  [_rewardedAdDelegate willPresentFullScreenView];
  [_rewardedAdDelegate didStartVideo];
  [_rewardedAdDelegate reportImpression];
}

- (void)rewardedAd:(nonnull SampleRewardedAd *)rewardedAd userDidEarnReward:(NSUInteger)reward {
  GADAdReward *aReward =
      [[GADAdReward alloc] initWithRewardType:@""
                                 rewardAmount:[NSDecimalNumber numberWithUnsignedInt:reward]];
  [_rewardedAdDelegate didRewardUserWithReward:aReward];
}

@end
