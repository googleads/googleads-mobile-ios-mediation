//
//  GADMVerizonNativeAd.h
//
// @copyright Copyright (c) 2019 Verizon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <VerizonAdsNativePlacement/VerizonAdsNativePlacement.h>

/// Verizon media native ad wrapper.
@interface GADMAdapterVerizonNativeAd : NSObject <GADMediatedUnifiedNativeAd>

/// Creates a GADMAdapterVerizonNativeAd with the provided GADMAdNetworkConnector and
/// GADMAdNetworkAdapter.
- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                              withGADMAdNetworkAdapter:(nonnull id<GADMAdNetworkAdapter>)adapter
  NS_DESIGNATED_INITIALIZER;

/// Unavailable.
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Requests native ads from Verizon media SDK.
- (void)loadNativeAdWithAdTypes:(nonnull NSArray<GADAdLoaderAdType> *)adTypes
                        options:(nullable NSArray<GADAdLoaderOptions *> *)options;

@end
