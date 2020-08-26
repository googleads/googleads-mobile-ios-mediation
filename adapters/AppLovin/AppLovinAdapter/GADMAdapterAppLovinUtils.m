//
//  GADMAdapterAppLovinUtils.m
//
//
//  Created by Thomas So on 1/10/18.
//
//

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
    dictionary[key] = value;
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

@implementation GADMAdapterAppLovinUtils

+ (nullable ALSdk *)retrieveSDKFromCredentials:(NSDictionary *)credentials {
  // Attempt to use SDK key from server first.
  NSString *serverSDKKey = credentials[GADMAdapterAppLovinSDKKey];
  if ([self isValidAppLovinSDKKey:serverSDKKey]) {
    return [self retrieveSDKFromSDKKey:serverSDKKey];
  }

  // If server SDK key is invalid, then attempt to use SDK key from Info.plist.
  NSString *infoDictSDKKey = [self infoDictionarySDKKey];
  if ([self isValidAppLovinSDKKey:infoDictSDKKey]) {
    return [self retrieveSDKFromSDKKey:infoDictSDKKey];
  }

  return nil;
}

+ (nullable ALSdk *)retrieveSDKFromSDKKey:(nonnull NSString *)sdkKey {
  ALSdk *sdk = [ALSdk sharedWithKey:sdkKey];
  [sdk setPluginVersion:GADMAdapterAppLovinAdapterVersion];
  sdk.mediationProvider = ALMediationProviderAdMob;

  return sdk;
}

+ (BOOL)isValidAppLovinSDKKey:(nonnull NSString *)sdkKey {
  return [sdkKey isKindOfClass:[NSString class]] && ((NSString *)sdkKey).length == kALSDKKeyLength;
}

+ (nullable NSString *)infoDictionarySDKKey {
  return NSBundle.mainBundle.infoDictionary[GADMAdapterAppLovinInfoPListSDKKey];
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
    potentials = @[
      NSValueFromGADAdSize(banner), NSValueFromGADAdSize(leaderboard)
    ];
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
  NSLog(@"AppLovinAdapter: %@", message);
}

@end
