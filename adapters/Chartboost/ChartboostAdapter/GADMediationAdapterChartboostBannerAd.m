// Copyright 2023 Google LLC.
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

#import "GADMediationAdapterChartboostBannerAd.h"

#if __has_include(<ChartboostSDK/ChartboostSDK.h>)
#import <ChartboostSDK/ChartboostSDK.h>
#else
#import "ChartboostSDK.h"
#endif

#include <stdatomic.h>

#import "GADMAdapterChartboostConstants.h"
#import "GADMAdapterChartboostUtils.h"
#import "GADMChartboostError.h"

@interface GADMediationAdapterChartboostBannerAd () <CHBBannerDelegate>
@end

@implementation GADMediationAdapterChartboostBannerAd {
  /// The banner ad configuration.
  GADMediationBannerAdConfiguration *_adConfig;

  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationBannerLoadCompletionHandler _completionHandler;

  /// An ad event delegate to invoke when ad rendering events occur.
  id<GADMediationBannerAdEventDelegate> _adEventDelegate;

  /// Chartboost banner ad object
  CHBBanner *_banner;
}

- (nonnull instancetype)initWithAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                              completionHandler:
                                  (GADMediationBannerLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adConfig = adConfiguration;

    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationBannerLoadCompletionHandler originalCompletionHandler =
        [completionHandler copy];
    _completionHandler =
        ^id<GADMediationBannerAdEventDelegate>(id<GADMediationBannerAd> bannerAd, NSError *error) {
      if (atomic_flag_test_and_set(&completionHandlerCalled)) {
        return nil;
      }
      id<GADMediationBannerAdEventDelegate> delegate = nil;
      if (originalCompletionHandler) {
        delegate = originalCompletionHandler(bannerAd, error);
      }
      originalCompletionHandler = nil;
      return delegate;
    };
  }
  return self;
}

- (void)loadBannerAd {
  NSString *appID = [_adConfig.credentials.settings[GADMAdapterChartboostAppID]
      stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
  NSString *appSignature = [_adConfig.credentials.settings[GADMAdapterChartboostAppSignature]
      stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];

  if (!appID.length || !appSignature.length) {
    NSError *error = GADMAdapterChartboostErrorWithCodeAndDescription(
        GADMAdapterChartboostErrorInvalidServerParameters,
        @"App ID and/or App Signature cannot be nil.");
    _completionHandler(nil, error);
    return;
  }

  if (SYSTEM_VERSION_LESS_THAN(GADMAdapterChartboostMinimumOSVersion)) {
    NSString *logMessage = [NSString
        stringWithFormat:
            @"Chartboost minimum supported OS version is iOS %@. Requested action is a no-op.",
            GADMAdapterChartboostMinimumOSVersion];
    NSError *error = GADMAdapterChartboostErrorWithCodeAndDescription(
        GADMAdapterChartboostErrorMinimumOSVersion, logMessage);
    _completionHandler(nil, error);
    return;
  }

  // Convert requested size to Chartboost Ad Size.
  NSError *error = nil;
  CHBBannerSize chartboostAdSize =
      GADMAdapterChartboostBannerSizeFromAdSize(_adConfig.adSize, &error);
  if (error) {
    _completionHandler(nil, error);
    return;
  }

  NSString *adLocation = GADMAdapterChartboostLocationFromAdConfiguration(_adConfig);
  GADMediationAdapterChartboostBannerAd *weakSelf = self;
  [Chartboost startWithAppID:appID
                appSignature:appSignature
                  completion:^(CHBStartError *cbError) {
                    GADMediationAdapterChartboostBannerAd *strongSelf = weakSelf;
                    if (!strongSelf) {
                      return;
                    }

                    if (cbError) {
                      NSLog(@"Failed to initialize Chartboost SDK: %@", cbError);
                      strongSelf->_completionHandler(nil, cbError);
                      return;
                    }

                    CHBMediation *mediation = GADMAdapterChartboostMediation();
                    strongSelf->_banner = [[CHBBanner alloc] initWithSize:chartboostAdSize
                                                                 location:adLocation
                                                                mediation:mediation
                                                                 delegate:strongSelf];
                    [strongSelf->_banner cache];
                  }];
}

#pragma mark - GADMediationBannerAd Methods

- (nonnull UIView *)view {
  return _banner;
}

#pragma mark - CHBBannerDelegate Methods

- (void)didCacheAd:(CHBCacheEvent *)event error:(nullable CHBCacheError *)error {
  if (error) {
    NSError *loadError = GADMChartboostErrorForCHBCacheError(error);
    NSLog(@"Failed to load banner ad from Chartboost: %@", loadError.localizedDescription);
    _completionHandler(nil, loadError);
    return;
  }

  [_banner showFromViewController:_adConfig.topViewController];
  _adEventDelegate = _completionHandler(self, nil);
}

- (void)didShowAd:(CHBShowEvent *)event error:(nullable CHBShowError *)error {
  if (error) {
    NSError *showError = GADMChartboostErrorForCHBShowError(error);
    NSLog(@"Failed to show banner ad from Chartboost: %@", showError.localizedDescription);

    [_adEventDelegate didFailToPresentWithError:showError];
    return;
  }
}

- (void)didClickAd:(CHBClickEvent *)event error:(CHBClickError *)error {
  [_adEventDelegate reportClick];
  if (error) {
    NSError *clickError = GADMChartboostErrorForCHBClickError(error);
    NSLog(@"An error occurred when clicking the Chartboost banner ad: %@",
          clickError.localizedDescription);
  }
}

- (void)didRecordImpression:(CHBImpressionEvent *)event {
  [_adEventDelegate reportImpression];
}

@end
