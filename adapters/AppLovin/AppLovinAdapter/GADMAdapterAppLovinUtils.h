//
//  GADMAdapterAppLovinUtils.h
//
//
//  Created by Thomas So on 1/10/18.
//
//

#import <AppLovinSDK/AppLovinSDK.h>
#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

#define IS_IPHONE ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define IS_IPAD ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

/// Adds |object| to |set| if |object| is not nil.
void GADMAdapterAppLovinMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);

/// Adds |object| to |array| if |object| is not nil.
void GADMAdapterAppLovinMutableArrayAddObject(NSMutableArray *_Nullable array,
                                              NSObject *_Nonnull object);

/// Removes the object for |key| in mapTable if |key| is not nil.
void GADMAdapterAppLovinMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable,
                                                   id _Nullable key);

/// Sets |value| for |key| in |mapTable| if |value| is not nil.
void GADMAdapterAppLovinMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                                id<NSCopying> _Nullable key, id _Nullable value);

/// Removes |object| from |array| if |object| is not nil.
void GADMAdapterAppLovinMutableArrayRemoveObject(NSMutableArray *_Nullable array,
                                                 NSObject *_Nonnull object);

/// Removes |object| from |set| if |object| is not nil.
void GADMAdapterAppLovinMutableSetRemoveObject(NSMutableSet *_Nullable set,
                                               NSObject *_Nonnull object);

/// Sets |value| for |key| in |dictionary| if |value| is not nil.
void GADMAdapterAppLovinMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                         id<NSCopying> _Nullable key,
                                                         id _Nullable value);

/// Removes the object for |key| in |dictionary| if |key| is not nil.
void GADMAdapterAppLovinMutableDictionaryRemoveObjectForKey(
    NSMutableDictionary *_Nonnull dictionary, id<NSCopying> _Nullable key);

/// Returns an error with the provided description and error code.
NSError *_Nonnull GADMAdapterAppLovinErrorWithCodeAndDescription(GADErrorCode code,
                                                                 NSString *_Nonnull description);

@interface GADMAdapterAppLovinUtils : NSObject

/// Retrieves the appropriate instance of AppLovin's SDK from the SDK key given in the credentials,
/// or Info.plist.
+ (nullable ALSdk *)retrieveSDKFromCredentials:(nonnull NSDictionary *)credentials;

/// Retrieve an instance of the AppLovin SDK with the provided SDK key.
+ (nullable ALSdk *)retrieveSDKFromSDKKey:(nonnull NSString *)sdkKey;

/// Returns whether the given string is a valid SDK key or not.
+ (BOOL)isValidAppLovinSDKKey:(nonnull NSString *)sdkKey;

/// Retrieve the SDK key from the Info.plist, if any.
+ (nullable NSString *)infoDictionarySDKKey;

/// Retrieves the zone identifier from an appropriate connector object. Returns the default
/// zone if no zone identifier exists. Returns nil for invalid custom zones.
+ (nullable NSString *)zoneIdentifierForConnector:(nonnull id<GADMediationAdRequest>)connector;

/// Retrieves the zone identifier from an appropriate adConfiguration object. Returns the
/// default zone if no zone identifier exists.
+ (nullable NSString *)zoneIdentifierForAdConfiguration:
    (nonnull GADMediationAdConfiguration *)adConfig;

/// Convert the given AppLovin SDK error code into the appropriate AdMob error code.
+ (GADErrorCode)toAdMobErrorCode:(int)appLovinErrorCode;

/// Returns the closest ALAdSize size from the requested GADAdSize.
+ (nullable ALAdSize *)appLovinAdSizeFromRequestedSize:(GADAdSize)size;

/// Formats and logs the string.
+ (void)log:(nonnull NSString *)format, ...;

@end
