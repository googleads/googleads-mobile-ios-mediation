//
//  GADMAdapterInMobiUtils.m
//  Adapter
//  Copyright © 2019 Google. All rights reserved.
//

#import "GADMAdapterInMobiUtils.h"

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <InMobiSDK/InMobiSDK.h>

#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"

#pragma mark - Internal utility method prototypes

/// Sets up additional InMobi targeting information from the specified |extras|.
void GADMAdapterInMobiSetTargetingFromExtras(GADInMobiExtras *_Nullable extras);

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
      @"[InMobi] Error - Placement ID not specified.");
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

void GADMAdapterInMobiSetTargetingFromConnector(id<GADMAdNetworkConnector> _Nonnull connector) {
  if (connector.userGender == kGADGenderMale) {
    [IMSdk setGender:kIMSDKGenderMale];
  } else if (connector.userGender == kGADGenderFemale) {
    [IMSdk setGender:kIMSDKGenderFemale];
  }

  if (connector.userBirthday != nil) {
    NSDateComponents *components = [NSCalendar.currentCalendar
        components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
          fromDate:connector.userBirthday];
    [IMSdk setYearOfBirth:components.year];
  }

  GADMAdapterInMobiSetTargetingFromExtras([connector networkExtras]);
}

void GADMAdapterInMobiSetTargetingFromAdConfiguration(
    GADMediationAdConfiguration *_Nonnull adConfig) {
  GADMAdapterInMobiSetTargetingFromExtras(adConfig.extras);
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
