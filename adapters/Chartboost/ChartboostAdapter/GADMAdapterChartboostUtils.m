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

#import "GADMAdapterChartboostConstants.h"

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

CHBMediation *_Nonnull GADMAdapterChartboostMediation(void) {
  return [[CHBMediation alloc] initWithType:CBMediationAdMob
                             libraryVersion:[GADRequest sdkVersion]
                             adapterVersion:kGADMAdapterChartboostVersion];
}

NSString *_Nonnull GADMAdapterChartboostAdLocationFromConnector(id<GADMAdNetworkConnector> _Nonnull connector) {
  return GADMAdapterChartboostAdLocationFromString(
    connector.credentials[kGADMAdapterChartboostAdLocation]);
}

NSString *_Nonnull GADMAdapterChartboostAdLocationFromAdConfig(GADMediationAdConfiguration * _Nonnull adConfig) {
  return GADMAdapterChartboostAdLocationFromString(
    adConfig.credentials.settings[kGADMAdapterChartboostAdLocation]);
}

NSString *_Nonnull GADMAdapterChartboostAdLocationFromString(NSString * _Nullable string) {
  NSString *adLocation = [string
    stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
  if (!adLocation.length) {
    NSLog(@"Missing or Invalid Chartboost location. Using Chartboost's default location...");
    adLocation = [CBLocationDefault copy];
  }
  return adLocation;
}
