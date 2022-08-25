//
//  GADMVerizonAdapterBaseClass.h
//
// @copyright Copyright (c) 2018 Verizon. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <VerizonAdsCore/VerizonAdsCore.h>
#import <VerizonAdsInlinePlacement/VerizonAdsInlinePlacement.h>
#import <VerizonAdsInterstitialPlacement/VerizonAdsInterstitialPlacement.h>
#import <VerizonAdsNativePlacement/VerizonAdsNativePlacement.h>

@interface GADMAdapterVerizonBaseClass : NSObject <GADMAdNetworkAdapter>

@property(nonatomic, strong, nullable) VASInlineAdFactory *inlineAdFactory;
@property(nonatomic, strong, nullable) VASInlineAdView *inlineAd;
@property(nonatomic, strong, nullable) VASInterstitialAdFactory *interstitialAdFactory;
@property(nonatomic, strong, nullable) VASInterstitialAd *interstitialAd;
@property(nonatomic, strong, nullable) NSString *placementID;
+ (nonnull VASLogger *)logger;

@end
