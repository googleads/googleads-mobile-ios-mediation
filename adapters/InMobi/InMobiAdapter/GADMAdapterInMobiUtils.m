// Copyright 2019 Google LLC
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
//

#import "GADMAdapterInMobiUtils.h"

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <InMobiSDK/InMobiSDK.h>

#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"

#pragma mark - Internal utility method prototypes

/// Sets up additional InMobi targeting information from the specified |extras|.
void GADMAdapterInMobiSetTargetingFromExtras(GADInMobiExtras *_Nullable extras);

void GADMAdapterInMobiSetIsAgeRestricted(NSNumber *_Nullable isRestricted);

/// Sets additional InMobi parameters to |requestParameters| from the specified |extras|.
NSDictionary<NSString *, id> *_Nonnull GADMAdapterInMobiAdditonalParametersFromInMobiExtras(
    GADInMobiExtras *_Nullable extras);

#pragma mark - Public utility methods

void GADMAdapterInMobiMutableArrayAddObject(NSMutableArray *_Nullable array,
                                            NSObject *_Nonnull object) {
  if (object) {
    [array addObject:object];  // Allow pattern.
  }
}

void GADMAdapterInMobiMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

void GADMAdapterInMobiMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                              id<NSCopying> _Nullable key, id _Nullable value) {
  if (value && key) {
    [mapTable setObject:value forKey:key];  // Allow pattern.
  }
}

void GADMAdapterInMobiMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable, id _Nullable key) {
  if (key) {
    [mapTable removeObjectForKey:key];  // Allow pattern.
  }
}

void GADMAdapterInMobiMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                       id<NSCopying> _Nullable key,
                                                       id _Nullable value) {
  if (value && key) {
    dictionary[key] = value;  // Allow pattern.
  }
}

void GADMAdapterInMobiCacheSetObjectForKey(NSCache *_Nonnull cache, id<NSCopying> _Nullable key,
                                           id _Nullable value) {
  if (value && key) {
    [cache setObject:value forKey:key];  // Allow pattern.
  }
}

NSError *_Nonnull GADMAdapterInMobiErrorWithCodeAndDescription(GADMAdapterInMobiErrorCode code,
                                                               NSString *_Nonnull description) {
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMAdapterInMobiErrorDomain
                                       code:code
                                   userInfo:userInfo];
  return error;
}

NSError *_Nullable GADMAdapterInMobiValidatePlacementIdentifier(
    NSNumber *_Nonnull placementIdentifier) {
  if (placementIdentifier.longLongValue) {
    return nil;
  }

  return GADMAdapterInMobiErrorWithCodeAndDescription(
      GADMAdapterInMobiErrorInvalidServerParameters,
      @"GADMediationAdapterInMobi - Error : Placement ID not specified.");
}

void GADMAdapterInMobiSetTargetingFromExtras(GADInMobiExtras *_Nullable extras) {
  if (extras == nil) {
    return;
  }

  if (extras.postalCode) {
    [IMSdk setPostalCode:extras.postalCode];
  }
  if (extras.areaCode) {
    [IMSdk setAreaCode:extras.areaCode];
  }
  if (extras.interests) {
    [IMSdk setInterests:extras.interests];
  }
  if (extras.age) {
    [IMSdk setAge:extras.age];
  }
  if (extras.yearOfBirth) {
    [IMSdk setYearOfBirth:extras.yearOfBirth];
  }
  if (extras.city && extras.state && extras.country) {
    [IMSdk setLocationWithCity:extras.city state:extras.state country:extras.country];
  }
  if (extras.language) {
    [IMSdk setLanguage:extras.language];
  }
}

void GADMAdapterInMobiLog(NSString *_Nonnull format, ...) {
  va_list arguments;
  va_start(arguments, format);
  NSString *log = [[NSString alloc] initWithFormat:format arguments:arguments];
  va_end(arguments);

  NSLog(@"GADMediationAdapterInMobi - %@", log);
}

void GADMAdapterInMobiSetTargetingFromConnector(id<GADMAdNetworkConnector> _Nonnull connector) {
  GADMAdapterInMobiSetTargetingFromExtras([connector networkExtras]);
  GADMAdapterInMobiSetIsAgeRestricted(connector.childDirectedTreatment);
}

void GADMAdapterInMobiSetTargetingFromAdConfiguration(
    GADMediationAdConfiguration *_Nonnull adConfig) {
  GADMAdapterInMobiSetTargetingFromExtras(adConfig.extras);
  GADMAdapterInMobiSetIsAgeRestricted(adConfig.childDirectedTreatment);
}

void GADMAdapterInMobiSetIsAgeRestricted(NSNumber *_Nullable isRestricted) {
  if ([isRestricted isEqual:@1]) {
    [IMSdk setIsAgeRestricted:true];
  }
}

NSDictionary<NSString *, id> *_Nonnull GADMAdapterInMobiAdditonalParametersFromInMobiExtras(
    GADInMobiExtras *_Nullable extras) {
  NSMutableDictionary<NSString *, id> *additionalParameters = [[NSMutableDictionary alloc] init];

  if (extras && extras.additionalParameters) {
    [additionalParameters addEntriesFromDictionary:extras.additionalParameters];
  }

  GADMAdapterInMobiMutableDictionarySetObjectForKey(additionalParameters, @"tp", @"c_admob");
  GADMAdapterInMobiMutableDictionarySetObjectForKey(additionalParameters, @"tp-ver",
                                                    GADMobileAds.sharedInstance.sdkVersion);

  return additionalParameters;
}

NSDictionary<NSString *, id> *_Nonnull GADMAdapterInMobiCreateRequestParametersFromConnector(
    id<GADMAdNetworkConnector> _Nonnull connector) {
  NSMutableDictionary<NSString *, id> *requestParameters =
      [GADMAdapterInMobiAdditonalParametersFromInMobiExtras([connector networkExtras]) mutableCopy];

  if ([connector childDirectedTreatment]) {
    NSString *coppaString = [[connector childDirectedTreatment] integerValue] ? @"1" : @"0";
    GADMAdapterInMobiMutableDictionarySetObjectForKey(requestParameters, @"coppa", coppaString);
  }

  return requestParameters;
}

NSDictionary<NSString *, id> *_Nonnull GADMAdapterInMobiCreateRequestParametersFromAdConfiguration(
    GADMediationAdConfiguration *_Nonnull adConfig) {
  NSMutableDictionary<NSString *, id> *requestParameters =
      [GADMAdapterInMobiAdditonalParametersFromInMobiExtras(adConfig.extras) mutableCopy];

  if (adConfig.childDirectedTreatment) {
    NSString *coppaString = [adConfig.childDirectedTreatment integerValue] ? @"1" : @"0";
    GADMAdapterInMobiMutableDictionarySetObjectForKey(requestParameters, @"coppa", coppaString);
  }

  return requestParameters;
}
