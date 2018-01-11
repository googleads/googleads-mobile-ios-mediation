//
//  GADMAdapterAppLovinUtils.h
//
//
//  Created by Thomas So on 1/10/18.
//
//

#import <Foundation/Foundation.h>
#import <AppLovinSDK/AppLovinSDK.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

@interface GADMAdapterAppLovinUtils : NSObject

/**
 * Retrieves the appropriate instance of AppLovin's SDK from the SDK key given in the credentials, or Info.plist.
 */
+ (nullable ALSdk *)retrieveSDKFromCredentials:(NSDictionary *)credentials;

/**
 * Convert the given AppLovin SDK error code into the appropriate AdMob error code.
 */
+ (GADErrorCode)toAdMobErrorCode:(int)appLovinErrorCode;

@end

NS_ASSUME_NONNULL_END
