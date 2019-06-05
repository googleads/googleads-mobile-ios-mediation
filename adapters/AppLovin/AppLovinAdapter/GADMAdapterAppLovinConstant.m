//
//  GADMAdapterAppLovinConstant.m
//
//
//  Created by Thomas So on 1/11/18.
//
//

#import "GADMAdapterAppLovinConstant.h"

@implementation GADMAdapterAppLovinConstant

+ (NSString *)errorDomain {
  return @"com.applovin.sdk.mediation.admob.errorDomain";
}

+ (NSString *)rtbErrorDomain {
  return @"com.applovin.sdk.mediation.admob.rtb.errorDomain";
}

+ (NSString *)adapterVersion {
  return @"6.6.1.0";
}

+ (NSString *)sdkKey {
  return @"sdkKey";
}

+ (NSString *)placementKey {
  return @"placement";
}

+ (NSString *)zoneIdentifierKey {
  return @"zone_id";
}

+ (NSString *)bundleIdentifierKey {
  return @"bundleId";
}

+ (BOOL)loggingEnabled {
  return YES;
}

@end
