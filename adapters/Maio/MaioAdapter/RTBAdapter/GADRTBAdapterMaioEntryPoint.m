//
//  GADRTBAdapterMaio.m
//  Adapter
//
//  Created by i-mobile on 2020/11/18.
//  Copyright © 2020 Google. All rights reserved.
//

#import "GADRTBAdapterMaioEntryPoint.h"
#import "GADRTBMaioRewardedAd.h"

@interface GADRTBAdapterMaioEntryPoint ()

@property (nonatomic) GADRTBMaioRewardedAd* rewarded;

@end

@implementation GADRTBAdapterMaioEntryPoint

-(void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
  self.rewarded = [[GADRTBMaioRewardedAd alloc] init];
  [self.rewarded loadRewardedAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

@end
