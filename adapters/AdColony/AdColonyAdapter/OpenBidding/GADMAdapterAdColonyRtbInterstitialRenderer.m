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

#import "GADMAdapterAdColonyRtbInterstitialRenderer.h"

#import <AdColony/AdColony.h>
#import "GADMAdapterAdColonyConstants.h"
#import "GADMAdapterAdColonyExtras.h"
#import "GADMAdapterAdColonyHelper.h"
#import "GADMediationAdapterAdColony.h"

@interface GADMAdapterAdColonyRtbInterstitialRenderer () <GADMediationInterstitialAd>

@property(nonatomic, copy) GADMediationInterstitialLoadCompletionHandler renderCompletionHandler;

@property(nonatomic, strong) AdColonyInterstitial *interstitialAd;

@property(nonatomic, strong) id<GADMediationInterstitialAdEventDelegate> adEventDelegate;

@end

@implementation GADMAdapterAdColonyRtbInterstitialRenderer

/// Asks the receiver to render the ad configuration.
- (void)renderInterstitialForAdConfig:(nonnull GADMediationInterstitialAdConfiguration *)adConfig
                    completionHandler:
                        (nonnull GADMediationInterstitialLoadCompletionHandler)handler {
  self.renderCompletionHandler = handler;

  // Take out zone Id for which request received
  NSString *zone = adConfig.credentials.settings[kGADMAdapterAdColonyZoneIDOpenBiddingKey];
  [self getInterstitialFromZoneId:zone withAdConfig:adConfig];
}

- (void)getInterstitialFromZoneId:(NSString *)zone
                     withAdConfig:(GADMediationInterstitialAdConfiguration *)adConfiguration {
  self.interstitialAd = nil;

  __weak typeof(self) weakSelf = self;

  NSLogDebug(@"getInterstitialFromZoneId: %@", zone);

  [AdColony requestInterstitialInZone:zone
      options:nil
      success:^(AdColonyInterstitial *_Nonnull ad) {
        NSLogDebug(@"Retrieve ad: %@", zone);
        [weakSelf handleAdReceived:ad forAdConfig:adConfiguration zone:zone];
      }
      failure:^(AdColonyAdRequestError *_Nonnull err) {
        NSError *error =
            [NSError errorWithDomain:kGADMAdapterAdColonyErrorDomain
                                code:kGADErrorInvalidRequest
                            userInfo:@{NSLocalizedDescriptionKey : err.localizedDescription}];
        weakSelf.renderCompletionHandler(nil, error);
        NSLog(@"AdColonyAdapter [Info] : Failed to retrieve ad: %@", error.localizedDescription);
      }];
}

- (void)handleAdReceived:(AdColonyInterstitial *_Nonnull)ad
             forAdConfig:(GADMediationInterstitialAdConfiguration *)adConfiguration
                    zone:(NSString *)zone {
  self.interstitialAd = ad;
  self.adEventDelegate = self.renderCompletionHandler(self, nil);

  // Re-request intersitial when expires, this avoids the situation:
  // 1. Admob interstitial request from zone A. Causes ADC configure to occur with zone A,
  // then ADC ad request from zone A. Both succeed.
  // 2. Admob rewarded video request from zone B. Causes ADC configure to occur with zones A,
  // B, then ADC ad request from zone B. Both succeed.
  // 3. Try to present ad loaded from zone A. It doesn’t show because of error: `No session
  // with id: xyz has been registered. Cannot show interstitial`.
  [ad setExpire:^{
    NSLog(@"AdColonyAdapter [Info]: Interstitial Ad expired from zone: %@ because of configuring "
          @"another Ad. To avoid this situation, use startWithCompletionHandler: to initialize "
          @"Google Mobile Ads SDK and wait for the completion handler to be called before "
          @"requesting an dd.",
          zone);
  }];
}

#pragma mark GADMediationInterstitialAd

- (void)presentFromViewController:(UIViewController *)viewController {
  GADMAdapterAdColonyRtbInterstitialRenderer *__weak weakSelf = self;

  [self.interstitialAd setOpen:^{
    id<GADMediationInterstitialAdEventDelegate> adEventDelegate = weakSelf.adEventDelegate;
    [adEventDelegate willPresentFullScreenView];
    [adEventDelegate reportImpression];
  }];

  [self.interstitialAd setClick:^{
    [weakSelf.adEventDelegate reportClick];
  }];

  [self.interstitialAd setClose:^{
    id<GADMediationInterstitialAdEventDelegate> adEventDelegate = weakSelf.adEventDelegate;
    [adEventDelegate willDismissFullScreenView];
    [adEventDelegate didDismissFullScreenView];
  }];

  [self.interstitialAd setLeftApplication:^{
    [weakSelf.adEventDelegate willBackgroundApplication];
  }];

  if (![self.interstitialAd showWithPresentingViewController:viewController]) {
    NSError *error =
        [NSError errorWithDomain:kGADMAdapterAdColonyErrorDomain
                            code:0
                        userInfo:@{NSLocalizedDescriptionKey : @"Failed to show ad for zone"}];
    [weakSelf.adEventDelegate didFailToPresentWithError:error];
  }
}

@end
