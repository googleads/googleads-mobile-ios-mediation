//
//  GADPangleRTBAppOpenRenderer.m
//  Adapter
//
//  Created by bytedance on 2023/5/5.
//

#import "GADPangleRTBAppOpenRenderer.h"
#import <PAGAdSDK/PAGAdSDK.h>
#include <stdatomic.h>
#import "GADMAdapterPangleUtils.h"
#import "GADMediationAdapterPangleConstants.h"

@interface GADPangleRTBAppOpenRenderer ()<PAGLAppOpenAdDelegate>{
    /// The completion handler to call when the ad loading succeeds or fails.
    GADMediationAppOpenLoadCompletionHandler _loadCompletionHandler;
    /// The Pangle app open ad.
    PAGLAppOpenAd *_appOpenAd;
    /// An ad event delegate to invoke when ad rendering events occur.
    __weak id<GADMediationAppOpenAdEventDelegate> _delegate;
}

@end

@implementation GADPangleRTBAppOpenRenderer

- (void)renderAppOpenAdForAdConfiguration:
            (nonnull GADMediationAppOpenAdConfiguration *)adConfiguration
                      completionHandler:
(nonnull GADMediationAppOpenLoadCompletionHandler)completionHandler {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationAppOpenLoadCompletionHandler originalCompletionHandler =
        [completionHandler copy];
    
    _loadCompletionHandler = ^id<GADMediationAppOpenAdEventDelegate> _Nullable (_Nullable id<GADMediationAppOpenAd> ad,NSError *_Nullable error) {
      if (atomic_flag_test_and_set(&completionHandlerCalled)) {
        return nil;
      }
      id<GADMediationAppOpenAdEventDelegate> delegate = nil;
      if (originalCompletionHandler) {
        delegate = originalCompletionHandler(ad, error);
      }
      originalCompletionHandler = nil;
      return delegate;
    };
    NSString *placementId = adConfiguration.credentials.settings[GADMAdapterPanglePlacementID];
    if (!placementId.length) {
      NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(
          GADPangleErrorInvalidServerParameters,
          [NSString stringWithFormat:@"%@ cannot be nil.", GADMAdapterPanglePlacementID]);
      _loadCompletionHandler(nil, error);
      return;
    }
    PAGAppOpenRequest *request = [PAGAppOpenRequest request];
    request.adString = adConfiguration.bidResponse.length ? adConfiguration.bidResponse : nil;
    GADPangleRTBAppOpenRenderer *__weak weakSelf = self;
    [PAGLAppOpenAd loadAdWithSlotID:placementId
                            request:request
                  completionHandler:^(PAGLAppOpenAd * _Nullable appOpenAd, NSError * _Nullable error) {
        GADPangleRTBAppOpenRenderer *strongSelf = weakSelf;
        if (!strongSelf) {
           return;
        }
        if (error) {
          if (strongSelf->_loadCompletionHandler) {
            strongSelf->_loadCompletionHandler(nil, error);
          }
          return;
        }

        strongSelf->_appOpenAd = appOpenAd;
        strongSelf->_appOpenAd.delegate = strongSelf;

        if (strongSelf->_loadCompletionHandler) {
          strongSelf->_delegate = strongSelf->_loadCompletionHandler(strongSelf, nil);
        }
    }];
}

#pragma mark - GADMediationAppOpenAd
/// Presents the receiver from the view controller.
- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    [_appOpenAd presentFromRootViewController:viewController];
}

#pragma mark - PAGLAppOpenAdDelegate
- (void)adDidShow:(PAGLAppOpenAd *)ad {
    id<GADMediationAppOpenAdEventDelegate> delegate = _delegate;
    [delegate willPresentFullScreenView];
    [delegate reportImpression];
}

- (void)adDidClick:(PAGLAppOpenAd *)ad {
    id<GADMediationAppOpenAdEventDelegate> delegate = _delegate;
    [delegate reportClick];
}

- (void)adDidDismiss:(PAGLAppOpenAd *)ad {
    id<GADMediationAppOpenAdEventDelegate> delegate = _delegate;
    [delegate willDismissFullScreenView];
    [delegate didDismissFullScreenView];
}

@end
