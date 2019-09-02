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
#import "GADMAdapterAdColonyConstants.h"
#import "GADMAdapterAdColonyExtras.h"
#import "GADMAdapterAdColonyHelper.h"
#import "GADMediationAdapterAdColony.h"

@interface GADMAdapterAdColonyRewardedRenderer () <GADMediationRewardedAd>

@property(nonatomic, copy) GADMediationRewardedLoadCompletionHandler loadCompletionHandler;

@property(nonatomic, strong) AdColonyInterstitial *rewardedAd;

@property(nonatomic, weak) id<GADMediationRewardedAdEventDelegate> adEventDelegate;

@end

@implementation GADMAdapterAdColonyRewardedRenderer

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfig
                       completionHandler:(GADMediationRewardedLoadCompletionHandler)handler {
  self.loadCompletionHandler = handler;
  GADMAdapterAdColonyRewardedRenderer *__weak weakSelf = self;
  [GADMAdapterAdColonyHelper setupZoneFromAdConfig:adConfig
                                          callback:^(NSString *zone, NSError *error) {
                                            __strong typeof(weakSelf) strongSelf = weakSelf;
                                            if (error && strongSelf) {
                                              strongSelf.loadCompletionHandler(nil, error);
                                              return;
                                            }
                                            [strongSelf getRewardedAdFromZoneId:zone
                                                                   withAdConfig:adConfig];
                                          }];
}

- (void)getRewardedAdFromZoneId:(NSString *)zone
                   withAdConfig:(GADMediationRewardedAdConfiguration *)adConfiguration {
  self.rewardedAd = nil;

  GADMAdapterAdColonyRewardedRenderer *__weak weakSelf = self;

  NSLogDebug(@"getInterstitialFromZoneId: %@", zone);

  AdColonyAdOptions *options = [GADMAdapterAdColonyHelper getAdOptionsFromAdConfig:adConfiguration];

  [AdColony requestInterstitialInZone:zone
      options:options
      success:^(AdColonyInterstitial *_Nonnull ad) {
        NSLogDebug(@"Retrieve ad: %@", zone);
        GADMAdapterAdColonyRewardedRenderer *strongSelf = weakSelf;
        if (strongSelf) {
          [strongSelf handleAdReceived:ad forAdConfig:adConfiguration zone:zone];
        }
      }
      failure:^(AdColonyAdRequestError *_Nonnull err) {
        NSError *error =
            [NSError errorWithDomain:kGADMAdapterAdColonyErrorDomain
                                code:kGADErrorInvalidRequest
                            userInfo:@{NSLocalizedDescriptionKey : err.localizedDescription}];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
          strongSelf.loadCompletionHandler(nil, error);
        }
        NSLog(@"AdColonyAdapter [Info] : Failed to retrieve ad: %@", error.localizedDescription);
      }];
}
- (void)handleAdReceived:(AdColonyInterstitial *_Nonnull)ad
             forAdConfig:(GADMediationRewardedAdConfiguration *)adConfiguration
                    zone:(NSString *)zone {
  AdColonyZone *adZone = [AdColony zoneForID:ad.zoneID];
  if (adZone.rewarded) {
    self.rewardedAd = ad;
    self.adEventDelegate = self.loadCompletionHandler(self, nil);
  } else {
    NSString *errorMessage =
        @"Zone used for rewarded video is not a rewarded video zone on AdColony portal.";
    NSLog(@"AdColonyAdapter [**Error**] : %@", errorMessage);
    NSError *error = [NSError errorWithDomain:kGADMAdapterAdColonyErrorDomain
                                         code:kGADErrorInvalidRequest
                                     userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
    self.loadCompletionHandler(nil, error);
  }
  // Re-request intersitial when expires, this avoids the situation:
  // 1. Admob interstitial request from zone A. Causes ADC configure to occur with zone A,
  // then ADC ad request from zone A. Both succeed.
  // 2. Admob rewarded video request from zone B. Causes ADC configure to occur with zones A,
  // B, then ADC ad request from zone B. Both succeed.
  // 3. Try to present ad loaded from zone A. It doesn’t show because of error: `No session
  // with id: xyz has been registered. Cannot show interstitial`.
  [ad setExpire:^{
    NSLog(@"AdColonyAdapter [Info]: Rewarded Ad expired from zone: %@ because of configuring "
          @"another Ad. To avoid this situation, use startWithCompletionHandler: to initialize "
          @"Google Mobile Ads SDK and wait for the completion handler to be called before "
          @"requesting an ad.",
          zone);
  }];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  __weak typeof(self) weakSelf = self;

  [self.rewardedAd setOpen:^{
    id<GADMediationRewardedAdEventDelegate> adEventDelegate = weakSelf.adEventDelegate;
    [adEventDelegate willPresentFullScreenView];
    [adEventDelegate reportImpression];
    [adEventDelegate didStartVideo];
  }];

  [self.rewardedAd setClick:^{
    [weakSelf.adEventDelegate reportClick];
  }];

  [self.rewardedAd setClose:^{
    id<GADMediationRewardedAdEventDelegate> adEventDelegate = weakSelf.adEventDelegate;
    [adEventDelegate didEndVideo];
    [adEventDelegate willDismissFullScreenView];
    [adEventDelegate didDismissFullScreenView];
  }];

  AdColonyZone *zone = [AdColony zoneForID:self.rewardedAd.zoneID];
  [zone setReward:^(BOOL success, NSString *_Nonnull name, int amount) {
    if (success) {
      GADAdReward *reward = [[GADAdReward alloc]
          initWithRewardType:name
                rewardAmount:(NSDecimalNumber *)[NSDecimalNumber numberWithInt:amount]];
      [weakSelf.adEventDelegate didRewardUserWithReward:reward];
    }
  }];

  if (![self.rewardedAd showWithPresentingViewController:viewController]) {
    NSString *errorMessage = @"Failed to show ad for zone";
    NSLog(@"AdColonyAdapter [Info] : %@, %@.", errorMessage, self.rewardedAd.zoneID);
    NSError *error = [NSError errorWithDomain:kGADMAdapterAdColonyErrorDomain
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
    [self.adEventDelegate didFailToPresentWithError:error];
  }
}

@end
