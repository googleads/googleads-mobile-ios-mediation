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
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleDelegate.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"

@interface GADMediationVungleRewardedAd () <GADMAdapterVungleDelegate, VungleRewardedDelegate>
@end

@implementation GADMediationVungleRewardedAd {
  /// Ad configuration for the ad to be loaded.
  GADMediationRewardedAdConfiguration *_adConfiguration;

  /// The completion handler to call when an ad loads successfully or fails.
  GADMediationRewardedLoadCompletionHandler _adLoadCompletionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  id<GADMediationRewardedAdEventDelegate> _delegate;

  /// Liftoff Monetize rewarded ad instance.
  VungleRewarded *_rewardedAd;
}

@synthesize desiredPlacement;

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
      [GADMAdapterVungleUtils findPlacement:_adConfiguration.credentials.settings];
  if (![VungleAds isInitialized]) {
    NSString *appID = [GADMAdapterVungleUtils findAppID:_adConfiguration.credentials.settings];
    [GADMAdapterVungleRouter.sharedInstance initWithAppId:appID delegate:self];
    return;
  }

  [self loadRewardedAd];
}

- (void)loadRewardedAd {
  _rewardedAd = [[VungleRewarded alloc] initWithPlacementId:self.desiredPlacement];
  _rewardedAd.delegate = self;
  VungleAdsExtras *extras = [[VungleAdsExtras alloc] init];
  [extras setWithWatermark:[_adConfiguration.watermark base64EncodedStringWithOptions:0]];
  [_rewardedAd setWithExtras:extras];
    if ([_adConfiguration extras] &&
        [[_adConfiguration extras] isKindOfClass:[VungleAdNetworkExtras class]]) {
      VungleAdNetworkExtras *extras = (VungleAdNetworkExtras *)[_adConfiguration extras];
      if (extras && extras.userId) {
        [_rewardedAd setUserIdWithUserId:extras.userId];
      }
    }
  [_rewardedAd load:_adConfiguration.bidResponse];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [_rewardedAd presentWith:viewController];
}

- (void)dealloc {
  _adLoadCompletionHandler = nil;
  _adConfiguration = nil;
  _delegate = nil;
  _rewardedAd = nil;
}

#pragma mark - VungleRewardedDelegate

- (void)rewardedAdDidLoad:(nonnull VungleRewarded *)rewarded {
  if (_adLoadCompletionHandler) {
    _delegate = _adLoadCompletionHandler(self, nil);
  }
}

- (void)rewardedAdDidFailToLoad:(nonnull VungleRewarded *)rewarded
                      withError:(nonnull NSError *)error {
  _adLoadCompletionHandler(nil, error);
}

- (void)rewardedAdWillPresent:(nonnull VungleRewarded *)rewarded {
  [_delegate willPresentFullScreenView];
}

- (void)rewardedAdDidPresent:(nonnull VungleRewarded *)rewarded {
  [_delegate didStartVideo];
}

- (void)rewardedAdDidFailToPresent:(nonnull VungleRewarded *)rewarded
                         withError:(nonnull NSError *)error {
  [_delegate didFailToPresentWithError:error];
}

- (void)rewardedAdWillClose:(nonnull VungleRewarded *)rewarded {
  [_delegate willDismissFullScreenView];
}

- (void)rewardedAdDidClose:(nonnull VungleRewarded *)rewarded {
  [_delegate didEndVideo];
  [_delegate didDismissFullScreenView];
}

- (void)rewardedAdDidTrackImpression:(nonnull VungleRewarded *)rewarded {
  [_delegate reportImpression];
}

- (void)rewardedAdDidClick:(nonnull VungleRewarded *)rewarded {
  [_delegate reportClick];
}

- (void)rewardedAdWillLeaveApplication:(nonnull VungleRewarded *)rewarded {
  // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)rewardedAdDidRewardUser:(nonnull VungleRewarded *)rewarded {
  [_delegate didRewardUser];
}

#pragma mark - GADMAdapterVungleDelegate

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error {
  if (!isSuccess) {
    _adLoadCompletionHandler(nil, error);
    return;
  }
  [self loadRewardedAd];
}

@end
