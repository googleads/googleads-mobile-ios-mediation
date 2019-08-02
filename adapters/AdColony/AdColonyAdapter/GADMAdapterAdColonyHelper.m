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

+ (AdColonyAppOptions *)getAppOptionsFromConnector:(id<GADMAdNetworkConnector>)connector {
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

+ (AdColonyAppOptions *)getAppOptionsFromAdConfig:(GADMediationAdConfiguration *)adConfig {
  AdColonyAppOptions *options = GADMediationAdapterAdColony.appOptions;
  options.userMetadata = [AdColonyUserMetadata new];

  if ([adConfig hasUserLocation]) {
    options.userMetadata.userLatitude = @([adConfig userLatitude]);
    options.userMetadata.userLongitude = @([adConfig userLongitude]);
  }

  // Set mediation network depending upon type of adapter (Legacy/RTB)
  if (adConfig.bidResponse) {
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

+ (AdColonyAdOptions *)getAdOptionsFromConnector:(id<GADMAdNetworkConnector>)connector {
  AdColonyAdOptions *options = nil;

  GADMAdapterAdColonyExtras *extras = connector.networkExtras;

  if (extras && [connector conformsToProtocol:@protocol(GADMRewardBasedVideoAdNetworkConnector)]) {
    // Popups only apply to rewarded ads.
    options = [self getAdOptionsFromExtras:extras];
  }

  return options;
}

+ (AdColonyAdOptions *)getAdOptionsFromAdConfig:(GADMediationAdConfiguration *)adConfig {
  // Don't return an empty options/metadata object if nothing was found.
  AdColonyAdOptions *options = nil;

  GADMAdapterAdColonyExtras *extras = adConfig.extras;

  if (extras) {
    // Popups only apply to rewarded ads.
    options = [self getAdOptionsFromExtras:extras];
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

+ (NSArray *)parseZoneIDs:(NSString *)zoneList {
  // Split on the character we care about.
  NSArray *zoneIDs = [zoneList componentsSeparatedByString:@";"];
  NSMutableArray *result = [NSMutableArray arrayWithCapacity:[zoneIDs count]];

  // Trim all whitespace and add to result if not empty.
  for (NSString *zoneID in zoneIDs) {
    NSString *trimmed =
        [zoneID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![trimmed isEqualToString:@""]) {
      [result addObject:trimmed];
    }
  }
  return result;
}

+ (void)setupZoneFromSettings:(NSDictionary *)settings
                      options:(AdColonyAppOptions *)options
                     callback:(void (^)(NSString *, NSError *))callback {
  NSString *appId = settings[kGADMAdapterAdColonyAppIDkey];
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

+ (void)setupZoneFromConnector:(id<GADMAdNetworkConnector>)connector
                      callback:(void (^)(NSString *, NSError *))callback {
  NSDictionary *credentials = connector.credentials;
  AdColonyAppOptions *options = [self getAppOptionsFromConnector:connector];
  [self setupZoneFromSettings:credentials options:options callback:callback];
}

+ (void)setupZoneFromAdConfig:(GADMediationAdConfiguration *)adConfig
                     callback:(void (^)(NSString *, NSError *))callback {
  NSDictionary *credentials = adConfig.credentials.settings;
  AdColonyAppOptions *options = [self getAppOptionsFromAdConfig:adConfig];
  [self setupZoneFromSettings:credentials options:options callback:callback];
}

+ (NSDictionary *)getDictionaryFromJsonString:(NSString *)jsonString {
  NSData *objectData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:objectData
                                                             options:NSJSONReadingMutableContainers
                                                               error:nil];
  return dictionary;
}

// Method to build JSON from dictionary
+ (NSString *)getJsonStringFromDictionary:(NSDictionary *)dictionary {
  NSString *json = nil;
  NSError *error;

  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                     options:NSJSONWritingPrettyPrinted
                                                       error:&error];
  if (!error) {
    json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  }
  return json;
}

@end

void GADMAdapterAdColonyMutableSetAddObject(NSMutableSet *_Nullable set,
                                            NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];
  }
}

NSString *_Nullable GADMAdapterAdColonyZoneIDForSettings(NSDictionary *_Nonnull settings) {
  NSString *encodedZoneID = settings[kGADMAdapterAdColonyZoneIDOpenBiddingKey];
  if (!encodedZoneID) {
    encodedZoneID = settings[kGADMAdapterAdColonyZoneIDkey];
  }

  NSArray<NSString *> *zoneIDs = [GADMAdapterAdColonyHelper parseZoneIDs:encodedZoneID];
  NSString *zoneID = zoneIDs.firstObject;

  return zoneID;
}

NSString *_Nullable GADMAdapterAdColonyZoneIDForReply(NSString *reply) {
  if (!reply) {
    return nil;
  }
  NSDictionary *bidData = [GADMAdapterAdColonyHelper getDictionaryFromJsonString:reply];
  NSString *zoneId = bidData[@"zone"];
  return zoneId;
}

void GADMAdapterAdColonyMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                         id<NSCopying> _Nullable key,
                                                         id _Nullable value) {
  if (value && key) {
    dictionary[key] = value;
  }
}
