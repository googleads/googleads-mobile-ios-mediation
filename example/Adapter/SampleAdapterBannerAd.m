// Copyright 2023 Google LLC
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

#import "SampleAdapterBannerAd.h"
#include <stdatomic.h>
#import "SampleAdapter.h"
#import "SampleAdapterConstants.h"

@implementation SampleAdapterBannerAd {
  /// The completion handler to call ad loading events.
  GADMediationBannerLoadCompletionHandler _adLoadCompletionHandler;

  /// An ad event delegate to forward ad rendering events.
  __weak id<GADMediationBannerAdEventDelegate> _adEventDelegate;

  /// The banner ad configuration.
  GADMediationBannerAdConfiguration *_adConfiguration;

  /// Banner ad object from Sample SDK.
  SampleBanner *_bannerAd;
}

- (nonnull instancetype)initWithAdConfiguration:
    (nonnull GADMediationBannerAdConfiguration *)adConfiguration {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)renderBannerAdWithCompletionHandler:
    (nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationBannerLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _adLoadCompletionHandler =
      ^id<GADMediationBannerAdEventDelegate>(id<GADMediationBannerAd> bannerAd, NSError *error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }
    id<GADMediationBannerAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(bannerAd, error);
    }
    originalCompletionHandler = nil;
    return delegate;
  };

  NSString *adUnit = _adConfiguration.credentials.settings[SampleSDKAdUnitIDKey];
  if (!adUnit.length) {
    NSError *parameterError =
        [NSError errorWithDomain:kAdapterErrorDomain
                            code:SampleAdapterErrorCodeInvalidServerParameters
                        userInfo:@{NSLocalizedDescriptionKey : @"Missing or invalid ad unit."}];
    _adLoadCompletionHandler(nil, parameterError);
    return;
  }

  GADAdSize adSize = _adConfiguration.adSize;
  _bannerAd =
      [[SampleBanner alloc] initWithFrame:CGRectMake(0, 0, adSize.size.width, adSize.size.height)];
  _bannerAd.delegate = self;
  _bannerAd.adUnit = adUnit;

  SampleAdRequest *request = [[SampleAdRequest alloc] init];
  // Set up request parameters.
  request.testMode = _adConfiguration.isTestRequest;

  NSLog(@"Requesting a banner ad from Sample Ad Network.");
  [_bannerAd fetchAd:request];
}

#pragma mark - GADMediationBannerAd

- (nonnull UIView *)view {
  return _bannerAd;
}

#pragma mark - SampleBannerAdDelegate methods

- (void)bannerDidLoad:(SampleBanner *)banner {
  _adEventDelegate = _adLoadCompletionHandler(self, nil);
}

- (void)banner:(SampleBanner *)banner didFailToLoadAdWithErrorCode:(SampleErrorCode)errorCode {
  NSError *loadError = [NSError
      errorWithDomain:kAdapterErrorDomain
                 code:errorCode
             userInfo:@{NSLocalizedDescriptionKey : @"Sample SDK returned an error callback."}];
  _adLoadCompletionHandler(nil, loadError);
}

- (void)bannerWillLeaveApplication:(SampleBanner *)banner {
  [_adEventDelegate reportClick];
}

@end
