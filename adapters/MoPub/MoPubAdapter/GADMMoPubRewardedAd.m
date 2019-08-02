
#import "GADMMoPubRewardedAd.h"
#import "GADMAdapterMoPubSingleton.h"
#import "MPRewardedVideo.h"
#import "MoPub.h"
#import "MoPubAdapterConstants.h"

@interface GADMMoPubRewardedAd () <MPRewardedVideoDelegate>

@property(nonatomic, weak) GADMediationRewardedAdConfiguration *adConfig;
@property(nonatomic, copy) GADMediationRewardedLoadCompletionHandler completionHandler;
@property(nonatomic, weak) id<GADMediationRewardedAdEventDelegate> adEventDelegate;
@property(nonatomic, copy) NSString *adUnitID;
@property(nonatomic, assign) BOOL adExpired;

@end

@implementation GADMMoPubRewardedAd

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  self.adConfig = adConfiguration;
  self.completionHandler = completionHandler;

  _adUnitID = [[adConfiguration.credentials settings] objectForKey:kGADMAdapterMoPubPubIdKey];
  if ([_adUnitID length] == 0) {
    NSString *description = @"Failed to request a MoPub rewarded ad. Ad unit ID is empty.";
    NSDictionary *userInfo =
        @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};

    NSError *error = [NSError errorWithDomain:kGADMAdapterMoPubErrorDomain
                                         code:0
                                     userInfo:userInfo];
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
    self.completionHandler(nil, error);
  }
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  // MoPub ads have a 4-hour expiration time window
  if ([MPRewardedVideo hasAdAvailableForAdUnitID:self.adUnitID]) {
    NSArray *rewards = [MPRewardedVideo availableRewardsForAdUnitID:self.adUnitID];
    MPRewardedVideoReward *reward = rewards[0];

    [MPRewardedVideo presentRewardedVideoAdForAdUnitID:self.adUnitID
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

    NSDictionary *userInfo =
        @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};

    NSError *error = [NSError errorWithDomain:kGADMAdapterMoPubErrorDomain
                                         code:0
                                     userInfo:userInfo];
    [self.adEventDelegate didFailToPresentWithError:error];
  }
}

#pragma mark GADMAdapterMoPubRewardedAdDelegate methods

- (void)rewardedVideoAdDidLoadForAdUnitID:(NSString *)adUnitID {
  self.adEventDelegate = self.completionHandler(self, nil);
}

- (void)rewardedVideoAdDidFailToLoadForAdUnitID:(NSString *)adUnitID error:(NSError *)error {
  self.completionHandler(nil, error);
}

- (void)rewardedVideoAdWillAppearForAdUnitID:(NSString *)adUnitID {
  id<GADMediationRewardedAdEventDelegate> strongAdEventDelegate = self.adEventDelegate;
  [strongAdEventDelegate willPresentFullScreenView];
}

- (void)rewardedVideoAdDidAppearForAdUnitID:(NSString *)adUnitID {
  id<GADMediationRewardedAdEventDelegate> strongAdEventDelegate = self.adEventDelegate;
  [strongAdEventDelegate reportImpression];
  [strongAdEventDelegate didStartVideo];
}

- (void)rewardedVideoAdWillDisappearForAdUnitID:(NSString *)adUnitID {
  [self.adEventDelegate willDismissFullScreenView];
}

- (void)rewardedVideoAdDidDisappearForAdUnitID:(NSString *)adUnitID {
  [self.adEventDelegate didDismissFullScreenView];
}

- (void)rewardedVideoAdDidExpireForAdUnitID:(NSString *)adUnitID {
  MPLogDebug(@"MoPub rewarded ad has been expired. Please make a new ad request.");
  _adExpired = true;
}

- (void)rewardedVideoAdDidReceiveTapEventForAdUnitID:(NSString *)adUnitID {
  [self.adEventDelegate reportClick];
}

- (void)rewardedVideoWillLeaveApplicationForAdUnitID:(NSString *)adUnitID {
  // No equivalent API to call in GoogleMobileAds SDK.
}

- (void)rewardedVideoAdShouldRewardForAdUnitID:(NSString *)adUnitID
                                        reward:(MPRewardedVideoReward *)reward {
  id<GADMediationRewardedAdEventDelegate> strongAdEventDelegate = self.adEventDelegate;
  NSDecimalNumber *rewardAmount =
      [NSDecimalNumber decimalNumberWithDecimal:[reward.amount decimalValue]];
  NSString *rewardType = reward.currencyType;

  GADAdReward *rewardItem = [[GADAdReward alloc] initWithRewardType:rewardType
                                                       rewardAmount:rewardAmount];
  [strongAdEventDelegate didEndVideo];
  [strongAdEventDelegate didRewardUserWithReward:rewardItem];
}

@end
