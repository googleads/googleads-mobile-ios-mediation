//
//  GADMAdapterAppLovinConstant.m
//
//
//  Created by Thomas So on 1/11/18.
//
//

#import "GADMAdapterAppLovinConstant.h"

@implementation GADMAdapterAppLovinConstant

+ (NSString *)errorDomain
{
    return @"com.applovin.sdk.mediation.admob.errorDomain";
}

+ (NSString *)adapterVersion
{
    return @"4.6.1.0";
}

+ (NSString *)sdkKey
{
    return @"sdkKey";
}

+ (NSString *)placementKey
{
    return @"placement";
}

+ (NSString *)bundleIdentifierKey
{
    return @"bundleId";
}

+ (BOOL)loggingEnabled
{
    return YES;
}

@end
