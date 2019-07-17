//
//  AdapterBaseClass.h
//
// @copyright Copyright (c) 2018 Verizon. All rights reserved.
//

#import <VerizonAdsStandardEdition/VerizonAdsStandardEdition.h>
#import <VerizonAdsCore/VerizonAdsCore.h>
#import <VerizonAdsInlinePlacement/VerizonAdsInlinePlacement.h>
#import <VerizonAdsInterstitialPlacement/VerizonAdsInterstitialPlacement.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMVASAdapterBaseClass : NSObject <GADMAdNetworkAdapter, VASInlineAdFactoryDelegate, VASInterstitialAdFactoryDelegate, VASInterstitialAdDelegate, VASInlineAdViewDelegate>

@property (nonatomic, strong) VASInlineAdFactory *inlineAdFactory;
@property (nonatomic, strong) VASInlineAdView *inlineAd;
@property (nonatomic, strong) VASInterstitialAdFactory *interstitialAdFactory;
@property (nonatomic, strong) VASInterstitialAd *interstitialAd;
@property (nonatomic, strong) VASAds *vasAds;
@property (nonatomic, strong) NSString *placementID;
@property (nonatomic, readonly) id<GADMAdNetworkConnector> gadConnector;
@property (nonatomic, weak, readonly) id<GADMediationAdRequest> connector;


@end
