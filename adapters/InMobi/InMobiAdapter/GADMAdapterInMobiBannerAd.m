// Copyright 2015 Google LLC
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
//

#import "GADMAdapterInMobiBannerAd.h"
#include <stdatomic.h>
#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiInitializer.h"
#import "GADMAdapterInMobiUtils.h"
#import "GADMInMobiConsent.h"
#import "GADMediationAdapterInMobi.h"

static CGSize GADMAdapterInMobiSupportedAdSizeFromGADAdSize(GADAdSize gadAdSize) {
  NSArray<NSValue *> *potentialSizeValues =
      @[ @(GADAdSizeBanner), @(GADAdSizeMediumRectangle), @(GADAdSizeLeaderboard) ];

  GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentialSizeValues);
  return CGSizeFromGADAdSize(closestSize);
}

@implementation GADMAdapterInMobiBannerAd {
  /// An ad event delegate to invoke when ad rendering events occur.
  id<GADMediationBannerAdEventDelegate> _bannerAdEventDelegate;

  /// Ad Configuration for the banner ad to be rendered.
  GADMediationBannerAdConfiguration *_bannerAdConfig;

  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationBannerLoadCompletionHandler _bannerAdLoadCompletionHandler;

  /// InMobi banner ad object.
  IMBanner *_adView;
}

- (void)loadBannerAdForAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
                     completionHandler:
                         (nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
  _bannerAdConfig = adConfiguration;
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;

  __block GADMediationBannerLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _bannerAdLoadCompletionHandler = ^id<GADMediationBannerAdEventDelegate>(
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

  GADMAdapterInMobiBannerAd *__weak weakSelf = self;
  NSString *accountId = _bannerAdConfig.credentials.settings[GADMAdapterInMobiAccountID];
  [GADMAdapterInMobiInitializer.sharedInstance
      initializeWithAccountID:accountId
            completionHandler:^(NSError *_Nullable error) {
              GADMAdapterInMobiBannerAd *strongSelf = weakSelf;
              if (!strongSelf) {
                return;
              }

              if (error) {
                GADMAdapterInMobiLog(@"Initialization failed: %@", error.localizedDescription);
                strongSelf->_bannerAdLoadCompletionHandler(nil, error);
                return;
              }
              [strongSelf requestBannerWithSize:strongSelf->_bannerAdConfig.adSize];
            }];
}

- (void)requestBannerWithSize:(GADAdSize)requestedAdSize {
  long long placementId =
      [_bannerAdConfig.credentials.settings[GADMAdapterInMobiPlacementID] longLongValue];

  if (placementId == 0) {
    NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
        GADMAdapterInMobiErrorInvalidServerParameters,
        @"GADMediationAdapterInMobi - Error : Placement ID not specified.");
    _bannerAdLoadCompletionHandler(nil, error);
    return;
  }

  if (_bannerAdConfig.isTestRequest) {
    GADMAdapterInMobiLog(
        @"Please enter your device ID in the InMobi console to recieve test ads from "
        @"Inmobi");
  }

  CGSize size = GADMAdapterInMobiSupportedAdSizeFromGADAdSize(requestedAdSize);
  if (CGSizeEqualToSize(size, CGSizeZero)) {
    NSString *errorMessage =
        [NSString stringWithFormat:@"The requested banner size: %@ is not supported by InMobi SDK.",
                                   NSStringFromGADAdSize(requestedAdSize)];
    NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
        GADMAdapterInMobiErrorBannerSizeMismatch, errorMessage);
    _bannerAdLoadCompletionHandler(nil, error);
    return;
  }

  _adView = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)
                                placementId:placementId];

  // Let Mediation do the refresh.
  [_adView shouldAutoRefresh:NO];
  _adView.transitionAnimation = UIViewAnimationTransitionNone;

  GADInMobiExtras *extras = _bannerAdConfig.extras;
  if (extras && extras.keywords) {
    [_adView setKeywords:extras.keywords];
  }

  GADMAdapterInMobiSetTargetingFromAdConfiguration(_bannerAdConfig);
  NSDictionary<NSString *, id> *requestParameters =
      GADMAdapterInMobiCreateRequestParametersFromAdConfiguration(_bannerAdConfig);
  [_adView setExtras:requestParameters];

  _adView.delegate = self;
  [_adView load];
}

- (void)stopBeingDelegate {
  _adView.delegate = nil;
}

#pragma mark IMBannerDelegate methods

- (void)bannerDidFinishLoading:(nonnull IMBanner *)banner {
  GADMAdapterInMobiLog(@"InMobi SDK loaded a banner ad successfully.");
  _bannerAdEventDelegate = _bannerAdLoadCompletionHandler(self, nil);
}

- (void)banner:(nonnull IMBanner *)banner didFailToLoadWithError:(nonnull IMRequestStatus *)error {
  GADMAdapterInMobiLog(@"InMobi SDK failed to load banner ad.");
  _bannerAdLoadCompletionHandler(nil, error);
}

- (void)banner:(nonnull IMBanner *)banner
    didInteractWithParams:(nullable NSDictionary<NSString *, id> *)params {
  GADMAdapterInMobiLog(@"InMobi SDK recorded a click on a banner ad.");
  [_bannerAdEventDelegate reportClick];
}

- (void)userWillLeaveApplicationFromBanner:(nonnull IMBanner *)banner {
  GADMAdapterInMobiLog(
      @"InMobi SDK will cause the user to leave the application from a banner ad.");
}

- (void)bannerWillPresentScreen:(nonnull IMBanner *)banner {
  GADMAdapterInMobiLog(@"InMobi SDK will present a full screen modal view from a banner ad.");
  [_bannerAdEventDelegate willPresentFullScreenView];
}

- (void)bannerDidPresentScreen:(nonnull IMBanner *)banner {
  GADMAdapterInMobiLog(@"InMobi SDK did present a full screen modal view from a banner ad.");
}

- (void)bannerWillDismissScreen:(nonnull IMBanner *)banner {
  GADMAdapterInMobiLog(@"InMobi SDK will dismiss a full screen modal view from a banner ad.");
  [_bannerAdEventDelegate willDismissFullScreenView];
}

- (void)bannerDidDismissScreen:(nonnull IMBanner *)banner {
  GADMAdapterInMobiLog(@"InMobi SDK did dismiss a full screen modal view from a banner ad.");
  [_bannerAdEventDelegate didDismissFullScreenView];
}

- (void)banner:(nonnull IMBanner *)banner
    rewardActionCompletedWithRewards:(nonnull NSDictionary<NSString *, id> *)rewards {
  GADMAdapterInMobiLog(@"InMobi banner reward action completed with rewards: %@",
                       rewards.description);
}

- (void)bannerAdImpressed:(nonnull IMBanner *)banner {
  GADMAdapterInMobiLog(@"InMobi SDK recorded an impression from a banner ad.");
  [_bannerAdEventDelegate reportImpression];
}

- (nonnull UIView *)view {
  return _adView;
}

@end
