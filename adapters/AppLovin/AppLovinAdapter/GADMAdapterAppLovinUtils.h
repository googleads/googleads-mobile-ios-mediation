//
//  GADMAdapterAppLovinUtils.h
//  AdMobAdapterDev
//
//  Created by Josh Gleeson on 8/15/17.
//  Copyright © 2017 AppLovin. All rights reserved.
//

@import GoogleMobileAds;
@import Foundation;
@class ALSdk;

@interface GADMAdapterAppLovinUtils : NSObject

+ (ALSdk *)sdkForCredentials:(NSDictionary *)credentials;
+ (NSString *)placementFromCredentials:(NSDictionary *)credentials;
+ (GADErrorCode)toAdMobErrorCode:(int)appLovinErrorCode;

@end
