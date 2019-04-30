//
//  GADMAdapterInMobi.h
//
//  Copyright (c) 2015 InMobi. All rights reserved.
//

@import GoogleMobileAds;
#import <InMobiSDK/IMBanner.h>
#import <InMobiSDK/IMBannerDelegate.h>
#import <InMobiSDK/IMInterstitial.h>
#import <InMobiSDK/IMInterstitialDelegate.h>
#import <InMobiSDK/IMNative.h>
#import <InMobiSDK/IMNativeDelegate.h>
#import <InMobiSDK/IMRequestStatus.h>

@interface GADMAdapterInMobi
    : NSObject <GADMAdNetworkAdapter, IMBannerDelegate, IMInterstitialDelegate, IMNativeDelegate> {
}
+ (BOOL)isAppInitialised;
@property(nonatomic, retain) IMBanner *adView;
@property(nonatomic, retain) IMInterstitial *interstitial;
@property(nonatomic, retain) IMNative *native;
@property(nonatomic, readonly) long long placementId;
@property(nonatomic, strong) id<GADMAdNetworkConnector> connector;
@end
