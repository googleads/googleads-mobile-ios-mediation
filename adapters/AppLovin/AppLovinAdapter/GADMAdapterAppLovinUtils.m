//
//  GADMAdapterAppLovinUtils.m
//
//
//  Created by Thomas So on 1/10/18.
//
//

#import "GADMAdapterAppLovinUtils.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinExtras.h"
#import <AppLovinSDK/AppLovinSDK.h>

#define DEFAULT_ZONE @""

@implementation GADMAdapterAppLovinUtils

+ (nullable ALSdk *)retrieveSDKFromCredentials:(NSDictionary *)credentials
{
    NSString *sdkKey = credentials[GADMAdapterAppLovinConstant.sdkKey];
    
    if ( sdkKey.length == 0 )
    {
        sdkKey = [[NSBundle mainBundle] infoDictionary][@"AppLovinSdkKey"];
    }
    
    ALSdk *sdk = [ALSdk sharedWithKey: sdkKey];
    [sdk setPluginVersion: GADMAdapterAppLovinConstant.adapterVersion];
    
    return sdk;
}

+ (NSString *)retrievePlacementFromConnector:(id<GADMediationAdRequest>)connector
{
    return connector.credentials[GADMAdapterAppLovinConstant.placementKey] ?: @"";
}

+ (NSString *)retrieveZoneIdentifierFromConnector:(id<GADMediationAdRequest>)connector
{
    return ((GADMAdapterAppLovinExtras *) connector.networkExtras).zoneIdentifier ?: DEFAULT_ZONE;
}

+ (GADErrorCode)toAdMobErrorCode:(int)code
{
    //
    // TODO: Be more exhaustive
    //
    
    if ( code == kALErrorCodeNoFill )
    {
        return kGADErrorMediationNoFill;
    }
    else if ( code == kALErrorCodeAdRequestNetworkTimeout )
    {
        return kGADErrorTimeout;
    }
    else if ( code == kALErrorCodeInvalidResponse )
    {
        return kGADErrorReceivedInvalidResponse;
    }
    else if ( code == kALErrorCodeUnableToRenderAd )
    {
        return kGADErrorServerError;
    }
    else
    {
        return kGADErrorInternalError;
    }
}

@end

