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

#import "GADMAdapterInMobiRewardedAd.h"
#import <InMobiSDK/InMobiSDK.h>
#include <stdatomic.h>
#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiDelegateManager.h"
#import "GADMAdapterInMobiUtils.h"
#import "GADMInMobiConsent.h"
#import "GADMediationAdapterInMobi.h"

@interface GADMAdapterInMobiRewardedAd () <IMInterstitialDelegate>
@end

@implementation GADMAdapterInMobiRewardedAd {
  /// Ad Configuration for the ad to be rendered.
  GADMediationRewardedAdConfiguration *_adConfig;

  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _renderCompletionHandler;

  /// The Completion handler for signal generation. Returns either signals or an error object.
  GADRTBSignalCompletionHandler _signalCompletionHandler;

  /// An ad event delegate to invoke when ad rendering events occur.
  id<GADMediationRewardedAdEventDelegate> __weak _adEventDelegate;

  /// InMobi rewarded ad.
  IMInterstitial *_rewardedAd;

  /// InMobi Placement identifier.
  NSNumber *_placementIdentifier;

  /// Optional Parameters for targeted advertising during an Ad Request.
  GADInMobiExtras *_extraInfo;
}

- (nonnull instancetype)initWithPlacementIdentifier:(nonnull NSNumber *)placementIdentifier {
  self = [super init];
  if (self) {
    _placementIdentifier = placementIdentifier;
    _rewardedAd = [[IMInterstitial alloc] initWithPlacementId:_placementIdentifier.longLongValue];
    [self prepareRequestParameters];
    _rewardedAd.delegate = self;
  }
  return self;
}

- (void)collectIMSignalsWithGACompletionHandler:
    (nonnull GADRTBSignalCompletionHandler)completionHandler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADRTBSignalCompletionHandler originalCompletionHandler = [completionHandler copy];
  _signalCompletionHandler = ^void(NSString *_Nullable signals, NSError *_Nullable error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return;
    }
    if (originalCompletionHandler) {
      originalCompletionHandler(signals, error);
    }
    originalCompletionHandler = nil;
  };
  [_rewardedAd getSignals];
}

- (void)loadRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  _adConfig = adConfiguration;
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _renderCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(
      id<GADMediationRewardedAd> rewardedAd, NSError *error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }
    id<GADMediationRewardedAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(rewardedAd, error);
    }
    originalCompletionHandler = nil;
    return delegate;
  };

  // Converting a string to a long long value.
  long long placement =
      [adConfiguration.credentials.settings[kGADMAdapterInMobiPlacementID] longLongValue];

  // Converting a long long value to a NSNumber so that it can be used as a key to store in a
  // dictionary.
  _placementIdentifier = @(placement);

  // Validates the placement identifier.
  NSError *error = GADMAdapterInMobiValidatePlacementIdentifier(_placementIdentifier);
  if (error) {
    _renderCompletionHandler(nil, error);
    return;
  }

  GADMAdapterInMobiDelegateManager *delegateManager =
      GADMAdapterInMobiDelegateManager.sharedInstance;
  if ([delegateManager containsDelegateForPlacementIdentifier:_placementIdentifier]) {
    NSString *errorDesc = [NSString
        stringWithFormat:@"[InMobi] Error - cannot request multiple ads using same placement ID."];
    NSDictionary *errorInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
    GADRequestError *error = [GADRequestError errorWithDomain:kGADMAdapterInMobiErrorDomain
                                                         code:kGADErrorInvalidRequest
                                                     userInfo:errorInfo];
    _renderCompletionHandler(nil, error);
    return;
  }

  [delegateManager addDelegate:self forPlacementIdentifier:_placementIdentifier];

  if (_adConfig.isTestRequest) {
    NSLog(@"[InMobi] Please enter your device ID in the InMobi console to receive test ads from "
          @"Inmobi");
  }
  [self prepareRequestParameters];
  if (_adConfig.bidResponse) {
    [_rewardedAd load:[adConfiguration.bidResponse dataUsingEncoding:NSUTF8StringEncoding]];
  } else {
    [_rewardedAd load];
  }
}

- (void)prepareRequestParameters {
  GADMediationRewardedAdConfiguration *strongAdConfig = _adConfig;

  if (strongAdConfig.extras) {
    _extraInfo = [strongAdConfig extras];
  }

  if (_extraInfo.postalCode) {
    [IMSdk setPostalCode:_extraInfo.postalCode];
  }
  if (_extraInfo.areaCode) {
    [IMSdk setAreaCode:_extraInfo.areaCode];
  }
  if (_extraInfo.interests) {
    [IMSdk setInterests:_extraInfo.interests];
  }
  if (_extraInfo.age) {
    [IMSdk setAge:_extraInfo.age];
  }
  if (_extraInfo.yearOfBirth) {
    [IMSdk setYearOfBirth:_extraInfo.yearOfBirth];
  }
  if (_extraInfo.city && _extraInfo.state && _extraInfo.country) {
    [IMSdk setLocationWithCity:_extraInfo.city state:_extraInfo.state country:_extraInfo.country];
  }
  if (_extraInfo.language) {
    [IMSdk setLanguage:_extraInfo.language];
  }

  NSMutableDictionary<NSString *, id> *extrasDictionary = [[NSMutableDictionary alloc] init];
  if (_extraInfo.additionalParameters) {
    extrasDictionary = [_extraInfo.additionalParameters mutableCopy];
  }

  GADMAdapterInMobiMutableDictionarySetObjectForKey(extrasDictionary, @"tp", @"c_admob");
  NSString *versionString = [GADRequest sdkVersion];
  GADMAdapterInMobiMutableDictionarySetObjectForKey(extrasDictionary, @"tp-ver", versionString);

  NSNumber *childDirectedTreatment = [strongAdConfig childDirectedTreatment];
  if (childDirectedTreatment) {
    NSString *coppaString =
        (childDirectedTreatment.boolValue || [_extraInfo.additionalParameters[@"coppa"] boolValue])
            ? @"1"
            : @"0";
    GADMAdapterInMobiMutableDictionarySetObjectForKey(extrasDictionary, @"coppa", coppaString);
  }

  if (_rewardedAd) {
    if (_extraInfo.keywords != nil) [_rewardedAd setKeywords:_extraInfo.keywords];
    [_rewardedAd setExtras:[extrasDictionary copy]];
  }
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if ([_rewardedAd isReady]) {
    [_rewardedAd showFromViewController:viewController];
  }
}

#pragma mark IMInterstitialDelegate methods

- (void)interstitial:(IMInterstitial *)interstitial gotSignals:(NSData *)signals {
  NSString *signalsString = [[NSString alloc] initWithData:signals encoding:NSUTF8StringEncoding];
  _signalCompletionHandler(signalsString, nil);
}

- (void)interstitial:(IMInterstitial *)interstitial
    failedToGetSignalsWithError:(IMRequestStatus *)status {
  _signalCompletionHandler(nil, status);
}

- (void)interstitialDidFinishLoading:(IMInterstitial *)interstitial {
  _adEventDelegate = _renderCompletionHandler(self, nil);
}

- (void)interstitial:(IMInterstitial *)interstitial
    didFailToLoadWithError:(IMRequestStatus *)error {
  NSInteger errorCode = GADMAdapterInMobiAdMobErrorCodeForInMobiCode([error code]);
  NSString *errorDesc = [error localizedDescription];
  NSDictionary *errorInfo =
      [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
  GADRequestError *requestError = [GADRequestError errorWithDomain:kGADMAdapterInMobiErrorDomain
                                                              code:errorCode
                                                          userInfo:errorInfo];
  GADMAdapterInMobiDelegateManager *delegateManager =
      GADMAdapterInMobiDelegateManager.sharedInstance;
  [delegateManager removeDelegateForPlacementIdentifier:_placementIdentifier];
  _renderCompletionHandler(nil, requestError);
}

- (void)interstitialWillPresent:(IMInterstitial *)interstitial {
  [_adEventDelegate willPresentFullScreenView];
}

- (void)interstitialDidPresent:(IMInterstitial *)interstitial {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  if (strongDelegate) {
    [strongDelegate reportImpression];
    [strongDelegate didStartVideo];
  }
}

- (void)interstitial:(IMInterstitial *)interstitial
    didFailToPresentWithError:(IMRequestStatus *)error {
  NSInteger errorCode = GADMAdapterInMobiAdMobErrorCodeForInMobiCode([error code]);
  NSString *errorDesc = [error localizedDescription];
  GADRequestError *reqError =
      [GADRequestError errorWithDomain:kGADMAdapterInMobiErrorDomain
                                  code:errorCode
                              userInfo:@{NSLocalizedDescriptionKey : errorDesc ?: @""}];
  GADMAdapterInMobiDelegateManager *delegateManager =
      GADMAdapterInMobiDelegateManager.sharedInstance;
  [delegateManager removeDelegateForPlacementIdentifier:_placementIdentifier];
  [_adEventDelegate didFailToPresentWithError:reqError];
}

- (void)interstitialWillDismiss:(IMInterstitial *)interstitial {
  [_adEventDelegate willDismissFullScreenView];
}

- (void)interstitialDidDismiss:(IMInterstitial *)interstitial {
  GADMAdapterInMobiDelegateManager *delegateManager =
      GADMAdapterInMobiDelegateManager.sharedInstance;
  [delegateManager removeDelegateForPlacementIdentifier:_placementIdentifier];
  [_adEventDelegate didDismissFullScreenView];
}

- (void)interstitial:(IMInterstitial *)interstitial didInteractWithParams:(NSDictionary *)params {
  [_adEventDelegate reportClick];
}

- (void)interstitialDidReceiveAd:(IMInterstitial *)interstitial {
  // No equivalent callback in the Google Mobile Ads SDK.
  // This event indicates that InMobi fetched an ad from the server, but hasn't loaded it yet.
}

- (void)interstitial:(IMInterstitial *)interstitial
    rewardActionCompletedWithRewards:(nonnull NSDictionary *)rewards {
  id<GADMediationRewardedAdEventDelegate> strongAdEventDelegate = _adEventDelegate;
  NSString *key = rewards.allKeys.firstObject;
  if (key) {
    GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:key rewardAmount:rewards[key]];
    [strongAdEventDelegate didRewardUserWithReward:reward];
  }

  [strongAdEventDelegate didEndVideo];
}

@end
