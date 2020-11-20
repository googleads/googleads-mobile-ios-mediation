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

@interface GADRTBAdapterMaioEntryPoint ()

@property (nonatomic) GADRTBMaioRewardedAd* rewarded;
@property (nonatomic) GADRTBMaioInterstitialAd* interstitial;

@end

@implementation GADRTBAdapterMaioEntryPoint

- (void)collectSignalsForRequestParameters:(GADRTBRequestParameters *)params completionHandler:(GADRTBSignalCompletionHandler)completionHandler {
  completionHandler(nil, nil);
}

-(void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
  self.rewarded = [[GADRTBMaioRewardedAd alloc] init];
  [self.rewarded loadRewardedAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration completionHandler:(GADMediationInterstitialLoadCompletionHandler)completionHandler {
  self.interstitial = [[GADRTBMaioInterstitialAd alloc] init];
  [self.interstitial loadInterstitialForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

@end
