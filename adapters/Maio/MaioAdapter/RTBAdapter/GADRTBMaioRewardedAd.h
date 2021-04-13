//
//  GADRTBMaioRewardedAd.h
//  Adapter
//
//  Created by i-mobile on 2020/11/18.
//  Copyright © 2020 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADRTBMaioRewardedAd : NSObject<GADMediationRewardedAd>

- (nonnull instancetype)initWithAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration;
- (void)loadRewardedAdWithCompletionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)completionHandler;

@end
