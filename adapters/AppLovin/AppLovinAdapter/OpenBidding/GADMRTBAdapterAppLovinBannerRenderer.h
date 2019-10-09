//
//  GADMRTBAdapterAppLovinBannerRenderer.h
//  Adapter
//
//  Created by Christopher Cong on 7/17/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMRTBAdapterAppLovinBannerRenderer : NSObject

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationBannerLoadCompletionHandler)handler;

- (nonnull instancetype)init NS_UNAVAILABLE;

/// Loads an AppLovin banner ad.
- (void)loadAd;

@end
