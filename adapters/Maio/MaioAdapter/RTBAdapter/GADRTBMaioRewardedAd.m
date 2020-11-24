//
//  GADRTBMaioRewardedAd.m
//  Adapter
//
//  Created by i-mobile on 2020/11/18.
//  Copyright © 2020 Google. All rights reserved.
//

#import "GADRTBMaioRewardedAd.h"
#import "GADMMaioConstants.h"
#import "GADMMaioError.h"

#import <MaioOB/MaioOB-Swift.h>

@interface GADRTBMaioRewardedAd () <MaioRewardedLoadCallback, MaioRewardedShowCallback>

@property (nonatomic, copy) GADMediationRewardedLoadCompletionHandler completionHandler;
@property (nonatomic, weak) id<GADMediationRewardedAdEventDelegate> adEventDelegate;
@property (nonatomic, strong) MaioRewarded *rewarded;

@end

@implementation GADRTBMaioRewardedAd

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
  self.completionHandler = completionHandler;

  MaioRequest *request = [[MaioRequest alloc] initWithZoneId:kGADRTBMaioAdapterZoneId testMode:adConfiguration.isTestRequest bidData:adConfiguration.bidResponse];
  self.rewarded = [MaioRewarded loadAdWithRequest:request callback:self];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [self.rewarded showWithViewContext:viewController callback:self];
}

#pragma mark - MaioRewardedLoadCallback, MaioRewardedShowCallback

- (void)didLoad:(MaioRewarded *)ad {
  self.adEventDelegate = self.completionHandler(self, nil);
}

- (void)didFail:(MaioRewarded *)ad errorCode:(NSInteger)errorCode {
  NSString *description = [GADMMaioError stringFromErrorCode:errorCode];
  NSError *error = [GADMMaioError errorWithDescription:description errorCode:errorCode];

  BOOL failToLoad = [GADMMaioError codeIsAboutLoad:errorCode];
  if (failToLoad) {
    self.completionHandler(nil, error);
    return;
  }
  BOOL failToShow = [GADMMaioError codeIsAboutShow:errorCode];
  if (failToShow) {
    [self.adEventDelegate didFailToPresentWithError:error];
    return;
  }
}

- (void)didOpen:(MaioRewarded *)ad {
  id<GADMediationRewardedAdEventDelegate> delegate = self.adEventDelegate;
  [delegate willPresentFullScreenView];
  [delegate reportImpression];
  [delegate didStartVideo];
}

- (void)didClose:(MaioRewarded *)ad {
  id<GADMediationRewardedAdEventDelegate> delegate = self.adEventDelegate;
  [delegate didEndVideo];
  [delegate willDismissFullScreenView];
  [delegate didDismissFullScreenView];
}

- (void)didReward:(MaioRewarded *)ad reward:(RewardData *)reward {
  GADAdReward *gReward = [[GADAdReward alloc] initWithRewardType:reward.value rewardAmount:[NSDecimalNumber one]];

  id<GADMediationRewardedAdEventDelegate> delegate = self.adEventDelegate;
  [delegate didRewardUserWithReward:gReward];
}

@end
