// Copyright 2020 Google LLC.
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

#import "GADMAdapterUnityUtils.h"
#import "GADMAdapterUnityConstants.h"

void GADMAdapterUnityConfigureMediationService(void) {
  UADSMediationMetaData *mediationMetaData = [[UADSMediationMetaData alloc] init];
  [mediationMetaData setName:GADMAdapterUnityMediationNetworkName];
  [mediationMetaData setVersion:GADMAdapterUnityVersion];
  [mediationMetaData set:@"adapter_version" value:[UnityAds getVersion]];
  [mediationMetaData commit];
}

void GADMAdapterUnityMutableArrayAddObject(NSMutableArray *_Nullable array,
                                           NSObject *_Nonnull object) {
  if (object) {
    [array addObject:object];  // Allow pattern.
  }
}

void GADMAdapterUnityMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

NSError *_Nonnull GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorCode code,
                                                              NSString *_Nonnull description) {
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMAdapterUnityErrorDomain
                                       code:code
                                   userInfo:userInfo];
  return error;
}

NSError *_Nonnull GADMAdapterUnitySDKErrorWithUnityAdsShowErrorAndMessage(
    UnityAdsShowError errorCode, NSString *_Nonnull message) {
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : message, NSLocalizedFailureReasonErrorKey : message};
  NSError *error = [NSError errorWithDomain:GADMAdapterUnitySDKErrorDomain
                                       code:errorCode
                                   userInfo:userInfo];
  return error;
}

GADAdSize supportedAdSizeFromRequestedSize(GADAdSize gadAdSize) {
  NSArray *potentials =
      @[ NSValueFromGADAdSize(GADAdSizeBanner), NSValueFromGADAdSize(GADAdSizeLeaderboard) ];
  return GADClosestValidSizeForAdSizes(gadAdSize, potentials);
}

GADVersionNumber extractVersionFromString(NSString *_Nonnull string) {
  GADVersionNumber version = {0};
  NSArray<NSString *> *components = [string componentsSeparatedByString:@"."];
  if (components.count >= 3) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    NSInteger patch = components[2].integerValue;
    version.patchVersion = components.count == 4 ? patch * 100 + components[3].integerValue : patch;
  }
  return version;
}
