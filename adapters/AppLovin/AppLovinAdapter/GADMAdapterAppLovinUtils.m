//
//  GADMAdapterAppLovinUtils.m
//  AdMobAdapterDev
//
//  Created by Josh Gleeson on 8/15/17.
//  Copyright © 2017 AppLovin. All rights reserved.
//

#import "GADMAdapterAppLovinUtils.h"
#import "GADMAdapterAppLovinConstants.h"
#import "GADMAdapterAppLovinExtras.h"

#if __has_include(<AppLovinSDK/AppLovinSDK.h>)
    #import <AppLovinSDK/AppLovinSDK.h>
#else
    #import "ALSdk.h"
    #import "ALErrorCodes.h"
#endif

@implementation GADMAdapterAppLovinUtils

+ (ALSdk *)sdkForCredentials:(NSDictionary *)credentials
{
    NSString *sdkKey = [[credentials objectForKey: kGADMAdapterAppLovinSdkKey] copy];
    
    // if no sdk key pulled from the dashboard, grab the key from the .plist
    if ( sdkKey == nil || [sdkKey isEqualToString: @""] )
    {
        NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
        sdkKey = [info objectForKey: @"AppLovinSdkKey"];
    }
    
    ALSdk *sdk = [ALSdk sharedWithKey: sdkKey];
    
    if ( sdk )
    {
        [sdk setPluginVersion: kGADMAdapterAppLovinVersion];
    }
    
    return sdk;
}

+ (NSString *)placementFromCredentials:(NSDictionary *)credentials
{
    return [[credentials objectForKey: kGADMAdapterAppLovinPlacement] copy];
}

+ (GADErrorCode)toAdMobErrorCode:(int)appLovinErrorCode
{
    if ( appLovinErrorCode == kALErrorCodeNoFill )
    {
        return kGADErrorMediationNoFill;
    }
    else if ( appLovinErrorCode == kALErrorCodeAdRequestNetworkTimeout )
    {
        return kGADErrorTimeout;
    }
    else if ( appLovinErrorCode == kALErrorCodeInvalidResponse )
    {
        return kGADErrorReceivedInvalidResponse;
    }
    else if ( appLovinErrorCode == kALErrorCodeUnableToRenderAd )
    {
        return kGADErrorServerError;
    }
    else
    {
        return kGADErrorInternalError;
    }
}

@end
