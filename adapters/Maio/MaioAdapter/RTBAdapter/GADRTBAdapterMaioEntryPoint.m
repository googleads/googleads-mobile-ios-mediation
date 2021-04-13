//
//  GADRTBAdapterMaio.m
//  Adapter
//
//  Created by i-mobile on 2020/11/18.
//  Copyright © 2020 Google. All rights reserved.
//

#import "GADRTBAdapterMaioEntryPoint.h"
#import "GADRTBMaioRewardedAd.h"
#import "GADRTBMaioInterstitialAd.h"

@implementation GADRTBAdapterMaioEntryPoint {
  GADRTBMaioRewardedAd *_rewarded;
  GADRTBMaioInterstitialAd *_interstitial;
}

- (void)collectSignalsForRequestParameters:(nonnull GADRTBRequestParameters *)params completionHandler:(nonnull GADRTBSignalCompletionHandler)completionHandler {
  completionHandler(nil, nil);
}

-(void)loadRewardedAdForAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  _rewarded = [[GADRTBMaioRewardedAd alloc] initWithAdConfiguration:adConfiguration];
  [_rewarded loadRewardedAdWithCompletionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler {
  _interstitial = [[GADRTBMaioInterstitialAd alloc] initWithAdConfiguration:adConfiguration];
  [_interstitial loadInterstitialWithCompletionHandler:completionHandler];
}

@end
