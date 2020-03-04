// Copyright 2019 Google LLC.
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

#import "GADMediationAdapterChartboost.h"
#import "GADMAdapterChartboostConstants.h"
#import "GADMAdapterChartboostSingleton.h"
#import "GADMChartboostExtras.h"
#import "GADMChartboostError.h"
#import "GADCHBRewarded.h"
#if __has_include(<Chartboost/Chartboost+Mediation.h>)
#import <Chartboost/Chartboost.h>
#else
#import "Chartboost.h"
#endif

@implementation GADMediationAdapterChartboost {
  GADCHBRewarded *_rewarded;
}

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSString *appID = nil;
  NSString *appSignature = nil;
  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *ID = cred.settings[kGADMAdapterChartboostAppID];
    NSString *signature = cred.settings[kGADMAdapterChartboostAppSignature];
    if (ID && signature) {
      if (!appID && !appSignature) {
        appID = ID;
        appSignature = signature;
      } else {
        NSLog(@"Found multiple app IDs: %@. "
              @"Please remove any app IDs you are not using from the AdMob UI.",
              configuration.credentials);
        NSLog(@"Initializing Chartboost SDK with the app ID: %@ and app signature: %@", appID,
              appSignature);
        break;
      }
    }
  }
  GADMAdapterChartboostSingleton *sharedInstance = GADMAdapterChartboostSingleton.sharedInstance;
  [sharedInstance startWithAppId:appID
                    appSignature:appSignature
               completionHandler:completionHandler];
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMChartboostExtras class];
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [Chartboost getSDKVersion];
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
  NSString *versionString = kGADMAdapterChartboostVersion;
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
  
  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion =
    [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

- (void)initializeChartboostWithAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                                     completion:(ChartboostInitCompletionHandler)completion {
  GADMAdapterChartboostSingleton *sharedInstance = [GADMAdapterChartboostSingleton sharedInstance];
  [sharedInstance startWithAppId:adConfiguration.credentials.settings[kGADMAdapterChartboostAppID]
                    appSignature:adConfiguration.credentials.settings[kGADMAdapterChartboostAppSignature]
               completionHandler:completion];
}

- (NSString *)locationFromAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration {
  NSString *location = adConfiguration.credentials.settings[kGADMAdapterChartboostAdLocation];
  if ([location isKindOfClass:NSString.class]) {
    location = [location stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  }
  location = location.length > 0 ? location : CBLocationDefault;
  return location;
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
  __weak GADMediationAdapterChartboost * weakSelf = self;
  [self initializeChartboostWithAdConfiguration:adConfiguration completion:^(NSError * _Nullable error) {
    if (error) {
      completionHandler(nil, error);
      return;
    }
    GADMediationAdapterChartboost *strongSelf = weakSelf;
    if (!strongSelf) {
      NSError *error = GADChartboostError(kGADErrorMediationAdapterError,
                                          @"GADMediationAdapterChartboost deallocated before "
                                          @"rewarded ad could be loaded");
      completionHandler(nil, error);
      return;
    }
    
    GADMAdapterChartboostSingleton *chartboost = GADMAdapterChartboostSingleton.sharedInstance;
    [strongSelf->_rewarded destroy];
    strongSelf->_rewarded =
    [[GADCHBRewarded alloc] initWithLocation:[strongSelf locationFromAdConfiguration:adConfiguration]
                                   mediation:[chartboost mediation]
                             adConfiguration:adConfiguration
                           completionHandler:completionHandler];
    [chartboost setFrameworkWithExtras:[adConfiguration extras]];
    [strongSelf->_rewarded load];
  }];
}

@end
