//
//  GADRTBAdapterMaio.h
//  Adapter
//
//  Created by i-mobile on 2020/11/18.
//  Copyright © 2020 Google. All rights reserved.
//

#import <Foundation/Foundation.h>

@import GoogleMobileAds;

NS_ASSUME_NONNULL_BEGIN

@interface GADRTBAdapterMaioEntryPoint : NSObject

- (void)collectSignalsForRequestParameters:(nonnull GADRTBRequestParameters *)params
                         completionHandler:(nonnull GADRTBSignalCompletionHandler)completionHandler;

- (void)loadRewardedAdForAdConfiguration: (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler: (nonnull GADMediationRewardedLoadCompletionHandler) completionHandler;

- (void)loadInterstitialForAdConfiguration: (nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler: (nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler;
@end

NS_ASSUME_NONNULL_END
