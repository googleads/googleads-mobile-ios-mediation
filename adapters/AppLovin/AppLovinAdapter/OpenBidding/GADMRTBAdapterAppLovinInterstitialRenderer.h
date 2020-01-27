//
//  GADMRTBAdapterAppLovinInterstitialRenderer.h
//  Adapter
//
//  Created by Christopher Cong on 7/17/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import <AppLovinSDK/AppLovinSDK.h>
#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMRTBAdapterAppLovinInterstitialRenderer : NSObject <GADMediationInterstitialAd>

/// Callback object to notify the Google Mobile Ads SDK if ad rendering succeeded or failed.
@property(nonatomic, copy, nonnull, readonly)
    GADMediationInterstitialLoadCompletionHandler adLoadCompletionHandler;

/// Delegate to notify the Google Mobile Ads SDK of interstitial presentation events.
@property(nonatomic, weak, nullable) id<GADMediationInterstitialAdEventDelegate> delegate;

/// An AppLovin interstitial ad.
@property(nonatomic, nullable) ALAd *ad;

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)handler;
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Loads an AppLovin interstitial ad.
- (void)loadAd;

@end
