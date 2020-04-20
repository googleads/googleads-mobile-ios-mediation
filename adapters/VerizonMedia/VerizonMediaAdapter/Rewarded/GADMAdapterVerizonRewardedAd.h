//
//  GADMAdapterVerizonRewardedAd.h
//
// @copyright Copyright (c) 2019 Verizon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

/// Verizon Media rewarded ad wrapper.
@interface GADMAdapterVerizonRewardedAd : NSObject <GADMediationRewardedAd>

/// Requests rewarded ads from Verizon media SDK.
- (void)loadRewardedAdForAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfig
                       completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)handler;

@end
