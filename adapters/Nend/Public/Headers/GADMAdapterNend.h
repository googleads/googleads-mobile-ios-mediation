//
//  GADMAdapterNend.h
//  NendAdapter
//
//  Copyright © 2017 FAN Communications. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMAdapterNend : NSObject<GADMAdNetworkAdapter>

@end

typedef NS_ENUM(NSInteger, GADMNendInterstitialType) {
  GADMNendInterstitialTypeNormal = 1,
  GADMNendInterstitialTypeVideo = 2,
};

typedef NS_ENUM(NSInteger, GADMNendNativeType) {
  GADMNendNativeTypeNormal = 1,
  GADMNendNativeTypeVideo = 2,
};

@interface GADMAdapterNendExtras : NSObject<GADAdNetworkExtras>

@property(nonatomic) GADMNendInterstitialType interstitialType;
@property(nonatomic) GADMNendNativeType nativeType;
@property(nonatomic, copy) NSString *userId;

@end
