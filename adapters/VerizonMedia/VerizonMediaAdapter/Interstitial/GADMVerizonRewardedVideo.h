//
//  GADMVerizonRewardedVideo.h
//
// @copyright Copyright (c) 2019 Verizon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <VerizonAdsInterstitialPlacement/VerizonAdsInterstitialPlacement.h>

NS_ASSUME_NONNULL_BEGIN

@interface GADMVerizonRewardedVideo : NSObject <GADMediationRewardedAd>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithInterstitialAd:(VASInterstitialAd *)interstitialAd NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
