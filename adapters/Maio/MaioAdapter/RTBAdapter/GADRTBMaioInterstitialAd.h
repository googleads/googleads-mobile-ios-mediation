//
//  GADRTBMaioInterstitialAd.h
//  Adapter
//
//  Created by i-mobile on 2020/11/18.
//  Copyright © 2020 Google. All rights reserved.
//

#import <Foundation/Foundation.h>

@import GoogleMobileAds;

NS_ASSUME_NONNULL_BEGIN

@interface GADRTBMaioInterstitialAd : NSObject <GADMediationInterstitialAd>

- (void)loadInterstitialForAdConfiguration: (nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler: (nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END