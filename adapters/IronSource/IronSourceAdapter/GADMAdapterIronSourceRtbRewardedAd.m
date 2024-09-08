// Copyright 2024 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
    
    if (credentials[GADMAdapterIronSourceInstanceId]) {
        self.instanceID = credentials[GADMAdapterIronSourceInstanceId];
    } else {
        [GADMAdapterIronSourceUtils onLog:@"Missing or invalid IronSource interstitial ad Instance ID. "
         @"Using the default instance ID."];
        self.instanceID = GADMIronSourceDefaultRtbInstanceId;
    }
    
    NSString *bidResponse = adConfiguration.bidResponse;
    NSMutableDictionary<NSString *, NSString *> *extraParams = [GADMAdapterIronSourceUtils getExtraParamsWithWatermark:adConfiguration.watermark];
    
    ISARewardedAdRequest *adRequest = [[[[ISARewardedAdRequestBuilder alloc] initWithInstanceId: self.instanceID adm: bidResponse] withExtraParams:extraParams] build];
    
    [ISARewardedAdLoader loadAdWithAdRequest: adRequest delegate: self];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    [GADMAdapterIronSourceUtils onLog:NSStringFromSelector(_cmd)];
    id<GADMediationRewardedAdEventDelegate> rewardedDelegate = self.rewardedAdEventDelegate;

    if (!self.biddingISARewardedAd){
        if (rewardedDelegate){
            NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(
                                                                              GADMAdapterIronSourceErrorFailedToShow,
                                                                              @"the ad is nil");
            [rewardedDelegate didFailToPresentWithError:error];
        }
        [GADMAdapterIronSourceUtils
         onLog:[NSString stringWithFormat:@"Failed to show due to ad not loaded, for Instance ID: %@",
                self.instanceID]];
        return;
    }
    
    [self.biddingISARewardedAd setDelegate:self];
    [self.biddingISARewardedAd showFromViewController:viewController ];
    [rewardedDelegate willPresentFullScreenView];
}

#pragma mark - ISARewardedAdLoaderDelegate


- (void)rewardedAdDidLoad:(nonnull ISARewardedAd *)rewardedAd {
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"%@ instanceId= %@ adId= %@", NSStringFromSelector(_cmd),
            rewardedAd.adInfo.instanceId,
            rewardedAd.adInfo.adId]];
    self.biddingISARewardedAd = rewardedAd;
    if (!self.rewardedAdLoadCompletionHandler){
        return;
    }
    
    self.rewardedAdEventDelegate = self.rewardedAdLoadCompletionHandler(self, nil);
}

- (void)rewardedAdDidFailToLoadWithError:(nonnull NSError *)error {
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"%@ with error= %@", NSStringFromSelector(_cmd), error.localizedDescription]];
    if (!self.rewardedAdLoadCompletionHandler){
        return;
    }
    self.rewardedAdLoadCompletionHandler(nil, error);
}

#pragma mark - ISARewardedAdDelegate

- (void)rewardedAdDidShow:(nonnull ISARewardedAd *)rewardedAd {
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"%@ instanceId= %@ adId= %@", NSStringFromSelector(_cmd),
            rewardedAd.adInfo.instanceId,
            rewardedAd.adInfo.adId]];
    id<GADMediationRewardedAdEventDelegate> rewardedDelegate = self.rewardedAdEventDelegate;
    if (!rewardedDelegate){
        return;
    }
    
    [rewardedDelegate didStartVideo];
    [rewardedDelegate reportImpression];
}

- (void)rewardedAd:(nonnull ISARewardedAd *)rewardedAd didFailToShowWithError:(nonnull NSError *)error {
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"%@ with error= %@", NSStringFromSelector(_cmd), error.localizedDescription]];
    id<GADMediationRewardedAdEventDelegate> rewardedDelegate = self.rewardedAdEventDelegate;
    if (!rewardedDelegate){
        return;
    }
    
    [rewardedDelegate didFailToPresentWithError:error];
}

- (void)rewardedAdDidClick:(nonnull ISARewardedAd *)rewardedAd {
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"%@ instanceId= %@ adId= %@", NSStringFromSelector(_cmd),
            rewardedAd.adInfo.instanceId,
            rewardedAd.adInfo.adId]];
    id<GADMediationRewardedAdEventDelegate> rewardedDelegate = self.rewardedAdEventDelegate;
    if (!rewardedDelegate){
        return;
    }
    
    [rewardedDelegate reportClick];
}

- (void)rewardedAdDidDismiss:(nonnull ISARewardedAd *)rewardedAd {
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"%@ instanceId= %@ adId= %@", NSStringFromSelector(_cmd),
            rewardedAd.adInfo.instanceId,
            rewardedAd.adInfo.adId]];
    id<GADMediationRewardedAdEventDelegate> rewardedDelegate = self.rewardedAdEventDelegate;
    if (!rewardedDelegate){
        return;
    }
    [rewardedDelegate willDismissFullScreenView];
    [rewardedDelegate didDismissFullScreenView];
}

- (void)rewardedAdDidUserEarnReward:(nonnull ISARewardedAd *)rewardedAd {
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"%@ instanceId= %@ adId= %@", NSStringFromSelector(_cmd),
            rewardedAd.adInfo.instanceId,
            rewardedAd.adInfo.adId]];
    id<GADMediationRewardedAdEventDelegate> rewardedDelegate = self.rewardedAdEventDelegate;
    if (!rewardedDelegate){
        return;
    }
    [rewardedDelegate didRewardUser];
    [rewardedDelegate didEndVideo];
}

@end
