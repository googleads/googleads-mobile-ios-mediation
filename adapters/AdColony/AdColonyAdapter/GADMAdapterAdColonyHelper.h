//
//  Copyright © 2018 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol GADMediationAdRequest;
@class AdColonyAppOptions;
@class AdColonyAdOptions;
#import <GoogleMobileAds/GoogleMobileAds.h>

#define DEBUG_LOGGING 0

#if DEBUG_LOGGING
#define NSLogDebug(...) NSLog(__VA_ARGS__)
#else
#define NSLogDebug(...)
#endif

/// Adds |object| to |set| if |object| is not nil.
void GADMAdapterAdColonyMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);
void GADMAdapterAdColonyMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                         id<NSCopying> _Nullable key,
                                                         id _Nullable value);
NSString *_Nullable GADMAdapterAdColonyZoneIDForSettings(NSDictionary *_Nonnull settings);
NSString *_Nullable GADMAdapterAdColonyZoneIDForReply(NSString *reply);

@interface GADMAdapterAdColonyHelper : NSObject

+ (AdColonyAdOptions *)getAdOptionsFromAdConfig:(GADMediationAdConfiguration *)adConfig;
+ (AdColonyAdOptions *)getAdOptionsFromConnector:(id<GADMAdNetworkConnector>)connector;

+ (AdColonyAppOptions *)getAppOptionsFromAdConfig:(GADMediationAdConfiguration *)adConfig;
+ (AdColonyAppOptions *)getAppOptionsFromConnector:(id<GADMAdNetworkConnector>)connector;

+ (NSArray *)parseZoneIDs:(NSString *)zoneList;

+ (void)setupZoneFromConnector:(id<GADMAdNetworkConnector>)connector
                      callback:(void (^)(NSString *, NSError *))callback;
+ (void)setupZoneFromAdConfig:(GADMediationAdConfiguration *)adConfig
                     callback:(void (^)(NSString *, NSError *))callback;

+ (NSDictionary *)getDictionaryFromJsonString:(NSString *)jsonString;
+ (NSString *)getJsonStringFromDictionary:(NSDictionary *)dictionary;

@end
