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

#import "GADMRewardedAdTapjoy.h"
#import <Tapjoy/Tapjoy.h>
#import "GADMAdapterTapjoy.h"
#import "GADMAdapterTapjoyConstants.h"
#import "GADMAdapterTapjoySingleton.h"
#import "GADMTapjoyExtras.h"

@interface GADMRewardedAdTapjoy () <GADMediationRewardedAd,
                                    TJPlacementDelegate,
                                    TJPlacementVideoDelegate>

@property(nonatomic, weak) GADMediationRewardedAdConfiguration *adConfig;
@property(nonatomic, copy) GADMediationRewardedLoadCompletionHandler completionHandler;
@property(nonatomic, weak) id<GADMediationRewardedAdEventDelegate> adEventDelegate;
@property(nonatomic, strong) TJPlacement *rvPlacement;
@property(nonatomic, copy) NSString *sdkKey;
@property(nonatomic, copy) NSString *placementName;

@end

@implementation GADMRewardedAdTapjoy

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  self.adConfig = adConfiguration;
  self.completionHandler = completionHandler;

  self.sdkKey = adConfiguration.credentials.settings[kGADMAdapterTapjoySdkKey];
  self.placementName = adConfiguration.credentials.settings[kGADMAdapterTapjoyPlacementKey];

  if (!self.sdkKey.length || !self.placementName.length) {
    NSError *adapterError = [NSError
        errorWithDomain:kGADMAdapterTapjoyErrorDomain
                   code:0
               userInfo:@{
                 NSLocalizedDescriptionKey : @"Did not receive valid Tapjoy server parameters"
               }];
    self.completionHandler(nil, adapterError);
    return;
  }

  GADMAdapterTapjoySingleton *sharedInstance = [GADMAdapterTapjoySingleton sharedInstance];

  GADMTapjoyExtras *extras = [adConfiguration extras];

  // if not yet connected, wait for connect response before requesting placement.
  if ([Tapjoy isConnected]) {
    [Tapjoy setDebugEnabled:extras.debugEnabled];
    _rvPlacement = [sharedInstance requestAdForPlacementName:self.placementName delegate:self];
  } else {
    NSDictionary *connectOptions =
        @{TJC_OPTION_ENABLE_LOGGING : [NSNumber numberWithInt:extras.debugEnabled]};
    GADMRewardedAdTapjoy *__weak weakSelf = self;
    [sharedInstance initializeTapjoySDKWithSDKKey:self.sdkKey
                                          options:connectOptions
                                completionHandler:^(NSError *error) {
                                  GADMRewardedAdTapjoy *__strong strongSelf = weakSelf;
                                  if (error) {
                                    completionHandler(nil, error);
                                  } else if (strongSelf) {
                                    strongSelf.rvPlacement =
                                        [[GADMAdapterTapjoySingleton sharedInstance]
                                            requestAdForPlacementName:strongSelf.placementName
                                                             delegate:strongSelf];
                                  }
                                }];
  }
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [_rvPlacement showContentWithViewController:viewController];
}

#pragma mark - TJPlacementDelegate methods
- (void)requestDidSucceed:(TJPlacement *)placement {
  // Do nothing. contentIsReady: indicates that an ad has loaded.
}

- (void)requestDidFail:(TJPlacement *)placement error:(NSError *)error {
  NSError *adapterError =
      [NSError errorWithDomain:kGADMAdapterTapjoyErrorDomain
                          code:0
                      userInfo:@{NSLocalizedDescriptionKey : @"Tapjoy Video failed to load"}];
  self.completionHandler(nil, adapterError);
}

- (void)contentIsReady:(TJPlacement *)placement {
  self.adEventDelegate = self.completionHandler(self, nil);
}

- (void)contentDidAppear:(TJPlacement *)placement {
  [self.adEventDelegate willPresentFullScreenView];
}

- (void)contentDidDisappear:(TJPlacement *)placement {
  [self.adEventDelegate didDismissFullScreenView];
}

#pragma mark Tapjoy Video
- (void)videoDidStart:(TJPlacement *)placement {
  [self.adEventDelegate didStartVideo];
}

- (void)videoDidComplete:(TJPlacement *)placement {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = self.adEventDelegate;
  [strongDelegate didEndVideo];
  // Tapjoy only supports fixed rewards and doesn't provide a reward type or amount.
  GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:@""
                                                   rewardAmount:[NSDecimalNumber one]];
  [strongDelegate didRewardUserWithReward:reward];
}

- (void)videoDidFail:(TJPlacement *)placement error:(NSString *)errorMsg {
  NSError *adapterError =
      [NSError errorWithDomain:kGADMAdapterTapjoyErrorDomain
                          code:0
                      userInfo:@{NSLocalizedDescriptionKey : @"Tapjoy Video playback failed"}];
  [self.adEventDelegate didFailToPresentWithError:adapterError];
}

@end
