// Copyright 2022 Google LLC
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

#import "GADMediationVungleBanner.h"
#include <stdatomic.h>
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleDelegate.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"

@interface GADMediationVungleBanner () <GADMAdapterVungleDelegate,
                                        GADMediationBannerAd,
                                        VungleBannerDelegate>
@end

@implementation GADMediationVungleBanner {
  /// Ad configuration for the ad to be loaded.
  GADMediationBannerAdConfiguration *_adConfiguration;

  /// The completion handler to call when an ad loads successfully or fails.
  GADMediationBannerLoadCompletionHandler _adLoadCompletionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  id<GADMediationBannerAdEventDelegate> _delegate;

  /// The requested ad size.
  GADAdSize _bannerSize;

  /// Liftoff Monetize banner ad instance.
  VungleBanner *_bannerAd;

  /// UIView to send to Google's view property and for Liftoff Monetize to mount the ad.
  UIView *_bannerView;
}

@synthesize desiredPlacement;

- (void)dealloc {
  _adConfiguration = nil;
  _adLoadCompletionHandler = nil;
  _bannerAd = nil;
  _delegate = nil;
  _bannerView = nil;
}

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    _bannerSize = GADMAdapterVungleAdSizeForAdSize(adConfiguration.adSize);

    self.desiredPlacement =
        [GADMAdapterVungleUtils findPlacement:adConfiguration.credentials.settings];

    __block atomic_flag adLoadHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationBannerLoadCompletionHandler origAdLoadHandler = [completionHandler copy];
    /// Ensure the original completion handler is only called once, and is deallocated once called.
    _adLoadCompletionHandler =
        ^id<GADMediationBannerAdEventDelegate>(id<GADMediationBannerAd> ad, NSError *error) {
      if (atomic_flag_test_and_set(&adLoadHandlerCalled)) {
        return nil;
      }
      id<GADMediationBannerAdEventDelegate> delegate = nil;
      if (origAdLoadHandler) {
        delegate = origAdLoadHandler(ad, error);
      }
      origAdLoadHandler = nil;
      return delegate;
    };
  }
  return self;
}

- (void)requestBannerAd {
  if (!IsGADAdSizeValid(_bannerSize)) {
    NSString *errorMessage = [NSString
        stringWithFormat:@"The requested banner size: %@ is not supported by Liftoff Monetize.",
                         NSStringFromGADAdSize(_bannerSize)];
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        GADMAdapterVungleErrorBannerSizeMismatch, errorMessage);
    _adLoadCompletionHandler(nil, error);
    return;
  }
  if (![VungleAds isInitialized]) {
    NSString *appID = [GADMAdapterVungleUtils findAppID:_adConfiguration.credentials.settings];
    [[GADMAdapterVungleRouter sharedInstance] initWithAppId:appID delegate:self];
    return;
  }

  [self loadAd];
}

- (void)loadAd {
  _bannerAd = [[VungleBanner alloc]
      initWithPlacementId:self.desiredPlacement
                     size:GADMAdapterVungleConvertGADAdSizeToBannerSize(_bannerSize)];
  _bannerAd.delegate = self;
  VungleAdsExtras *extras = [[VungleAdsExtras alloc] init];
  [extras setWithWatermark:[_adConfiguration.watermark base64EncodedStringWithOptions:0]];
  [_bannerAd setWithExtras:extras];
  [_bannerAd load:_adConfiguration.bidResponse];
}

#pragma mark - VungleBannerDelegate

- (void)bannerAdDidLoad:(nonnull VungleBanner *)banner {
  _bannerView = [[UIView alloc]
      initWithFrame:CGRectMake(0, 0, _bannerSize.size.width, _bannerSize.size.height)];
  if (_adLoadCompletionHandler) {
    [_bannerAd presentOn:_bannerView];
    _delegate = _adLoadCompletionHandler(self, nil);
  }
}

- (void)bannerAdDidFailToLoad:(nonnull VungleBanner *)banner withError:(nonnull NSError *)error {
  _adLoadCompletionHandler(nil, error);
}

- (void)bannerAdWillPresent:(nonnull VungleBanner *)banner {
  // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)bannerAdDidPresent:(nonnull VungleBanner *)banner {
  // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)bannerAdDidFailToPresent:(nonnull VungleBanner *)banner withError:(nonnull NSError *)error {
  [_delegate didFailToPresentWithError:error];
}

- (void)bannerAdWillClose:(nonnull VungleBanner *)banner {
  // This callback is fired when the banner itself is destroyed/removed, not when the user returns
  // to the app screen after clicking on an ad. Do not map to adViewWillDismissScreen:.
}

- (void)bannerAdDidClose:(nonnull VungleBanner *)banner {
  // This callback is fired when the banner itself is destroyed/removed, not when the user returns
  // to the app screen after clicking on an ad. Do not map to adViewDidDismissScreen:.
}

- (void)bannerAdDidTrackImpression:(nonnull VungleBanner *)banner {
  [_delegate reportImpression];
}

- (void)bannerAdDidClick:(nonnull VungleBanner *)banner {
  [_delegate reportClick];
}

- (void)bannerAdWillLeaveApplication:(nonnull VungleBanner *)banner {
  [_delegate willBackgroundApplication];
}

#pragma mark - GADMAdapterVungleDelegate

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error {
  if (!isSuccess) {
    _adLoadCompletionHandler(nil, error);
    return;
  }
  [self loadAd];
}

#pragma mark GADMediationBannerAd

- (UIView *)view {
  return _bannerView;
}

@end
