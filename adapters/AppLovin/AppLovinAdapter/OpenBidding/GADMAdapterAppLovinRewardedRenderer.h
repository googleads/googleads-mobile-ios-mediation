//
//  GADMRTBAdapterAppLovinRewardedRenderer.h
//  Adapter
//
//  Created by Christopher Cong on 7/17/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMAdapterAppLovinRewardedRenderer : NSObject <GADMediationRewardedAd>

- (instancetype)initWithAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                      completionHandler:(GADMediationRewardedLoadCompletionHandler)handler;
- (instancetype)init NS_UNAVAILABLE;
- (void)requestRTBRewardedAd;
- (void)requestRewardedAd;

@end
