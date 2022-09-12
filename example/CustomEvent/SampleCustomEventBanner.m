//
// Copyright (C) 2015 Google, Inc.
//
// SampleCustomEventBanner.m
// Sample Ad Network Custom Event
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "SampleCustomEventBanner.h"
#include <stdatomic.h>
#import "SampleCustomEventConstants.h"
#import "SampleCustomEventUtils.h"

#import <Foundation/Foundation.h>
#import <SampleAdSDK/SampleAdSDK.h>

@interface SampleCustomEventBanner () <SampleBannerAdDelegate, GADMediationBannerAd> {
  /// The sample banner ad.
  SampleBanner *_bannerAd;

  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationBannerLoadCompletionHandler _loadCompletionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  id<GADMediationBannerAdEventDelegate> _adEventDelegate;
}

@end

@implementation SampleCustomEventBanner

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationBannerLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];

  _loadCompletionHandler = ^id<GADMediationBannerAdEventDelegate>(
      _Nullable id<GADMediationBannerAd> ad, NSError *_Nullable error) {
    // Only allow completion handler to be called once.
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }

    id<GADMediationBannerAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      // Call original handler and hold on to its return value.
      delegate = originalCompletionHandler(ad, error);
    }

    // Release reference to handler. Objects retained by the handler will also be released.
    originalCompletionHandler = nil;

    return delegate;
  };

  NSString *adUnit = adConfiguration.credentials.settings[@"parameter"];
  _bannerAd =
      [[SampleBanner alloc] initWithFrame:CGRectMake(0, 0, adConfiguration.adSize.size.width,
                                                     adConfiguration.adSize.size.height)];
  _bannerAd.adUnit = adUnit;
  _bannerAd.delegate = self;
  SampleAdRequest *adRequest = [[SampleAdRequest alloc] init];
  adRequest.testMode = adConfiguration.isTestRequest;
  [_bannerAd fetchAd:adRequest];
}

#pragma mark GADMediationBannerAd implementation

- (nonnull UIView *)view {
  return _bannerAd;
}

#pragma mark SampleBannerAdDelegate implementation

- (void)bannerDidLoad:(SampleBanner *)banner {
  _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void)banner:(SampleBanner *)banner didFailToLoadAdWithErrorCode:(SampleErrorCode)errorCode {
  NSError *error = SampleCustomEventErrorWithCodeAndDescription(
      SampleCustomEventErrorAdLoadFailureCallback,
      [NSString
          stringWithFormat:@"Sample SDK returned an ad load failure callback with error code: %@",
                           errorCode]);
  _adEventDelegate = _loadCompletionHandler(nil, error);
}

- (void)bannerWillLeaveApplication:(SampleBanner *)banner {
  [_adEventDelegate reportClick];
}

@end
