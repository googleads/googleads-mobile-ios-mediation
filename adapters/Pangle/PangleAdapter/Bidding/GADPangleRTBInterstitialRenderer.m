//
//  GADPangleRTBInterstitialRenderer.m
//  PangleAdapter
//
//  Created by bytedance on 2022/1/11.
//

#import "GADPangleRTBInterstitialRenderer.h"
#import "GADMediationAdapterPangleConstants.h"
#import <BUAdSDK/BUAdSDK.h>
#import "GADMAdapterPangleUtils.h"

@interface GADPangleRTBInterstitialRenderer()<BUFullscreenVideoAdDelegate>

@property (nonatomic, strong) GADMediationInterstitialAdConfiguration *adConfig;
@property (nonatomic, copy) GADMediationInterstitialLoadCompletionHandler loadCompletionHandler;

@property (nonatomic, strong) BUFullscreenVideoAd *fullScreenAdVideo;

@property (nonatomic, weak) id<GADMediationInterstitialAdEventDelegate> delegate;

@end

@implementation GADPangleRTBInterstitialRenderer

- (void)renderInterstitialForAdConfiguration:
(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                           completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler {
    self.adConfig  = adConfiguration;
    self.loadCompletionHandler = completionHandler;
    NSString *slotId = self.adConfig.credentials.settings[GADMAdapterPanglePlacementID] ?: @"";\
    if (PangleIsEmptyString(slotId)) {
        NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorInvalidRequest, @"placementid cannot be nil.");
        self.loadCompletionHandler(nil, error);
        return;
    }
    self.fullScreenAdVideo = [[BUFullscreenVideoAd alloc]initWithSlotID:slotId];
    self.fullScreenAdVideo.delegate = self;
    [self.fullScreenAdVideo setMopubAdMarkUp:adConfiguration.bidResponse];
}

//MARK:--GADMediationInterstitialAd
- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    [self.fullScreenAdVideo showAdFromRootViewController:viewController];
}

//MARK:-- BUFullscreenVideoAdDelegate
- (void)fullscreenVideoMaterialMetaAdDidLoad:(BUFullscreenVideoAd *)fullscreenVideoAd {
    if (self.loadCompletionHandler) {
        self.delegate = self.loadCompletionHandler(self,nil);
    }
}

- (void)fullscreenVideoAd:(BUFullscreenVideoAd *)fullscreenVideoAd didFailWithError:(NSError *_Nullable)error {
    if (self.loadCompletionHandler) {
        self.loadCompletionHandler(nil, error);
    }
}

- (void)fullscreenVideoAdVideoDataDidLoad:(BUFullscreenVideoAd *)fullscreenVideoAd {
    NSLog(@"%s",__func__);
}

- (void)fullscreenVideoAdWillVisible:(BUFullscreenVideoAd *)fullscreenVideoAd {
    NSLog(@"%s",__func__);
    [self.delegate willPresentFullScreenView];
    [self.delegate reportImpression];
}

- (void)fullscreenVideoAdDidVisible:(BUFullscreenVideoAd *)fullscreenVideoAd {
    NSLog(@"%s",__func__);
    
}

- (void)fullscreenVideoAdDidClick:(BUFullscreenVideoAd *)fullscreenVideoAd {
    [self.delegate reportClick];
}

- (void)fullscreenVideoAdWillClose:(BUFullscreenVideoAd *)fullscreenVideoAd {
    NSLog(@"%s",__func__);
    [self.delegate willDismissFullScreenView];
}

- (void)fullscreenVideoAdDidClose:(BUFullscreenVideoAd *)fullscreenVideoAd {
    NSLog(@"%s",__func__);
    [self.delegate didDismissFullScreenView];
}

- (void)fullscreenVideoAdDidPlayFinish:(BUFullscreenVideoAd *)fullscreenVideoAd didFailWithError:(NSError *_Nullable)error {
    NSLog(@"%s",__func__);
    if (error) {
        [self.delegate didFailToPresentWithError:error];
    }
}

- (void)fullscreenVideoAdDidClickSkip:(BUFullscreenVideoAd *)fullscreenVideoAd {
    NSLog(@"%s",__func__);
}

- (void)fullscreenVideoAdCallback:(BUFullscreenVideoAd *)fullscreenVideoAd withType:(BUFullScreenVideoAdType)fullscreenVideoAdType {
    NSLog(@"%s",__func__);
}

@end
