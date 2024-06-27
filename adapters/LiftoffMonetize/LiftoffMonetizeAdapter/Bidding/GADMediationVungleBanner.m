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
                                        VungleBannerViewDelegate>
@end

@implementation GADMediationVungleBanner {
  /// Ad configuration for the ad to be loaded.
  GADMediationBannerAdConfiguration *_adConfiguration;

  /// The completion handler to call when an ad loads successfully or fails.
  GADMediationBannerLoadCompletionHandler _adLoadCompletionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  __weak id<GADMediationBannerAdEventDelegate> _delegate;

  /// The requested ad size.
  GADAdSize _bannerSize;

  /// Liftoff Monetize bannerView ad instance.
  VungleBannerView *_bannerAdView;
}

@synthesize desiredPlacement;

- (void)dealloc {
  _adConfiguration = nil;
  _adLoadCompletionHandler = nil;
  _bannerAdView = nil;
  _delegate = nil;
}

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    _bannerSize = adConfiguration.adSize;

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
  if (![VungleAds isInitialized]) {
    NSString *appID = [GADMAdapterVungleUtils findAppID:_adConfiguration.credentials.settings];
    [[GADMAdapterVungleRouter sharedInstance] initWithAppId:appID delegate:self];
    return;
  }

  [self loadAd];
}

- (void)loadAd {
  _bannerAdView = [[VungleBannerView alloc]
      initWithPlacementId:self.desiredPlacement
             vungleAdSize:GADMAdapterVungleConvertGADAdSizeToVungleAdSize(_bannerSize, self.desiredPlacement)];
  _bannerAdView.delegate = self;
  VungleAdsExtras *extras = [[VungleAdsExtras alloc] init];
  [extras setWithWatermark:[_adConfiguration.watermark base64EncodedStringWithOptions:0]];
  [_bannerAdView setWithExtras:extras];
  [_bannerAdView load:_adConfiguration.bidResponse];
}

#pragma mark - VungleBannerViewDelegate

- (void)bannerAdDidLoad:(VungleBannerView *)bannerView {
  if (_adLoadCompletionHandler) {
    _delegate = _adLoadCompletionHandler(self, nil);
  }
}

- (void)bannerAdDidFail:(VungleBannerView *)bannerView withError:(NSError *)withError {
  if (_delegate != nil) {
    [_delegate didFailToPresentWithError:withError];
    return;
  }
  _adLoadCompletionHandler(nil, withError);
}

- (void)bannerAdWillPresent:(VungleBannerView *)bannerView {
  // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)bannerAdDidPresent:(VungleBannerView *)bannerView {
  // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)bannerAdWillClose:(VungleBannerView *)bannerView {
  // This callback is fired when the banner itself is destroyed/removed, not when the user returns
  // to the app screen after clicking on an ad. Do not map to adViewWillDismissScreen:.
}

- (void)bannerAdDidClose:(VungleBannerView *)bannerView {
  // This callback is fired when the banner itself is destroyed/removed, not when the user returns
  // to the app screen after clicking on an ad. Do not map to adViewDidDismissScreen:.
}

- (void)bannerAdDidTrackImpression:(VungleBannerView *)bannerView {
  [_delegate reportImpression];
}

- (void)bannerAdDidClick:(VungleBannerView *)bannerView {
  [_delegate reportClick];
}

- (void)bannerAdWillLeaveApplication:(VungleBannerView *)bannerView {
  // Google Mobile Ads SDK doesn't have a matching event.
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
  return _bannerAdView;
}

@end
