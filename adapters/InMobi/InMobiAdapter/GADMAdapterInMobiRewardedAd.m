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
#import "GADMAdapterInMobiUtils.h"
#import "GADMInMobiConsent.h"
#import "GADMediationAdapterInMobi.h"

@interface GADMAdapterInMobiRewardedAd () <IMInterstitialDelegate>

@property(nonatomic, weak) GADMediationRewardedAdConfiguration *adConfig;
@property(nonatomic, copy) GADMediationRewardedLoadCompletionHandler renderCompletionHandler;
@property(nonatomic, copy) GADRTBSignalCompletionHandler signalCompletionHandler;
@property(nonatomic, weak) id<GADMediationRewardedAdEventDelegate> adEventDelegate;
@property(nonatomic, strong) IMInterstitial *rewardedAd;
@property(nonatomic) NSNumber *placementId;
@property(nonatomic, strong) GADInMobiExtras *extraInfo;

@end

@implementation GADMAdapterInMobiRewardedAd

static NSMapTable<NSNumber *, id<IMInterstitialDelegate>> *rewardedAdapterDelegates;

+ (void)load {
  rewardedAdapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                   valueOptions:NSPointerFunctionsWeakMemory];
}

- (instancetype)initWithPlacementId:(long long)placementID {
  _placementId = @(placementID);
  if (!placementID) {
    return nil;
  }
  _rewardedAd = [[IMInterstitial alloc] initWithPlacementId:placementID];
  [self prepareRequestParameters];
  _rewardedAd.delegate = self;
  return self;
}

- (void)collectIMSignalsWithGACompletionHandler:
    (nonnull GADRTBSignalCompletionHandler)completionHandler {
  GADMAdapterInMobiMutableSetSafeGADRTBSignalCompletionHandler(_signalCompletionHandler,
                                                               completionHandler);
  [_rewardedAd getSignals];
}

- (BOOL)isPlacementAlreadyRequested {
  @synchronized(rewardedAdapterDelegates) {
    if ([rewardedAdapterDelegates objectForKey:_placementId]) {
      return NO;
    } else {
      [rewardedAdapterDelegates setObject:self forKey:_placementId];
      return YES;
    }
  }
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
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

  long long placement =
      [adConfiguration.credentials.settings[kGADMAdapterInMobiPlacementID] longLongValue];
  _placementId = @(placement);

  if ([self isPlacementAlreadyRequested]) {
    NSString *errorDesc = [NSString
        stringWithFormat:@"[InMobi] Error - cannot request multiple ads using same placement ID."];
    NSDictionary *errorInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
    GADRequestError *error = [GADRequestError errorWithDomain:kGADMAdapterInMobiErrorDomain
                                                         code:kGADErrorInvalidRequest
                                                     userInfo:errorInfo];
    completionHandler(nil, error);
    return;
  }

  if (adConfiguration.isTestRequest) {
    NSLog(@"[InMobi] Please enter your device ID in the InMobi console to receive test ads from "
          @"Inmobi");
  }
  [self prepareRequestParameters];
  if (adConfiguration.bidResponse) {
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

  if (_extraInfo != nil) {
    if (_extraInfo.postalCode != nil) [IMSdk setPostalCode:_extraInfo.postalCode];
    if (_extraInfo.areaCode != nil) [IMSdk setAreaCode:_extraInfo.areaCode];
    if (_extraInfo.interests != nil) [IMSdk setInterests:_extraInfo.interests];
    if (_extraInfo.age) [IMSdk setAge:_extraInfo.age];
    if (_extraInfo.yearOfBirth) [IMSdk setYearOfBirth:_extraInfo.yearOfBirth];
    if (_extraInfo.city && _extraInfo.state && _extraInfo.country) {
      [IMSdk setLocationWithCity:_extraInfo.city state:_extraInfo.state country:_extraInfo.country];
    }
    if (_extraInfo.language != nil) [IMSdk setLanguage:_extraInfo.language];
  }

  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  if (_extraInfo && _extraInfo.additionalParameters) {
    dict = [NSMutableDictionary dictionaryWithDictionary:_extraInfo.additionalParameters];
  }

  dict[@"tp"] = @"c_admob";
  dict[@"tp-ver"] = [GADRequest sdkVersion];

  if ([[strongAdConfig childDirectedTreatment] integerValue] == 1) {
    dict[@"coppa"] = @"1";
  } else {
    dict[@"coppa"] = @"0";
  }

  if (_rewardedAd) {
    if (_extraInfo.keywords != nil) [_rewardedAd setKeywords:_extraInfo.keywords];
    [_rewardedAd setExtras:[NSDictionary dictionaryWithDictionary:dict]];
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
  GADRequestError *reqError = [GADRequestError errorWithDomain:kGADMAdapterInMobiErrorDomain
                                                          code:errorCode
                                                      userInfo:errorInfo];
  @synchronized(rewardedAdapterDelegates) {
    [rewardedAdapterDelegates removeObjectForKey:_placementId];
  }
  _renderCompletionHandler(nil, reqError);
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
  @synchronized(rewardedAdapterDelegates) {
    [rewardedAdapterDelegates removeObjectForKey:_placementId];
  }
  [_adEventDelegate didFailToPresentWithError:reqError];
}

- (void)interstitialWillDismiss:(IMInterstitial *)interstitial {
  [_adEventDelegate willDismissFullScreenView];
}

- (void)interstitialDidDismiss:(IMInterstitial *)interstitial {
  @synchronized(rewardedAdapterDelegates) {
    [rewardedAdapterDelegates removeObjectForKey:_placementId];
  }
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
    rewardActionCompletedWithRewards:(NSDictionary *)rewards {
  id<GADMediationRewardedAdEventDelegate> strongAdEventDelegate = _adEventDelegate;
  NSString *key = [rewards allKeys][0];
  GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:key
                                                   rewardAmount:[rewards objectForKey:key]];
  [strongAdEventDelegate didEndVideo];
  [strongAdEventDelegate didRewardUserWithReward:reward];
}

@end
