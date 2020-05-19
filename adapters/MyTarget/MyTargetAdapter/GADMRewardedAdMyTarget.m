// Copyright 2019 Google Inc.
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

#import "GADMRewardedAdMyTarget.h"
#import <MyTargetSDK/MyTargetSDK.h>
#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtras.h"
#import "GADMAdapterMyTargetUtils.h"

@interface GADMRewardedAdMyTarget () <MTRGInterstitialAdDelegate>

@property(nonatomic, copy) GADMediationRewardedLoadCompletionHandler completionHandler;
@property(nonatomic, weak) id<GADMediationRewardedAdEventDelegate> adEventDelegate;
@property(nonatomic, strong) MTRGInterstitialAd *rewardedAd;

@end

@implementation GADMRewardedAdMyTarget

BOOL _isRewardedAdLoaded;

- (void)loadRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  MTRGLogInfo();
  self.completionHandler = completionHandler;

  id<GADAdNetworkExtras> networkExtras = adConfiguration.extras;
  if (networkExtras && [networkExtras isKindOfClass:[GADMAdapterMyTargetExtras class]]) {
    GADMAdapterMyTargetExtras *extras = (GADMAdapterMyTargetExtras *)networkExtras;
    [GADMAdapterMyTargetUtils setLogEnabled:extras.isDebugMode];
  }

  NSDictionary *credentials = adConfiguration.credentials.settings;

  MTRGLogDebug(@"Credentials: %@", credentials);

  NSUInteger slotId = [GADMAdapterMyTargetUtils slotIdFromCredentials:credentials];

  if (slotId <= 0) {
    MTRGLogError(kGADMAdapterMyTargetErrorSlotId);
    NSError *error =
        [GADMAdapterMyTargetUtils errorWithDescription:kGADMAdapterMyTargetErrorSlotId];
    completionHandler(nil, error);
    return;
  }

  _isRewardedAdLoaded = NO;
  self.rewardedAd = [[MTRGInterstitialAd alloc] initWithSlotId:slotId];
  self.rewardedAd.delegate = self;
  // INFO: This is where you can pass customParams if you want to send any.
  [self.rewardedAd load];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  MTRGLogInfo();

  if (!_isRewardedAdLoaded || !self.rewardedAd) {
    NSError *error = [GADMAdapterMyTargetUtils errorWithDescription:kGADMAdapterMyTargetErrorNoAd];
    id<GADMediationRewardedAdEventDelegate> strongDelegate = self.adEventDelegate;
    if (strongDelegate) {
      [strongDelegate didFailToPresentWithError:error];
    }
    return;
  }
  [self.rewardedAd showWithController:viewController];
}

#pragma mark - MTRGInterstitialAdDelegate

- (void)onLoadWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  MTRGLogInfo();
  _isRewardedAdLoaded = YES;
  self.adEventDelegate = self.completionHandler(self, nil);
}

- (void)onNoAdWithReason:(nonnull NSString *)reason
          interstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  MTRGLogInfo();
  NSString *description = [GADMAdapterMyTargetUtils noAdWithReason:reason];
  MTRGLogError(description);
  NSError *error = [GADMAdapterMyTargetUtils errorWithDescription:description];
  self.completionHandler(nil, error);
}

- (void)onClickWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = self.adEventDelegate;
  MTRGLogInfo();
  if (!strongDelegate) {
    return;
  }

  [strongDelegate reportClick];
}

- (void)onCloseWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = self.adEventDelegate;
  MTRGLogInfo();
  if (!strongDelegate) {
    return;
  }

  [strongDelegate didDismissFullScreenView];
}

- (void)onVideoCompleteWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = self.adEventDelegate;
  MTRGLogInfo();
  if (!strongDelegate) {
    return;
  }

  [strongDelegate didEndVideo];
  NSString *rewardType = @"";                             // must not be nil
  NSDecimalNumber *rewardAmount = [NSDecimalNumber one];  // must not be nil
  GADAdReward *adReward = [[GADAdReward alloc] initWithRewardType:rewardType
                                                     rewardAmount:rewardAmount];
  [strongDelegate didRewardUserWithReward:adReward];
}

- (void)onDisplayWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = self.adEventDelegate;
  MTRGLogInfo();
  if (!strongDelegate) {
    return;
  }

  [strongDelegate willPresentFullScreenView];
  [strongDelegate didStartVideo];
}

- (void)onLeaveApplicationWithInterstitialAd:(nonnull MTRGInterstitialAd *)interstitialAd {
  // Do nothing. The Google Mobile Ads SDK does not have an equivalent callback.
}

@end
