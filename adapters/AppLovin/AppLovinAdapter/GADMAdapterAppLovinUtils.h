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

/// Retrieves the placement from an appropriate connector object. Will use empty string if none
/// exists.
+ (NSString *)retrievePlacementFromConnector:(id<GADMediationAdRequest>)connector;

/// Retrieves the zone identifier from an appropriate connector object. Will use empty string if
/// none exists.
+ (NSString *)retrieveZoneIdentifierFromConnector:(id<GADMediationAdRequest>)connector;

/// Convert the given AppLovin SDK error code into the appropriate AdMob error code.
+ (GADErrorCode)toAdMobErrorCode:(int)appLovinErrorCode;

+ (nullable ALAdSize *)adSizeFromRequestedSize:(GADAdSize)size;

/// Dynamically create an instance of ALIncentivizedAd with a given zone and SDK. We must do it
/// dynamically as it is not exposed publically until iOS SDK 4.7.0.
+ (ALIncentivizedInterstitialAd *)incentivizedInterstitialAdWithZoneIdentifier:
                                      (NSString *)zoneIdentifier
                                                                           sdk:(ALSdk *)sdk;

+ (void)log:(NSString *)format, ...;

@end

NS_ASSUME_NONNULL_END
