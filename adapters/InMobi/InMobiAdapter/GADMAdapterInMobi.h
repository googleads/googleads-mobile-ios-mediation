//
//  GADMAdapterInMobi.h
//
//  Copyright (c) 2015 InMobi. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <InMobiSDK/IMBanner.h>
#import <InMobiSDK/IMBannerDelegate.h>
#import <InMobiSDK/IMInterstitial.h>
#import <InMobiSDK/IMInterstitialDelegate.h>
#import <InMobiSDK/IMNative.h>
#import <InMobiSDK/IMNativeDelegate.h>
#import <InMobiSDK/IMRequestStatus.h>

@interface GADMAdapterInMobi
    : NSObject <GADMAdNetworkAdapter, IMBannerDelegate, IMInterstitialDelegate>

@end
