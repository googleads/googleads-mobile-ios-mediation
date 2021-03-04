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

@end

@implementation GADRTBMaioInterstitialAd {
  GADMediationInterstitialLoadCompletionHandler _completionHandler;
  __weak id<GADMediationInterstitialAdEventDelegate> _adEventDelegate;
  MaioInterstitial *_interstitial;
}

- (void)loadInterstitialForAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                       completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler {
  _completionHandler = completionHandler;

  MaioRequest *request = [[MaioRequest alloc] initWithZoneId:kGADRTBMaioAdapterZoneId testMode:adConfiguration.isTestRequest bidData:adConfiguration.bidResponse];
  _interstitial = [MaioInterstitial loadAdWithRequest:request callback:self];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [_interstitial showWithViewContext:viewController callback:self];
}

#pragma mark - MaioInterstitialLoadCallback, MaioInterstitialShowCallback

- (void)didLoad:(MaioInterstitial *)ad {
  _adEventDelegate = _completionHandler(self, nil);
}

- (void)didFail:(MaioInterstitial *)ad errorCode:(NSInteger)errorCode {
  NSString *description = @"maio open-bidding SDK returned error";
  NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:kGADMMaioSDKErrorDomain code:errorCode userInfo:userInfo];

  if (10000 <= errorCode && errorCode < 20000) {
    _completionHandler(nil, error);
    return;
  }
  if (20000 <= errorCode && errorCode < 30000) {
    [_adEventDelegate didFailToPresentWithError:error];
    return;
  }
}

- (void)didOpen:(MaioInterstitial *)ad {
  id<GADMediationInterstitialAdEventDelegate> delegate = _adEventDelegate;
  [delegate willPresentFullScreenView];
  [delegate reportImpression];
}

- (void)didClose:(MaioInterstitial *)ad {
  id<GADMediationInterstitialAdEventDelegate> delegate = _adEventDelegate;
  [delegate willDismissFullScreenView];
  [delegate didDismissFullScreenView];
}

@end
