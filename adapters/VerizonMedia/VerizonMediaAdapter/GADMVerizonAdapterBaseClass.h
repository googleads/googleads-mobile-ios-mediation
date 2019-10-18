//
//  GADMVerizonAdapterBaseClass.h
//
// @copyright Copyright (c) 2018 Verizon. All rights reserved.
//

#import <VerizonAdsStandardEdition/VerizonAdsStandardEdition.h>
#import <VerizonAdsCore/VerizonAdsCore.h>
#import <VerizonAdsInlinePlacement/VerizonAdsInlinePlacement.h>
#import <VerizonAdsInterstitialPlacement/VerizonAdsInterstitialPlacement.h>
#import <VerizonAdsNativePlacement/VerizonAdsNativePlacement.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMVerizonAdapterBaseClass : NSObject <GADMediationAdapter,GADMAdNetworkAdapter, GADMRewardBasedVideoAdNetworkAdapter, VASInlineAdFactoryDelegate, VASInterstitialAdFactoryDelegate, VASNativeAdFactoryDelegate, VASInterstitialAdDelegate, VASInlineAdViewDelegate, VASNativeAdDelegate>

@property (nonatomic, strong) VASInlineAdFactory *inlineAdFactory;
@property (nonatomic, strong) VASInlineAdView *inlineAd;
@property (nonatomic, strong) VASInterstitialAdFactory *interstitialAdFactory;
@property (nonatomic, strong) VASInterstitialAd *interstitialAd;
@property (nonatomic, strong) VASNativeAdFactory *nativeAdFactory;
@property (nonatomic, strong) VASAds *vasAds;
@property (nonatomic, strong) NSString *placementID;
@property (nonatomic, readonly) id<GADMAdNetworkConnector> gadConnector;
@property (nonatomic, readonly) id<GADMRewardBasedVideoAdNetworkConnector> rewardConnector;
@property (nonatomic, weak, readonly) id<GADMediationAdRequest> connector;

@end
