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

#import "GADMediationAdapterIMobile.h"
#import "GADIMobileMediatedUnifiedNativeAd.h"
#import "GADMAdapterIMobileConstants.h"
#import "GADMAdapterIMobileUtils.h"

@implementation GADMediationAdapterIMobile {
  /// Connector for AdMob.
  __weak id<GADMAdNetworkConnector> _connector;

  /// View for i-mobile SDK.
  UIView *_sdkView;

  /// i-mobile spot id.
  NSString *_spotID;
}

#pragma mark - GADMediationAdapter

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  // i-Mobile SDK doesn't have any initialization API.
  completionHandler(nil);
}

+ (GADVersionNumber)adSDKVersion {
  // i-Mobile SDK doesn't have any API to get the version.
  GADVersionNumber version = {0};
  return version;
}

+ (GADVersionNumber)version {
  GADVersionNumber version = {0};
  NSArray<NSString *> *components = [kGADMAdapterIMobileVersion componentsSeparatedByString:@"."];

  if (components.count >= 4) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue * 100 + components[3].integerValue;
  }

  return version;
}

#pragma mark - GADMAdNetworkAdapter

+ (NSString *)adapterVersion {
  return kGADMAdapterIMobileVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return Nil;
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    // Initialize.
    _connector = connector;
    _sdkView = [[UIView alloc] init];

    // Get parameters for i-mobile SDK.
    NSDictionary<NSString *, NSString *> *params = [connector credentials];
    NSString *publisherId = params[kGADMAdapterIMobilePublisherIdKey];
    NSString *mediaId = params[kGADMAdapterIMobileMediaIdKey];
    _spotID = params[kGADMAdapterIMobileSpotIdKey];

    // Call i-mobile SDK.
    [ImobileSdkAds registerWithPublisherID:publisherId MediaID:mediaId SpotID:_spotID];
    [ImobileSdkAds startBySpotID:_spotID];
  }
  return self;
}

/// Not supported.
- (void)getBannerWithSize:(GADAdSize)adSize {
  NSString *errorString =
      @"GADMediationAdapterIMobile doesn't support banner ads. Please use GADMAdapterIMobile.";
  NSError *error =
      GADMAdapterIMobileErrorWithCodeAndDescription(kGADErrorInvalidRequest, errorString);
  [_connector adapter:self didFailAd:error];
}

/// Not supported.
- (void)getInterstitial {
  NSString *errorString = @"GADMediationAdapterIMobile doesn't support interstitial ads. Please "
                          @"use GADMAdapterIMobile.";
  NSError *error =
      GADMAdapterIMobileErrorWithCodeAndDescription(kGADErrorInvalidRequest, errorString);
  [_connector adapter:self didFailAd:error];
}

- (void)stopBeingDelegate {
  _sdkView = nil;
}

/// Not supported.
- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  NSString *errorString = @"GADMediationAdapterIMobile doesn't support interstitial ads. Please "
                          @"use GADMAdapterIMobile.";
  NSError *error =
      GADMAdapterIMobileErrorWithCodeAndDescription(kGADErrorInvalidRequest, errorString);
  [_connector adapter:self didFailAd:error];
}

- (void)getNativeAdWithAdTypes:(NSArray<GADAdLoaderAdType> *)adTypes
                       options:(NSArray<GADAdLoaderOptions *> *)options {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  // Validate adTypes.
  if (![adTypes containsObject:kGADAdLoaderAdTypeUnifiedNative]) {
    NSError *error = GADMAdapterIMobileErrorWithCodeAndDescription(
        kGADErrorInvalidRequest, @"GADMediationAdapterIMobile only supports UnifiedNative.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  // Call i-mobile SDK.
  [ImobileSdkAds getNativeAdData:_spotID
                            View:_sdkView
                          Params:[[ImobileSdkAdsNativeParams alloc] init]
                        Delegate:self];
}

#pragma mark - IMobileSdkAdsDelegate

- (void)imobileSdkAdsSpot:(NSString *)spotId
         didFailWithValue:(ImobileSdkAdsFailResult)value {
  [self stopBeingDelegate];
  NSInteger errorCode = GADMAdapterIMobileAdMobErrorFromIMobileResult(value);
  NSString *errorString = [NSString stringWithFormat:@"Failed to get an ad for spotID: %@", spotId];
  NSError *error = GADMAdapterIMobileErrorWithCodeAndDescription(errorCode, errorString);
  [_connector adapter:self didFailAd:error];
}

- (void)onNativeAdDataReciveCompleted:(NSString *)spotId nativeArray:(NSArray<id> *)nativeArray {
  // Check ad data.
  if ([nativeArray count] == 0) {
    NSError *error =
        GADMAdapterIMobileErrorWithCodeAndDescription(kGADErrorNoFill, @"No ads to show.");
    [_connector adapter:self didFailAd:error];
    return;
  }

  // Get ad image.
  ImobileSdkAdsNativeObject *iMobileNativeAd = nativeArray[0];
  [iMobileNativeAd getAdImageCompleteHandler:^(UIImage *image) {
    id<GADMAdNetworkConnector> strongConnector = self->_connector;
    if (!image) {
      NSError *error = GADMAdapterIMobileErrorWithCodeAndDescription(
          kGADErrorNoFill, @"Can't download native ad assets.");
      [strongConnector adapter:self didFailAd:error];
      return;
    }
    GADIMobileMediatedUnifiedNativeAd *unifiedAd =
        [[GADIMobileMediatedUnifiedNativeAd alloc] initWithIMobileNativeAd:iMobileNativeAd
                                                                     image:image];
    [strongConnector adapter:self didReceiveMediatedUnifiedNativeAd:unifiedAd];
  }];
}

@end
