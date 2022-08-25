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
    return [CBLocationDefault copy];
  }
  return adLocation;
}

CHBMediation *_Nonnull GADMAdapterChartboostMediation(void) {
  return [[CHBMediation alloc] initWithType:CBMediationAdMob
                             libraryVersion:GADMobileAds.sharedInstance.sdkVersion
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
