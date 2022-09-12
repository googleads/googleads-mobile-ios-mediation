//
// Copyright 2018, AdColony, Inc.
//

#import "GADMAdapterAdColonyHelper.h"

#import <AdColony/AdColony.h>

#import "GADMAdapterAdColony.h"
#import "GADMAdapterAdColonyConstants.h"
#import "GADMAdapterAdColonyExtras.h"
#import "GADMAdapterAdColonyInitializer.h"
#import "GADMediationAdapterAdColony.h"

@implementation GADMAdapterAdColonyHelper

+ (nullable AdColonyAppOptions *)getAppOptionsFromConnector:
    (nonnull id<GADMAdNetworkConnector>)connector {
  AdColonyAppOptions *options = GADMediationAdapterAdColony.appOptions;
  options.userMetadata = [AdColonyUserMetadata new];

  if ([connector userHasLocation]) {
    options.userMetadata.userLatitude = @([connector userLatitude]);
    options.userMetadata.userLongitude = @([connector userLongitude]);
  }

  GADGender gender = [connector userGender];
  if (gender == kGADGenderMale) {
    options.userMetadata.userGender = ADCUserMale;
  } else if (gender == kGADGenderFemale) {
    options.userMetadata.userGender = ADCUserFemale;
  }

  NSDate *birthday = [connector userBirthday];
  if (birthday) {
    options.userMetadata.userAge = [self getNumberOfYearsSinceDate:birthday];
  }

  [options setMediationNetwork:ADCAdMob];
  [options setMediationNetworkVersion:[GADMAdapterAdColony adapterVersion]];

  return options;
}

+ (nullable AdColonyAppOptions *)getAppOptionsFromAdConfig:
    (nonnull GADMediationAdConfiguration *)adConfig {
  AdColonyAppOptions *options = GADMediationAdapterAdColony.appOptions;
  options.userMetadata = [AdColonyUserMetadata new];

  if ([adConfig hasUserLocation]) {
    options.userMetadata.userLatitude = @([adConfig userLatitude]);
    options.userMetadata.userLongitude = @([adConfig userLongitude]);
  }

  // Set mediation network depending upon type of adapter (Legacy/RTB)
  if (adConfig.bidResponse) {
    // TODO: Confirm with AdColony if this can be renamed AdMob_Bidding.
    [options setMediationNetwork:@"AdMob_OpenBidding"];
  } else {
    [options setMediationNetwork:ADCAdMob];
  }

  [options setMediationNetworkVersion:[GADMAdapterAdColony adapterVersion]];

  return options;
}

+ (AdColonyAdOptions *)getAdOptionsFromExtras:(GADMAdapterAdColonyExtras *)extras {
  AdColonyAdOptions *options = [AdColonyAdOptions new];
  options.userMetadata = [AdColonyUserMetadata new];

  if (extras && [extras isKindOfClass:[GADMAdapterAdColonyExtras class]]) {
    // Popups only apply to rewarded ads.
    options.showPrePopup = extras.showPrePopup;
    options.showPostPopup = extras.showPostPopup;
  }
  return options;
}

+ (nullable AdColonyAdOptions *)getAdOptionsFromConnector:
    (nonnull id<GADMAdNetworkConnector>)connector {
  AdColonyAdOptions *options = nil;

  GADMAdapterAdColonyExtras *extras = connector.networkExtras;

  if (extras && [connector conformsToProtocol:@protocol(GADMRewardBasedVideoAdNetworkConnector)]) {
    // Popups only apply to rewarded ads.
    options = [self getAdOptionsFromExtras:extras];
  }

  return options;
}

+ (nullable AdColonyAdOptions *)getAdOptionsFromAdConfig:
    (nonnull GADMediationAdConfiguration *)adConfig {
  // Don't return an empty options/metadata object if nothing was found.
  AdColonyAdOptions *options = nil;

  GADMAdapterAdColonyExtras *extras = adConfig.extras;

  if (extras) {
    // Popups only apply to rewarded ads.
    options = [self getAdOptionsFromExtras:extras];
  }

  if (adConfig.bidResponse) {
    if (options == nil) {
      options = [AdColonyAdOptions new];
    }
    [options setOption:GADMAdapterAdColonyAdMarkupKey withStringValue:adConfig.bidResponse];
  }

  return options;
}

+ (NSInteger)getNumberOfYearsSinceDate:(NSDate *)date {
  NSCalendar *calendar =
      [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  NSDateComponents *components = [calendar components:NSCalendarUnitYear
                                             fromDate:date
                                               toDate:[NSDate date]
                                              options:0];
  return [components year];
}

+ (nullable NSArray<NSString *> *)parseZoneIDs:(nonnull NSString *)zoneList {
  // Split on the character we care about.
  NSArray *zoneIDs = [zoneList componentsSeparatedByString:@";"];
  NSMutableArray<NSString *> *result = [[NSMutableArray alloc] init];

  // Trim all whitespace and add to result if not empty.
  for (NSString *zoneID in zoneIDs) {
    NSString *trimmed =
        [zoneID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![trimmed isEqualToString:@""]) {
      GADMAdapterAdColonyMutableArrayAddObject(result, trimmed);
    }
  }
  return result;
}

+ (void)setupZoneFromSettings:(NSDictionary *)settings
                      options:(AdColonyAppOptions *)options
                     callback:(void (^)(NSString *, NSError *))callback {
  NSString *appId = settings[GADMAdapterAdColonyAppIDkey];
  NSString *zone = GADMAdapterAdColonyZoneIDForSettings(settings);

  [[GADMAdapterAdColonyInitializer sharedInstance] initializeAdColonyWithAppId:appId
                                                                         zones:@[ zone ]
                                                                       options:options
                                                                      callback:^(NSError *error) {
                                                                        if (callback) {
                                                                          callback(zone, error);
                                                                        }
                                                                      }];
}

+ (void)setupZoneFromConnector:(nonnull id<GADMAdNetworkConnector>)connector
                      callback:(nonnull void (^)(NSString *_Nullable, NSError *_Nullable))callback {
  NSDictionary *credentials = connector.credentials;
  AdColonyAppOptions *options = [self getAppOptionsFromConnector:connector];
  [self setupZoneFromSettings:credentials options:options callback:callback];
}

+ (void)setupZoneFromAdConfig:(nonnull GADMediationAdConfiguration *)adConfig
                     callback:(nonnull void (^)(NSString *_Nullable, NSError *_Nullable))callback {
  NSDictionary *credentials = adConfig.credentials.settings;
  AdColonyAppOptions *options = [self getAppOptionsFromAdConfig:adConfig];
  [self setupZoneFromSettings:credentials options:options callback:callback];
}

@end

NSError *_Nonnull GADMAdapterAdColonyErrorWithCodeAndDescription(GADMAdapterAdColonyErrorCode code,
                                                                 NSString *_Nonnull description) {
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMAdapterAdColonyErrorDomain
                                       code:code
                                   userInfo:userInfo];
  return error;
}

void GADMAdapterAdColonyMutableSetAddObject(NSMutableSet *_Nullable set,
                                            NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

NSString *_Nullable GADMAdapterAdColonyZoneIDForSettings(
    NSDictionary<NSString *, id> *_Nonnull settings) {
  NSString *encodedZoneID = settings[GADMAdapterAdColonyZoneIDBiddingKey];
  if (!encodedZoneID) {
    encodedZoneID = settings[GADMAdapterAdColonyZoneIDkey];
  }

  NSArray<NSString *> *zoneIDs = [GADMAdapterAdColonyHelper parseZoneIDs:encodedZoneID];
  NSString *zoneID = zoneIDs.firstObject;

  return zoneID;
}

void GADMAdapterAdColonyMutableArrayAddObject(NSMutableArray *_Nullable array,
                                              NSObject *_Nonnull object) {
  if (object) {
    [array addObject:object];  // Allow pattern.
  }
}

void GADMAdapterAdColonyMutableSetAddObjectsFromArray(NSMutableSet *_Nullable set,
                                                      NSArray *_Nonnull array) {
  if (array) {
    [set addObjectsFromArray:array];
  }
}

dispatch_time_t GADMAdapterAdColonyDispatchTimeForInterval(NSTimeInterval interval) {
  if (interval < 0) {
    return DISPATCH_TIME_NOW;
  }
  return dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC));  // Allow pattern.
}
