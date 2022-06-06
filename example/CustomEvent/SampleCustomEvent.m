// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "SampleCustomEvent.h"
#import <Foundation/Foundation.h>
#import <SampleAdSDK/SampleAdSDK.h>
#import "SampleCustomEventBanner.h"
#import "SampleCustomEventConstants.h"
#import "SampleCustomEventInterstitial.h"
#import "SampleCustomEventNativeAd.h"
#import "SampleCustomEventRewarded.h"

@implementation SampleCustomEvent {
  SampleCustomEventRewarded *sampleRewarded;

  SampleCustomEventBanner *sampleBanner;

  SampleCustomEventNativeAd *sampleNative;

  SampleCustomEventInterstitial *sampleInterstitial;
}

#pragma mark GADMediationAdapter implementation

+ (GADVersionNumber)adSDKVersion {
  NSArray *versionComponents = [SampleAdRequest.SampleSDKVersion componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};
  if (versionComponents.count >= 3) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion = [versionComponents[2] integerValue];
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return Nil;
}

+ (GADVersionNumber)adapterVersion {
  NSArray *versionComponents = [SampleCustomEventAdapterVersion componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  // This is where you you will initialize the SDK that this custom event is built for.
  // Upon finishing the SDK initialization, call the completion handler with success.
  completionHandler(nil);
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  sampleBanner = [[SampleCustomEventBanner alloc] init];
  [sampleBanner loadBannerForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  sampleInterstitial = [[SampleCustomEventInterstitial alloc] init];
  [sampleInterstitial loadInterstitialForAdConfiguration:adConfiguration
                                       completionHandler:completionHandler];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  sampleRewarded = [[SampleCustomEventRewarded alloc] init];
  [sampleRewarded loadRewardedAdForAdConfiguration:adConfiguration
                                 completionHandler:completionHandler];
}

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler {
  sampleNative = [[SampleCustomEventNativeAd alloc] init];
  [sampleNative loadNativeAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

@end
