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
#import <VerizonAdsStandardEdition/VerizonAdsStandardEdition.h>

@interface GADMAdapterVerizonBaseClass : NSObject <GADMAdNetworkAdapter>

@property(nonatomic, strong) VASInlineAdFactory *inlineAdFactory;
@property(nonatomic, strong) VASInlineAdView *inlineAd;
@property(nonatomic, strong) VASInterstitialAdFactory *interstitialAdFactory;
@property(nonatomic, strong) VASInterstitialAd *interstitialAd;
@property(nonatomic, strong) VASAds *vasAds;
@property(nonatomic, strong) NSString *placementID;
@property(nonatomic, weak, readonly) id<GADMAdNetworkConnector> connector;
+ (VASLogger *)logger;

@end
