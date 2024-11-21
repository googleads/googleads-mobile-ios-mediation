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
  __weak id<GADMediationInterstitialAdEventDelegate> _interstitialAdEventDelegate;

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

  if (_adConfiguration.bidResponse) {
    [self loadBiddingAd];
  } else {
    [self loadWaterfallAd];
  }
}

- (void)loadWaterfallAd {
  NSError *error;
  NSString *slotID = GADMediationAdapterLineSlotID(_adConfiguration.credentials, &error);
  if (error) {
    _interstitialAdLoadCompletionHandler(nil, error);
    return;
  }

  _interstitialAd = [[FADInterstitial alloc] initWithSlotId:slotID];
  [_interstitialAd setLoadDelegate:self];
  [_interstitialAd setEventListener:self];
  [_interstitialAd enableSound:GADMediationAdapterLineShouldEnableAudio(_adConfiguration.extras)];
  GADMediationAdapterLineLog(@"Start loading an interstitial ad from FiveAd SDK.");
  [_interstitialAd loadAdAsync];
}

- (void)loadBiddingAd {
  __block NSError *error;
  FADAdLoader *adLoader = GADMediationAdapterLineFADAdLoaderForRegisteredConfig(&error);
  if (error) {
    _interstitialAdLoadCompletionHandler(nil, error);
    return;
  }
  NSString *watermarkString =
      GADMediationAdapterLineWatermarkStringFromAdConfiguration(_adConfiguration);
  FADBidData *bidData = [[FADBidData alloc] initWithBidResponse:_adConfiguration.bidResponse
                                                  withWatermark:watermarkString];
  GADMediationAdapterLineInterstitialAdLoader *__weak weakSelf = self;
  [adLoader
      loadInterstitialAdWithBidData:bidData
                   withLoadCallback:^(FADInterstitial *_Nullable interstitialAd,
                                      NSError *_Nullable adLoadError) {
                     GADMediationAdapterLineInterstitialAdLoader *strongSelf = weakSelf;
                     if (!strongSelf) {
                       return;
                     }

                     if (adLoadError) {
                       GADMediationAdapterLineLog(@"FiveAd SDK failed to load a bidding "
                                                  @"interstitial ad. The FiveAd error code: %ld.",
                                                  adLoadError.code);
                       error = GADMediationAdapterLineErrorWithFiveAdErrorCode(adLoadError.code);
                       strongSelf->_interstitialAdLoadCompletionHandler(nil, error);
                       return;
                     }

                     [interstitialAd setEventListener:strongSelf];
                     [interstitialAd enableSound:GADMediationAdapterLineShouldEnableAudio(
                                                     strongSelf->_adConfiguration.extras)];
                     strongSelf->_interstitialAd = interstitialAd;
                     strongSelf->_interstitialAdEventDelegate =
                         strongSelf->_interstitialAdLoadCompletionHandler(strongSelf, nil);
                   }];
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  GADMediationAdapterLineLog(@"FiveAd SDK will present the interstitial ad.");
  [_interstitialAdEventDelegate willPresentFullScreenView];
  [_interstitialAd show];
}

#pragma mark - FADLoadDelegate (for waterfall interstitial ad)

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

#pragma mark - FADInterstitialEventListener

- (void)fiveInterstitialAd:(nonnull FADInterstitial *)ad
    didFailedToShowAdWithError:(FADErrorCode)errorCode {
  GADMediationAdapterLineLog(
      @"The FiveAd interstitial ad did fail to show. The FiveAd error code: %ld.", errorCode);
  NSError *error = GADMediationAdapterLineErrorWithFiveAdErrorCode(errorCode);
  [_interstitialAdEventDelegate didFailToPresentWithError:error];
}

- (void)fiveInterstitialAdDidImpression:(nonnull FADInterstitial *)ad {
  GADMediationAdapterLineLog(@"The FiveAd interstitial ad did impression.");
  [_interstitialAdEventDelegate reportImpression];
}

- (void)fiveInterstitialAdDidClick:(nonnull FADInterstitial *)ad {
  GADMediationAdapterLineLog(@"The FiveAd interstitial ad did click.");
  [_interstitialAdEventDelegate reportClick];
}

- (void)fiveInterstitialAdFullScreenDidOpen:(nonnull FADInterstitial *)ad {
  GADMediationAdapterLineLog(@"The FiveAd interstitial ad did open.");
}

- (void)fiveInterstitialAdFullScreenDidClose:(nonnull FADInterstitial *)ad {
  GADMediationAdapterLineLog(@"The FiveAd interstitial ad did close.");
  [_interstitialAdEventDelegate didDismissFullScreenView];
}

- (void)fiveInterstitialAdDidPlay:(nonnull FADInterstitial *)ad {
  GADMediationAdapterLineLog(@"The FiveAd interstitial ad did play.");
}

- (void)fiveInterstitialAdDidPause:(nonnull FADInterstitial *)ad {
  GADMediationAdapterLineLog(@"The FiveAd interstitial ad did pause.");
}

- (void)fiveInterstitialAdDidViewThrough:(nonnull FADInterstitial *)ad {
  GADMediationAdapterLineLog(@"The FiveAd interstitial ad did view through.");
}

@end
