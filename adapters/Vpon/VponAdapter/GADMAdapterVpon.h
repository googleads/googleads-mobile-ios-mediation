//
// GADMAdapterVpon.h
//
// Copyright 2011 Google, Inc.
//

@import GoogleMobileAds;
@import VpadnSDKAdKit;

@protocol GADMAdNetworkAdapter;
@protocol GADMAdNetworkConnector;

@interface GADMAdapterVpon : NSObject <GADMAdNetworkAdapter>

@property (nonatomic, assign) id<GADMAdNetworkAdapter> adapter;
@property (nonatomic, assign) id<GADMAdNetworkConnector> connector;

@property (nonatomic, retain) UIView *adView;

@property (strong, nonatomic) VpadnBanner *banner;
@property (strong, nonatomic) VpadnInterstitial *interstitial;

@end
