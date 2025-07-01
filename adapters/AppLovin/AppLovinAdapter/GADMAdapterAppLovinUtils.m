// Copyright 2018 Google LLC
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

#import "GADMAdapterAppLovinUtils.h"
#import <AppLovinSDK/AppLovinSDK.h>
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinExtras.h"
#import "GADMediationAdapterAppLovin.h"

static const NSUInteger kALSDKKeyLength = 86;
static const NSUInteger kALZoneIdentifierLength = 16;

void GADMAdapterAppLovinMutableSetAddObject(NSMutableSet *_Nullable set,
                                            NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

void GADMAdapterAppLovinMutableArrayAddObject(NSMutableArray *_Nullable array,
                                              NSObject *_Nonnull object) {
  if (object) {
    [array addObject:object];  // Allow pattern.
  }
}

void GADMAdapterAppLovinMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable,
                                                   id _Nullable key) {
  if (key) {
    [mapTable removeObjectForKey:key];  // Allow pattern.
  }
}

void GADMAdapterAppLovinMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                                id<NSCopying> _Nullable key, id _Nullable value) {
  if (value && key) {
    [mapTable setObject:value forKey:key];  // Allow pattern.
  }
}

void GADMAdapterAppLovinMutableArrayRemoveObject(NSMutableArray *_Nullable array,
                                                 NSObject *_Nonnull object) {
  if (object) {
    [array removeObject:object];  // Allow pattern.
  }
}

void GADMAdapterAppLovinMutableSetRemoveObject(NSMutableSet *_Nullable set,
                                               NSObject *_Nonnull object) {
  if (object) {
    [set removeObject:object];  // Allow pattern.
  }
}

void GADMAdapterAppLovinMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                         id<NSCopying> _Nullable key,
                                                         id _Nullable value) {
  if (value && key) {
    dictionary[key] = value;  // Allow pattern.
  }
}

void GADMAdapterAppLovinMutableDictionaryRemoveObjectForKey(
    NSMutableDictionary *_Nonnull dictionary, id<NSCopying> _Nullable key) {
  if (key) {
    [dictionary removeObjectForKey:key];  // Allow pattern.
  }
}

NSError *_Nonnull GADMAdapterAppLovinErrorWithCodeAndDescription(GADMAdapterAppLovinErrorCode code,
                                                                 NSString *_Nonnull description) {
  NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinErrorDomain
                                       code:code
                                   userInfo:@{NSLocalizedFailureReasonErrorKey : description}];
  return error;
}

NSError *_Nonnull GADMAdapterAppLovinSDKErrorWithCode(NSInteger code) {
  NSError *error = [NSError
      errorWithDomain:GADMAdapterAppLovinSDKErrorDomain
                 code:code
             userInfo:@{
               NSLocalizedFailureReasonErrorKey : @"AppLovin SDK returned a failure callback."
             }];
  return error;
};

NSError *_Nonnull GADMAdapterAppLovinChildUserError() {
  NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
      GADMAdapterAppLovinErrorChildUser, @"GADMobileAds.sharedInstance.requestConfiguration "
                                         @"indicates the user is a child. AppLovin SDK 13.0.0 or "
                                         @"higher does not support child users.");
  return error;
}

/// Always set to true.
///
/// TODO: Remove the code branches for the case where this is false since this is
/// always true now.
BOOL GADMAdapterAppLovinIsMultipleAdsLoadingEnabled() { return true; }

@implementation GADMAdapterAppLovinUtils

+ (nullable NSString *)retrieveSDKKeyFromCredentials:(nonnull NSDictionary *)credentials {
  // Attempt to retrieve the SDK key from the credentials first.
  NSString *serverSDKKey = credentials[GADMAdapterAppLovinSDKKey];
  if (serverSDKKey && [self isValidAppLovinSDKKey:serverSDKKey]) {
    return serverSDKKey;
  }

  return nil;
}

+ (BOOL)isValidAppLovinSDKKey:(nonnull NSString *)SDKKey {
  return [SDKKey isKindOfClass:[NSString class]] && ((NSString *)SDKKey).length == kALSDKKeyLength;
}

+ (nullable NSString *)zoneIdentifierForConnector:(nonnull id<GADMediationAdRequest>)connector {
  return [self retrieveZoneIdentifierFromDict:connector.credentials];
}

+ (nullable NSString *)zoneIdentifierForAdConfiguration:
    (nonnull GADMediationAdConfiguration *)adConfig {
  return [self retrieveZoneIdentifierFromDict:adConfig.credentials.settings];
}

+ (nullable NSString *)retrieveZoneIdentifierFromDict:(nonnull NSDictionary<NSString *, id> *)dict {
  NSString *customZoneIdentifier = dict[GADMAdapterAppLovinZoneIdentifierKey];

  // Custom zone found and is valid.
  if (customZoneIdentifier.length == kALZoneIdentifierLength) {
    return customZoneIdentifier;
  }

  // Use default zone if no custom zone attempted.
  if (!customZoneIdentifier.length) {
    [self log:@"WARNING: Please provide a custom zone in your AdMob configuration. Using default "
              @"zone..."];
    return GADMAdapterAppLovinDefaultZoneIdentifier;
  }

  // Custom zone is invalid - return nil (adapter will fail the ad load).
  return nil;
}

#pragma mark - Banner Util Methods

+ (nullable ALAdSize *)appLovinAdSizeFromRequestedSize:(GADAdSize)size {
  GADAdSize banner = GADAdSizeFromCGSize(CGSizeMake(320, 50));
  GADAdSize leaderboard = GADAdSizeFromCGSize(CGSizeMake(728, 90));
  NSArray<NSValue *> *potentials = @[ NSValueFromGADAdSize(banner) ];
  if (IS_IPAD) {
    // iPad also supports 728x90.
    potentials = @[ NSValueFromGADAdSize(banner), NSValueFromGADAdSize(leaderboard) ];
  }
  GADAdSize closestSize = GADClosestValidSizeForAdSizes(size, potentials);
  CGSize closestCGSize = CGSizeFromGADAdSize(closestSize);
  if (CGSizeEqualToSize(CGSizeFromGADAdSize(banner), closestCGSize)) {
    return ALAdSize.banner;
  }
  if (CGSizeEqualToSize(CGSizeFromGADAdSize(leaderboard), closestCGSize)) {
    return ALAdSize.leader;
  }

  [GADMAdapterAppLovinUtils
      log:@"Unable to retrieve AppLovin size from GADAdSize: %@", NSStringFromGADAdSize(size)];
  return nil;
}

#pragma mark - Logging

+ (void)log:(nonnull NSString *)format, ... {
  va_list valist;
  va_start(valist, format);
  NSString *message = [[NSString alloc] initWithFormat:format arguments:valist];
  va_end(valist);
  NSLog(@"AppLovinAdapter: %@", message);  // Allow pattern.
}

+ (BOOL)isChildUser {
  GADRequestConfiguration *requestConfiguration = GADMobileAds.sharedInstance.requestConfiguration;
  return [requestConfiguration.tagForChildDirectedTreatment boolValue] ||
         [requestConfiguration.tagForUnderAgeOfConsent boolValue];
}

@end
