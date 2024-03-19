// Copyright 2024 Google LLC
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

#import "GADMediationVungleAppOpenAd.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"

@interface GADMediationVungleAppOpenAd () <GADMAdapterVungleDelegate, VungleInterstitialDelegate>
@end

@implementation GADMediationVungleAppOpenAd {
  /// The completion handler to call when ad loading succeeds or fails.
  GADMediationAppOpenLoadCompletionHandler _loadCompletionHandler;

  /// Indicates whether the load completion handler was called or not.
  BOOL _isLoadCompletionHandlerCalled;

  /// Banner ad configuration of the ad request.
  GADMediationAppOpenAdConfiguration *_adConfiguration;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  id<GADMediationAppOpenAdEventDelegate> _adEventDelegate;

  /// Liftoff Monetize app open ad instance. Note: Liftoff uses VungleInterstitial for displaying
  /// app open ads.
  VungleInterstitial *_appOpenAd;
}

@synthesize desiredPlacement;

#pragma mark - GADMediationVungleAppOpenAd Methods

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationAppOpenAdConfiguration *)adConfiguration
      loadCompletionHandler:
          (nonnull GADMediationAppOpenLoadCompletionHandler)loadCompletionHandler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    _isLoadCompletionHandlerCalled = NO;
    _loadCompletionHandler = [loadCompletionHandler copy];
  }
  return self;
}

- (void)requestAppOpenAd {
  NSString *appId = [GADMAdapterVungleUtils findAppID:_adConfiguration.credentials.settings];
  if (appId.length == 0) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        GADMAdapterVungleErrorInvalidServerParameters,
        @"Failed to load app open ad from Liftoff Monetize. Missing or invalid App ID configured "
        @"for this ad source instance in the AdMob or Ad Manager UI.");
    [self callLoadCompletionHandlerIfNeededWithAd:nil error:error];
    return;
  }

  NSString *placementId =
      [GADMAdapterVungleUtils findPlacement:_adConfiguration.credentials.settings];
  if (placementId.length == 0) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        GADMAdapterVungleErrorInvalidServerParameters,
        @"Failed to load app open ad from Liftoff Monetize. Missing or Invalid Placement ID "
        @"configured for this ad source instance in the AdMob or Ad Manager UI.");
    [self callLoadCompletionHandlerIfNeededWithAd:nil error:error];
    return;
  }
  self.desiredPlacement = placementId;

  if (![VungleAds isInitialized]) {
    [GADMAdapterVungleRouter.sharedInstance initWithAppId:appId delegate:self];
    return;
  }

  [self loadAd];
}

#pragma mark - Private methods

- (void)loadAd {
  _appOpenAd = [[VungleInterstitial alloc] initWithPlacementId:self.desiredPlacement];
  _appOpenAd.delegate = self;
  if (_adConfiguration.bidResponse) {
    // If bid response is present, then it is an RTB ad.
    VungleAdsExtras *extras = [[VungleAdsExtras alloc] init];
    // Should add watermark for RTB ads.
    [extras setWithWatermark:[_adConfiguration.watermark base64EncodedStringWithOptions:0]];
    [_appOpenAd setWithExtras:extras];
    [_appOpenAd load:_adConfiguration.bidResponse];
  } else {
    // If bid response is absent, then it is a waterfall ad.
    [_appOpenAd load:/*bidPayload=*/nil];
  }
}

- (void)callLoadCompletionHandlerIfNeededWithAd:(nullable id<GADMediationAppOpenAd>)ad
                                          error:(nullable NSError *)error {
  GADMediationAppOpenLoadCompletionHandler completionHandler;
  @synchronized(self) {
    completionHandler = _loadCompletionHandler;
    _loadCompletionHandler = nil;
  }

  if (completionHandler) {
    _adEventDelegate = completionHandler(ad, error);
  }
}

#pragma mark - GADMAdapterVungleDelegate

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error {
  if (!isSuccess) {
    [self callLoadCompletionHandlerIfNeededWithAd:nil error:error];
    return;
  }
  [self loadAd];
}

#pragma mark - GADMediationAppOpenAd Methods

- (void)presentFromViewController:(UIViewController *)rootViewController {
  if ([_appOpenAd canPlayAd]) {
    [_appOpenAd presentWith:rootViewController];
  } else {
    [_adEventDelegate
        didFailToPresentWithError:GADMAdapterVungleErrorWithCodeAndDescription(
                                      GADMAdapterVungleErrorCannotPlayAd,
                                      @"Failed to show app open ad from Liftoff Monetize.")];
  }
}

#pragma mark - VungleInterstitialDelegate

- (void)interstitialAdDidLoad:(nonnull VungleInterstitial *)appOpenAd {
  [self callLoadCompletionHandlerIfNeededWithAd:self error:nil];
}

- (void)interstitialAdDidFailToLoad:(nonnull VungleInterstitial *)appOpenAd
                          withError:(nonnull NSError *)error {
  [self callLoadCompletionHandlerIfNeededWithAd:nil error:error];
}

- (void)interstitialAdWillPresent:(nonnull VungleInterstitial *)appOpenAd {
  [_adEventDelegate willPresentFullScreenView];
}

- (void)interstitialAdDidPresent:(nonnull VungleInterstitial *)appOpenAd {
  // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)interstitialAdDidFailToPresent:(nonnull VungleInterstitial *)appOpenAd
                             withError:(nonnull NSError *)error {
  [_adEventDelegate didFailToPresentWithError:error];
}

- (void)interstitialAdWillClose:(nonnull VungleInterstitial *)appOpenAd {
  [_adEventDelegate willDismissFullScreenView];
}

- (void)interstitialAdDidClose:(nonnull VungleInterstitial *)appOpenAd {
  [_adEventDelegate didDismissFullScreenView];
}

- (void)interstitialAdDidTrackImpression:(nonnull VungleInterstitial *)appOpenAd {
  [_adEventDelegate reportImpression];
}

- (void)interstitialAdDidClick:(nonnull VungleInterstitial *)appOpenAd {
  [_adEventDelegate reportClick];
}

- (void)interstitialAdWillLeaveApplication:(nonnull VungleInterstitial *)appOpenAd {
  // Google Mobile Ads SDK doesn't have a matching event.
}

@end
