//
//  GADPangleRTBBannerRenderer.m
//  PangleAdapter
//
//  Created by bytedance on 2022/1/11.
//

#import "GADPangleRTBBannerRenderer.h"
#import "GADMediationAdapterPangleConstants.h"
#import <BUAdSDK/BUAdSDK.h>
#import "GADMAdapterPangleUtils.h"

@interface GADPangleRTBBannerRenderer()<BUNativeExpressBannerViewDelegate>

@property (nonatomic, strong) GADMediationBannerAdConfiguration *adConfig;
@property (nonatomic, copy) GADMediationBannerLoadCompletionHandler loadCompletionHandler;

@property (nonatomic, strong) BUNativeExpressBannerView *nativeExpressBannerView;

@property (nonatomic, weak) id<GADMediationBannerAdEventDelegate> delegate;

@end

@implementation GADPangleRTBBannerRenderer

- (void)renderBannerForAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
                     completionHandler:
(nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
    self.adConfig  = adConfiguration;
    self.loadCompletionHandler = completionHandler;
    NSString *slotId = self.adConfig.credentials.settings[GADMAdapterPanglePlacementID] ?: @"";
    if (PangleIsEmptyString(slotId)) {
        NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorInvalidRequest, [NSString stringWithFormat:@"%@ cannot be nil.",GADMAdapterPanglePlacementID]);
        self.loadCompletionHandler(nil, error);
        return;
    }
    self.nativeExpressBannerView = [[BUNativeExpressBannerView alloc]initWithSlotID:slotId rootViewController:self.adConfig.topViewController adSize:self.adConfig.adSize.size];
    self.nativeExpressBannerView.delegate = self;
    [self.nativeExpressBannerView setMopubAdMarkUp:adConfiguration.bidResponse];
}

//MARK:-- GADMediationBannerAd
- (UIView *)view {
    return self.nativeExpressBannerView;
}

//MARK:--BUNativeExpressBannerViewDelegate
- (void)nativeExpressBannerAdViewDidLoad:(BUNativeExpressBannerView *)bannerAdView {
    if (self.loadCompletionHandler) {
        self.delegate = self.loadCompletionHandler(self,nil);
    }
    NSLog(@"nativeExpressBannerAdViewDidLoad");
}

- (void)nativeExpressBannerAdView:(BUNativeExpressBannerView *)bannerAdView didLoadFailWithError:(NSError *)error {
    NSLog(@"nativeExpressAdFailToLoad with error %@", error.description);
    if (self.loadCompletionHandler) {
        self.loadCompletionHandler(nil, error);
    }
}

- (void)nativeExpressBannerAdViewRenderSuccess:(BUNativeExpressBannerView *)bannerAdView {
    NSLog(@"nativeExpressBannerAdViewRenderSuccess");
    [self.delegate reportImpression];
}

- (void)nativeExpressBannerAdViewRenderFail:(BUNativeExpressBannerView *)bannerAdView error:(NSError *)error {
    NSLog(@"nativeExpressBannerAdViewRenderFail");
    if (self.loadCompletionHandler) {
        self.loadCompletionHandler(nil, error);
    }
}

- (void)nativeExpressBannerAdViewWillBecomVisible:(BUNativeExpressBannerView *)bannerAdView {
    NSLog(@"nativeExpressBannerAdViewWillBecomVisible");
}

- (void)nativeExpressBannerAdViewDidClick:(BUNativeExpressBannerView *)bannerAdView {
    [self.delegate reportClick];
}

- (void)nativeExpressBannerAdView:(BUNativeExpressBannerView *)bannerAdView dislikeWithReason:(NSArray<BUDislikeWords *> *)filterwords {
    NSLog(@"nativeExpressBannerAdView dislikeWithReason");
    
}

- (void)nativeExpressBannerAdViewDidCloseOtherController:(BUNativeExpressBannerView *)bannerAdView interactionType:(BUInteractionType)interactionType {
    
}

- (void)nativeExpressBannerAdViewDidRemoved:(BUNativeExpressBannerView *)bannerAdView {
    
}

@end
