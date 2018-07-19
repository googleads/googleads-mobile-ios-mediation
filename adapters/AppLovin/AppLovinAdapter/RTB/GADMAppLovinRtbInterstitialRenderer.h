//
//  GADMAppLovinRtbInterstitialRenderer.h
//  Adapter
//
//  Created by Christopher Cong on 7/17/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

@interface GADMAppLovinRtbInterstitialRenderer : NSObject

- (void)loadAd;

- (instancetype)initWithAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration
                      completionHandler:(nonnull GADInterstitialRenderCompletionHandler)handler;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
