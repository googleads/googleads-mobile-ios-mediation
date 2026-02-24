// Copyright 2025 Google LLC
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

#import "GADMAdapterMaioBannerAd.h"

#import <Maio/Maio-Swift.h>
#import <stdatomic.h>

#import "GADMAdapterMaioUtils.h"
#import "GADMMaioConstants.h"

@interface GADMAdapterMaioBannerAd () <MaioBannerDelegate>

@property(nonatomic, copy) GADMediationBannerLoadCompletionHandler completionHandler;
@property(nonatomic, weak) id<GADMediationBannerAdEventDelegate> adEventDelegate;

@property(nonatomic) MaioBannerView *maioBannerView;

@end

@implementation GADMAdapterMaioBannerAd

- (void)loadBannerAdForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  // Safe handling of completionHandler from CONTRIBUTING.md#best-practices
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationBannerLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  self.completionHandler = ^id<GADMediationBannerAdEventDelegate>(
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

  NSString *zoneId = adConfiguration.credentials.settings[GADMMaioAdapterZoneIdKey];
  MaioBannerSize *maioBannerSize =
      [GADMAdapterMaioUtils maioAdSizeFromRequestedSize:adConfiguration.adSize];

  if (maioBannerSize == nil) {
    NSString *description =
        [NSString stringWithFormat:@"Unsupported ad size requested for maio. Requested size: %@",
         NSStringFromGADAdSize(adConfiguration.adSize)];
    NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
    NSError *error = [NSError errorWithDomain:GADMMaioSDKErrorDomain
                                         code:0
                                     userInfo:userInfo];

    NSLog(@"maio banner ad failed to load with error code: %@", error);
    self.completionHandler(nil, error);
    return;
  }

  self.maioBannerView = [[MaioBannerView alloc] initWithZoneId:zoneId size:maioBannerSize];
  self.maioBannerView.delegate = self;
  self.maioBannerView.rootViewController = adConfiguration.topViewController;

  [self.maioBannerView loadWithTestMode:adConfiguration.isTestRequest bidData:nil];
}

#pragma mark - GADMediationBannerAd

- (UIView *)view {
  self.maioBannerView.translatesAutoresizingMaskIntoConstraints = NO;
  return self.maioBannerView;
}

#pragma mark - MaioBannerDelegate

- (void)didLoad:(MaioBannerView *)ad {
  self.adEventDelegate = self.completionHandler(self, nil);
}

- (void)didFailToLoad:(MaioBannerView *)ad errorCode:(NSInteger)errorCode {
  NSString *description = @"maio SDK returned an error.";
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMMaioSDKErrorDomain
                                       code:errorCode
                                   userInfo:userInfo];

  NSLog(@"maio banner ad failed to load with error code: %@", error);
  self.completionHandler(nil, error);
}

- (void)didMakeImpression:(MaioBannerView *)ad {
  id<GADMediationBannerAdEventDelegate> adEventDelegate = self.adEventDelegate;
  [adEventDelegate reportImpression];
}

- (void)didClick:(MaioBannerView *)ad {
  id<GADMediationBannerAdEventDelegate> adEventDelegate = self.adEventDelegate;
  [adEventDelegate reportClick];
}

- (void)didLeaveApplication:(MaioBannerView *)ad {
  id<GADMediationBannerAdEventDelegate> adEventDelegate = self.adEventDelegate;
  [adEventDelegate willDismissFullScreenView];
}

- (void)didFailToShow:(MaioBannerView *)ad errorCode:(NSInteger)errorCode {
  NSString *description = @"maio SDK returned an error.";
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMMaioSDKErrorDomain
                                       code:errorCode
                                   userInfo:userInfo];

  NSLog(@"maio banner ad failed to show with error code: %@", error);
  self.completionHandler(nil, error);
}

@end
