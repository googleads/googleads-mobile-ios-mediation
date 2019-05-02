// Copyright 2018 Google Inc.
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

#import "GADMediationAdapterAppLovin.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinExtras.h"
#import "GADMAdapterAppLovinRewardedRenderer.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMRTBAdapterAppLovinBannerRenderer.h"
#import "GADMRTBAdapterAppLovinInterstitialRenderer.h"

@interface GADMediationAdapterAppLovin ()
@property(nonatomic, strong) GADMAdapterAppLovinRewardedRenderer *rewardedRenderer;
@property(nonatomic, strong) GADMRTBAdapterAppLovinBannerRenderer *bannerRenderer;
@property(nonatomic, strong) GADMRTBAdapterAppLovinInterstitialRenderer *interstitialRenderer;
@end

@implementation GADMediationAdapterAppLovin

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  // Compile all the SDK keys we should initialize for
  NSMutableSet<NSString *> *sdkKeys = [NSMutableSet set];
  NSObject *sdkKeysLock = [[NSObject alloc] init];

  // Compile SDK keys from configuration credentials
  for (GADMediationCredentials *credentials in configuration.credentials) {
    NSString *sdkKey = credentials.settings[GADMAdapterAppLovinConstant.sdkKey];
    if (sdkKey) {
      [sdkKeys addObject:sdkKey];
    }
  }

  // Add SDK key from Info.plist if exists
  if ([GADMAdapterAppLovinUtils infoDictionaryHasValidSDKKey]) {
    NSString *sdkKey = [GADMAdapterAppLovinUtils infoDictionarySDKKey];
    [sdkKeys addObject:sdkKey];
  }

  // Log to the publisher that having more than 1 SDK key is... abnormal
  if (sdkKeys.count > 1) {
    [GADMAdapterAppLovinUtils
        log:@"Found %lu SDK keys. Please remove any SDK keys you are not using from the AdMob UI.",
            sdkKeys.count];
  }

  // Initialize SDKs based on SDK keys
  NSSet<NSString *> *sdkKeysCopy = [sdkKeys copy];
  for (NSString *sdkKey in sdkKeysCopy) {
    [GADMAdapterAppLovinUtils log:@"Initializing SDK for SDK key %@", sdkKey];

    ALSdk *sdk = [GADMAdapterAppLovinUtils retrieveSDKFromSDKKey:sdkKey];
    [sdk initializeSdkWithCompletionHandler:^(ALSdkConfiguration *configuration) {
      @synchronized(sdkKeysLock) {
        [sdkKeys removeObject:sdkKey];

        // Once all instances of SDK keys have been initialized, callback the initialization
        // listener
        if (sdkKeys.count == 0) {
          [GADMAdapterAppLovinUtils log:@"All SDK(s) completed initialization"];
          completionHandler(nil);
        }
      }
    }];
  }
}

+ (GADVersionNumber)version {
  NSString *versionString = GADMAdapterAppLovinConstant.adapterVersion;
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
  [GADMAdapterAppLovinUtils
      log:[NSString stringWithFormat:@"AppLovin adapter version: %@", versionString]];
  GADVersionNumber version = {0};
  if (versionComponents.count == 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    // Adapter versions have 2 patch versions. Multiply the first patch by 100.
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = ALSdk.version;
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
  [GADMAdapterAppLovinUtils
      log:[NSString stringWithFormat:@"AppLovin SDK version: %@", versionString]];
  GADVersionNumber version = {0};
  if (versionComponents.count == 3) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion = [versionComponents[2] integerValue];
  }
  return version;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterAppLovinExtras class];
}

- (void)collectSignalsForRequestParameters:(GADRTBRequestParameters *)params
                         completionHandler:(GADRTBSignalCompletionHandler)completionHandler {
  [GADMAdapterAppLovinUtils log:@"AppLovin adapter collecting signals."];
  // Check if supported ad format
  if (params.credentials.format == GADAdFormatNative) {
    [self handleCollectSignalsFailureForMessage:
              @"Requested to collect signal for unsupported native ad format. Ignoring..."
                              completionHandler:completionHandler];
    return;
  }

  ALSdk *sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials:params.credentials.settings];

  NSString *signal = sdk.adService.bidToken;

  if (signal.length > 0) {
    [GADMAdapterAppLovinUtils log:@"Generated bid token %@", signal];
    completionHandler(signal, nil);
  } else {
    [GADMAdapterAppLovinUtils log:@"Failed to generate bid token"];
    [self handleCollectSignalsFailureForMessage:@"Failed to generate bid token"
                              completionHandler:completionHandler];
  }
}

- (void)handleCollectSignalsFailureForMessage:(NSString *)errorMessage
                            completionHandler:(GADRTBSignalCompletionHandler)completionHandler {
  NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.rtbErrorDomain
                                       code:kGADErrorMediationAdapterError
                                   userInfo:@{NSLocalizedFailureReasonErrorKey : errorMessage}];
  [GADMAdapterAppLovinUtils log:errorMessage];
  completionHandler(nil, error);
}

- (void)dealloc {
  self.bannerRenderer = nil;
  self.interstitialRenderer = nil;
  self.rewardedRenderer = nil;
}

#pragma mark - GADMediationAdapter load Ad

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  self.bannerRenderer =
      [[GADMRTBAdapterAppLovinBannerRenderer alloc] initWithAdConfiguration:adConfiguration
                                                          completionHandler:completionHandler];
  [self.bannerRenderer loadAd];
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  self.interstitialRenderer = [[GADMRTBAdapterAppLovinInterstitialRenderer alloc]
      initWithAdConfiguration:adConfiguration
            completionHandler:completionHandler];
  [self.interstitialRenderer loadAd];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  self.rewardedRenderer =
      [[GADMAdapterAppLovinRewardedRenderer alloc] initWithAdConfiguration:adConfiguration
                                                         completionHandler:completionHandler];
  /// If adConfiguration has a bid response, this load call is for open bidding.
  if (adConfiguration.bidResponse) {
    [self.rewardedRenderer requestRTBRewardedAd];
  } else {
    [self.rewardedRenderer requestRewardedAd];
  }
}

@end
