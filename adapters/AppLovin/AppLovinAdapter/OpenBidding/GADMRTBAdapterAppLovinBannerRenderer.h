//
//  GADMRTBAdapterAppLovinBannerRenderer.h
//  Adapter
//
//  Created by Christopher Cong on 7/17/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import <AppLovinSDK/AppLovinSDK.h>
#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMRTBAdapterAppLovinBannerRenderer : NSObject <GADMediationBannerAd>

/// Callback object to notify the Google Mobile Ads SDK if ad rendering succeeded or failed.
@property(nonatomic, nonnull, copy, readonly)
    GADMediationBannerLoadCompletionHandler adLoadCompletionHandler;

/// Delegate to notify the Google Mobile Ads SDK of banner presentation events.
@property(nonatomic, weak, nullable) id<GADMediationBannerAdEventDelegate> delegate;

/// AppLovin banner ad view.
@property(nonatomic, nullable) ALAdView *adView;

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationBannerLoadCompletionHandler)handler;

- (nonnull instancetype)init NS_UNAVAILABLE;

/// Loads an AppLovin banner ad.
- (void)loadAd;

@end
