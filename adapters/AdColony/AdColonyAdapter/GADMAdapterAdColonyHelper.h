//
//  Copyright © 2018 Google. All rights reserved.
//

#import <AdColony/AdColony.h>
#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

#import "GADMediationAdapterAdColony.h"

#define GADMAdapterAdColonyLog(format, args...) NSLog(@"AdColonyAdapter: " format, ##args)

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterAdColonyErrorWithCodeAndDescription(GADMAdapterAdColonyErrorCode code,
                                                                 NSString *_Nonnull description);

/// Adds |object| to |set| if |object| is not nil.
void GADMAdapterAdColonyMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);

/// Adds objects from array to the set.
void GADMAdapterAdColonyMutableSetAddObjectsFromArray(NSMutableSet *_Nullable set,
                                                      NSArray *_Nonnull array);

/// Adds |object| to |array| if |object| is not nil.
void GADMAdapterAdColonyMutableArrayAddObject(NSMutableArray *_Nullable array,
                                              NSObject *_Nonnull object);

/// Returns a dispatch time relative to DISPATCH_TIME_NOW for the provided time interval or
/// DISPATCH_TIME_NOW if the interval is negative.
dispatch_time_t GADMAdapterAdColonyDispatchTimeForInterval(NSTimeInterval interval);

/// Retrieve zone ID from the settings dictionary.
NSString *_Nullable GADMAdapterAdColonyZoneIDForSettings(
    NSDictionary<NSString *, id> *_Nonnull settings);

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

@end
