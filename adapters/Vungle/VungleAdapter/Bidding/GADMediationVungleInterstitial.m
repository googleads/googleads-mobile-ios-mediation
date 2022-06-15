// Copyright 2021 Google LLC
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

#import "GADMediationVungleInterstitial.h"
#include <stdatomic.h>
#import "GADMAdapterVungleBiddingRouter.h"
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleUtils.h"

@interface GADMediationVungleInterstitial () <GADMAdapterVungleDelegate, GADMediationInterstitialAd>
@end

@implementation GADMediationVungleInterstitial {
  /// Ad configuration for the ad to be loaded.
  GADMediationInterstitialAdConfiguration *_adConfiguration;

  /// The completion handler to call when an ad loads successfully or fails.
  GADMediationInterstitialLoadCompletionHandler _adLoadCompletionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  id<GADMediationInterstitialAdEventDelegate> _delegate;
}

@synthesize desiredPlacement;
@synthesize isAdLoaded;

#pragma mark - GADMediationVungleInterstitial Methods

- (nonnull instancetype)initWithAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration*)adConfiguration
                              completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    self.desiredPlacement = [GADMAdapterVungleUtils findPlacement:adConfiguration.credentials.settings networkExtras:adConfiguration.extras];

    __block atomic_flag adLoadHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationInterstitialLoadCompletionHandler origAdLoadHandler = [completionHandler copy];

    /// Ensure the original completion handler is only called once, and is deallocated once called.
    _adLoadCompletionHandler = ^id<GADMediationInterstitialAdEventDelegate>(
      id<GADMediationInterstitialAd> ad, NSError *error) {
      if (atomic_flag_test_and_set(&adLoadHandlerCalled)) {
        return nil;
      }
      id<GADMediationInterstitialAdEventDelegate> delegate = nil;
      if (origAdLoadHandler) {
        delegate = origAdLoadHandler(ad, error);
      }
      origAdLoadHandler = nil;
      return delegate;
    };
  }
  return self;
}

- (void)requestInterstitialAd {
  if (!self.desiredPlacement.length) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
      GADMAdapterVungleErrorInvalidServerParameters,
      @"Placement ID not specified.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  if (![GADMAdapterVungleBiddingRouter.sharedInstance isSDKInitialized]) {
    NSString *appID = [GADMAdapterVungleUtils findAppID:_adConfiguration.credentials.settings];
    [GADMAdapterVungleBiddingRouter.sharedInstance initWithAppId:appID delegate:self];
    return;
  }

  [self loadAd];
}

#pragma mark - GADMediationInterstitialAd Methods

- (void)presentFromViewController:(UIViewController *)rootViewController {
  NSError *error = nil;
  if (![VungleSDK.sharedSDK
               playAd:rootViewController
              options:GADMAdapterVunglePlaybackOptionsDictionaryForExtras(_adConfiguration.extras)
          placementID:self.desiredPlacement
             adMarkup:[self bidResponse]
                error:&error]) {
    // Ad not playable.
    if (error) {
      [_delegate didFailToPresentWithError:error];
    }
  }
}

#pragma mark - Private methods

- (void)loadAd {
  NSError *error = [GADMAdapterVungleBiddingRouter.sharedInstance loadAdWithDelegate:self];
  if (error) {
    _adLoadCompletionHandler(nil, error);
  }
}

#pragma mark - GADMAdapterVungleDelegate

- (NSString *)bidResponse {
    return [_adConfiguration bidResponse];
}

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error {
  if (!isSuccess) {
    _adLoadCompletionHandler(nil, error);
    return;
  }
  [self loadAd];
}

- (void)adAvailable {
  if (self.isAdLoaded) {
    // Already invoked an ad load callback.
    return;
  }
  self.isAdLoaded = YES;
    
  if (_adLoadCompletionHandler) {
    _delegate = _adLoadCompletionHandler(self, nil);
  }

  if (!_delegate) {
    // In this case, the request for Vungle has been timed out. Clean up self.
    [GADMAdapterVungleBiddingRouter.sharedInstance removeDelegate:self];
  }
}

- (void)adNotAvailable:(nonnull NSError *)error {
  if (self.isAdLoaded) {
    // Already invoked an ad load callback.
    return;
  }
  _adLoadCompletionHandler(nil, error);
}

- (void)willShowAd {
  [_delegate willPresentFullScreenView];
}

- (void)didViewAd {
  // Do nothing.
}

- (void)willCloseAd {
  [_delegate willDismissFullScreenView];
}

- (void)didCloseAd {
  [_delegate didDismissFullScreenView];
}

- (void)trackClick {
  [_delegate reportClick];
}

- (void)willLeaveApplication {
  [_delegate willBackgroundApplication];
}

- (void)rewardUser {
  // Do nothing.
}

@end
