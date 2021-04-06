

#import "GADMAdapterAdColonyRTBBannerRenderer.h"
#import <AdColony/AdColony.h>
#include <stdatomic.h>

#import "GADMAdapterAdColonyConstants.h"
#import "GADMAdapterAdColonyExtras.h"
#import "GADMAdapterAdColonyHelper.h"
#import "GADMediationAdapterAdColony.h"

@interface GADMAdapterAdColonyRTBBannerRenderer () <GADMediationBannerAd, AdColonyAdViewDelegate>
@end

@implementation GADMAdapterAdColonyRTBBannerRenderer {
  /// Completion handler to call when the ad loading succeeds or fails.
  GADMediationBannerLoadCompletionHandler _renderCompletionHandler;

  /// AdColony banner ad.
  AdColonyAdView *_bannerAdView;

  /// An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationBannerAdEventDelegate> _adEventDelegate;

  /// Ad configuration for the ad to be loaded.
  GADMediationBannerAdConfiguration *_adConfiguration;
}

/// Asks the receiver to render the ad configuration.
- (void)renderBannerForAdConfig:(nonnull GADMediationBannerAdConfiguration *)adConfig
              completionHandler:(nonnull GADMediationBannerLoadCompletionHandler)handler {
  _adConfiguration = adConfig;
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationBannerLoadCompletionHandler originalCompletionHandler = [handler copy];
  _renderCompletionHandler = ^id<GADMediationBannerAdEventDelegate>(
      _Nullable id<GADMediationBannerAd> bannerAd, NSError *_Nullable error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }
    id<GADMediationBannerAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(bannerAd, error);
    }
    originalCompletionHandler = nil;
    return delegate;
  };

  [self loadAd];
}

- (void)loadAd {
  GADMAdapterAdColonyRTBBannerRenderer *__weak weakSelf = self;
  [GADMAdapterAdColonyHelper
      setupZoneFromAdConfig:_adConfiguration
                   callback:^(NSString *zone, NSError *error) {
                     GADMAdapterAdColonyRTBBannerRenderer *strongSelf = weakSelf;

                     if (!strongSelf) {
                       return;
                     }

                     if (error) {
                       if (strongSelf->_renderCompletionHandler) {
                         strongSelf->_renderCompletionHandler(nil, error);
                       }

                       return;
                     }

                     GADMAdapterAdColonyLog(@"Requesting banner ad for zone: %@", zone);
                     AdColonyAdOptions *options = [GADMAdapterAdColonyHelper
                         getAdOptionsFromAdConfig:strongSelf->_adConfiguration];

                     UIViewController *viewController =
                         strongSelf->_adConfiguration.topViewController;
                     if (!viewController) {
                       NSString *errorMessage = @"View controller cannot be nil.";
                       NSError *error = GADMAdapterAdColonyErrorWithCodeAndDescription(
                           GADMAdapterAdColonyErrorRootViewControllerNil, errorMessage);
                       strongSelf->_renderCompletionHandler(nil, error);
                       return;
                     }

                     GADAdSize adSize = strongSelf->_adConfiguration.adSize;
                     AdColonyAdSize adColonyAdSize =
                         AdColonyAdSizeMake(adSize.size.width, adSize.size.height);
                     [AdColony requestAdViewInZone:zone
                                          withSize:adColonyAdSize
                                        andOptions:options
                                    viewController:viewController
                                       andDelegate:self];
                   }];
}

#pragma mark - GADMediationBannerAd

- (nonnull UIView *)view {
  return _bannerAdView;
}

#pragma mark - AdColonyAdViewDelegate Delegate

- (void)adColonyAdViewDidLoad:(nonnull AdColonyAdView *)adView {
  GADMAdapterAdColonyLog(@"Banner ad loaded.");
  _bannerAdView = adView;
  _adEventDelegate = _renderCompletionHandler(self, nil);
}

- (void)adColonyAdViewDidFailToLoad:(nonnull AdColonyAdRequestError *)error {
  GADMAdapterAdColonyLog(@"Failed to load banner ad: %@", error.localizedDescription);
  _adEventDelegate = _renderCompletionHandler(nil, error);
}

- (void)adColonyAdViewWillLeaveApplication:(nonnull AdColonyAdView *)adView {
  [_adEventDelegate willBackgroundApplication];
}

- (void)adColonyAdViewWillOpen:(nonnull AdColonyAdView *)adView {
  [_adEventDelegate willPresentFullScreenView];
}

- (void)adColonyAdViewDidClose:(nonnull AdColonyAdView *)adView {
  [_adEventDelegate didDismissFullScreenView];
}

- (void)adColonyAdViewDidReceiveClick:(nonnull AdColonyAdView *)adView {
  [_adEventDelegate reportClick];
}
@end
