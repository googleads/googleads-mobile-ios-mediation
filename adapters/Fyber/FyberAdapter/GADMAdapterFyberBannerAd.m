// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterFyberBannerAd.h"

#import <IASDKCore/IASDKCore.h>

#import <stdatomic.h>

#import "GADMAdapterFyberConstants.h"
#import "GADMAdapterFyberUtils.h"

@interface GADMAdapterFyberBannerAd () <GADMediationBannerAd, IAUnitDelegate>
@end

@implementation GADMAdapterFyberBannerAd {
  /// Ad configuration for the ad to be loaded.
  GADMediationBannerAdConfiguration *_adConfiguration;

  /// The completion handler to call when an ad loads successfully or fails.
  GADMediationBannerLoadCompletionHandler _loadCompletionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  /// Intentionally keeping a reference to the delegate because this delegate is returned from the
  /// GMA SDK, not set on the GMA SDK.
  id<GADMediationBannerAdEventDelegate> _delegate;

  /// Fyber Ad Spot to be loaded.
  IAAdSpot *_adSpot;

  /// Fyber MRAID controller to support HTML ads.
  IAMRAIDContentController *_MRAIDContentController;

  /// Fyber view controller to catch banner related ad events.
  IAViewUnitController *_viewUnitController;
}

- (instancetype)initWithAdConfiguration:
    (nonnull GADMediationBannerAdConfiguration *)adConfiguration {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)loadBannerAdWithCompletionHandler:
    (nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
  __block atomic_flag adLoadHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationBannerLoadCompletionHandler originalAdLoadHandler = [completionHandler copy];

  // Ensure the original completion handler is only called once, and is deallocated once called.
  _loadCompletionHandler =
      ^id<GADMediationBannerAdEventDelegate>(id<GADMediationBannerAd> bannerAd, NSError *error) {
    if (atomic_flag_test_and_set(&adLoadHandlerCalled)) {
      return nil;
    }

    id<GADMediationBannerAdEventDelegate> delegate = nil;
    if (originalAdLoadHandler) {
      delegate = originalAdLoadHandler(bannerAd, error);
    }

    originalAdLoadHandler = nil;
    return delegate;
  };

  GADMAdapterFyberBannerAd *__weak weakSelf = self;
  GADMAdapterFyberInitializeWithAppId(
      _adConfiguration.credentials.settings[GADMAdapterFyberApplicationID],
      ^(NSError *_Nullable error) {
        GADMAdapterFyberBannerAd *strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }

        if (error) {
          GADMAdapterFyberLog("Failed to initialize Fyber Marketplace SDK: %@",
                              error.localizedDescription);
          strongSelf->_loadCompletionHandler(nil, error);
          return;
        }

        [self loadBannerAd];
      });
}

- (void)loadBannerAd {
  NSString *spotID = _adConfiguration.credentials.settings[GADMAdapterFyberSpotID];
  if (!spotID.length) {
    NSError *error = GADMAdapterFyberErrorWithCodeAndDescription(
        GADMAdapterFyberErrorInvalidServerParameters, @"Missing or Invalid Spot ID.");
    GADMAdapterFyberLog(@"%@", error.localizedDescription);
    _loadCompletionHandler(nil, error);
    return;
  }

  _MRAIDContentController =
      [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder> _Nonnull builder){
      }];

  GADMAdapterFyberBannerAd *__weak weakSelf = self;
  _viewUnitController =
      [IAViewUnitController build:^(id<IAViewUnitControllerBuilder> _Nonnull builder) {
        GADMAdapterFyberBannerAd *strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }

        builder.unitDelegate = strongSelf;
        [builder addSupportedContentController:strongSelf->_MRAIDContentController];
      }];

  IAAdRequest *request =
      GADMAdapterFyberBuildRequestWithSpotIDAndAdConfiguration(spotID, _adConfiguration);
  _adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder> _Nonnull builder) {
    builder.adRequest = request;
    builder.mediationType = [[IAMediationAdMob alloc] init];

    GADMAdapterFyberBannerAd *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    [builder addSupportedUnitController:strongSelf->_viewUnitController];
  }];

  [_adSpot fetchAdWithCompletion:^(IAAdSpot *_Nullable adSpot, IAAdModel *_Nullable adModel,
                                   NSError *_Nullable error) {
    GADMAdapterFyberBannerAd *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    if (error) {
      GADMAdapterFyberLog(@"Failed to load banner ad: %@", error.localizedDescription);
      strongSelf->_loadCompletionHandler(nil, error);
      return;
    }

    // Verify the loaded ad size with the requested ad size.
    GADAdSize loadedAdSize =
        GADAdSizeFromCGSize(CGSizeMake(strongSelf->_viewUnitController.adView.frame.size.width,
                                       strongSelf->_viewUnitController.adView.frame.size.height));
    NSArray<NSValue *> *potentials = @[ NSValueFromGADAdSize(loadedAdSize) ];
    GADAdSize closestSize =
        GADClosestValidSizeForAdSizes(strongSelf->_adConfiguration.adSize, potentials);
    if (!IsGADAdSizeValid(closestSize)) {
      NSString *errorMessage =
          [NSString stringWithFormat:@"The loaded ad size did not match the requested ad size. "
                                     @"Requested ad size: %@. Loaded size: %@.",
                                     NSStringFromGADAdSize(strongSelf->_adConfiguration.adSize),
                                     NSStringFromGADAdSize(loadedAdSize)];
      NSError *error = GADMAdapterFyberErrorWithCodeAndDescription(
          GADMAdapterFyberErrorBannerSizeMismatch, errorMessage);
      GADMAdapterFyberLog(@"%@", error.localizedDescription);
      strongSelf->_loadCompletionHandler(nil, error);

      return;
    }

    strongSelf->_delegate = strongSelf->_loadCompletionHandler(strongSelf, nil);

    UIView *view = strongSelf->_viewUnitController.adView;

    // Set constraints for rotations or banner expand support.
    if (view.superview) {
      view.translatesAutoresizingMaskIntoConstraints = NO;

      [view.superview addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                                 attribute:NSLayoutAttributeCenterX
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:view.superview
                                                                 attribute:NSLayoutAttributeCenterX
                                                                multiplier:1
                                                                  constant:0]];

      [view.superview addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:view.superview
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1
                                                                  constant:0]];

      [view.superview addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:view
                                                                 attribute:NSLayoutAttributeWidth
                                                                multiplier:1
                                                                  constant:0]];

      [view.superview addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:view
                                                                 attribute:NSLayoutAttributeHeight
                                                                multiplier:1
                                                                  constant:0]];
    }
  }];
}

#pragma mark - GADMediationBannerAd

- (UIView *)view {
  return _viewUnitController.adView;
}

#pragma mark - IAUnitDelegate

- (nonnull UIViewController *)IAParentViewControllerForUnitController:
    (nullable IAUnitController *)unitController {
  return _adConfiguration.topViewController;
}

- (void)IAAdDidReceiveClick:(nullable IAUnitController *)unitController {
  [_delegate reportClick];
}

- (void)IAAdWillLogImpression:(nullable IAUnitController *)unitController {
  [_delegate reportImpression];
}

- (void)IAUnitControllerWillPresentFullscreen:(nullable IAUnitController *)unitController {
  [_delegate willPresentFullScreenView];
}

- (void)IAUnitControllerWillDismissFullscreen:(nullable IAUnitController *)unitController {
  [_delegate willDismissFullScreenView];
}

- (void)IAUnitControllerDidDismissFullscreen:(nullable IAUnitController *)unitController {
  [_delegate didDismissFullScreenView];
}

- (void)IAUnitControllerWillOpenExternalApp:(nullable IAUnitController *)unitController {
  [_delegate willBackgroundApplication];
}

@end
