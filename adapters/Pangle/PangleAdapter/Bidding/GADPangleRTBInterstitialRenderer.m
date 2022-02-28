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

@end

@implementation GADPangleRTBInterstitialRenderer {
    /// The completion handler to call when the ad loading succeeds or fails.
    GADMediationInterstitialLoadCompletionHandler _loadCompletionHandler;
    /// The Pangle interstitial ad.
    BUFullscreenVideoAd *_fullScreenAdVideo;
    /// An ad event delegate to invoke when ad rendering events occur.
    id<GADMediationInterstitialAdEventDelegate> _delegate;
}

- (void)renderInterstitialForAdConfiguration:
(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                           completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler {
    _loadCompletionHandler = completionHandler;
    NSString *slotId = adConfiguration.credentials.settings[GADMAdapterPanglePlacementID] ?: @"";\
    if (PangleIsEmptyString(slotId)) {
        NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorInvalidServerParameters, @"placementid cannot be nil,please update Pangle SDK to the latest version.");
        _loadCompletionHandler(nil, error);
        return;
    }
    _fullScreenAdVideo = [[BUFullscreenVideoAd alloc]initWithSlotID:slotId];
    _fullScreenAdVideo.delegate = self;
    if (![_fullScreenAdVideo respondsToSelector:@selector(setAdMarkup:)]) {
        NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorVersionLow, @"Pangle SDK version is too low");
        _loadCompletionHandler(nil, error);
        return;
    }
    [_fullScreenAdVideo setAdMarkup:adConfiguration.bidResponse];
}

#pragma mark--GADMediationInterstitialAd
- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    [_fullScreenAdVideo showAdFromRootViewController:viewController];
}

#pragma mark-- BUFullscreenVideoAdDelegate
- (void)fullscreenVideoMaterialMetaAdDidLoad:(BUFullscreenVideoAd *)fullscreenVideoAd {
    if (_loadCompletionHandler) {
        id<GADMediationInterstitialAdEventDelegate> delegate = _delegate;
        delegate = _loadCompletionHandler(self,nil);
    }
}

- (void)fullscreenVideoAd:(BUFullscreenVideoAd *)fullscreenVideoAd didFailWithError:(NSError *_Nullable)error {
    if (_loadCompletionHandler) {
        _loadCompletionHandler(nil, error);
    }
}

- (void)fullscreenVideoAdWillVisible:(BUFullscreenVideoAd *)fullscreenVideoAd {
    id<GADMediationInterstitialAdEventDelegate> delegate = _delegate;
    [delegate willPresentFullScreenView];
    [delegate reportImpression];
}

- (void)fullscreenVideoAdDidClick:(BUFullscreenVideoAd *)fullscreenVideoAd {
    id<GADMediationInterstitialAdEventDelegate> delegate = _delegate;
    [delegate reportClick];
}

- (void)fullscreenVideoAdWillClose:(BUFullscreenVideoAd *)fullscreenVideoAd {
    id<GADMediationInterstitialAdEventDelegate> delegate = _delegate;
    [delegate willDismissFullScreenView];
}

- (void)fullscreenVideoAdDidClose:(BUFullscreenVideoAd *)fullscreenVideoAd {
    id<GADMediationInterstitialAdEventDelegate> delegate = _delegate;
    [delegate didDismissFullScreenView];
}

- (void)fullscreenVideoAdDidPlayFinish:(BUFullscreenVideoAd *)fullscreenVideoAd didFailWithError:(NSError *_Nullable)error {
    if (error) {
        id<GADMediationInterstitialAdEventDelegate> delegate = _delegate;
        [delegate didFailToPresentWithError:error];
    }
}

@end
