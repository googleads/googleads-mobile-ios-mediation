// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterYahooRewardedAd.h"
#import <YahooAds/YahooAds.h>
#include <stdatomic.h>
#import "GADMAdapterYahooConstants.h"
#import "GADMAdapterYahooUtils.h"

NSString *const GADMAdapterVerizonVideoCompleteEventId = @"onVideoComplete";

@interface GADMAdapterYahooRewardedAd () <YASInterstitialAdDelegate>
@end

@implementation GADMAdapterYahooRewardedAd {
  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _adLoadCompletionHandler;

  /// Yahoo rewarded ad.
  YASInterstitialAd *_rewardedAd;

  /// Placement ID string used to request ads from Yahoo Mobile SDK.
  NSString *_placementID;

  /// An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  /// Ad Configuration for the ad to be rendered.
  GADMediationRewardedAdConfiguration *_adConfiguration;

  BOOL _isVideoCompletionEventCalled;
}

- (void)loadRewardedAdForAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfig
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)handler {
  // Store the ad config and completion handler for later use.
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler = [handler copy];
  _adLoadCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(
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
  _adConfiguration = adConfig;

  NSDictionary<NSString *, id> *credentials = adConfig.credentials.settings;
  NSString *siteID = credentials[GADMAdapterYahooDCN];
  BOOL isInitialized = GADMAdapterYahooInitializeYASAdsWithSiteID(siteID);
  if (!isInitialized) {
    NSError *error = GADMAdapterYahooErrorWithCodeAndDescription(
        GADMAdapterYahooErrorInitialization, @"Yahoo Mobile SDK failed to initialize.");
    handler(nil, error);
    return;
  }

  _placementID = credentials[GADMAdapterYahooPosition];
  if (!_placementID) {
    NSError *error = GADMAdapterYahooErrorWithCodeAndDescription(
        GADMAdapterYahooErrorInvalidServerParameters, @"Placement ID cannot be nil.");
    handler(nil, error);
    return;
  }

  [self setRequestInfoFromAdConfiguration];

  _adLoadCompletionHandler = handler;
  YASInterstitialPlacementConfig *placementConfig =
      [[YASInterstitialPlacementConfig alloc] initWithPlacementId:_placementID requestMetadata:nil];
  _rewardedAd = [[YASInterstitialAd alloc] initWithPlacementId:_placementID];
  _rewardedAd.delegate = self;

  NSLog(@"[YahooAdapter] Requesting a rewarded ad with placement ID: %@", _placementID);
  [_rewardedAd loadWithPlacementConfig:placementConfig];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [_rewardedAd showFromViewController:viewController];
}

- (void)setRequestInfoFromAdConfiguration {
  YASRequestMetadataBuilder *builder = [[YASRequestMetadataBuilder alloc] init];
  builder.mediator = [NSString stringWithFormat:@"AdMobYAS-%@", GADMAdapterYahooVersion];
  YASAds.sharedInstance.requestMetadata = [builder build];

  // Set debug mode in Yahoo Mobile SDK.
  if (_adConfiguration.isTestRequest) {
    YASAds.logLevel = YASLogLevelDebug;
  } else {
    YASAds.logLevel = YASLogLevelError;
  }

  // Forward COPPA value to Yahoo Mobile SDK.
  if (_adConfiguration.childDirectedTreatment.boolValue) {
    NSLog(@"[YahooAdapter] Applying COPPA.");
    [YASAds.sharedInstance applyCoppa];
  }
}

- (void)dealloc {
  _rewardedAd.delegate = nil;
  _rewardedAd = nil;
}

#pragma mark - YASInterstitialAdDelegate

- (void)interstitialAdDidLoad:(nonnull YASInterstitialAd *)interstitialAd {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK loaded a rewarded ad successfully.");
  dispatch_async(dispatch_get_main_queue(), ^{
    self->_rewardedAd = interstitialAd;
    self->_adEventDelegate = self->_adLoadCompletionHandler(self, nil);
  });
}

- (void)interstitialAdLoadDidFail:(nonnull YASInterstitialAd *)interstitialAd
                        withError:(nonnull YASErrorInfo *)errorInfo {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK failed to load a rewarded ad with error: %@",
        errorInfo.description);
  dispatch_async(dispatch_get_main_queue(), ^{
    self->_adLoadCompletionHandler(nil, errorInfo);
  });
}

- (void)interstitialAdDidFail:(nonnull YASInterstitialAd *)interstitialAd
                    withError:(nonnull YASErrorInfo *)errorInfo {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK returned an error for rewarded ad: %@",
        errorInfo.description);
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_adEventDelegate didFailToPresentWithError:errorInfo];
  });
}

- (void)interstitialAdDidShow:(nonnull YASInterstitialAd *)interstitialAd {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK showed a rewarded ad.");
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_adEventDelegate willPresentFullScreenView];
  });
}

- (void)interstitialAdDidClose:(nonnull YASInterstitialAd *)interstitialAd {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK closed a rewarded ad.");
  dispatch_async(dispatch_get_main_queue(), ^{
    id<GADMediationRewardedAdEventDelegate> strongDelegate = self->_adEventDelegate;
    [strongDelegate willDismissFullScreenView];
    [strongDelegate didDismissFullScreenView];
  });
}

- (void)interstitialAdClicked:(nonnull YASInterstitialAd *)interstitialAd {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK recorded a click on a rewarded ad.");
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_adEventDelegate reportClick];
  });
}

- (void)interstitialAdDidLeaveApplication:(nonnull YASInterstitialAd *)interstitialAd {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK has caused the user to leave the application from a "
        @"rewarded ad.");
  // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)interstitialAdEvent:(nonnull YASInterstitialAd *)interstitialAd
                     source:(nonnull NSString *)source
                    eventId:(nonnull NSString *)eventId
                  arguments:(nullable NSDictionary<NSString *, id> *)arguments {
  if ([eventId isEqualToString:GADMAdapterVerizonVideoCompleteEventId] &&
      !_isVideoCompletionEventCalled) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self->_adEventDelegate didRewardUser];
      self->_isVideoCompletionEventCalled = YES;
    });
  }
}

@end
