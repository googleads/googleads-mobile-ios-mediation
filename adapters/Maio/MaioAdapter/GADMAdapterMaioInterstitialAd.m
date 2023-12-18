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

#import "GADMAdapterMaioInterstitialAd.h"

#import <Maio/Maio-Swift.h>
#import <stdatomic.h>

#import "GADMAdapterMaioUtils.h"
#import "GADMMaioConstants.h"

@interface GADMAdapterMaioInterstitialAd () <MaioInterstitialLoadCallback,
                                             MaioInterstitialShowCallback>
@end

@implementation GADMAdapterMaioInterstitialAd {
  /// An interstitial ad of Maio.
  MaioInterstitial *_interstitial;

  /// An ad configuration used for loading an interstitial ad.
  GADMediationInterstitialAdConfiguration *_adConfiguration;

  /// An event delegate object that reports interstitial related information to the Google Mobile
  /// Ads SDK.
  __weak id<GADMediationInterstitialAdEventDelegate> _adEventDelegate;

  /// A completion handler that is called up on interstitial ad load completion or failure.
  GADMediationInterstitialLoadCompletionHandler _completionHandler;
}

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
          completionHandler:
              (nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    // Safe handling of completionHandler from CONTRIBUTING.md#best-practices
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationInterstitialLoadCompletionHandler originalCompletionHandler =
        [completionHandler copy];
    _completionHandler = ^id<GADMediationInterstitialAdEventDelegate>(
        _Nullable id<GADMediationInterstitialAd> ad, NSError *_Nullable error) {
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
  }
  return self;
}

- (void)loadInterstitialAd {
  NSString *zoneId = _adConfiguration.credentials.settings[GADMMaioAdapterZoneIdKey];
  MaioRequest *request = [[MaioRequest alloc] initWithZoneId:zoneId
                                                    testMode:_adConfiguration.isTestRequest];
  _interstitial = [MaioInterstitial loadAdWithRequest:request callback:self];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  id<GADMediationInterstitialAdEventDelegate> adEventDelegate = _adEventDelegate;
  [adEventDelegate willPresentFullScreenView];
  [_interstitial showWithViewContext:viewController callback:self];
}

- (void)didFailToPresentWithErrorCode:(NSInteger)errorCode {
  NSString *description = [NSString
      stringWithFormat:@"maio interstitial ad failed to show with error code: %ld", errorCode];
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMMaioSDKErrorDomain
                                       code:errorCode
                                   userInfo:userInfo];
  NSLog(@"%@", description);
  [_adEventDelegate didFailToPresentWithError:error];
}

#pragma mark - MaioInterstitialLoadCallback

- (void)didLoad:(MaioInterstitial *)ad {
  _adEventDelegate = _completionHandler(self, nil);
}

- (void)didFail:(MaioInterstitial *)ad errorCode:(NSInteger)errorCode {
  if (20000 <= errorCode && errorCode < 30000) {
    // Fail to present.
    [self didFailToPresentWithErrorCode:errorCode];
    return;
  }

  NSString *description = nil;
  if (10000 <= errorCode && errorCode < 20000) {
    // Fail to load.
    description = [NSString
        stringWithFormat:@"maio interstitial ad failed to load with error code: %ld", errorCode];
  } else {
    // Unknown error code
    description = [NSString
        stringWithFormat:@"maio interstitial ad received an error with error code: %ld", errorCode];
  }
  NSLog(@"%@", description);

  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMMaioSDKErrorDomain
                                       code:errorCode
                                   userInfo:userInfo];
  _completionHandler(nil, error);
}

#pragma mark - MaioInterstitialShowCallback

- (void)didOpen:(MaioInterstitial *)ad {
  id<GADMediationInterstitialAdEventDelegate> adEventDelegate = _adEventDelegate;
  [adEventDelegate reportImpression];
}

- (void)didClose:(MaioInterstitial *)ad {
  id<GADMediationInterstitialAdEventDelegate> adEventDelegate = _adEventDelegate;
  [adEventDelegate willDismissFullScreenView];
  [adEventDelegate didDismissFullScreenView];
}

@end
