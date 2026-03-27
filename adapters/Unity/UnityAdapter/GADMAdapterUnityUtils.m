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

NSError *_Nonnull GADMAdapterUnitySDKErrorWithUnityAdsLoadErrorAndMessage(
    UnityAdsLoadError loadError, NSString *_Nonnull message) {
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : message, NSLocalizedFailureReasonErrorKey : message};
  NSError *error = [NSError errorWithDomain:GADMAdapterUnitySDKErrorDomain
                                       code:loadError
                                   userInfo:userInfo];
  return error;
}

GADMAdapterUnityConsentResult GADMAdapterUnityHasACConsent(NSInteger vendorId) {
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

  NSInteger gdprApplies = [userDefaults integerForKey:@"IABTCF_gdprApplies"];
  if (gdprApplies != 1) {
    return GADMAdapterUnityConsentResultUnknown;
  }

  NSString *additionalConsentString = [userDefaults stringForKey:@"IABTCF_AddtlConsent"];
  if (!additionalConsentString.length) {
    return GADMAdapterUnityConsentResultUnknown;
  }

  NSString *vendorIdString = @(vendorId).stringValue;
  NSArray<NSString *> *additionalConsentParts =
      [additionalConsentString componentsSeparatedByString:@"~"];

  NSInteger version = additionalConsentParts[0].integerValue;
  if (version == 1) {
    // Spec version 1
    GADMUnityLog("The IABTCF_AddtlConsent string uses version 1 of Google’s Additional Consent "
                 "spec. Version 1 does not report vendors to whom the user denied consent. To "
                 "detect vendors that the user denied consent, upgrade to a CMP that supports "
                 "version 2 of Google's Additional Consent technical specification.");

    if (additionalConsentParts.count == 1) {
      // The AC string had no consented vendor.
      return GADMAdapterUnityConsentResultUnknown;
    } else if (additionalConsentParts.count == 2) {
      NSArray<NSString *> *consentedIds =
          [additionalConsentParts[1] componentsSeparatedByString:@"."];
      if ([consentedIds containsObject:vendorIdString]) {
        return GADMAdapterUnityConsentResultTrue;
      }

      return GADMAdapterUnityConsentResultUnknown;
    } else {
      NSString *errorMessage =
          [NSString stringWithFormat:
                        @"Could not parse the IABTCF_AddtlConsent string: \"%@\". String had more "
                        @"parts than expected. Did your CMP write IABTCF_AddtlConsent correctly?",
                        additionalConsentString];
      GADMUnityLog(@"%@", errorMessage);
      return GADMAdapterUnityConsentResultUnknown;
    }
  } else if (version >= 2) {
    // Spec version 2 and above.
    if (additionalConsentParts.count < 3) {
      NSString *errorMessage =
          [NSString stringWithFormat:
                        @"Could not parse the IABTCF_AddtlConsent string: \"%@\". String has less "
                        @"parts than expected. Did your CMP write IABTCF_AddtlConsent correctly?",
                        additionalConsentString];
      GADMUnityLog(@"%@", errorMessage);
      return GADMAdapterUnityConsentResultUnknown;
    }

    NSArray<NSString *> *disclosedIds =
        [additionalConsentParts[2] componentsSeparatedByString:@"."];
    if (![disclosedIds[0] isEqualToString:@"dv"]) {
      NSString *errorMessage = [NSString
          stringWithFormat:
              @"Could not parse the IABTCF_AddtlConsent string: \"%@\". Expected disclosed vendors "
              @"part to have the string \"dv.\". Did your CMP write IABTCF_AddtlConsent correctly?",
              additionalConsentString];
      GADMUnityLog(@"%@", errorMessage);
      return GADMAdapterUnityConsentResultUnknown;
    }

    NSArray<NSString *> *consentedIds =
        [additionalConsentParts[1] componentsSeparatedByString:@"."];
    if ([consentedIds containsObject:vendorIdString]) {
      return GADMAdapterUnityConsentResultTrue;
    }

    if ([disclosedIds containsObject:vendorIdString]) {
      return GADMAdapterUnityConsentResultFalse;
    }

    return GADMAdapterUnityConsentResultUnknown;
  } else {
    // Unknown spec version
    NSString *errorMessage = [NSString
        stringWithFormat:@"Could not parse the IABTCF_AddtlConsent string: \"%@\". Spec version "
                         @"was unexpected. Did your CMP write IABTCF_AddtlConsent correctly?",
                         additionalConsentString];
    GADMUnityLog(@"%@", errorMessage);
    return GADMAdapterUnityConsentResultUnknown;
  }
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
