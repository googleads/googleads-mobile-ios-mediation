//
//  GADMRTBAdapterAppLovinInterstitialRenderer.h
//  Adapter
//
//  Created by Christopher Cong on 7/17/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMRTBAdapterAppLovinInterstitialRenderer : NSObject

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)handler;
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Loads an AppLovin interstitial ad.
- (void)loadAd;

@end
