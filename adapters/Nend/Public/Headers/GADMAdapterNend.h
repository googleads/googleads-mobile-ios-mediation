//
//  GADMAdapterNend.h
//  NendAdapter
//
//  Copyright © 2017 F@N Communications. All rights reserved.
//

@import GoogleMobileAds;

@interface GADMAdapterNend : NSObject<GADMAdNetworkAdapter>

@end

typedef NS_ENUM(NSInteger, GADMNendInterstitialType) {
  GADMNendInterstitialTypeNormal = 1,
  GADMNendInterstitialTypeVideo = 2,
};

@interface GADMAdapterNendExtras : NSObject<GADAdNetworkExtras>

@property(nonatomic) GADMNendInterstitialType interstitialType;
@property(nonatomic, copy) NSString *userId;

@end
