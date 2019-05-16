//
//  Copyright © 2018 Google. All rights reserved.
//

#import "GADMAdapterAdColonyRewardedAd.h"
#import <AdColony/AdColony.h>
#import "GADMAdapterAdColonyConstants.h"
#import "GADMAdapterAdColonyHelper.h"
#import "GADMAdapterAdColonyInitializer.h"

@interface GADMAdapterAdColonyRewardedAd ()

@property(nonatomic, copy) GADMediationRewardedLoadCompletionHandler loadCompletionHandler;

@property(nonatomic, strong) AdColonyInterstitial *rewardedAd;

@property(nonatomic, weak) id<GADMediationRewardedAdEventDelegate> adEventDelegate;

@property(nonatomic) NSString *zoneID;

@end

@implementation GADMAdapterAdColonyRewardedAd

/// Render a rewarded ad with the provided ad configuration.
- (void)renderRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationRewardedLoadCompletionHandler)completionHandler {
  self.loadCompletionHandler = completionHandler;
  GADMAdapterAdColonyRewardedAd *__weak weakSelf = self;
  [GADMAdapterAdColonyHelper setupZoneFromAdConfig:adConfiguration
                                          callback:^(NSString *zone, NSError *error) {
                                            __strong typeof(weakSelf) strongSelf = weakSelf;
                                            if (error && strongSelf) {
                                              strongSelf.loadCompletionHandler(nil, error);
                                              return;
                                            }

                                            [strongSelf getRewardedAdFromZoneId:zone
                                                                   withAdConfig:adConfiguration];
                                          }];
}

- (void)getRewardedAdFromZoneId:(NSString *)zone
                   withAdConfig:(GADMediationRewardedAdConfiguration *)adConfiguration {
  self.rewardedAd = nil;
  self.zoneID = zone;

  GADMAdapterAdColonyRewardedAd *__weak weakSelf = self;

  NSLogDebug(@"getInterstitialFromZoneId: %@", zone);

  AdColonyAdOptions *options = [GADMAdapterAdColonyHelper getAdOptionsFromAdConfig:adConfiguration];

  [AdColony requestInterstitialInZone:zone
      options:options
      success:^(AdColonyInterstitial *_Nonnull ad) {
        NSLogDebug(@"Retrieve ad: %@", zone);
        __strong typeof(weakSelf) strongSelf = weakSelf;
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
          @"another Ad. To avoid this situation use startWithCompletionHandler: to initialize "
          @"Google Mobile Ads SDK and wait for the completion handler to be called before "
          @"requesting an Ad.",
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
    NSLog(@"AdColonyAdapter [Info] : %@, %@.", errorMessage, self.zoneID);
    NSError *error = [NSError errorWithDomain:kGADMAdapterAdColonyErrorDomain
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
    [self.adEventDelegate didFailToPresentWithError:error];
  }
}

@end
