//
//  GADRTBMaioInterstitialAd.m
//  Adapter
//
//  Created by i-mobile on 2020/11/18.
//  Copyright © 2020 Google. All rights reserved.
//

#import "GADRTBMaioInterstitialAd.h"
#import "GADMMaioConstants.h"
#import <stdatomic.h>

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
  GADMediationInterstitialAdConfiguration *_adConfiguration;
}

- (nonnull instancetype)initWithAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)loadInterstitialForAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                       completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler {
  _adConfiguration = adConfiguration;

  [self loadInterstitialWithCompletionHandler:completionHandler];
}

- (void)loadInterstitialWithCompletionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler {
  // Safe handling of completionHandler from CONTRIBUTING.md#best-practices
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationInterstitialLoadCompletionHandler originalCompletionHandler = [completionHandler copy];
  _completionHandler = ^id<GADMediationInterstitialAdEventDelegate>(_Nullable id<GADMediationInterstitialAd> ad, NSError *_Nullable error){
    // Only allow completion handler to be called once.
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }

    id<GADMediationInterstitialAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      // Call original handler and hold on to its return value.
      delegate = originalCompletionHandler(ad, error);
    }
    // Release reference to handler. Objects retained by the handler will also be released.
    originalCompletionHandler = nil;

    return delegate;
  };

  MaioRequest *request = [[MaioRequest alloc] initWithZoneId:kGADRTBMaioAdapterZoneId testMode:_adConfiguration.isTestRequest bidData:_adConfiguration.bidResponse];
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
    // Fail to load.
    _completionHandler(nil, error);
  } else if (20000 <= errorCode && errorCode < 30000) {
    // Fail to Show
    [_adEventDelegate didFailToPresentWithError:error];
  } else {
    // Unknown error code
  }
}

- (void)didOpen:(MaioInterstitial *)ad {
  [_adEventDelegate willPresentFullScreenView];
  [_adEventDelegate reportImpression];
}

- (void)didClose:(MaioInterstitial *)ad {
  [_adEventDelegate willDismissFullScreenView];
  [_adEventDelegate didDismissFullScreenView];
}

@end
