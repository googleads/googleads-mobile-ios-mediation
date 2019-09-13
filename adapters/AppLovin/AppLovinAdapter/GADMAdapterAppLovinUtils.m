//
//  GADMAdapterAppLovinUtils.m
//
//
//  Created by Thomas So on 1/10/18.
//
//

#import "GADMAdapterAppLovinUtils.h"
#import <AppLovinSDK/AppLovinSDK.h>
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinExtras.h"

#define DEFAULT_ZONE @""

@implementation GADMAdapterAppLovinUtils
static NSString *const kALAppLovinSDKKey = @"AppLovinSdkKey";
static const CGFloat kALBannerHeightOffsetTolerance = 10.0f;
static const CGFloat kALBannerStandardHeight = 50.0f;
static const NSUInteger kALSDKKeyLength = 86;
static const NSUInteger kALZoneIdentifierLength = 16;

+ (nullable ALSdk *)retrieveSDKFromCredentials:(NSDictionary *)credentials {
  // Attempt to use SDK key from server first
  NSString *serverSDKKey = credentials[GADMAdapterAppLovinConstant.sdkKey];
  if ([self isValidSDKKey:serverSDKKey]) {
    return [self retrieveSDKFromSDKKey:serverSDKKey];
  }
  
  // If server SDK key is invalid, then attempt to use SDK key from Info.plist
  NSString *infoDictSDKKey = [self infoDictionarySDKKey];
  if ([self isValidSDKKey:infoDictSDKKey]) {
    return [self retrieveSDKFromSDKKey:infoDictSDKKey];
  }
  
  return nil;
}

+ (nullable ALSdk *)retrieveSDKFromSDKKey:(NSString *)sdkKey {
  ALSdk *sdk = [ALSdk sharedWithKey:sdkKey];
  [sdk setPluginVersion:GADMAdapterAppLovinConstant.adapterVersion];
  sdk.mediationProvider = ALMediationProviderAdMob;

  return sdk;
}

+ (nullable NSString *)infoDictionarySDKKey {
  return [[NSBundle mainBundle] infoDictionary][kALAppLovinSDKKey];
}

+ (BOOL)infoDictionaryHasValidSDKKey {
  return [self isValidSDKKey: [self infoDictionarySDKKey]];
}

+ (BOOL)isValidSDKKey:(NSString *)key {
  return [key isKindOfClass:[NSString class]] && ((NSString *) key).length == kALSDKKeyLength;
}

+ (nullable NSString *)retrieveZoneIdentifierFromConnector:(id<GADMediationAdRequest>)connector {
  return [self retrieveZoneIdentifierFromDict:connector.credentials];
}

+ (nullable NSString *)retrieveZoneIdentifierFromAdConfiguration:(GADMediationAdConfiguration *)adConfig {
    return [self retrieveZoneIdentifierFromDict:adConfig.credentials.settings];
}

+ (nullable NSString *)retrieveZoneIdentifierFromDict:(NSDictionary <NSString *, id> *)dict {
  NSString *customZoneIdentifier = dict[GADMAdapterAppLovinConstant.zoneIdentifierKey];
  
  // Custom zone found
  if (customZoneIdentifier) {
    // Custom zone is valid
    if (customZoneIdentifier.length == kALZoneIdentifierLength) {
      return customZoneIdentifier;
    // Custom zone is invalid - return nil (adapter will fail the ad load)
    } else {
      return nil;
    }
  }
  
  [self log: @"WARNING: Please provide a custom zone in your AdMob configuration. Using default zone..."];
    
  // Use default zone if no custom zone attempted
  return DEFAULT_ZONE;
}

+ (GADErrorCode)toAdMobErrorCode:(int)code {
  if (code == kALErrorCodeNoFill) {
    return kGADErrorMediationNoFill;
  } else if (code == kALErrorCodeAdRequestNetworkTimeout) {
    return kGADErrorTimeout;
  } else if (code == kALErrorCodeInvalidResponse) {
    return kGADErrorReceivedInvalidResponse;
  } else if (code == kALErrorCodeUnableToRenderAd) {
    return kGADErrorServerError;
  } else {
    return kGADErrorInternalError;
  }
}

+ (nullable ALAdSize *)adSizeFromRequestedSize:(GADAdSize)size {
  if (GADAdSizeEqualToSize(kGADAdSizeBanner, size) ||
      GADAdSizeEqualToSize(kGADAdSizeLargeBanner, size) ||
      (IS_IPHONE && GADAdSizeEqualToSize(kGADAdSizeSmartBannerPortrait,
                                         size)))  // Smart iPhone portrait banners 50px tall.
  {
    return [ALAdSize sizeBanner];
  } else if (GADAdSizeEqualToSize(kGADAdSizeMediumRectangle, size)) {
    return [ALAdSize sizeMRec];
  } else if (GADAdSizeEqualToSize(kGADAdSizeLeaderboard, size) ||
             (IS_IPAD && GADAdSizeEqualToSize(kGADAdSizeSmartBannerPortrait,
                                              size)))  // Smart iPad portrait "banners" 90px tall.
  {
    return [ALAdSize sizeLeader];
  } else {
    // This is not a one of AdMob's predefined size.
    CGSize frameSize = size.size;
    // Attempt to check for fluid size.
    if (CGRectGetWidth([UIScreen mainScreen].bounds) == frameSize.width) {
      CGFloat frameHeight = frameSize.height;
      if (frameHeight == CGSizeFromGADAdSize(kGADAdSizeBanner).height ||
          frameHeight == CGSizeFromGADAdSize(kGADAdSizeLargeBanner).height) {
        return [ALAdSize sizeBanner];
      } else if (frameHeight == CGSizeFromGADAdSize(kGADAdSizeMediumRectangle).height) {
        return [ALAdSize sizeMRec];
      } else if (frameHeight == CGSizeFromGADAdSize(kGADAdSizeLeaderboard).height) {
        return [ALAdSize sizeLeader];
      }
    }
    // Assume fluid width, and check for height with offset tolerance.
    CGFloat offset = ABS(kALBannerStandardHeight - frameSize.height);
    if (offset <= kALBannerHeightOffsetTolerance) {
      return [ALAdSize sizeBanner];
    }
  }

  [GADMAdapterAppLovinUtils
      log:@"Unable to retrieve AppLovin size from GADAdSize: %@", NSStringFromGADAdSize(size)];

  return nil;
}

#pragma mark - Logging

+ (void)log:(NSString *)format, ... {
  if (GADMAdapterAppLovinConstant.loggingEnabled) {
    va_list valist;
    va_start(valist, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:valist];
    va_end(valist);

    NSLog(@"AppLovinAdapter: %@", message);
  }
}

@end
