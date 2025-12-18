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

#import "GADMAdapterChartboostUtils.h"

#import <GoogleMobileAds/GoogleMobileAds.h>

#import "GADMAdapterChartboostConstants.h"
#import "GADMChartboostError.h"

#pragma mark - Private utility method prototypes

/// Returns a valid Chartboost ad location based on the given string.
NSString *_Nonnull GADMAdapterChartboostLocationFromString(NSString *_Nullable string);

#pragma mark - Public utility methods

void GADMAdapterChartboostMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                           id<NSCopying> _Nullable key,
                                                           id _Nullable value) {
  if (value && key) {
    dictionary[key] = value;  // Allow pattern.
  }
}

void GADMAdapterChartboostMutableArrayAddObject(NSMutableArray *_Nullable array,
                                                NSObject *_Nonnull object) {
  if (object) {
    [array addObject:object];  // Allow pattern.
  }
}

void GADMAdapterChartboostMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable,
                                                     id _Nullable key) {
  if (key) {
    [mapTable removeObjectForKey:key];  // Allow pattern.
  }
}

void GADMAdapterChartboostMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                                  id<NSCopying> _Nullable key, id _Nullable value) {
  if (value && key) {
    [mapTable setObject:value forKey:key];  // Allow pattern.
  }
}

NSString *_Nonnull GADMAdapterChartboostLocationFromConnector(
    id<GADMAdNetworkConnector> _Nonnull connector) {
  return GADMAdapterChartboostLocationFromString(
      connector.credentials[GADMAdapterChartboostAdLocation]);
}

NSString *_Nonnull GADMAdapterChartboostLocationFromAdConfiguration(
    GADMediationAdConfiguration *_Nonnull adConfiguration) {
  return GADMAdapterChartboostLocationFromString(
      adConfiguration.credentials.settings[GADMAdapterChartboostAdLocation]);
}

NSString *_Nonnull GADMAdapterChartboostLocationFromString(NSString *_Nullable string) {
  NSString *adLocation =
      [string stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
  if (!adLocation.length) {
    NSLog(@"Missing or Invalid Chartboost location. Using Chartboost's default location.");
    return @"Default";
  }
  return adLocation;
}

CHBMediation *_Nonnull GADMAdapterChartboostMediation(void) {
  NSString *versionString =
      [NSString stringWithFormat:@"afma-sdk-i-v%ld.%ld.%ld",
                                 GADMobileAds.sharedInstance.versionNumber.majorVersion,
                                 GADMobileAds.sharedInstance.versionNumber.minorVersion,
                                 GADMobileAds.sharedInstance.versionNumber.patchVersion];
  return [[CHBMediation alloc] initWithName:@"AdMob"
                             libraryVersion:versionString
                             adapterVersion:GADMAdapterChartboostVersion];
}

NSError *_Nonnull GADMAdapterChartboostErrorWithCodeAndDescription(
    GADMAdapterChartboostErrorCode code, NSString *_Nonnull description) {
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMAdapterChartboostErrorDomain
                                       code:code
                                   userInfo:userInfo];
  return error;
}

GADMAdapterChartboostConsentResult GADMAdapterChartboostHasACConsent(NSInteger vendorId) {
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

  NSInteger gdprApplies = [userDefaults integerForKey:@"IABTCF_gdprApplies"];
  if (gdprApplies != 1) {
    return GADMAdapterChartboostConsentResultUnknown;
  }

  NSString *additionalConsentString = [userDefaults stringForKey:@"IABTCF_AddtlConsent"];
  if (!additionalConsentString.length) {
    return GADMAdapterChartboostConsentResultUnknown;
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
      return GADMAdapterChartboostConsentResultUnknown;
    } else if (additionalConsentParts.count == 2) {
      NSArray<NSString *> *consentedIds =
          [additionalConsentParts[1] componentsSeparatedByString:@"."];
      if ([consentedIds containsObject:vendorIdString]) {
        return GADMAdapterChartboostConsentResultTrue;
      }

      return GADMAdapterChartboostConsentResultUnknown;
    } else {
      NSString *errorMessage =
          [NSString stringWithFormat:
                        @"Could not parse the IABTCF_AddtlConsent string: \"%@\". String had more "
                        @"parts than expected. Did your CMP write IABTCF_AddtlConsent correctly?",
                        additionalConsentString];
      NSLog(@"%@", errorMessage);
      return GADMAdapterChartboostConsentResultUnknown;
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
      return GADMAdapterChartboostConsentResultUnknown;
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
      return GADMAdapterChartboostConsentResultUnknown;
    }

    NSArray<NSString *> *consentedIds =
        [additionalConsentParts[1] componentsSeparatedByString:@"."];
    if ([consentedIds containsObject:vendorIdString]) {
      return GADMAdapterChartboostConsentResultTrue;
    }

    if ([disclosedIds containsObject:vendorIdString]) {
      return GADMAdapterChartboostConsentResultFalse;
    }

    return GADMAdapterChartboostConsentResultUnknown;
  } else {
    // Unknown spec version
    NSString *errorMessage = [NSString
        stringWithFormat:@"Could not parse the IABTCF_AddtlConsent string: \"%@\". Spec version "
                         @"was unexpected. Did your CMP write IABTCF_AddtlConsent correctly?",
                         additionalConsentString];
    NSLog(@"%@", errorMessage);
    return GADMAdapterChartboostConsentResultUnknown;
  }
}

#pragma mark - Banner Util Methods

CHBBannerSize GADMAdapterChartboostBannerSizeFromAdSize(
    GADAdSize gadAdSize, NSError *_Nullable __autoreleasing *_Nullable error) {
  NSArray *potentials = @[
    NSValueFromGADAdSize(GADAdSizeBanner), NSValueFromGADAdSize(GADAdSizeMediumRectangle),
    NSValueFromGADAdSize(GADAdSizeLeaderboard)
  ];

  GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentials);
  if (GADAdSizeEqualToSize(closestSize, GADAdSizeBanner)) {
    return CHBBannerSizeStandard;
  } else if (GADAdSizeEqualToSize(closestSize, GADAdSizeMediumRectangle)) {
    return CHBBannerSizeMedium;
  } else if (GADAdSizeEqualToSize(closestSize, GADAdSizeLeaderboard)) {
    return CHBBannerSizeLeaderboard;
  }
  if (error) {
    NSString *description =
        [NSString stringWithFormat:@"Chartboost's supported banner sizes are not valid for the "
                                   @"requested ad size. Requested ad size: %@",
                                   NSStringFromGADAdSize(gadAdSize)];
    *error = GADMAdapterChartboostErrorWithCodeAndDescription(
        GADMAdapterChartboostErrorBannerSizeMismatch, description);
  }

  CHBBannerSize chartboostSize = {0};
  return chartboostSize;
}
