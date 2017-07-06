//
//  GADMAdapterInMobi.h
//
//  Copyright (c) 2015 InMobi. All rights reserved.
//

#import <GoogleMobileAds/Mediation/GADMAdNetworkAdapterProtocol.h>
#import <GoogleMobileAds/Mediation/GADMAdNetworkConnectorProtocol.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <GoogleMobileAds/Mediation/GADMRewardBasedVideoAdNetworkConnectorProtocol.h>
#import <GoogleMobileAds/Mediation/GADMRewardBasedVideoAdNetworkAdapterProtocol.h>

#import <InMobiSDK/IMBanner.h>
#import <InMobiSDK/IMBannerDelegate.h>
#import <InMobiSDK/IMInterstitial.h>
#import <InMobiSDK/IMInterstitialDelegate.h>
#import <InMobiSDK/IMNative.h>
#import <InMobiSDK/IMNativeDelegate.h>
#import <InMobiSDK/IMRequestStatus.h>

@interface GADMAdapterInMobi : NSObject <GADMAdNetworkAdapter,
GADMRewardBasedVideoAdNetworkAdapter, IMBannerDelegate, IMInterstitialDelegate, IMNativeDelegate> {
}

@property(nonatomic, retain) IMBanner *adView;
@property(nonatomic, retain) IMInterstitial *interstitial;
@property(nonatomic, retain) IMInterstitial *adRewarded;
@property(nonatomic, retain) IMNative *native;
@property(nonatomic, readonly) long long placementId;
@property(nonatomic, strong) id<GADMAdNetworkConnector> connector;
@property(nonatomic, strong) id<GADMRewardBasedVideoAdNetworkConnector> rewardedConnector;
@end
