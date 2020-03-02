#import "GADMMoPubRewardedAd.h"

#include <stdatomic.h>

#import "GADMAdapterMoPubConstants.h"
#import "GADMAdapterMoPubSingleton.h"
#import "GADMAdapterMoPubUtils.h"
#import "MPRewardedVideo.h"
#import "MoPub.h"

@interface GADMMoPubRewardedAd () <MPRewardedVideoDelegate>
@end

@implementation GADMMoPubRewardedAd {
  // An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _completionHandler;

  /// Ad Configuration for the ad to be rendered.
  GADMediationRewardedAdConfiguration *_adConfig;

  /// MoPub's ad unit ID.
  NSString *_adUnitID;

  /// Indicates whether the MoPub rewarded ad has expired or not.
  BOOL _adExpired;
}

- (void)loadRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  _adConfig = adConfiguration;
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _completionHandler = ^id<GADMediationRewardedAdEventDelegate>(
      id<GADMediationRewardedAd> rewardedAd, NSError *error) {
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

  _adUnitID = adConfiguration.credentials.settings[kGADMAdapterMoPubPubIdKey];
  if ([_adUnitID length] == 0) {
    NSString *description = @"Failed to request a MoPub rewarded ad. Ad unit ID is empty.";
    NSError *error =
        GADMAdapterMoPubErrorWithCodeAndDescription(kGADErrorMediationAdapterError, description);
    completionHandler(nil, error);
    return;
  }

  [[GADMAdapterMoPubSingleton sharedInstance] initializeMoPubSDKWithAdUnitID:_adUnitID
                                                           completionHandler:^{
                                                             [self requestRewarded];
                                                           }];
}

- (void)requestRewarded {
  MPLogDebug(@"Requesting Rewarded Ad from MoPub Ad Network.");
  NSError *error =
      [[GADMAdapterMoPubSingleton sharedInstance] requestRewardedAdForAdUnitID:_adUnitID
                                                                      adConfig:_adConfig
                                                                      delegate:self];
  if (error) {
    _completionHandler(nil, error);
  }
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  // MoPub ads have a 4-hour expiration time window
  if ([MPRewardedVideo hasAdAvailableForAdUnitID:_adUnitID]) {
    NSArray *rewards = [MPRewardedVideo availableRewardsForAdUnitID:_adUnitID];
    MPRewardedVideoReward *reward = rewards[0];

    [MPRewardedVideo presentRewardedVideoAdForAdUnitID:_adUnitID
                                    fromViewController:viewController
                                            withReward:reward];
  } else {
    NSString *description;
    if (_adExpired) {
      description = @"Failed to show a MoPub rewarded ad. Ad has expired after 4 hours. "
                    @"Please make a new ad request.";
    } else {
      description = @"Failed to show a MoPub rewarded ad. No ad available.";
    }

    NSError *error =
        GADMAdapterMoPubErrorWithCodeAndDescription(kGADErrorMediationAdapterError, description);
    [_adEventDelegate didFailToPresentWithError:error];
  }
}

#pragma mark GADMAdapterMoPubRewardedAdDelegate methods

- (void)rewardedVideoAdDidLoadForAdUnitID:(NSString *)adUnitID {
  _adEventDelegate = _completionHandler(self, nil);
}

- (void)rewardedVideoAdDidFailToLoadForAdUnitID:(NSString *)adUnitID error:(NSError *)error {
  _completionHandler(nil, error);
}

- (void)rewardedVideoAdWillAppearForAdUnitID:(NSString *)adUnitID {
  [_adEventDelegate willPresentFullScreenView];
}

- (void)rewardedVideoAdDidAppearForAdUnitID:(NSString *)adUnitID {
  id<GADMediationRewardedAdEventDelegate> strongAdEventDelegate = _adEventDelegate;
  [strongAdEventDelegate reportImpression];
  [strongAdEventDelegate didStartVideo];
}

- (void)rewardedVideoAdWillDisappearForAdUnitID:(NSString *)adUnitID {
  [_adEventDelegate willDismissFullScreenView];
}

- (void)rewardedVideoAdDidDisappearForAdUnitID:(NSString *)adUnitID {
  [_adEventDelegate didDismissFullScreenView];
}

- (void)rewardedVideoAdDidExpireForAdUnitID:(NSString *)adUnitID {
  MPLogDebug(@"MoPub rewarded ad has been expired. Please make a new ad request.");
  _adExpired = true;
}

- (void)rewardedVideoAdDidReceiveTapEventForAdUnitID:(NSString *)adUnitID {
  [_adEventDelegate reportClick];
}

- (void)rewardedVideoWillLeaveApplicationForAdUnitID:(NSString *)adUnitID {
  // No equivalent API to call in GoogleMobileAds SDK.
}

- (void)rewardedVideoAdShouldRewardForAdUnitID:(NSString *)adUnitID
                                        reward:(MPRewardedVideoReward *)reward {
  id<GADMediationRewardedAdEventDelegate> strongAdEventDelegate = _adEventDelegate;
  NSDecimalNumber *rewardAmount =
      [NSDecimalNumber decimalNumberWithDecimal:[reward.amount decimalValue]];
  NSString *rewardType = reward.currencyType;

  GADAdReward *rewardItem = [[GADAdReward alloc] initWithRewardType:rewardType
                                                       rewardAmount:rewardAmount];
  [strongAdEventDelegate didEndVideo];
  [strongAdEventDelegate didRewardUserWithReward:rewardItem];
}

@end
