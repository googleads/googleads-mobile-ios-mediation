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

+(BOOL) isAppInitialised;
@property(nonatomic, strong) IMBanner *adView;
@property(nonatomic, strong) IMInterstitial *interstitial;
@property(nonatomic, strong) IMInterstitial *adRewarded;
@property(nonatomic, strong) IMNative *native;
@property(nonatomic, readonly) long long placementId;
@property(nonatomic, weak) id<GADMAdNetworkConnector> connector;
@property(nonatomic, weak) id<GADMRewardBasedVideoAdNetworkConnector> rewardedConnector;
@end
