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

#import "GADMediationAdapterAppLovin.h"

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

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterAppLovinErrorWithCodeAndDescription(GADMAdapterAppLovinErrorCode code,
                                                                 NSString *_Nonnull description);

/// Returns an NSError with the provided error code.
NSError *_Nonnull GADMAdapterAppLovinSDKErrorWithCode(NSInteger code);

/// Returns an error where the instance of the AppLovin SDK for a given SDKKey cannot be found.
NSError *_Nonnull GADMAdapterAppLovinNilSDKError(NSString *_Nonnull SDKKey);

@interface GADMAdapterAppLovinUtils : NSObject

/// Retrieves the AppLovin SDK key from the specified |credentials| or from Info.plist.
+ (nullable NSString *)retrieveSDKKeyFromCredentials:(nonnull NSDictionary *)credentials;

/// Retrieve an instance of the AppLovin SDK with the provided SDK key.
+ (nullable ALSdk *)retrieveSDKFromSDKKey:(nonnull NSString *)SDKKey;

/// Returns whether the given string is a valid SDK key or not.
+ (BOOL)isValidAppLovinSDKKey:(nonnull NSString *)SDKKey;

/// Retrieve the SDK key from the Info.plist, if any.
+ (nullable NSString *)infoDictionarySDKKey;

/// Retrieves the zone identifier from an appropriate connector object. Returns the default
/// zone if no zone identifier exists. Returns nil for invalid custom zones.
+ (nullable NSString *)zoneIdentifierForConnector:(nonnull id<GADMediationAdRequest>)connector;

/// Retrieves the zone identifier from an appropriate adConfiguration object. Returns the
/// default zone if no zone identifier exists.
+ (nullable NSString *)zoneIdentifierForAdConfiguration:
    (nonnull GADMediationAdConfiguration *)adConfig;

/// Returns the closest ALAdSize size from the requested GADAdSize.
+ (nullable ALAdSize *)appLovinAdSizeFromRequestedSize:(GADAdSize)size;

/// Formats and logs the string.
+ (void)log:(nonnull NSString *)format, ...;

@end
