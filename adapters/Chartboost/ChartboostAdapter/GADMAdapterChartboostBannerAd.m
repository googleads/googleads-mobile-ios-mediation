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

#import "GADMAdapterChartboostBannerAd.h"

#if __has_include(<Chartboost/Chartboost+Mediation.h>)
#import <Chartboost/Chartboost+Mediation.h>
#else
#import "Chartboost+Mediation.h"
#endif

#import "GADMAdapterChartboostConstants.h"
#import "GADMAdapterChartboostUtils.h"
#import "GADMChartboostError.h"
#import "GADMChartboostExtras.h"

@interface GADMAdapterChartboostBannerAd () <CHBBannerDelegate>
@end

@implementation GADMAdapterChartboostBannerAd {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// Chartboost banner ad object.
  CHBBanner *_bannerAd;
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

- (void)getBannerWithSize:(GADAdSize)adSize {
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

  // Convert requested size to Chartboost Ad Size.
  NSError *error = nil;
  CHBBannerSize chartboostAdSize = GADMAdapterChartboostBannerSizeFromAdSize(adSize, &error);
  if (error) {
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  NSString *adLocation = GADMAdapterChartboostLocationFromConnector(strongConnector);
  GADMAdapterChartboostBannerAd *__weak weakSelf = self;
  [Chartboost startWithAppId:appID
                appSignature:appSignature
                  completion:^(BOOL success) {
                    // Chartboost's CHBBanner is a UIView subclass so it is safer to use it on the
                    // main thread.
                    dispatch_async(dispatch_get_main_queue(), ^{
                      GADMAdapterChartboostBannerAd *strongSelf = weakSelf;
                      if (!strongSelf || !strongConnector) {
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
                        [Chartboost setFramework:extras.framework
                                     withVersion:extras.frameworkVersion];
                      }

                      CHBMediation *mediation = GADMAdapterChartboostMediation();
                      strongSelf->_bannerAd = [[CHBBanner alloc] initWithSize:chartboostAdSize
                                                                     location:adLocation
                                                                    mediation:mediation
                                                                     delegate:strongSelf];
                      strongSelf->_bannerAd.automaticallyRefreshesContent = NO;
                      [strongSelf->_bannerAd cache];
                    });
                  }];
}

#pragma mark - CHBBannerDelegate methods

- (void)didCacheAd:(nonnull CHBCacheEvent *)event error:(nullable CHBCacheError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (!strongConnector || !strongAdapter) {
    return;
  }

  if (error) {
    NSError *loadError = GADMChartboostErrorForCHBCacheError(error);
    NSLog(@"Failed to load banner ad from Chartboost: %@", loadError.localizedDescription);
    [strongConnector adapter:strongAdapter didFailAd:loadError];
    return;
  }

  UIViewController *viewController = [strongConnector viewControllerForPresentingModalView];
  [_bannerAd showFromViewController:viewController];
  [strongConnector adapter:strongAdapter didReceiveAdView:_bannerAd];
}

- (void)didShowAd:(nonnull CHBShowEvent *)event error:(nullable CHBShowError *)error {
  if (error) {
    NSError *showError = GADMChartboostErrorForCHBShowError(error);
    NSLog(@"An error occurred when showing the Chartboost banner ad: %@",
          showError.localizedDescription);
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
    NSLog(@"An error occurred when clicking the Chartboost banner ad: %@",
          clickError.localizedDescription);
    return;
  }
  [strongConnector adapterWillLeaveApplication:strongAdapter];
}

- (void)didFinishHandlingClick:(nonnull CHBClickEvent *)event
                         error:(nullable CHBClickError *)error {
  if (error) {
    NSError *clickError = GADMChartboostErrorForCHBClickError(error);
    NSLog(@"An error occurred when the Chartboost banner ad was clicked: %@",
          clickError.localizedDescription);
  }
}

@end
