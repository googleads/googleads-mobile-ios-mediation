// Copyright 2020 Google LLC
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

#import "GADMAdapterIMobileInterstitialAd.h"

#import <ImobileSdkAds/ImobileSdkAds.h>

#import <stdatomic.h>

#import "GADMAdapterIMobileConstants.h"
#import "GADMAdapterIMobileManager.h"
#import "GADMAdapterIMobileUtils.h"
#import "GADMediationAdapterIMobile.h"

@interface GADMAdapterIMobileInterstitialAd () <GADMediationInterstitialAd, IMobileSdkAdsDelegate>
@end

@implementation GADMAdapterIMobileInterstitialAd {
  /// Ad configuration for the ad to be loaded.
  GADMediationInterstitialAdConfiguration *_adConfiguration;

  /// The completion handler to call when an ad loads successfully or fails.
  GADMediationInterstitialLoadCompletionHandler _loadCompletionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  /// Intentionally keeping a reference to the delegate because this delegate is returned from the
  /// GMA SDK, not set on the GMA SDK.
  id<GADMediationInterstitialAdEventDelegate> _delegate;

  /// i-mobile spot ID.
  NSString *_spotID;
}

- (nonnull instancetype)initWithAdConfiguration:
    (nonnull GADMediationInterstitialAdConfiguration *)adConfiguration {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)loadInterstitialAdWithCompletionHandler:
    (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  __block atomic_flag adLoadHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationInterstitialLoadCompletionHandler originalAdLoadHandler =
      [completionHandler copy];

  // Ensure the original completion handler is only called once, and is deallocated once called.
  _loadCompletionHandler = ^id<GADMediationInterstitialAdEventDelegate>(
      id<GADMediationInterstitialAd> interstitialAd, NSError *error) {
    if (atomic_flag_test_and_set(&adLoadHandlerCalled)) {
      return nil;
    }

    id<GADMediationInterstitialAdEventDelegate> delegate = nil;
    if (originalAdLoadHandler) {
      delegate = originalAdLoadHandler(interstitialAd, error);
    }

    originalAdLoadHandler = nil;
    return delegate;
  };

  NSString *publisherID = _adConfiguration.credentials.settings[GADMAdapterIMobilePublisherIdKey];
  if (!publisherID.length) {
    NSString *errorMessage = @"Missing or invalid Publisher ID.";
    GADMAdapterIMobileLog(@"%@", errorMessage);
    NSError *error = GADMAdapterIMobileErrorWithCodeAndDescription(
        GADMAdapterIMobileErrorInvalidServerParameters, errorMessage);
    _loadCompletionHandler(nil, error);
    return;
  }

  NSString *mediaID = _adConfiguration.credentials.settings[GADMAdapterIMobileMediaIdKey];
  if (!mediaID.length) {
    NSString *errorMessage = @"Missing or invalid Media ID.";
    GADMAdapterIMobileLog(@"%@", errorMessage);
    NSError *error = GADMAdapterIMobileErrorWithCodeAndDescription(
        GADMAdapterIMobileErrorInvalidServerParameters, errorMessage);
    _loadCompletionHandler(nil, error);
    return;
  }

  _spotID = _adConfiguration.credentials.settings[GADMAdapterIMobileSpotIdKey];
  if (!_spotID.length) {
    NSString *errorMessage = @"Missing or invalid Spot ID.";
    GADMAdapterIMobileLog(@"%@", errorMessage);
    NSError *error = GADMAdapterIMobileErrorWithCodeAndDescription(
        GADMAdapterIMobileErrorInvalidServerParameters, errorMessage);
    _loadCompletionHandler(nil, error);
    return;
  }

  // Call i-mobile SDK.
  [ImobileSdkAds registerWithPublisherID:publisherID MediaID:mediaID SpotID:_spotID];
  NSError *error = [GADMAdapterIMobileManager.sharedInstance requestInterstitialAdForSpotId:_spotID
                                                                                   delegate:self];
  if (error) {
    GADMAdapterIMobileLog(@"%@", error.localizedDescription);
    _loadCompletionHandler(nil, error);
  }
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(UIViewController *)viewController {
  BOOL didPresent = [ImobileSdkAds showBySpotID:_spotID];
  if (!didPresent) {
    NSString *errorMessage = @"Spot ID not registered.";
    GADMAdapterIMobileLog(@"%@", errorMessage);
    NSError *error = GADMAdapterIMobileErrorWithCodeAndDescription(
        GADMAdapterIMobileErrorAdNotPresented, errorMessage);
    [_delegate didFailToPresentWithError:error];
    return;
  }
  [_delegate willPresentFullScreenView];
}

#pragma mark - IMobileSdkAdsDelegate

- (void)imobileSdkAdsSpot:(NSString *)spotId didReadyWithValue:(ImobileSdkAdsReadyResult)value {
  _delegate = _loadCompletionHandler(self, nil);
}

- (void)imobileSdkAdsSpot:(NSString *)spotId didFailWithValue:(ImobileSdkAdsFailResult)value {
  NSString *errorMessage =
      [NSString stringWithFormat:@"Failed to get an ad for Spot ID: %@", spotId];
  GADMAdapterIMobileLog(@"%@", errorMessage);
  NSError *error = GADMAdapterIMobileErrorWithFailResultAndDescription(value, errorMessage);
  _loadCompletionHandler(nil, error);
}

- (void)imobileSdkAdsSpotDidClick:(NSString *)spotId {
  [_delegate reportClick];
  [_delegate willBackgroundApplication];
}

- (void)imobileSdkAdsSpotDidClose:(NSString *)spotId {
  [_delegate didDismissFullScreenView];
}

@end
