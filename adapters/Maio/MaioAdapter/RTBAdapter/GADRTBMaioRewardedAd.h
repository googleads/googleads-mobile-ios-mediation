//
//  GADRTBMaioRewardedAd.h
//  Adapter
//
//  Created by i-mobile on 2020/11/18.
//  Copyright © 2020 Google. All rights reserved.
//

#import <Foundation/Foundation.h>

@import GoogleMobileAds;

NS_ASSUME_NONNULL_BEGIN

@interface GADRTBMaioRewardedAd : NSObject

- (void)loadRewardedAdForAdConfiguration: (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler: (nonnull GADMediationRewardedLoadCompletionHandler) completionHandler;

@end

NS_ASSUME_NONNULL_END
