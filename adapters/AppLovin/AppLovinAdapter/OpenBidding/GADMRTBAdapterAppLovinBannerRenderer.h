//
//  GADMRTBAdapterAppLovinBannerRenderer.h
//  Adapter
//
//  Created by Christopher Cong on 7/17/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

@interface GADMRTBAdapterAppLovinBannerRenderer : NSObject

- (void)loadAd;

- (instancetype)initWithAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                      completionHandler:(GADMediationBannerLoadCompletionHandler)handler;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
