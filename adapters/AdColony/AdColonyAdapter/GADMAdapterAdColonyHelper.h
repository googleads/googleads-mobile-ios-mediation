//
//  Copyright © 2018 Google. All rights reserved.
//

#import <AdColony/AdColony.h>
#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

#define GADMAdapterAdColonyLog(format, args...) NSLog(@"AdColonyAdapter: " format, ##args)

/// Returns an NSError with provided error code and description.
NSError *_Nonnull GADMAdapterAdColonyErrorWithCodeAndDescription(NSUInteger code,
                                                                 NSString *_Nonnull description);

/// Adds |object| to |set| if |object| is not nil.
void GADMAdapterAdColonyMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);

/// Adds objects from array to the set.
void GADMAdapterAdColonyMutableSetAddObjectsFromArray(NSMutableSet *_Nullable set,
                                                      NSArray *_Nonnull array);

/// Sets |value| for |key| in |dictionary| if |value| is not nil.
void GADMAdapterAdColonyMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                         id<NSCopying> _Nullable key,
                                                         id _Nullable value);

/// Adds |object| to |array| if |object| is not nil.
void GADMAdapterAdColonyMutableArrayAddObject(NSMutableArray *_Nullable array,
                                              NSObject *_Nonnull object);

/// Retrieve zone ID from the settings dictionary.
NSString *_Nullable GADMAdapterAdColonyZoneIDForSettings(
    NSDictionary<NSString *, id> *_Nonnull settings);

/// Retrieve zone ID from the reply string.
NSString *_Nullable GADMAdapterAdColonyZoneIDForReply(NSString *_Nonnull reply);

@interface GADMAdapterAdColonyHelper : NSObject

/// Return AdColonyAdOptions from a GADMediationAdConfiguration.
+ (nullable AdColonyAdOptions *)getAdOptionsFromAdConfig:
    (nonnull GADMediationAdConfiguration *)adConfig;

/// Return AdColonyAdOptions from a GADMAdNetworkConnector.
+ (nullable AdColonyAdOptions *)getAdOptionsFromConnector:
    (nonnull id<GADMAdNetworkConnector>)connector;

/// Return AdColonyAppOptions from a GADMediationAdConfiguration.
+ (nullable AdColonyAppOptions *)getAppOptionsFromAdConfig:
    (nonnull GADMediationAdConfiguration *)adConfig;

/// Return AdColonyAppOptions from a GADMAdNetworkConnector.
+ (nullable AdColonyAppOptions *)getAppOptionsFromConnector:
    (nonnull id<GADMAdNetworkConnector>)connector;

/// Converts the provided zone IDs string to an array of zone IDs.
+ (nullable NSArray<NSString *> *)parseZoneIDs:(nonnull NSString *)zoneList;

/// Configures the zone provided by the GADMAdNetworkConnector info with AdColony SDK.
+ (void)setupZoneFromConnector:(nonnull id<GADMAdNetworkConnector>)connector
                      callback:(nonnull void (^)(NSString *_Nullable, NSError *_Nullable))callback;

/// Configures the zone provided by the GADMediationAdConfiguration with AdColony SDK.
+ (void)setupZoneFromAdConfig:(nonnull GADMediationAdConfiguration *)adConfig
                     callback:(nonnull void (^)(NSString *_Nullable, NSError *_Nullable))callback;

/// Retrieves a dictionary from the provided JSON string.
+ (nullable NSDictionary *)getDictionaryFromJsonString:(nonnull NSString *)jsonString;

/// Retrieves a JSON string from the provided dictionary.
+ (nullable NSString *)getJsonStringFromDictionary:(nonnull NSDictionary *)dictionary;

@end
