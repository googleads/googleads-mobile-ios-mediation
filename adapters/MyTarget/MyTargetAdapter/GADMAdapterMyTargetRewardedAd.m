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

#import "GADMAdapterMyTargetRewardedAd.h"

#import <MyTargetSDK/MyTargetSDK.h>

#import <stdatomic.h>

#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtras.h"
#import "GADMAdapterMyTargetUtils.h"

@interface GADMAdapterMyTargetRewardedAd () <MTRGRewardedAdDelegate>
@end

@implementation GADMAdapterMyTargetRewardedAd {
  /// Completion handler to forward ad load events to the Google Mobile Ads SDK.
  GADMediationRewardedLoadCompletionHandler _completionHandler;

  /// Rewarded ad configuration of the ad request.
  GADMediationRewardedAdConfiguration *_adConfiguration;

  /// Ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  /// Intentionally keeping a strong reference to the delegate because this is returned from the
  /// GMA SDK, not set on the GMA SDK.
  id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  /// myTarget rewarded ad object.
  MTRGRewardedAd *_rewardedAd;
}

BOOL _isRewardedAdLoaded;

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler =
        [completionHandler copy];

    _completionHandler = ^id<GADMediationRewardedAdEventDelegate>(
        _Nullable id<GADMediationRewardedAd> ad, NSError *_Nullable error) {
      if (atomic_flag_test_and_set(&completionHandlerCalled)) {
        return nil;
      }

      id<GADMediationRewardedAdEventDelegate> delegate = nil;
      if (originalCompletionHandler) {
        delegate = originalCompletionHandler(ad, error);
      }

      originalCompletionHandler = nil;
      return delegate;
    };

    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)loadRewardedAd {
  MTRGLogInfo();
  id<GADAdNetworkExtras> networkExtras = _adConfiguration.extras;
  if (networkExtras && [networkExtras isKindOfClass:[GADMAdapterMyTargetExtras class]]) {
    GADMAdapterMyTargetExtras *extras = (GADMAdapterMyTargetExtras *)networkExtras;
    GADMAdapterMyTargetUtils.logEnabled = extras.isDebugMode;
  }

  NSDictionary<NSString *, id> *credentials = _adConfiguration.credentials.settings;
  MTRGLogDebug(@"Credentials: %@", credentials);

  NSUInteger slotId = GADMAdapterMyTargetSlotIdFromCredentials(credentials);
  if (slotId <= 0) {
    NSError *error = GADMAdapterMyTargetErrorWithCodeAndDescription(
        GADMAdapterMyTargetErrorInvalidServerParameters, @"Slot ID cannot be nil.");
    _completionHandler(nil, error);
    return;
  }

  _isRewardedAdLoaded = NO;
  _rewardedAd = [MTRGRewardedAd rewardedAdWithSlotId:slotId];
  _rewardedAd.delegate = self;
  GADMAdapterMyTargetFillCustomParams(_rewardedAd.customParams, _adConfiguration.extras);
  [_rewardedAd load];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  MTRGLogInfo();

  if (!_isRewardedAdLoaded || !_rewardedAd) {
    NSError *error = GADMAdapterMyTargetErrorWithCodeAndDescription(
        GADMAdapterMyTargetErrorAdNotLoaded, @"No Ad loaded.");
    [_adEventDelegate didFailToPresentWithError:error];
    return;
  }
  [_rewardedAd showWithController:viewController];
}

#pragma mark - MTRGRewardedAdDelegate

- (void)onLoadWithRewardedAd:(nonnull MTRGRewardedAd *)rewardedAd {
  MTRGLogInfo();
  _isRewardedAdLoaded = YES;
  _adEventDelegate = _completionHandler(self, nil);
}

- (void)onNoAdWithReason:(nonnull NSString *)reason
              rewardedAd:(nonnull MTRGRewardedAd *)rewardedAd {
  MTRGLogInfo();
  MTRGLogError(reason);
  NSError *error =
      GADMAdapterMyTargetErrorWithCodeAndDescription(GADMAdapterMyTargetErrorNoFill, reason);
  _completionHandler(nil, error);
}

- (void)onClickWithRewardedAd:(nonnull MTRGRewardedAd *)rewardedAd {
  MTRGLogInfo();
  [_adEventDelegate reportClick];
}

- (void)onCloseWithRewardedAd:(nonnull MTRGRewardedAd *)rewardedAd {
  MTRGLogInfo();
  [_adEventDelegate didDismissFullScreenView];
}

- (void)onReward:(nonnull MTRGReward *)reward rewardedAd:(nonnull MTRGRewardedAd *)rewardedAd {
  MTRGLogInfo();
  [_adEventDelegate didEndVideo];

  NSString *rewardType = @"";                           // Must not be nil.
  NSDecimalNumber *rewardAmount = NSDecimalNumber.one;  // Must not be nil.
  GADAdReward *adReward = [[GADAdReward alloc] initWithRewardType:rewardType
                                                     rewardAmount:rewardAmount];
  [_adEventDelegate didRewardUserWithReward:adReward];
}

- (void)onDisplayWithRewardedAd:(nonnull MTRGRewardedAd *)rewardedAd {
  MTRGLogInfo();
  [_adEventDelegate willPresentFullScreenView];
  [_adEventDelegate didStartVideo];
}

- (void)onLeaveApplicationWithRewardedAd:(nonnull MTRGRewardedAd *)rewardedAd {
  // Do nothing. The Google Mobile Ads SDK does not have an equivalent callback.
}

@end
