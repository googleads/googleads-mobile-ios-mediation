// Copyright 2019 Google LLC
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

#import "GADMediationVungleRewardedAd.h"
#include <stdatomic.h>
#import "GADMAdapterVungleBiddingRouter.h"
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleUtils.h"

@interface GADMediationVungleRewardedAd () <GADMAdapterVungleDelegate>
@end

@implementation GADMediationVungleRewardedAd {
  /// Ad configuration for the ad to be loaded.
  GADMediationRewardedAdConfiguration *_adConfiguration;

  /// The completion handler to call when an ad loads successfully or fails.
  GADMediationRewardedLoadCompletionHandler _adLoadCompletionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  id<GADMediationRewardedAdEventDelegate> _delegate;
}

@synthesize desiredPlacement;
@synthesize isAdLoaded;

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)handler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;

    __block atomic_flag adLoadHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationRewardedLoadCompletionHandler origAdLoadHandler = [handler copy];

    // Ensure the original completion handler is only called once, and is deallocated once called.
    _adLoadCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(
        id<GADMediationRewardedAd> rewardedAd, NSError *error) {
      if (atomic_flag_test_and_set(&adLoadHandlerCalled)) {
        return nil;
      }

      id<GADMediationRewardedAdEventDelegate> delegate = nil;
      if (origAdLoadHandler) {
        delegate = origAdLoadHandler(rewardedAd, error);
      }

      origAdLoadHandler = nil;
      return delegate;
    };
  }
  return self;
}

- (void)requestRewardedAd {
  self.desiredPlacement =
      [GADMAdapterVungleUtils findPlacement:_adConfiguration.credentials.settings
                              networkExtras:_adConfiguration.extras];
  if (!self.desiredPlacement.length) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        GADMAdapterVungleErrorInvalidServerParameters, @"Placement ID not specified.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  if (![[VungleSDK sharedSDK] isInitialized]) {
    NSString *appID = [GADMAdapterVungleUtils findAppID:_adConfiguration.credentials.settings];
    [GADMAdapterVungleBiddingRouter.sharedInstance initWithAppId:appID delegate:self];
    return;
  }

  [self loadRewardedAd];
}

- (void)loadRewardedAd {
  NSError *error = nil;
  error = [GADMAdapterVungleBiddingRouter.sharedInstance loadAdWithDelegate:self];

  if (error) {
    _adLoadCompletionHandler(nil, error);
  }
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  NSError *error = nil;
  if (![VungleSDK.sharedSDK
               playAd:viewController
              options:GADMAdapterVunglePlaybackOptionsDictionaryForExtras(_adConfiguration.extras)
          placementID:self.desiredPlacement
             adMarkup:[self bidResponse]
                error:&error]) {
    [_delegate didFailToPresentWithError:error];
  }
}

- (void)dealloc {
  _adLoadCompletionHandler = nil;
  _adConfiguration = nil;
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
  [self loadRewardedAd];
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

- (void)didCloseAd {
  [_delegate didDismissFullScreenView];

  [GADMAdapterVungleBiddingRouter.sharedInstance removeDelegate:self];
}

- (void)willCloseAd {
  [_delegate willDismissFullScreenView];
}

- (void)willShowAd {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _delegate;
  [strongDelegate willPresentFullScreenView];
  [strongDelegate didStartVideo];
}

- (void)didViewAd {
  [_delegate reportImpression];
}

- (void)adNotAvailable:(nonnull NSError *)error {
  if (self.isAdLoaded) {
    // Already invoked an ad load callback.
    return;
  }
  _adLoadCompletionHandler(nil, error);
  [GADMAdapterVungleBiddingRouter.sharedInstance removeDelegate:self];
}

- (void)trackClick {
  [_delegate reportClick];
}

- (void)rewardUser {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _delegate;
  [strongDelegate didEndVideo];
  GADAdReward *reward =
      [[GADAdReward alloc] initWithRewardType:@"vungle"
                                 rewardAmount:[NSDecimalNumber decimalNumberWithString:@"1"]];
  [strongDelegate didRewardUserWithReward:reward];
}

- (void)willLeaveApplication {
  // Do nothing.
}

@end
