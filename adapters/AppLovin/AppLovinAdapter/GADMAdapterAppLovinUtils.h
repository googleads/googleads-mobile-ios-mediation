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

NS_ASSUME_NONNULL_BEGIN

#define IS_IPHONE ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define IS_IPAD ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

@interface GADMAdapterAppLovinUtils : NSObject

/// Retrieves the appropriate instance of AppLovin's SDK from the SDK key given in the credentials,
/// or Info.plist.
+ (nullable ALSdk *)retrieveSDKFromCredentials:(NSDictionary *)credentials;

// Retrieve an instance of the AppLovin SDK with the provided SDK key.
+ (nullable ALSdk *)retrieveSDKFromSDKKey:(NSString *)sdkKey;

// Checks whether or not the Info.plist has a valid SDK key
+ (BOOL)infoDictionaryHasValidSDKKey;

// Retrieve the SDK key from the Info.plist, if any
+ (nullable NSString *)infoDictionarySDKKey;

/// Retrieves the placement from an appropriate connector object. Will use empty string if none
/// exists.
+ (NSString *)retrievePlacementFromConnector:(id<GADMediationAdRequest>)connector;

/// Retrieves the zone identifier from an appropriate connector object. Will use empty string if
/// none exists.
+ (NSString *)retrieveZoneIdentifierFromConnector:(id<GADMediationAdRequest>)connector;

/// Retrieves the placement from an appropriate adConfiguration object. Will use empty string if
/// none exists.
+ (NSString *)retrievePlacementFromAdConfiguration:(GADMediationAdConfiguration *)adConfig;

/// Retrieves the zone identifier from an appropriate adConfiguration object. Will use empty string
/// if none exists.
+ (NSString *)retrieveZoneIdentifierFromAdConfiguration:(GADMediationAdConfiguration *)adConfig;

/// Convert the given AppLovin SDK error code into the appropriate AdMob error code.
+ (GADErrorCode)toAdMobErrorCode:(int)appLovinErrorCode;

+ (nullable ALAdSize *)adSizeFromRequestedSize:(GADAdSize)size;

+ (void)log:(NSString *)format, ...;

@end

NS_ASSUME_NONNULL_END
