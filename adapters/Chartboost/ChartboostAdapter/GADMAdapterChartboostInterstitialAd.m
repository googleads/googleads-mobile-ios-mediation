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

#import <Chartboost/Chartboost+Mediation.h>

#import "GADMAdapterChartboostSingleton.h"
#import "GADMAdapterChartboostUtils.h"
#import "GADMChartboostError.h"

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

  GADMAdapterChartboostSingleton *sharedInstance = GADMAdapterChartboostSingleton.sharedInstance;
  GADMAdapterChartboostInterstitialAd *__weak weakSelf = self;
  [sharedInstance startWithNetworkConnector:strongConnector
                          completionHandler:^(NSError *_Nullable error) {
                 GADMAdapterChartboostInterstitialAd *strongSelf = weakSelf;
                 if (!strongSelf) {
                   return;
                 }

                 if (error) {
                   NSLog(@"Failed to load interstitial ad from Chartboost: %@", error.localizedDescription);
                   [strongConnector adapter:strongAdapter didFailAd:error];
                   return;
                 }

                 CHBMediation *mediation = GADMAdapterChartboostMediation();
                 NSString *adLocation = GADMAdapterChartboostAdLocationFromConnector(strongConnector);
                 strongSelf->_interstitialAd =
                     [[CHBInterstitial alloc] initWithLocation:adLocation
                                                     mediation:mediation
                                                      delegate:strongSelf];
                 [strongSelf->_interstitialAd cache];
               }];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
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
    NSError *loadError = NSErrorForCHBCacheError(error);
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
    NSError *showError = NSErrorForCHBShowError(error);
    NSLog(@"Failed to show interstitial ad from Chartboost: %@", showError.localizedDescription);
    [strongConnector adapterWillDismissInterstitial:strongAdapter];
    [strongConnector adapterDidDismissInterstitial:strongAdapter];
    return;
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
    NSError *clickError = NSErrorForCHBClickError(error);
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
