// Copyright 2020 Google LLC.
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

#import "GADMAdapterChartboostInterstitialAd.h"

#if __has_include(<Chartboost/Chartboost+Mediation.h>)
#import <Chartboost/Chartboost+Mediation.h>
#else
#import "Chartboost+Mediation.h"
#endif

#import "GADMAdapterChartboostConstants.h"
#import "GADMAdapterChartboostUtils.h"
#import "GADMChartboostError.h"
#import "GADMChartboostExtras.h"

@interface GADMAdapterChartboostInterstitialAd () <CHBInterstitialDelegate>

@end

@implementation GADMAdapterChartboostInterstitialAd {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// Chartboost interstitial ad object.
  CHBInterstitial *_interstitialAd;
}

- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                               adapter:(nonnull id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _adapter = adapter;
    _connector = connector;
  }
  return self;
}

- (void)loadInterstitialAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (!strongConnector || !strongAdapter) {
    return;
  }

  if (SYSTEM_VERSION_LESS_THAN(GADMAdapterChartboostMinimumOSVersion)) {
    NSString *logMessage = [NSString
        stringWithFormat:
            @"Chartboost minimum supported OS version is iOS %@. Requested action is a no-op.",
            GADMAdapterChartboostMinimumOSVersion];
    NSError *error = GADMAdapterChartboostErrorWithCodeAndDescription(
        GADMAdapterChartboostErrorMinimumOSVersion, logMessage);
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  NSString *appID = [strongConnector.credentials[GADMAdapterChartboostAppID]
      stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
  NSString *appSignature = [strongConnector.credentials[GADMAdapterChartboostAppSignature]
      stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];

  if (!appID.length || !appSignature.length) {
    NSError *error = GADMAdapterChartboostErrorWithCodeAndDescription(
        GADMAdapterChartboostErrorInvalidServerParameters,
        @"App ID and/or App Signature cannot be nil.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  NSString *adLocation = GADMAdapterChartboostLocationFromConnector(strongConnector);
  GADMAdapterChartboostInterstitialAd *__weak weakSelf = self;
  [Chartboost
      startWithAppId:appID
        appSignature:appSignature
          completion:^(BOOL success) {
            GADMAdapterChartboostInterstitialAd *strongSelf = weakSelf;
            if (!strongSelf) {
              return;
            }

            if (!success) {
              NSError *error = GADMAdapterChartboostErrorWithCodeAndDescription(
                  GADMAdapterChartboostErrorInitializationFailure,
                  @"Failed to initialize Chartboost SDK.");
              [strongConnector adapter:strongAdapter didFailAd:error];
              return;
            }

            GADMChartboostExtras *extras = [strongConnector networkExtras];
            if (extras) {
              [Chartboost setFramework:extras.framework withVersion:extras.frameworkVersion];
            }

            CHBMediation *mediation = GADMAdapterChartboostMediation();
            strongSelf->_interstitialAd = [[CHBInterstitial alloc] initWithLocation:adLocation
                                                                          mediation:mediation
                                                                           delegate:strongSelf];
            [strongSelf->_interstitialAd cache];
          }];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  if (!_interstitialAd.isCached) {
    NSLog(@"Failed to show interstitial ad from Chartboost: Interstitial ad not cached.");
    id<GADMAdNetworkConnector> strongConnector = _connector;
    id<GADMAdNetworkAdapter> strongAdapter = _adapter;
    if (strongConnector && strongAdapter) {
      [strongConnector adapterWillPresentInterstitial:strongAdapter];
      [strongConnector adapterWillDismissInterstitial:strongAdapter];
      [strongConnector adapterDidDismissInterstitial:strongAdapter];
    }
    return;
  }
  [_interstitialAd showFromViewController:rootViewController];
}

#pragma mark - CHBInterstitialDelegate Methods

- (void)didCacheAd:(CHBCacheEvent *)event error:(CHBCacheError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (!strongConnector || !strongAdapter) {
    return;
  }

  if (error) {
    NSError *loadError = GADMChartboostErrorForCHBCacheError(error);
    NSLog(@"Failed to load interstitial ad from Chartboost: %@", loadError.localizedDescription);
    [strongConnector adapter:strongAdapter didFailAd:loadError];
    return;
  }

  [strongConnector adapterDidReceiveInterstitial:strongAdapter];
}

- (void)didShowAd:(CHBShowEvent *)event error:(nullable CHBShowError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (!strongConnector || !strongAdapter) {
    return;
  }

  [strongConnector adapterWillPresentInterstitial:strongAdapter];

  if (error) {
    NSError *showError = GADMChartboostErrorForCHBShowError(error);
    NSLog(@"Failed to show interstitial ad from Chartboost: %@", showError.localizedDescription);

    // If the ad has been shown, Chartboost will proceed to dismiss it and the rest is handled in
    // -didDismissAd:
    [strongConnector adapterWillDismissInterstitial:strongAdapter];
    [strongConnector adapterDidDismissInterstitial:strongAdapter];
  }
}

- (void)didClickAd:(nonnull CHBClickEvent *)event error:(nullable CHBClickError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (!strongConnector || !strongAdapter) {
    return;
  }

  [strongConnector adapterDidGetAdClick:strongAdapter];
  if (error) {
    NSError *clickError = GADMChartboostErrorForCHBClickError(error);
    NSLog(@"An error occurred when clicking the Chartboost interstitial ad: %@",
          clickError.localizedDescription);
    return;
  }
}

- (void)didDismissAd:(CHBDismissEvent *)event {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (!strongConnector || !strongAdapter) {
    return;
  }

  [strongConnector adapterWillDismissInterstitial:strongAdapter];
  [strongConnector adapterDidDismissInterstitial:strongAdapter];
}

@end
