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

static const CGFloat kALBannerHeightOffsetTolerance = 10.0f;
static const CGFloat kALBannerStandardHeight = 50.0f;

@implementation GADMAdapterAppLovinUtils

+ (nullable ALSdk *)retrieveSDKFromCredentials:(NSDictionary *)credentials {
  NSString *sdkKey = credentials[GADMAdapterAppLovinConstant.sdkKey];

  if (sdkKey.length == 0) {
    sdkKey = [[NSBundle mainBundle] infoDictionary][@"AppLovinSdkKey"];
  }

  ALSdk *sdk = [ALSdk sharedWithKey:sdkKey];
  [sdk setPluginVersion:GADMAdapterAppLovinConstant.adapterVersion];
  sdk.mediationProvider = ALMediationProviderAdMob;

  return sdk;
}

+ (NSString *)retrievePlacementFromConnector:(id<GADMediationAdRequest>)connector {
  return connector.credentials[GADMAdapterAppLovinConstant.placementKey] ?: @"";
}

+ (NSString *)retrieveZoneIdentifierFromConnector:(id<GADMediationAdRequest>)connector {
  return connector.credentials[GADMAdapterAppLovinConstant.zoneIdentifierKey] ?: DEFAULT_ZONE;
}

+ (GADErrorCode)toAdMobErrorCode:(int)code {
  //
  // TODO: Be more exhaustive.
  //

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
    }
    // This is not a one of AdMob's predefined size.
    else {
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

+ (ALIncentivizedInterstitialAd *)incentivizedInterstitialAdWithZoneIdentifier:
                                      (NSString *)zoneIdentifier
                                                                           sdk:(ALSdk *)sdk {
  // Prematurely create instance of ALAdView to store initialized one in later.
  ALIncentivizedInterstitialAd *incent = [ALIncentivizedInterstitialAd alloc];

  // We must use NSInvocation over performSelector: for initializers.
  NSMethodSignature *methodSignature = [ALIncentivizedInterstitialAd
      instanceMethodSignatureForSelector:@selector(initWithZoneIdentifier:sdk:)];
  NSInvocation *inv = [NSInvocation invocationWithMethodSignature:methodSignature];
  [inv setSelector:@selector(initWithZoneIdentifier:sdk:)];
  [inv setArgument:&zoneIdentifier atIndex:2];
  [inv setArgument:&sdk atIndex:3];
  [inv setReturnValue:&incent];
  [inv invokeWithTarget:incent];

  return incent;
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
