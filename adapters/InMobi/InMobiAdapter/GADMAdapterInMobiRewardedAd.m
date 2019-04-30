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
#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMInMobiConsent.h"
#import "GADMediationAdapterInMobi.h"
#import "GADMAdapterInMobiUtils.h"
@import InMobiSDK;

@interface GADMAdapterInMobiRewardedAd () <IMInterstitialDelegate>

@property(nonatomic, weak) GADMediationRewardedAdConfiguration *adConfig;
@property(nonatomic, copy) GADMediationRewardedLoadCompletionHandler completionHandler;
@property(nonatomic, weak) id<GADMediationRewardedAdEventDelegate> adEventDelegate;
@property(nonatomic, strong) IMInterstitial *rewardedAd;
@property(nonatomic) long long placementId;
@property(nonatomic, strong) GADInMobiExtras *extraInfo;

@end

@implementation GADMAdapterInMobiRewardedAd

static NSMapTable *rewardedAdapterDelegates;

+ (void)load {
  rewardedAdapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                       valueOptions:NSPointerFunctionsWeakMemory];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  self.adConfig = adConfiguration;
  self.completionHandler = completionHandler;

  self.placementId =
      [adConfiguration.credentials.settings[kGADMAdapterInMobiPlacementID] longLongValue];

  if (!self.placementId) {
    NSString *errorDesc =
        [NSString stringWithFormat:@"[InMobi] Error - Placement ID not specified."];
    NSDictionary *errorInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
    GADRequestError *error = [GADRequestError errorWithDomain:kGADMAdapterInMobiErrorDomain
                                                         code:kGADErrorInvalidRequest
                                                     userInfo:errorInfo];
    completionHandler(nil, error);
    return;
  }

  @synchronized (rewardedAdapterDelegates) {
    if ([rewardedAdapterDelegates objectForKey:[NSNumber numberWithLong:self.placementId]]) {
      NSString *errorDesc =
      [NSString stringWithFormat:
       @"[InMobi] Error - cannot request multiple ads using same placement ID."];
      NSDictionary *errorInfo =
      [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
      GADRequestError *error = [GADRequestError errorWithDomain:kGADMAdapterInMobiErrorDomain
                                                           code:kGADErrorInvalidRequest
                                                       userInfo:errorInfo];
      completionHandler(nil, error);
      return;
    }
  }

  if (adConfiguration.isTestRequest) {
    NSLog(@"[InMobi] Please enter your device ID in the InMobi console to receive test ads from "
          @"Inmobi");
  }

  @synchronized (rewardedAdapterDelegates) {
    [rewardedAdapterDelegates setObject:self forKey:[NSNumber numberWithLong:self.placementId]];
  }

  self.rewardedAd = [[IMInterstitial alloc] initWithPlacementId:self.placementId];
  [self prepareRequestParameters];
  self.rewardedAd.delegate = self;
  [self.rewardedAd load];
}

- (void)prepareRequestParameters {
  GADMediationRewardedAdConfiguration *strongAdConfig = self.adConfig;

  if (strongAdConfig.extras) {
    self.extraInfo = [strongAdConfig extras];
  }

  if (self.extraInfo != nil) {
    if (self.extraInfo.postalCode != nil) [IMSdk setPostalCode:self.extraInfo.postalCode];
    if (self.extraInfo.areaCode != nil) [IMSdk setAreaCode:self.extraInfo.areaCode];
    if (self.extraInfo.interests != nil) [IMSdk setInterests:self.extraInfo.interests];
    if (self.extraInfo.age) [IMSdk setAge:self.extraInfo.age];
    if (self.extraInfo.yearOfBirth) [IMSdk setYearOfBirth:self.extraInfo.yearOfBirth];
    if (self.extraInfo.city && self.extraInfo.state && self.extraInfo.country) {
      [IMSdk setLocationWithCity:self.extraInfo.city
                           state:self.extraInfo.state
                         country:self.extraInfo.country];
    }
    if (self.extraInfo.language != nil) [IMSdk setLanguage:self.extraInfo.language];
  }

  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  if (self.extraInfo && self.extraInfo.additionalParameters) {
    dict = [NSMutableDictionary dictionaryWithDictionary:self.extraInfo.additionalParameters];
  }

  dict[@"tp"] = @"c_admob";
  dict[@"tp-ver"] = [GADRequest sdkVersion];

  if ([[strongAdConfig childDirectedTreatment] integerValue] == 1) {
    dict[@"coppa"] = @"1";
  } else {
    dict[@"coppa"] = @"0";
  }

  if (self.rewardedAd) {
    if (self.extraInfo.keywords != nil) [self.rewardedAd setKeywords:self.extraInfo.keywords];
    [self.rewardedAd setExtras:[NSDictionary dictionaryWithDictionary:dict]];
  }
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if ([self.rewardedAd isReady]) {
    [self.rewardedAd showFromViewController:viewController];
  }
}

#pragma mark IMAdInterstitialDelegate methods

- (void)interstitialDidFinishLoading:(IMInterstitial *)interstitial {
  self.adEventDelegate = self.completionHandler(self, nil);
}

- (void)interstitial:(IMInterstitial *)interstitial
    didFailToLoadWithError:(IMRequestStatus *)error {
  NSInteger errorCode = [GADMAdapterInMobiUtils getAdMobErrorCode:[error code]];
  NSString *errorDesc = [error localizedDescription];
  NSDictionary *errorInfo =
      [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
  GADRequestError *reqError = [GADRequestError errorWithDomain:kGADErrorDomain
                                                          code:errorCode
                                                      userInfo:errorInfo];
  @synchronized (rewardedAdapterDelegates) {
    [rewardedAdapterDelegates removeObjectForKey:[NSNumber numberWithLong:self.placementId]];
  }
  self.completionHandler(nil, reqError);
}

- (void)interstitialWillPresent:(IMInterstitial *)interstitial {
  [self.adEventDelegate willPresentFullScreenView];
}

- (void)interstitialDidPresent:(IMInterstitial *)interstitial {
  [self.adEventDelegate didStartVideo];
}

- (void)interstitial:(IMInterstitial *)interstitial
    didFailToPresentWithError:(IMRequestStatus *)error {
  NSInteger errorCode = [GADMAdapterInMobiUtils getAdMobErrorCode:[error code]];
  NSString *errorDesc = [error localizedDescription];
  NSDictionary *errorInfo =
      [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
  GADRequestError *reqError = [GADRequestError errorWithDomain:kGADErrorDomain
                                                          code:errorCode
                                                      userInfo:errorInfo];
  @synchronized (rewardedAdapterDelegates) {
    [rewardedAdapterDelegates removeObjectForKey:[NSNumber numberWithLong:self.placementId]];
  }
  [self.adEventDelegate didFailToPresentWithError:reqError];
}

- (void)interstitialWillDismiss:(IMInterstitial *)interstitial {
  [self.adEventDelegate willDismissFullScreenView];
}

- (void)interstitialDidDismiss:(IMInterstitial *)interstitial {
  @synchronized (rewardedAdapterDelegates) {
    [rewardedAdapterDelegates removeObjectForKey:[NSNumber numberWithLong:self.placementId]];
  }
  [self.adEventDelegate didDismissFullScreenView];
}

- (void)interstitial:(IMInterstitial *)interstitial didInteractWithParams:(NSDictionary *)params {
  [self.adEventDelegate reportClick];
}

- (void)interstitial:(IMInterstitial *)interstitial
    rewardActionCompletedWithRewards:(NSDictionary *)rewards {
  id<GADMediationRewardedAdEventDelegate> strongAdEventDelegate = self.adEventDelegate;
  NSString *key = [rewards allKeys][0];
  GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:key
                                                   rewardAmount:[rewards objectForKey:key]];
  [strongAdEventDelegate didEndVideo];
  [strongAdEventDelegate didRewardUserWithReward:reward];
}

- (void)interstitialDidReceiveAd:(IMInterstitial *)interstitial {
  // No equivalent callback in the Google Mobile Ads SDK.
  // This event indicates that InMobi fetched an ad from the server, but hasn't loaded it yet.
}

@end
