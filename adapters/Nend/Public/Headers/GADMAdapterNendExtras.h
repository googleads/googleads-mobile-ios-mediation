//
//  GADMAdapterNendExtras.h
//  NendAdapter
//
//  Copyright © 2017 FAN Communications. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

typedef NS_ENUM(NSInteger, GADMAdapterNendInterstitialType) {
  GADMAdapterNendInterstitialTypeNormal = 1,  // << nend normal interstitial ad type
  GADMAdapterNendInterstitialTypeVideo = 2,   // << nend interstitial video ad type
};

typedef NS_ENUM(NSInteger, GADMAdapterNendNativeType) {
  GADMAdapterNendNativeTypeNormal = 1,  // << nend normal native ad type
  GADMAdapterNendNativeTypeVideo = 2,   // << nend native video ad type
};

/// Network extras for the nend adapter.
@interface GADMAdapterNendExtras : NSObject <GADAdNetworkExtras>

/// nend interstitial ad type.
@property(nonatomic) GADMAdapterNendInterstitialType interstitialType;

/// nend native ad type.
@property(nonatomic) GADMAdapterNendNativeType nativeType;

/// nend user ID.
@property(nonatomic, copy) NSString *userId;

@end
