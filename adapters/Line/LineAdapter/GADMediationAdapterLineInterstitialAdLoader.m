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

#import "GADMediationAdapterLineInterstitialAdLoader.h"

#import <UIKit/UIKit.h>

#include <stdatomic.h>

#import "GADMediationAdapterLineConstants.h"
#import "GADMediationAdapterLineUtils.h"

@implementation GADMediationAdapterLineInterstitialAdLoader {
  /// The interstitial ad configuration.
  GADMediationInterstitialAdConfiguration *_adConfiguration;

  /// The completion handler to call when interstitial ad loading succeeds or fails.
  GADMediationInterstitialLoadCompletionHandler _interstitialAdLoadCompletionHandler;

  /// The ad event delegate which is used to report interstitial related information to the Google
  /// Mobile Ads SDK.
  id<GADMediationInterstitialAdEventDelegate> _interstitialAdEventDelegate;

  /// The interstitial ad.
  FADInterstitial *_interstitialAd;
}

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
      loadCompletionHandler:
          (nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;

    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationInterstitialLoadCompletionHandler originalCompletionHandler =
        [completionHandler copy];
    _interstitialAdLoadCompletionHandler = ^id<GADMediationInterstitialAdEventDelegate>(
        id<GADMediationInterstitialAd> interstitialAd, NSError *error) {
      if (atomic_flag_test_and_set(&completionHandlerCalled)) {
        return nil;
      }
      id<GADMediationInterstitialAdEventDelegate> delegate = nil;
      if (originalCompletionHandler) {
        delegate = originalCompletionHandler(interstitialAd, error);
      }
      originalCompletionHandler = nil;
      return delegate;
    };
  }
  return self;
}

- (void)loadAd {
  NSError *error = GADMediationAdapterLineRegisterFiveAd(@[ _adConfiguration.credentials ]);
  if (error) {
    _interstitialAdLoadCompletionHandler(nil, error);
    return;
  }

  NSString *slotID = GADMediationAdapterLineSlotID(_adConfiguration, &error);
  if (error) {
    _interstitialAdLoadCompletionHandler(nil, error);
    return;
  }

  _interstitialAd = [[FADInterstitial alloc] initWithSlotId:slotID];
  [_interstitialAd setLoadDelegate:self];
  [_interstitialAd setAdViewEventListener:self];
  [_interstitialAd enableSound:!GADMobileAds.sharedInstance.applicationMuted];
  GADMediationAdapterLineLog(@"Start loading an interstitial ad from FiveAd SDK.");
  [_interstitialAd loadAdAsync];
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  GADMediationAdapterLineLog(@"FiveAd SDK will present the interstitial ad.");
  [_interstitialAdEventDelegate willPresentFullScreenView];
  [_interstitialAd show];
}

#pragma mark - FADLoadDelegate

- (void)fiveAdDidLoad:(id<FADAdInterface>)ad {
  GADMediationAdapterLineLog(@"FiveAd SDK loaded an interstitial ad.");
  _interstitialAdEventDelegate = _interstitialAdLoadCompletionHandler(self, nil);
}

- (void)fiveAd:(id<FADAdInterface>)ad didFailedToReceiveAdWithError:(FADErrorCode)errorCode {
  GADMediationAdapterLineLog(
      @"FiveAd SDK failed to load an interstitial ad. The FiveAd error code: %ld.", errorCode);
  NSError *error = GADMediationAdapterLineErrorWithFiveAdErrorCode(errorCode);
  _interstitialAdLoadCompletionHandler(nil, error);
}

#pragma mark - FADAdViewEventListener

- (void)fiveAdDidClick:(id<FADAdInterface>)ad {
  GADMediationAdapterLineLog(@"The FiveAd interstitial ad did click.");
  [_interstitialAdEventDelegate reportClick];
}

- (void)fiveAdDidImpression:(id<FADAdInterface>)ad {
  GADMediationAdapterLineLog(@"The FiveAd interstitial ad did impression.");
  [_interstitialAdEventDelegate reportImpression];
}

- (void)fiveAdDidClose:(id<FADAdInterface>)ad {
  GADMediationAdapterLineLog(@"The FiveAd interstitial ad did close.");
  [_interstitialAdEventDelegate didDismissFullScreenView];
}

- (void)fiveAd:(id<FADAdInterface>)ad didFailedToShowAdWithError:(FADErrorCode)errorCode {
  GADMediationAdapterLineLog(
      @"The FiveAd interstitial ad did fail to show. The FiveAd error code: %ld.", errorCode);
  NSError *error = GADMediationAdapterLineErrorWithFiveAdErrorCode(errorCode);
  [_interstitialAdEventDelegate didFailToPresentWithError:error];
}

- (void)fiveAdDidStart:(id<FADAdInterface>)ad {
  GADMediationAdapterLineLog(@"The FiveAd interstitial ad did start.");
}

- (void)fiveAdDidPause:(id<FADAdInterface>)ad {
  GADMediationAdapterLineLog(@"The FiveAd interstitial ad did pause.");
}

- (void)fiveAdDidResume:(id<FADAdInterface>)ad {
  GADMediationAdapterLineLog(@"The FiveAd interstitial ad did resume.");
}

- (void)fiveAdDidViewThrough:(id<FADAdInterface>)ad {
  GADMediationAdapterLineLog(@"The FiveAd interstitial ad did view through.");
}

- (void)fiveAdDidReplay:(id<FADAdInterface>)ad {
  GADMediationAdapterLineLog(@"The FiveAd interstitial ad did replay.");
}

- (void)fiveAdDidStall:(id<FADAdInterface>)ad {
  GADMediationAdapterLineLog(@"The FiveAd interstitial ad did stall.");
}

- (void)fiveAdDidRecover:(id<FADAdInterface>)ad {
  GADMediationAdapterLineLog(@"The FiveAd interstitial ad did recover.");
}

@end
