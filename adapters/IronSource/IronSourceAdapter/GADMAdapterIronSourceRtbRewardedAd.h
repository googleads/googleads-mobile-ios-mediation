//
//  GADMAdapterIronSourceRtbRewardedAd.h
//  ISMedAdapters
//
//  Created by Jonathan Benedek on 13/08/2024.
//  Copyright © 2024 ironSource Ltd. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/IronSource.h>

#ifndef GADMAdapterIronSourceRtbRewardedAd_h
#define GADMAdapterIronSourceRtbRewardedAd_h


@interface GADMAdapterIronSourceRtbRewardedAd : NSObject <GADMediationRewardedAd,ISARewardedAdDelegate, ISARewardedAdLoaderDelegate>

@property(nonatomic, copy) NSString *instanceID;
@property (nonatomic, strong) ISARewardedAd *biddingISARewardedAd;
@property(copy, nonatomic) GADMediationRewardedLoadCompletionHandler rewardedAdLoadCompletionHandler;
@property(weak, nonatomic) id<GADMediationRewardedAdEventDelegate> rewardedAdEventDelegate;


/// Initializes a new instance with adConfiguration and completionHandler.
- (void)loadRewardedAdForConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                     completionHandler:
(GADMediationRewardedLoadCompletionHandler)completionHandler;



@end
#endif /* GADMAdapterIronSourceRtbRewardedAd_h */
