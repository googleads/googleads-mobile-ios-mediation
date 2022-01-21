//
//  GADPangleRTBRewardedlRenderer.m
//  PangleAdapter
//
//  Created by bytedance on 2022/1/11.
//

#import "GADPangleRTBRewardedlRenderer.h"
#import "GADMediationAdapterPangleConstants.h"
#import <BUAdSDK/BUAdSDK.h>
#import "GADMAdapterPangleUtils.h"

@interface GADPangleRTBRewardedlRenderer()<BURewardedVideoAdDelegate>

@property (nonatomic, strong) GADMediationRewardedAdConfiguration *adConfig;
@property (nonatomic, copy) GADMediationRewardedLoadCompletionHandler loadCompletionHandler;

@property (nonatomic, strong) BURewardedVideoAd *rewardedVideoAd;

@property (nonatomic, weak) id<GADMediationRewardedAdEventDelegate> delegate;

@end

@implementation GADPangleRTBRewardedlRenderer

- (void)renderRewardedAdForAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
    self.adConfig  = adConfiguration;
    self.loadCompletionHandler = completionHandler;
    NSString *slotId = self.adConfig.credentials.settings[GADMAdapterPanglePlacementID] ?: @"";
    if (PangleIsEmptyString(slotId)) {
        NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorInvalidRequest, [NSString stringWithFormat:@"%@ cannot be nil.",GADMAdapterPanglePlacementID]);
        self.loadCompletionHandler(nil, error);
        return;
    }
    BURewardedVideoModel *model = [[BURewardedVideoModel alloc] init];
    self.rewardedVideoAd = [[BURewardedVideoAd alloc]initWithSlotID:slotId rewardedVideoModel:model];
    self.rewardedVideoAd.delegate = self;
    [self.rewardedVideoAd setMopubAdMarkUp:adConfiguration.bidResponse];
}

//MARK:GADMediationRewardedAd
- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    [self.rewardedVideoAd showAdFromRootViewController:viewController];
}
#pragma mark BURewardedVideoAdDelegate
- (void)rewardedVideoAdDidLoad:(BURewardedVideoAd *)rewardedVideoAd {
    if (self.loadCompletionHandler) {
        self.delegate = self.loadCompletionHandler(self,nil);
    }
    NSLog(@"%s", __func__);
}

- (void)rewardedVideoAdVideoDidLoad:(BURewardedVideoAd *)rewardedVideoAd {
    NSLog(@"%s", __func__);
}

- (void)rewardedVideoAd:(BURewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
    if (self.loadCompletionHandler) {
        self.loadCompletionHandler(nil, error);
    }
    NSLog(@"rewardedVideoAd with error %@", error.description);
}

- (void)rewardedVideoAdWillVisible:(BURewardedVideoAd *)rewardedVideoAd {
    NSLog(@"%s", __func__);
}

- (void)rewardedVideoAdDidVisible:(BURewardedVideoAd *)rewardedVideoAd {
    NSLog(@"%s", __func__);
    [self.delegate willPresentFullScreenView];
    [self.delegate reportImpression];
}

- (void)rewardedVideoAdWillClose:(BURewardedVideoAd *)rewardedVideoAd{
    NSLog(@"%s", __func__);
    [self.delegate willDismissFullScreenView];
}

- (void)rewardedVideoAdDidClose:(BURewardedVideoAd *)rewardedVideoAd {
    NSLog(@"%s", __func__);
    [self.delegate didDismissFullScreenView];
}

- (void)rewardedVideoAdDidClick:(BURewardedVideoAd *)rewardedVideoAd {
    [self.delegate reportClick];
    NSLog(@"%s", __func__);
}

- (void)rewardedVideoAdDidPlayFinish:(BURewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
    NSLog(@"%s", __func__);
}

- (void)rewardedVideoAdServerRewardDidFail:(BURewardedVideoAd *)rewardedVideoAd error:(NSError *)error {
    NSLog(@"%s", __func__);
}

- (void)rewardedVideoAdServerRewardDidSucceed:(BURewardedVideoAd *)rewardedVideoAd verify:(BOOL)verify {
    NSLog(@"%s", __func__);
    if (verify) {
        NSNumber *amount = [NSDecimalNumber numberWithInteger:rewardedVideoAd.rewardedVideoModel.rewardAmount];
        GADAdReward *reward = [[GADAdReward alloc]initWithRewardType:@"" rewardAmount:[NSDecimalNumber decimalNumberWithDecimal:[amount decimalValue]]];
        [self.delegate didRewardUserWithReward:reward];
    }
    
}

- (void)rewardedVideoAdDidClickSkip:(BURewardedVideoAd *)rewardedVideoAd {
    NSLog(@"%s", __func__);
}

- (void)rewardedVideoAdCallback:(BURewardedVideoAd *)rewardedVideoAd withType:(BURewardedVideoAdType)rewardedVideoAdType {
    NSLog(@"%s", __func__);
}



@end
