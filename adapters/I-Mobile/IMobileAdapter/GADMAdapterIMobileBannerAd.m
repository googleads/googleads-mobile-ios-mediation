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

#import "GADMAdapterIMobileBannerAd.h"

#import <ImobileSdkAds/ImobileSdkAds.h>

#import <stdatomic.h>

#import "GADMAdapterIMobileConstants.h"
#import "GADMAdapterIMobileUtils.h"
#import "GADMediationAdapterIMobile.h"

@interface GADMAdapterIMobileBannerAd () <GADMediationBannerAd, IMobileSdkAdsDelegate>
@end

@implementation GADMAdapterIMobileBannerAd {
  /// Ad configuration for the ad to be loaded.
  GADMediationBannerAdConfiguration *_adConfiguration;

  /// The completion handler to call when an ad loads successfully or fails.
  GADMediationBannerLoadCompletionHandler _loadCompletionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  /// Intentionally keeping a reference to the delegate because this delegate is returned from the
  /// GMA SDK, not set on the GMA SDK.
  id<GADMediationBannerAdEventDelegate> _delegate;

  /// View to display the i-mobile banner ad.
  UIView *_imobileAdView;
}

- (nonnull instancetype)initWithAdConfiguration:
    (nonnull GADMediationBannerAdConfiguration *)adConfiguration {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)loadBannerAdWithCompletionHandler:
    (nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
  __block atomic_flag adLoadHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationBannerLoadCompletionHandler originalAdLoadHandler = [completionHandler copy];

  // Ensure the original completion handler is only called once, and is deallocated once called.
  _loadCompletionHandler =
      ^id<GADMediationBannerAdEventDelegate>(id<GADMediationBannerAd> bannerAd, NSError *error) {
    if (atomic_flag_test_and_set(&adLoadHandlerCalled)) {
      return nil;
    }

    id<GADMediationBannerAdEventDelegate> delegate = nil;
    if (originalAdLoadHandler) {
      delegate = originalAdLoadHandler(bannerAd, error);
    }

    originalAdLoadHandler = nil;
    return delegate;
  };

  // Create view to display ads.
  GADAdSize iMobileAdSize = GADMAdapterIMobileAdSizeFromGADAdSize(_adConfiguration.adSize);
  if (!IsGADAdSizeValid(iMobileAdSize)) {
    NSString *errorMessage =
        [NSString stringWithFormat:@"Invalid size for i-mobile adapter. Size: %@",
                                   NSStringFromGADAdSize(_adConfiguration.adSize)];
    GADMAdapterIMobileLog(@"%@", errorMessage);
    NSError *error = GADMAdapterIMobileErrorWithCodeAndDescription(
        GADMAdapterIMobileErrorBannerSizeMismatch, errorMessage);
    _loadCompletionHandler(nil, error);
    return;
  }

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

  NSString *spotID = _adConfiguration.credentials.settings[GADMAdapterIMobileSpotIdKey];
  if (!spotID.length) {
    NSString *errorMessage = @"Missing or invalid Spot ID.";
    GADMAdapterIMobileLog(@"%@", errorMessage);
    NSError *error = GADMAdapterIMobileErrorWithCodeAndDescription(
        GADMAdapterIMobileErrorInvalidServerParameters, errorMessage);
    _loadCompletionHandler(nil, error);
    return;
  }

  GADMAdapterIMobileLog(@"Requesting banner ad of size: %@, Spot ID: %@.",
                        NSStringFromGADAdSize(_adConfiguration.adSize), spotID);

  // Call i-mobile SDK.
  [ImobileSdkAds registerWithPublisherID:publisherID MediaID:mediaID SpotID:spotID];
  [ImobileSdkAds setSpotDelegate:spotID delegate:self];
  [ImobileSdkAds startBySpotID:spotID];

  // Create view to display banner ads.
  float scaleRatio = 1.0f;
  if (iMobileAdSize.size.width == 320 &&
      (iMobileAdSize.size.height == 50 || iMobileAdSize.size.height == 100)) {
    scaleRatio = MIN((_adConfiguration.adSize.size.width / iMobileAdSize.size.width),
                     (_adConfiguration.adSize.size.height / iMobileAdSize.size.height));
  }
  _imobileAdView =
      [[UIView alloc] initWithFrame:CGRectMake(0, 0, iMobileAdSize.size.width * scaleRatio,
                                               iMobileAdSize.size.height * scaleRatio)];
  [ImobileSdkAds showBySpotIDForAdMobMediation:spotID View:_imobileAdView Ratio:scaleRatio];
}

#pragma mark - GADMediationBannerAd

- (UIView *)view {
  return _imobileAdView;
}

#pragma mark - IMobileSdkAdsDelegate

- (void)imobileSdkAdsSpot:(NSString *)spotId didReadyWithValue:(ImobileSdkAdsReadyResult)value {
  _delegate = _loadCompletionHandler(self, nil);
}

- (void)imobileSdkAdsSpot:(NSString *)spotId didFailWithValue:(ImobileSdkAdsFailResult)value {
  _imobileAdView = nil;

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

- (void)imobileSdkAdsSpotDidShow:(NSString *)spotId {
  [_delegate reportImpression];
}

@end
