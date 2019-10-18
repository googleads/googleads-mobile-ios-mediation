//
//  GADMVerizonRewardedVideo.m
//
// @copyright Copyright (c) 2019 Verizon. All rights reserved.
//

#import "GADMVerizonRewardedVideo.h"

@interface GADMVerizonRewardedVideo()

@property(nonatomic, strong) VASInterstitialAd *rewardedAd;

@end

@implementation GADMVerizonRewardedVideo

- (instancetype)initWithInterstitialAd:(VASInterstitialAd *)interstitialAd
{
    if (self = [super init]) {
        _rewardedAd = interstitialAd;
    }
    return self;
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController
{
    [self.rewardedAd showFromViewController:viewController];
}

@end
