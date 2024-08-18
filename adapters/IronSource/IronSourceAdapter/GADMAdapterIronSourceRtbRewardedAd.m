//
//  GADMAdapterIronSourceRtbRewardedAd.m
//  ISMedAdapters
//
//  Created by Jonathan Benedek on 13/08/2024.
//  Copyright © 2024 ironSource Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GADMAdapterIronSourceRtbRewardedAd.h"
#import "GADMAdapterIronSourceUtils.h"
#import "GADMAdapterIronSourceConstants.h"

@interface GADMAdapterIronSourceRtbRewardedAd ()


@end

@implementation GADMAdapterIronSourceRtbRewardedAd


- (void)loadRewardedAdForConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                     completionHandler:
                         (GADMediationRewardedLoadCompletionHandler)completionHandler {
    _rewardedAdLoadCompletionHandler = completionHandler;

    NSDictionary *credentials = [adConfiguration.credentials settings];
    NSString *applicationKey = credentials[GADMAdapterIronSourceAppKey];
      
    if (applicationKey != nil && ![GADMAdapterIronSourceUtils isEmpty:applicationKey]) {
      applicationKey = credentials[GADMAdapterIronSourceAppKey];
    } else {
      NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(
          GADMAdapterIronSourceErrorInvalidServerParameters,
          @"Missing or invalid IronSource application key.");

      _rewardedAdLoadCompletionHandler(nil, error);
      return;
    }

    if (credentials[GADMAdapterIronSourceInstanceId]) {
      self.instanceID = credentials[GADMAdapterIronSourceInstanceId];
    } else {
      [GADMAdapterIronSourceUtils onLog:@"Missing or invalid IronSource interstitial ad Instance ID. "
                                        @"Using the default instance ID."];
      self.instanceID = GADMIronSourceDefaultInstanceId;
    }

        NSString *bidResponse = adConfiguration.bidResponse;
        NSString *watermarkString = [[NSString alloc] initWithData:adConfiguration.watermark encoding:NSUTF8StringEncoding];
      
        [IronSource setMetaDataWithKey:@"google_water_mark" value:watermarkString];
        
      
      ISARewardedAdRequest *adRequest = [[[ISARewardedAdRequestBuilder alloc] initWithInstanceId: self.instanceID adm: bidResponse] build];
      
      [ISARewardedAdLoader loadAdWithAdRequest: adRequest delegate: self];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:@"Showing IronSource interstitial ad for Instance ID: %@",
                                         self.instanceID]];
    if (!self.biddingISARewardedAd){
        if (self.rewardedAdEventDelegate){
            NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(
                                                                              GADMAdapterIronSourceErrorFailedToShow,
                                                                              @"the ad is nil");
            [self.rewardedAdEventDelegate didFailToPresentWithError:error];
        }
        [GADMAdapterIronSourceUtils
            onLog:[NSString stringWithFormat:@"Failed to show due to ad not loaded, for Instance ID: %@",
                                             self.instanceID]];
        return;
    }
    
      [self.biddingISARewardedAd setDelegate:self];
      [self.biddingISARewardedAd showFromViewController:viewController ];
}

- (void)rewardedAdDidLoad:(nonnull ISARewardedAd *)rewardedAd {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    self.biddingISARewardedAd = rewardedAd;
    if (!self.rewardedAdLoadCompletionHandler){
        return;
    }
    
    self.rewardedAdEventDelegate = self.rewardedAdLoadCompletionHandler(self, nil);
}

- (void)rewardedAdDidFailToLoadWithError:(nonnull NSError *)error {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (!self.rewardedAdLoadCompletionHandler){
        return;
    }
    self.rewardedAdLoadCompletionHandler(nil, error);
}

- (void)rewardedAdDidShow:(nonnull ISARewardedAd *)rewardedAd {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (!self.rewardedAdEventDelegate){
        return;
    }
    
    [self.rewardedAdEventDelegate willPresentFullScreenView];
    [self.rewardedAdEventDelegate didStartVideo];
    [self.rewardedAdEventDelegate reportImpression];
}

- (void)rewardedAd:(nonnull ISARewardedAd *)rewardedAd didFailToShowWithError:(nonnull NSError *)error {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (!self.rewardedAdEventDelegate){
        return;
    }
    
    [self.rewardedAdEventDelegate didFailToPresentWithError:error];
}

- (void)rewardedAdDidClick:(nonnull ISARewardedAd *)rewardedAd {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (!self.rewardedAdEventDelegate){
        return;
    }
    
    [self.rewardedAdEventDelegate reportClick];
}

- (void)rewardedAdDidDismiss:(nonnull ISARewardedAd *)rewardedAd {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (!self.rewardedAdEventDelegate){
        return;
    }
    [self.rewardedAdEventDelegate willDismissFullScreenView];
    [self.rewardedAdEventDelegate didDismissFullScreenView];
}

- (void)rewardedAdDidUserEarnReward:(nonnull ISARewardedAd *)rewardedAd {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    if (!self.rewardedAdEventDelegate){
        return;
    }
    [self.rewardedAdEventDelegate didRewardUser];
    [self.rewardedAdEventDelegate didEndVideo];
}



@end
