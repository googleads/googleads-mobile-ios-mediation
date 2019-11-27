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

#import "GADMAdapterVungleRewardedAd.h"
#include <stdatomic.h>
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"

@interface GADMAdapterVungleRewardedAd () <GADMAdapterVungleDelegate>
@end

@implementation GADMAdapterVungleRewardedAd {
  /// Ad configuration for the ad to be loaded.
  GADMediationRewardedAdConfiguration *_adConfiguration;

  /// The completion handler to call when an ad loads successfully or fails.
  GADMediationRewardedLoadCompletionHandler _adLoadCompletionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  __weak id<GADMediationRewardedAdEventDelegate> _delegate;

  /// Indicates whether the rewarded ad is presenting.
  BOOL _isRewardedAdPresenting;
}

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
  self.adapterAdType = GADMAdapterVungleAdTypeRewarded;
  self.desiredPlacement =
      [GADMAdapterVungleUtils findPlacement:_adConfiguration.credentials.settings
                              networkExtras:_adConfiguration.extras];
  if (!self.desiredPlacement) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(kGADErrorMediationDataError,
                                                                  @"Placement ID not specified.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  if ([[GADMAdapterVungleRouter sharedInstance]
          hasDelegateForPlacementID:self.desiredPlacement
                        adapterType:GADMAdapterVungleAdTypeRewarded]) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        kGADErrorMediationAdapterError,
        @"Only a maximum of one ad per placement can be requested from Vungle.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  VungleSDK *sdk = [VungleSDK sharedSDK];

  if (![sdk isInitialized]) {
    NSString *appID = [GADMAdapterVungleUtils findAppID:_adConfiguration.credentials.settings];
    if (appID) {
      [[GADMAdapterVungleRouter sharedInstance] initWithAppId:appID delegate:self];
    } else {
      NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
          kGADErrorMediationDataError, @"Vungle app ID should be specified.");
      _adLoadCompletionHandler(nil, error);
    }
  } else {
    [self loadRewardedAd];
  }
}

- (void)loadRewardedAd {
  NSError *error = [[GADMAdapterVungleRouter sharedInstance] loadAd:self.desiredPlacement
                                                       withDelegate:self];
  if (error) {
    _adLoadCompletionHandler(nil, error);
  }
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  _isRewardedAdPresenting = YES;
  if (![[GADMAdapterVungleRouter sharedInstance] playAd:viewController
                                               delegate:self
                                                 extras:[_adConfiguration extras]]) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        kGADErrorMediationAdapterError, @"Adapter failed to present rewarded ad.");
    _adLoadCompletionHandler(nil, error);
  }
}

- (void)dealloc {
  _adLoadCompletionHandler = nil;
  _adConfiguration = nil;
}

#pragma mark - VungleRouter delegates

@synthesize desiredPlacement;
@synthesize adapterAdType;

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error {
  if (isSuccess) {
    [self loadRewardedAd];
  } else {
    _adLoadCompletionHandler(nil, error);
  }
}

- (void)adAvailable {
  if (!_isRewardedAdPresenting) {
    if (_adLoadCompletionHandler) {
      _delegate = _adLoadCompletionHandler(self, nil);
    }

    if (!_delegate) {
      // In this case, the request for Vungle has been timed out. Clean up self.
      [[GADMAdapterVungleRouter sharedInstance] removeDelegate:self];
    }
  }
}

- (void)didCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _delegate;
  if (completedView) {
    [strongDelegate didEndVideo];
    GADAdReward *reward =
        [[GADAdReward alloc] initWithRewardType:@"vungle"
                                   rewardAmount:[NSDecimalNumber decimalNumberWithString:@"1"]];
    [strongDelegate didRewardUserWithReward:reward];
  }
  if (didDownload) {
    [strongDelegate reportClick];
  }
  [strongDelegate didDismissFullScreenView];

  GADMAdapterVungleRewardedAd __weak *weakSelf = self;
  [[GADMAdapterVungleRouter sharedInstance] removeDelegate:weakSelf];
}

- (void)willCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload {
  _isRewardedAdPresenting = NO;
  [_delegate willDismissFullScreenView];
}

- (void)willShowAd {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _delegate;
  [strongDelegate willPresentFullScreenView];
  [strongDelegate reportImpression];
  [strongDelegate didStartVideo];
}

- (void)adNotAvailable:(nonnull NSError *)error {
  _adLoadCompletionHandler(nil, error);
  [[GADMAdapterVungleRouter sharedInstance] removeDelegate:self];
}

@end
