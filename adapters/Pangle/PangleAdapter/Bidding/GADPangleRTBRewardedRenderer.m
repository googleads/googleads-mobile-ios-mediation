//
//  GADPangleRTBRewardedRenderer.m
//  PangleAdapter
//
//  Created by bytedance on 2022/1/11.
//

#import "GADPangleRTBRewardedRenderer.h"
#import "GADMediationAdapterPangleConstants.h"
#import <BUAdSDK/BUAdSDK.h>
#import "GADMAdapterPangleUtils.h"

@interface GADPangleRTBRewardedRenderer()<BURewardedVideoAdDelegate>

@end

@implementation GADPangleRTBRewardedRenderer {
    /// The completion handler to call when the ad loading succeeds or fails.
    GADMediationRewardedLoadCompletionHandler _loadCompletionHandler;
    /// The Pangle rewarded ad.
    BURewardedVideoAd *_rewardedVideoAd;
    /// An ad event delegate to invoke when ad rendering events occur.
    id<GADMediationRewardedAdEventDelegate> _delegate;
}

- (void)renderRewardedAdForAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
    _loadCompletionHandler = completionHandler;
    NSString *slotId = adConfiguration.credentials.settings[GADMAdapterPanglePlacementID] ?: @"";
    if (PangleIsEmptyString(slotId)) {
        NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorInvalidServerParameters, [NSString stringWithFormat:@"%@ cannot be nil,please update Pangle SDK to the latest version.",GADMAdapterPanglePlacementID]);
        _loadCompletionHandler(nil, error);
        return;
    }
    BURewardedVideoModel *model = [[BURewardedVideoModel alloc] init];
    _rewardedVideoAd = [[BURewardedVideoAd alloc]initWithSlotID:slotId rewardedVideoModel:model];
    _rewardedVideoAd.delegate = self;
    if (![_rewardedVideoAd respondsToSelector:@selector(setAdMarkup:)]) {
        NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorVersionLow, @"Pangle SDK version is too low");
        _loadCompletionHandler(nil, error);
        return;
    }
    [_rewardedVideoAd setAdMarkup:adConfiguration.bidResponse];
}

#pragma mark GADMediationRewardedAd
- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    [_rewardedVideoAd showAdFromRootViewController:viewController];
}

#pragma mark  BURewardedVideoAdDelegate
- (void)rewardedVideoAdDidLoad:(BURewardedVideoAd *)rewardedVideoAd {
    if (_loadCompletionHandler) {
        _delegate = _loadCompletionHandler(self,nil);
    }
}

- (void)rewardedVideoAd:(BURewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
    if (_loadCompletionHandler) {
        _loadCompletionHandler(nil, error);
    }
}

- (void)rewardedVideoAdDidVisible:(BURewardedVideoAd *)rewardedVideoAd {
    id<GADMediationRewardedAdEventDelegate> delegate = _delegate;
    [delegate willPresentFullScreenView];
    [delegate reportImpression];
}

- (void)rewardedVideoAdWillClose:(BURewardedVideoAd *)rewardedVideoAd{
    id<GADMediationRewardedAdEventDelegate> delegate = _delegate;
    [delegate willDismissFullScreenView];
}

- (void)rewardedVideoAdDidClose:(BURewardedVideoAd *)rewardedVideoAd {
    id<GADMediationRewardedAdEventDelegate> delegate = _delegate;
    [delegate didDismissFullScreenView];
}

- (void)rewardedVideoAdDidClick:(BURewardedVideoAd *)rewardedVideoAd {
    id<GADMediationRewardedAdEventDelegate> delegate = _delegate;
    [delegate reportClick];
}

- (void)rewardedVideoAdServerRewardDidSucceed:(BURewardedVideoAd *)rewardedVideoAd verify:(BOOL)verify {
    if (verify) {
        NSNumber *amount = [NSDecimalNumber numberWithInteger:rewardedVideoAd.rewardedVideoModel.rewardAmount];
        GADAdReward *reward = [[GADAdReward alloc]initWithRewardType:@"" rewardAmount:[NSDecimalNumber decimalNumberWithDecimal:[amount decimalValue]]];
        
        id<GADMediationRewardedAdEventDelegate> delegate = _delegate;
        [delegate didRewardUserWithReward:reward];
    }
}

@end
