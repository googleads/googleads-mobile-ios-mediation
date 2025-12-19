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

#import "GADMAdapterPangleUtils.h"
#import "GADMediationAdapterPangleConstants.h"

NSError *_Nonnull GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorCode code,
                                                               NSString *_Nonnull description) {
  return [NSError errorWithDomain:GADMAdapterPangleErrorDomain
                             code:code
                         userInfo:@{
                           NSLocalizedDescriptionKey : description,
                           NSLocalizedFailureReasonErrorKey : description
                         }];
}

NSError *_Nonnull GADMAdapterPangleChildUserError(void) {
  NSString *errorMsg = @"GADMobileAds.sharedInstance.requestConfiguration indicates the user is a "
                       @"child. Pangle SDK V71 or higher does not support child users.";
  return GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorChildUser, errorMsg);
  ;
}

void GADMAdapterPangleMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

GADMAdapterPangleConsentResult GADMAdapterPangleHasACConsent(NSInteger vendorId) {
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

  NSInteger gdprApplies = [userDefaults integerForKey:@"IABTCF_gdprApplies"];
  if (gdprApplies != 1) {
    return GADMAdapterPangleConsentResultUnknown;
  }

  NSString *additionalConsentString = [userDefaults stringForKey:@"IABTCF_AddtlConsent"];
  if (!additionalConsentString.length) {
    return GADMAdapterPangleConsentResultUnknown;
  }

  NSString *vendorIdString = @(vendorId).stringValue;
  NSArray<NSString *> *additionalConsentParts =
      [additionalConsentString componentsSeparatedByString:@"~"];

  NSInteger version = additionalConsentParts[0].integerValue;
  if (version == 1) {
    // Spec version 1
    NSLog(@"The IABTCF_AddtlConsent string uses version 1 of Google’s Additional Consent "
           "spec. Version 1 does not report vendors to whom the user denied consent. To "
           "detect vendors that the user denied consent, upgrade to a CMP that supports "
           "version 2 of Google's Additional Consent technical specification.");

    if (additionalConsentParts.count == 1) {
      // The AC string had no consented vendor.
      return GADMAdapterPangleConsentResultUnknown;
    } else if (additionalConsentParts.count == 2) {
      NSArray<NSString *> *consentedIds =
          [additionalConsentParts[1] componentsSeparatedByString:@"."];
      if ([consentedIds containsObject:vendorIdString]) {
        return GADMAdapterPangleConsentResultTrue;
      }

      return GADMAdapterPangleConsentResultUnknown;
    } else {
      NSString *errorMessage =
          [NSString stringWithFormat:
                        @"Could not parse the IABTCF_AddtlConsent string: \"%@\". String had more "
                        @"parts than expected. Did your CMP write IABTCF_AddtlConsent correctly?",
                        additionalConsentString];
      NSLog(@"%@", errorMessage);
      return GADMAdapterPangleConsentResultUnknown;
    }
  } else if (version >= 2) {
    // Spec version 2 and above.
    if (additionalConsentParts.count < 3) {
      NSString *errorMessage =
          [NSString stringWithFormat:
                        @"Could not parse the IABTCF_AddtlConsent string: \"%@\". String has less "
                        @"parts than expected. Did your CMP write IABTCF_AddtlConsent correctly?",
                        additionalConsentString];
      NSLog(@"%@", errorMessage);
      return GADMAdapterPangleConsentResultUnknown;
    }

    NSArray<NSString *> *disclosedIds =
        [additionalConsentParts[2] componentsSeparatedByString:@"."];
    if (![disclosedIds[0] isEqualToString:@"dv"]) {
      NSString *errorMessage = [NSString
          stringWithFormat:
              @"Could not parse the IABTCF_AddtlConsent string: \"%@\". Expected disclosed vendors "
              @"part to have the string \"dv.\". Did your CMP write IABTCF_AddtlConsent correctly?",
              additionalConsentString];
      NSLog(@"%@", errorMessage);
      return GADMAdapterPangleConsentResultUnknown;
    }

    NSArray<NSString *> *consentedIds =
        [additionalConsentParts[1] componentsSeparatedByString:@"."];
    if ([consentedIds containsObject:vendorIdString]) {
      return GADMAdapterPangleConsentResultTrue;
    }

    if ([disclosedIds containsObject:vendorIdString]) {
      return GADMAdapterPangleConsentResultFalse;
    }

    return GADMAdapterPangleConsentResultUnknown;
  } else {
    // Unknown spec version
    NSString *errorMessage = [NSString
        stringWithFormat:@"Could not parse the IABTCF_AddtlConsent string: \"%@\". Spec version "
                         @"was unexpected. Did your CMP write IABTCF_AddtlConsent correctly?",
                         additionalConsentString];
    NSLog(@"%@", errorMessage);
    return GADMAdapterPangleConsentResultUnknown;
  }
}

@implementation GADMAdapterPangleUtils

+ (BOOL)isChildUser {
  GADRequestConfiguration *requestConfiguration = GADMobileAds.sharedInstance.requestConfiguration;
  return [requestConfiguration.tagForChildDirectedTreatment boolValue] ||
         [requestConfiguration.tagForUnderAgeOfConsent boolValue];
}

@end
