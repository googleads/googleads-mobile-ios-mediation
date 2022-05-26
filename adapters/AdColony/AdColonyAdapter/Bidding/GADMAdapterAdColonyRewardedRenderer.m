// Copyright 2018 Google Inc.
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

#import "GADMAdapterAdColonyRewardedRenderer.h"

#import <AdColony/AdColony.h>
#include <stdatomic.h>

#import "GADMAdapterAdColonyConstants.h"
#import "GADMAdapterAdColonyExtras.h"
#import "GADMAdapterAdColonyHelper.h"
#import "GADMediationAdapterAdColony.h"

@interface GADMAdapterAdColonyRewardedRenderer () <GADMediationRewardedAd,
                                                   AdColonyInterstitialDelegate>
@end

@implementation GADMAdapterAdColonyRewardedRenderer {
  /// An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  /// AdColony rewarded ad.
  AdColonyInterstitial *_rewardedAd;

  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _loadCompletionHandler;

  /// Ad configuration for the ad to be loaded.
  GADMediationRewardedAdConfiguration *_adConfiguration;
}

- (void)loadRewardedAdForAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfig
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)handler {
  _adConfiguration = adConfig;
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler = [handler copy];
  _loadCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(
      _Nullable id<GADMediationRewardedAd> rewardedAd, NSError *_Nullable error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }
    id<GADMediationRewardedAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(rewardedAd, error);
    }
    originalCompletionHandler = nil;
    return delegate;
  };

  [self loadAd];
}

- (void)loadAd {
  GADMAdapterAdColonyRewardedRenderer *__weak weakSelf = self;

  [GADMAdapterAdColonyHelper
      setupZoneFromAdConfig:_adConfiguration
                   callback:^(NSString *zone, NSError *error) {
                     GADMAdapterAdColonyRewardedRenderer *strongSelf = weakSelf;
                     if (!strongSelf) {
                       return;
                     }
                     if (error) {
                       if (strongSelf->_loadCompletionHandler) {
                         strongSelf->_loadCompletionHandler(nil, error);
                       }
                       return;
                     }
                     GADMAdapterAdColonyLog(@"Requesting rewarded ad for zone: %@", zone);
                     AdColonyAdOptions *options = [GADMAdapterAdColonyHelper
                         getAdOptionsFromAdConfig:strongSelf->_adConfiguration];
                     [AdColony requestInterstitialInZone:zone
                                                 options:options
                                             andDelegate:strongSelf];
                   }];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  AdColonyZone *zone = [AdColony zoneForID:_rewardedAd.zoneID];
  GADMAdapterAdColonyRewardedRenderer *__weak weakSelf = self;
  [zone setReward:^(BOOL success, NSString *_Nonnull name, int amount) {
    GADMAdapterAdColonyRewardedRenderer *strongSelf = weakSelf;
    if (success && strongSelf) {
      GADAdReward *reward = [[GADAdReward alloc]
          initWithRewardType:name
                rewardAmount:(NSDecimalNumber *)[NSDecimalNumber numberWithInt:amount]];
      [strongSelf->_adEventDelegate didRewardUserWithReward:reward];
    }
  }];

  if (![_rewardedAd showWithPresentingViewController:viewController]) {
    NSString *errorMessage =
        [NSString stringWithFormat:@"Failed to show ad for zone: %@", _rewardedAd.zoneID];
    GADMAdapterAdColonyLog(@"%@", errorMessage);
    NSError *error =
        GADMAdapterAdColonyErrorWithCodeAndDescription(GADMAdapterAdColonyErrorShow, errorMessage);
    [_adEventDelegate didFailToPresentWithError:error];
  }
}

#pragma mark - AdColonyInterstitialDelegate Delegate

- (void)adColonyInterstitialDidLoad:(nonnull AdColonyInterstitial *)interstitial {
  GADMAdapterAdColonyLog(@"Loaded rewarded ad for zone: %@", interstitial.zoneID);
  AdColonyZone *adZone = [AdColony zoneForID:interstitial.zoneID];
  if (!adZone.rewarded) {
    NSString *errorMessage =
        @"Zone used for rewarded video is not a rewarded video zone on AdColony portal.";
    GADMAdapterAdColonyLog(@"%@", errorMessage);
    NSError *error = GADMAdapterAdColonyErrorWithCodeAndDescription(
        GADMAdapterAdColonyErrorZoneNotRewarded, errorMessage);
    _loadCompletionHandler(nil, error);
    return;
  }

  _rewardedAd = interstitial;
  _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void)adColonyInterstitialDidFailToLoad:(nonnull AdColonyAdRequestError *)error {
  GADMAdapterAdColonyLog(@"Failed to load rewarded ad with error: %@", error.localizedDescription);
  _loadCompletionHandler(nil, error);
}

- (void)adColonyInterstitialWillOpen:(nonnull AdColonyInterstitial *)interstitial {
  id<GADMediationRewardedAdEventDelegate> strongAdEventDelegate = _adEventDelegate;
  [strongAdEventDelegate willPresentFullScreenView];
  [strongAdEventDelegate reportImpression];
  [strongAdEventDelegate didStartVideo];
}

- (void)adColonyInterstitialDidClose:(nonnull AdColonyInterstitial *)interstitial {
  id<GADMediationRewardedAdEventDelegate> strongAdEventDelegate = _adEventDelegate;
  [strongAdEventDelegate didEndVideo];
  [strongAdEventDelegate willDismissFullScreenView];
  [strongAdEventDelegate didDismissFullScreenView];
}

- (void)adColonyInterstitialExpired:(nonnull AdColonyInterstitial *)interstitial {
  // Only reload an ad on bidding, where AdColony would otherwise be charged for an impression
  // it couldn't show. Don't reload ads for regular mediation, as it has side effects on reporting.
  if (_adConfiguration.bidResponse) {
    // Re-requesting rewarded ad to avoid the following situation:
    // 1. Request a rewarded ad from AdColony.
    // 2. AdColony ad loads. Adapter sends a callback saying the ad has been loaded.
    // 3. AdColony ad expires due to timeout.
    // 4. Publisher will not be able to present the ad as it has expired.
    [self loadAd];
    return;
  }

  // Each time AdColony's SDK is configured, it discards previously loaded ads. Publishers should
  // initialize the GMA SDK and wait for initialization to complete to ensure that AdColony's SDK
  // gets initialized with all known zones.
  GADMAdapterAdColonyLog(
      @"Rewarded ad expired due to configuring another ad. Use -[GADMobileAds "
      @"startWithCompletionHandler:] to initialize the Google Mobile Ads SDK and wait for the "
      @"completion handler to be called before requesting an ad. Zone: %@",
      interstitial.zoneID);
}

- (void)adColonyInterstitialDidReceiveClick:(nonnull AdColonyInterstitial *)interstitial {
  [_adEventDelegate reportClick];
}

@end
