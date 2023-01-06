// Copyright 2021 Google LLC
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

@interface GADMediationVungleBanner () <GADMAdapterVungleDelegate, GADMediationBannerAd, VungleBannerDelegate>
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
    
    /// Vungle Banner instance
    VungleBanner *_bannerAd;
    
    /// Banner UIView for Google's view property and for Vungle to present on
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

- (nonnull instancetype)initWithAdConfiguration:(nonnull GADMediationBannerAdConfiguration*)adConfiguration
                              completionHandler:(nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    _bannerSize = [self vungleAdSizeForAdSize:[adConfiguration adSize]];

    VungleAdNetworkExtras *networkExtras = adConfiguration.extras;
    self.desiredPlacement = [GADMAdapterVungleUtils findPlacement:adConfiguration.credentials.settings networkExtras:networkExtras];

    __block atomic_flag adLoadHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationBannerLoadCompletionHandler origAdLoadHandler = [completionHandler copy];
    /// Ensure the original completion handler is only called once, and is deallocated once called.
    _adLoadCompletionHandler = ^id<GADMediationBannerAdEventDelegate>(
      id<GADMediationBannerAd> ad, NSError *error) {
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
    NSString *errorMessage = [NSString stringWithFormat:@"Unsupported ad size requested for Vungle. Size: %@", NSStringFromGADAdSize(_bannerSize)];
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(GADMAdapterVungleErrorBannerSizeMismatch, errorMessage);
    _adLoadCompletionHandler(nil, error);
    return;
  }

  if (!self.desiredPlacement.length) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(GADMAdapterVungleErrorInvalidServerParameters, @"Placement ID not specified.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  if (![[GADMAdapterVungleRouter sharedInstance] isSDKInitialized]) {
    NSString *appID = [GADMAdapterVungleUtils findAppID:_adConfiguration.credentials.settings];
    [[GADMAdapterVungleRouter sharedInstance] initWithAppId:appID delegate:self];
    return;
  }

  [self loadAd];
}

- (void)loadAd {
  _bannerAd = [[VungleBanner alloc] initWithPlacementId:self.desiredPlacement
                                                   size:[self convertGADAdSizeToBannerSize]];
  _bannerAd.delegate = self;
  [_bannerAd load:_adConfiguration.bidResponse];
}

- (GADAdSize)vungleAdSizeForAdSize:(GADAdSize)adSize {
    // It has to match for MREC, otherwise it would be a banner with flexible size
    if (adSize.size.height == GADAdSizeMediumRectangle.size.height &&
      adSize.size.width == GADAdSizeMediumRectangle.size.width) {
      return GADAdSizeMediumRectangle;
    }
      
    // An array of supported ad sizes.
    GADAdSize shortBannerSize = GADAdSizeFromCGSize(kVNGBannerShortSize);
    NSArray<NSValue *> *potentials = @[
      NSValueFromGADAdSize(GADAdSizeBanner), NSValueFromGADAdSize(GADAdSizeLeaderboard),
      NSValueFromGADAdSize(shortBannerSize)
    ];

    GADAdSize closestSize = GADClosestValidSizeForAdSizes(adSize, potentials);
    CGSize size = CGSizeFromGADAdSize(closestSize);
    if (size.height == GADAdSizeBanner.size.height) {
      if (size.width < GADAdSizeBanner.size.width) {
        return shortBannerSize;
      } else {
        return GADAdSizeBanner;
      }
    } else if (size.height == GADAdSizeLeaderboard.size.height) {
      return GADAdSizeLeaderboard;
    }
    return GADAdSizeInvalid;
}

- (BannerSize)convertGADAdSizeToBannerSize {
  if (GADAdSizeEqualToSize(_bannerSize, GADAdSizeMediumRectangle)) {
    return BannerSizeMrec;
  }
  if (_bannerSize.size.height == GADAdSizeLeaderboard.size.height) {
    return BannerSizeLeaderboard;
  }
  // Height is 50.
  if (_bannerSize.size.width < GADAdSizeBanner.size.width) {
    return BannerSizeShort;
  }
  return BannerSizeRegular;
}

#pragma mark - VungleBannerDelegate

- (void)bannerAdDidLoad:(VungleBanner *)banner {
  _bannerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _bannerSize.size.width, _bannerSize.size.height)];
  if (_adLoadCompletionHandler) {
    _delegate = _adLoadCompletionHandler(self, nil);
    [_bannerAd presentOn:_bannerView];
  }
}

- (void)bannerAdDidFailToLoad:(VungleBanner *)banner withError:(NSError *)error {
  NSError *gadError = GADMAdapterVungleErrorToGADError(GADMAdapterVungleErrorAdNotPlayable,
                                                       error.code,
                                                       error.localizedDescription);
  _adLoadCompletionHandler(nil, gadError);
}

- (void)bannerAdWillPresent:(VungleBanner *)banner {
  // No-op.
}

- (void)bannerAdDidPresent:(VungleBanner *)banner {
  // No-op.
}

- (void)bannerAdDidFailToPresent:(VungleBanner *)banner withError:(NSError *)error {
  NSError *gadError = GADMAdapterVungleErrorToGADError(GADMAdapterVungleErrorRenderBannerAd,
                                                       error.code,
                                                       error.localizedDescription);
  [_delegate didFailToPresentWithError:gadError];
}

- (void)bannerAdWillClose:(VungleBanner *)banner {
  // This callback is fired when the banner itself is destroyed/removed, not when the user returns
  // to the app screen after clicking on an ad. Do not map to adViewWillDismissScreen:.
}

- (void)bannerAdDidClose:(VungleBanner *)banner {
  // This callback is fired when the banner itself is destroyed/removed, not when the user returns
  // to the app screen after clicking on an ad. Do not map to adViewDidDismissScreen:.
}

- (void)bannerAdDidTrackImpression:(VungleBanner *)banner {
  [_delegate reportImpression];
}

- (void)bannerAdDidClick:(VungleBanner *)banner {
  [_delegate reportClick];
}

- (void)bannerAdWillLeaveApplication:(VungleBanner *)banner {
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
