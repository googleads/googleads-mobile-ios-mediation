// Copyright 2019 Google LLC.
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

#import "GADMAdapterMaioRewardedAd.h"
#import <Maio/Maio-Swift.h>
#import <stdatomic.h>
#import "GADMAdapterMaioAdsManager.h"
#import "GADMAdapterMaioUtils.h"
#import "GADMMaioConstants.h"

@interface GADMAdapterMaioRewardedAd () <MaioRewardedLoadCallback, MaioRewardedShowCallback>

@property(nonatomic, copy) GADMediationRewardedLoadCompletionHandler completionHandler;
@property(nonatomic, weak) id<GADMediationRewardedAdEventDelegate> adEventDelegate;
@property(nonatomic, copy) NSString *mediaId;
@property(nonatomic, copy) NSString *zoneId;

@property(nonatomic) MaioRewarded *rewarded;

@end

@implementation GADMAdapterMaioRewardedAd

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  // Safe handling of completionHandler from CONTRIBUTING.md#best-practices
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  self.completionHandler = ^id<GADMediationRewardedAdEventDelegate>(
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

  _mediaId = adConfiguration.credentials.settings[GADMMaioAdapterMediaIdKey];
  _zoneId = adConfiguration.credentials.settings[GADMMaioAdapterZoneIdKey];

  if (!self.mediaId) {
    NSError *error = GADMAdapterMaioErrorWithCodeAndDescription(
        GADMAdapterMaioErrorInvalidServerParameters,
        @"maio mediation configurations did not contain a valid media ID.");
    completionHandler(nil, error);
    return;
  }

  MaioRequest *request = [[MaioRequest alloc] initWithZoneId:self.zoneId testMode:adConfiguration.isTestRequest];
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
  NSString *description = @"maio SDK returned error";
  NSDictionary *userInfo = @{
    NSLocalizedDescriptionKey: description,
    NSLocalizedFailureReasonErrorKey: description
  };
  NSError *error = [NSError errorWithDomain:GADMMaioSDKErrorDomain
                                       code:errorCode
                                   userInfo:userInfo];

  NSLog(@"Maiorewarded did fail. error: %@", error);

  if (10000 <= errorCode && errorCode < 20000) {
    // Fail to load.
    self.completionHandler(nil, error);
  } else if (20000 <= errorCode && errorCode < 30000) {
    // Fail to show.
    [self.adEventDelegate didFailToPresentWithError:error];
  } else {
    // Unknown error code

    // Notify an error when loading.
    self.completionHandler(nil, error);
  }

}

- (void)didOpen:(MaioRewarded *)ad {
  [self.adEventDelegate willPresentFullScreenView];
  [self.adEventDelegate reportImpression];
  [self.adEventDelegate didStartVideo];
}

- (void)didClose:(MaioRewarded *)ad {
  [self.adEventDelegate didEndVideo];
  [self.adEventDelegate willDismissFullScreenView];
  [self.adEventDelegate didDismissFullScreenView];
}

- (void)didReward:(MaioRewarded *)ad reward:(RewardData *)reward {
  [self.adEventDelegate didRewardUser];
}

@end
