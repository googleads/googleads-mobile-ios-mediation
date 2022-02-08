// Copyright 2020 Google LLC.
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

#import "GADRTBMaioRewardedAd.h"
#import <MaioOB/MaioOB-Swift.h>
#import <stdatomic.h>
#import "GADMMaioConstants.h"

@interface GADRTBMaioRewardedAd () <MaioRewardedLoadCallback, MaioRewardedShowCallback>
@end

@implementation GADRTBMaioRewardedAd {
  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _completionHandler;

  /// An ad event delegate to invoke when ad rendering events occur.
  /// Intentionally keeping a reference to the delegate because this delegate is returned from the
  /// GMA SDK, not set on the GMA SDK.
  id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  /// Ad configuration of the ad request.
  GADMediationRewardedAdConfiguration *_adConfiguration;

  /// maio's rewarded ad object.
  MaioRewarded *_rewarded;
}

- (nonnull instancetype)initWithAdConfiguration:
    (nonnull GADMediationRewardedAdConfiguration *)adConfiguration {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)loadRewardedAdWithCompletionHandler:
    (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  // Safe handling of completionHandler from CONTRIBUTING.md#best-practices
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _completionHandler = ^id<GADMediationRewardedAdEventDelegate>(
      _Nullable id<GADMediationRewardedAd> ad, NSError *_Nullable error) {
    // Only allow completion handler to be called once.
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }

    id<GADMediationRewardedAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      // Call original handler and hold on to its return value.
      delegate = originalCompletionHandler(ad, error);
    }
    // Release reference to handler. Objects retained by the handler will also be released.
    originalCompletionHandler = nil;

    return delegate;
  };

  // For bidding requests with bid data, the zone ID is unused.
  MaioRequest *request = [[MaioRequest alloc] initWithZoneId:@"dummyZoneForRTB"
                                                    testMode:_adConfiguration.isTestRequest
                                                     bidData:_adConfiguration.bidResponse];
  _rewarded = [MaioRewarded loadAdWithRequest:request callback:self];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [_rewarded showWithViewContext:viewController callback:self];
}

#pragma mark - MaioRewardedLoadCallback, MaioRewardedShowCallback

- (void)didLoad:(MaioRewarded *)ad {
  _adEventDelegate = _completionHandler(self, nil);
}

- (void)didFail:(MaioRewarded *)ad errorCode:(NSInteger)errorCode {
  NSString *description = @"maio bidding SDK returned error";
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMMaioSDKErrorDomain
                                       code:errorCode
                                   userInfo:userInfo];

  NSLog(@"MaioRewarded did fail. error: %@", error);

  if (10000 <= errorCode && errorCode < 20000) {
    // Fail to load.
    _completionHandler(nil, error);
  } else if (20000 <= errorCode && errorCode < 30000) {
    // Fail to show.
    [_adEventDelegate didFailToPresentWithError:error];
  } else {
    // Unknown error code

    // Notify an error when loading.
    _completionHandler(nil, error);
  }
}

- (void)didOpen:(MaioRewarded *)ad {
  [_adEventDelegate willPresentFullScreenView];
  [_adEventDelegate reportImpression];
  [_adEventDelegate didStartVideo];
}

- (void)didClose:(MaioRewarded *)ad {
  [_adEventDelegate didEndVideo];
  [_adEventDelegate willDismissFullScreenView];
  [_adEventDelegate didDismissFullScreenView];
}

- (void)didReward:(MaioRewarded *)ad reward:(RewardData *)reward {
  GADAdReward *gReward = [[GADAdReward alloc] initWithRewardType:reward.value
                                                    rewardAmount:[NSDecimalNumber one]];

  [_adEventDelegate didRewardUserWithReward:gReward];
}

@end
