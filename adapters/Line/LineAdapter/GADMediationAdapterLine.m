// Copyright 2023 Google LLC
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

#import "GADMediationAdapterLine.h"

#import <FiveAd/FiveAd.h>

#import "GADMediationAdapterLineConstants.h"
#import "GADMediationAdapterLineInterstitialAdLoader.h"
#import "GADMediationAdapterLineUtils.h"

/// Returns application ID from the configuration.
static NSString *_Nullable GADMediationAdapterLineApplicationID(
    GADMediationServerConfiguration *configuration, NSError *_Nullable *_Nonnull errorPtr) {
  if (!configuration.credentials.count) {
    *errorPtr = GADMediationAdapterLineErrorWithCodeAndDescription(
        GADMediationAdapterLineErrorInvalidServerParameters,
        @"Server configuration did not contain a credential for LINE mediation.");
    return nil;
  }

  NSArray<GADMediationCredentials *> *credentialsArray = configuration.credentials;
  NSMutableSet<NSString *> *applicationIDSet = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *credentials in credentialsArray) {
    GADMediationAdapterLineMutableSetAddObject(
        applicationIDSet, credentials.settings[GADMediationAdapterLineCredentialKeyApplicationID]);
  }

  if (!applicationIDSet.count) {
    *errorPtr = GADMediationAdapterLineErrorWithCodeAndDescription(
        GADMediationAdapterLineErrorInvalidServerParameters,
        @"Server configuration did not contain any application ID for LINE mediation.");
    return nil;
  }

  NSString *applicationID = applicationIDSet.anyObject;
  if (applicationIDSet.count > 1) {
    GADMediationAdapterLineLog(@"Found multiple application IDs. Please remove unused application "
                               @"IDs from the AdMob UI. Application IDs: %@",
                               applicationIDSet);
    GADMediationAdapterLineLog(@"Initializing FiveAd SDK with the application ID: %@",
                               applicationID);
  }
  return applicationID;
}

@implementation GADMediationAdapterLine {
  // The interstitial ad loader.
  GADMediationAdapterLineInterstitialAdLoader *_interstitialAdLoader;
}

+ (GADVersionNumber)adapterVersion {
  GADVersionNumber version = {0};
  NSArray<NSString *> *components =
      [GADMediationAdapterLineVersion componentsSeparatedByString:@"."];
  if (components.count == 4) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue * 100 + components[3].integerValue;
  }
  return version;
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [FADSettings semanticVersion];
  NSArray<NSString *> *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 3) {
    version.majorVersion = versionComponents[0].integerValue;
    version.minorVersion = versionComponents[1].integerValue;
    version.patchVersion = versionComponents[2].integerValue;
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return Nil;
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSCAssert(completionHandler, @"Completion handler must not be nil.");

  if (FADSettings.isConfigRegistered) {
    GADMediationAdapterLineLog(@"FiveAd SDK is already registered");
    completionHandler(nil);
    return;
  }

  NSError *error = nil;
  NSString *applicationID = GADMediationAdapterLineApplicationID(configuration, &error);
  if (error) {
    completionHandler(error);
    return;
  }

  // Initialize FiveAd SDK.
  GADMobileAds *mobileAds = GADMobileAds.sharedInstance;
  FADConfig *config = [[FADConfig alloc] initWithAppId:applicationID];
  [config enableSoundByDefault:!mobileAds.applicationMuted];
  [config setIsTest:mobileAds.requestConfiguration.testDeviceIdentifiers.count];
  // TODO: set GDPR using [config setNeedGdprNonPersonalizedAdsTreatment:]
  // TODO: set COPPA using [config setNeedChildDirectedTreatment:]
  [FADSettings registerConfig:config];

  completionHandler(nil);
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  _interstitialAdLoader = [[GADMediationAdapterLineInterstitialAdLoader alloc] init];
  [_interstitialAdLoader loadInterstitialAdForAdConfiguration:adConfiguration
                                            completionHandler:completionHandler];
}

@end
