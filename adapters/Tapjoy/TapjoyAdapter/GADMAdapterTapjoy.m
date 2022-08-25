// Copyright 2016-2019 Google LLC
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

#import "GADMAdapterTapjoy.h"

#import <Tapjoy/Tapjoy.h>

#import "GADMAdapterTapjoyConstants.h"
#import "GADMAdapterTapjoyDelegate.h"
#import "GADMAdapterTapjoySingleton.h"
#import "GADMAdapterTapjoyUtils.h"
#import "GADMTapjoyExtras.h"
#import "GADMediationAdapterTapjoy.h"

@interface GADMAdapterTapjoy () <GADMAdapterTapjoyDelegate>
@end

@implementation GADMAdapterTapjoy {
  /// Google Mobile Ads SDK ad network connector.
  __weak id<GADMAdNetworkConnector> _interstitialConnector;

  /// Tapjoy placement.
  TJPlacement *_intPlacement;

  /// Tapjoy placement name.
  NSString *_placementName;
}

+ (nonnull NSString *)adapterVersion {
  return GADMAdapterTapjoyVersion;
}

+ (nonnull Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMTapjoyExtras class];
}

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterTapjoy class];
}

#pragma mark - Interstitial

- (nullable instancetype)initWithGADMAdNetworkConnector:
    (nonnull id<GADMAdNetworkConnector>)connector {
  if (!connector) {
    return nil;
  }
  self = [super init];
  if (self) {
    _interstitialConnector = connector;
  }
  return self;
}

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
  NSString *sdkKey = strongConnector.credentials[GADMAdapterTapjoySdkKey];
  _placementName = strongConnector.credentials[GADMAdapterTapjoyPlacementKey];

  if (!sdkKey.length || !_placementName.length) {
    NSError *adapterError = GADMAdapterTapjoyErrorWithCodeAndDescription(
        GADMAdapterTapjoyErrorInvalidServerParameters,
        @"Did not receive valid Tapjoy server parameters.");
    [strongConnector adapter:self didFailAd:adapterError];
    return;
  }

  GADMTapjoyExtras *extras = [strongConnector networkExtras];
  GADMAdapterTapjoySingleton *sharedInstance = [GADMAdapterTapjoySingleton sharedInstance];

  if ([Tapjoy isConnected]) {
    [Tapjoy setDebugEnabled:extras.debugEnabled];
    _intPlacement = [sharedInstance requestAdForPlacementName:_placementName delegate:self];
    return;
  }

  // Tapjoy is not yet connected. Wait for initialization to complete before requesting a placement.
  NSDictionary<NSString *, NSNumber *> *connectOptions =
      @{TJC_OPTION_ENABLE_LOGGING : @(extras.debugEnabled)};
  GADMAdapterTapjoy __weak *weakSelf = self;
  [sharedInstance initializeTapjoySDKWithSDKKey:sdkKey
                                        options:connectOptions
                              completionHandler:^(NSError *error) {
                                GADMAdapterTapjoy __strong *strongSelf = weakSelf;
                                if (!strongSelf) {
                                  return;
                                }

                                if (error) {
                                  [strongSelf->_interstitialConnector adapter:self didFailAd:error];
                                  return;
                                }
                                strongSelf->_intPlacement =
                                    [[GADMAdapterTapjoySingleton sharedInstance]
                                        requestAdForPlacementName:strongSelf->_placementName
                                                         delegate:strongSelf];
                              }];
}

- (void)presentInterstitialFromRootViewController:(nonnull UIViewController *)rootViewController {
  [_intPlacement showContentWithViewController:rootViewController];
}

- (void)stopBeingDelegate {
  _intPlacement.delegate = nil;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  NSError *adapterError = GADMAdapterTapjoyErrorWithCodeAndDescription(
      GADMAdapterTapjoyErrorAdFormatNotSupported, @"This adapter doesn't support banner ads.");
  [_interstitialConnector adapter:self didFailAd:adapterError];
}

#pragma mark - TJPlacementDelegate methods

- (void)requestDidSucceed:(nonnull TJPlacement *)placement {
  // If the placement's content is not available at this time, then the request is considered a
  // failure.
  if (!placement.contentAvailable) {
    NSError *loadError = GADMAdapterTapjoyErrorWithCodeAndDescription(
        GADMAdapterTapjoyErrorPlacementContentNotAvailable, @"Ad not available.");
    [_interstitialConnector adapter:self didFailAd:loadError];
  }
}

- (void)requestDidFail:(nonnull TJPlacement *)placement error:(nullable NSError *)error {
  if (!error) {
    NSError *nullError = GADMAdapterTapjoyErrorWithCodeAndDescription(
        GADMAdapterTapjoyErrorUnknown, @"Tapjoy SDK placement unknown error.");
    [_interstitialConnector adapter:self didFailAd:nullError];
    return;
  }
  [_interstitialConnector adapter:self didFailAd:error];
}

- (void)contentIsReady:(nonnull TJPlacement *)placement {
  [_interstitialConnector adapterDidReceiveInterstitial:self];
}

- (void)contentDidAppear:(nonnull TJPlacement *)placement {
  [_interstitialConnector adapterWillPresentInterstitial:self];
}

- (void)didClick:(nonnull TJPlacement *)placement {
  id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
  if (!strongConnector) {
    return;
  }

  [strongConnector adapterDidGetAdClick:self];
  [strongConnector adapterWillLeaveApplication:self];
}

- (void)contentDidDisappear:(nonnull TJPlacement *)placement {
  id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
  if (!strongConnector) {
    return;
  }

  [strongConnector adapterWillDismissInterstitial:self];
  [strongConnector adapterDidDismissInterstitial:self];
}

#pragma mark - TJPlacementVideoDelegate methods

- (void)videoDidStart:(nonnull TJPlacement *)placement {
  // Do nothing.
}

- (void)videoDidComplete:(nonnull TJPlacement *)placement {
  // Do nothing.
}

- (void)videoDidFail:(nonnull TJPlacement *)placement error:(nullable NSString *)errorMsg {
  // Do nothing.
}

#pragma mark - GADMAdapterTapjoyDelegate

- (void)didFailToLoadWithError:(nonnull NSError *)error {
  [_interstitialConnector adapter:self didFailAd:error];
}

@end
