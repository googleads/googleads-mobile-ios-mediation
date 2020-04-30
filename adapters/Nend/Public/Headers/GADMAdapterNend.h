//
//  GADMAdapterNend.h
//  NendAdapter
//
//  Copyright © 2017 FAN Communications. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMAdapterNend : NSObject <GADMAdNetworkAdapter>

@end

typedef NS_ENUM(NSInteger, GADMNendInterstitialType) {
  GADMNendInterstitialTypeNormal = 1,
  GADMNendInterstitialTypeVideo = 2,
};

typedef NS_ENUM(NSInteger, GADMNendNativeType) {
  GADMNendNativeTypeNormal = 1,
  GADMNendNativeTypeVideo = 2,
};

@interface GADMAdapterNendExtras : NSObject <GADAdNetworkExtras>

/// Interstitial type.
@property(nonatomic) GADMNendInterstitialType interstitialType;

/// Native type.
@property(nonatomic) GADMNendNativeType nativeType;

/// User ID.
@property(nonatomic, copy) NSString *userId;

@end
