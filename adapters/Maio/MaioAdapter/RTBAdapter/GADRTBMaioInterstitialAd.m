//
//  GADRTBMaioInterstitialAd.m
//  Adapter
//
//  Created by i-mobile on 2020/11/18.
//  Copyright © 2020 Google. All rights reserved.
//

#import "GADRTBMaioInterstitialAd.h"
#import "GADMMaioConstants.h"

#import <MaioOB/MaioOB-Swift.h>

#define MaioInterstitial MaioRewarded
#define MaioInterstitialLoadCallback MaioRewardedLoadCallback
#define MaioInterstitialShowCallback MaioRewardedShowCallback

@interface GADRTBMaioInterstitialAd () <MaioInterstitialLoadCallback, MaioInterstitialShowCallback>

@property (nonatomic, copy) GADMediationInterstitialLoadCompletionHandler completionHandler;
@property (nonatomic, weak) id<GADMediationInterstitialAdEventDelegate> adEventDelegate;
@property (nonatomic, strong) MaioInterstitial *interstitial;

@end

@implementation GADRTBMaioInterstitialAd

- (void)loadInterstitialForAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                       completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler {
  self.completionHandler = completionHandler;

  MaioRequest *request = [[MaioRequest alloc] initWithZoneId:kGADRTBMaioAdapterZoneId testMode:adConfiguration.isTestRequest bidData:adConfiguration.bidResponse];
  self.interstitial = [MaioInterstitial loadAdWithRequest:request callback:self];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [self.interstitial showWithViewContext:viewController callback:self];
}

#pragma mark - MaioInterstitialLoadCallback, MaioInterstitialShowCallback

- (void)didLoad:(MaioInterstitial *)ad {
  self.adEventDelegate = self.completionHandler(self, nil);
}

- (void)didFail:(MaioInterstitial *)ad errorCode:(NSInteger)errorCode {
  NSString *description = @"maio open-bidding SDK returned error";
  NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:kGADMMaioSDKErrorDomain code:errorCode userInfo:userInfo];

  if (10000 <= errorCode && errorCode < 20000) {
    self.completionHandler(nil, error);
    return;
  }
  if (20000 <= errorCode && errorCode < 30000) {
    [self.adEventDelegate didFailToPresentWithError:error];
    return;
  }
}

- (void)didOpen:(MaioInterstitial *)ad {
  id<GADMediationInterstitialAdEventDelegate> delegate = self.adEventDelegate;
  [delegate willPresentFullScreenView];
  [delegate reportImpression];
}

- (void)didClose:(MaioInterstitial *)ad {
  id<GADMediationInterstitialAdEventDelegate> delegate = self.adEventDelegate;
  [delegate willDismissFullScreenView];
  [delegate didDismissFullScreenView];
}

@end
