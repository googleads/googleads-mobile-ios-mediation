// Copyright 2019 Google Inc.
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

#import "GADMediationAdapterNend.h"

#import <NendAd/NendAd.h>

#import "GADMAdapterNend.h"
#import "GADMAdapterNendConstants.h"
#import "GADMAdapterNendNativeAdLoader.h"
#import "GADMAdapterNendRewardedAd.h"
#import "GADMediationAdapterNendNativeForwarder.h"
#import "GADNendRewardedNetworkExtras.h"

@interface GADMediationAdapterNend ()

@property(nonatomic, strong) GADMAdapterNendRewardedAd *rewardedAd;
@property(nonatomic, strong) GADMediationAdapterNendNativeForwarder *nativeMediation;

@end

@implementation GADMediationAdapterNend

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  // INFO: Nend SDK doesn't have any initialization API.
  completionHandler(nil);
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [[NSNumber numberWithDouble:NendAdVersionNumber] stringValue];
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 3) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion = [versionComponents[2] integerValue];
  } else {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion = 0;
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterNendExtras class];
}

+ (nonnull NSString *)adapterVersion {
  return kGADMAdapterNendVersion;
}

- (void)stopBeingDelegate { /* Do nothing here */
}

- (void)getBannerWithSize:(GADAdSize)adSize { /* Do nothing here */
}

- (void)getInterstitial { /* Do nothing here */
}

- (void)presentInterstitialFromRootViewController:
    (nonnull UIViewController *)rootViewController { /* Do nothing here */
}

- (void)getNativeAdWithAdTypes:(NSArray<GADAdLoaderAdType> *)adTypes
                       options:(NSArray<GADAdLoaderOptions *> *)options {
  [self.nativeMediation getNativeAdWithAdTypes:adTypes options:options];
}

- (BOOL)handlesUserImpressions {
  return YES;
}

- (BOOL)handlesUserClicks {
  return YES;
}

- (nonnull instancetype)initWithGADMAdNetworkConnector:
    (nonnull id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self != nil) {
    _nativeMediation = [[GADMediationAdapterNendNativeForwarder alloc] initWithAdapter:self
                                                                             connector:connector];
  }
  return self;
}

+ (GADVersionNumber)version {
  NSArray *versionComponents = [kGADMAdapterNendVersion componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

- (void)loadRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  self.rewardedAd = [[GADMAdapterNendRewardedAd alloc] init];
  [self.rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                                  completionHandler:completionHandler];
}

@end
