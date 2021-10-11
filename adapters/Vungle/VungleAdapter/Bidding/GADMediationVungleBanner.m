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
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"

@interface GADMediationVungleBanner () <GADMAdapterVungleDelegate, GADMediationBannerAd>
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

  /// Indicates whether a banner ad is loaded.
  BOOL _isAdLoaded;

  /// Indicates whether the banner ad finished presenting.
  BOOL _didBannerFinishPresenting;
}

@synthesize desiredPlacement;
@synthesize bannerState;
@synthesize uniquePubRequestID;
@synthesize isRefreshedForBannerAd;
@synthesize isRequestingBannerAdForRefresh;
@synthesize view;

- (void)dealloc {
    [self cleanUp];
}

- (nonnull instancetype)initWithAdConfiguration:(nonnull GADMediationBannerAdConfiguration*)adConfiguration
                              completionHandler:(nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    _bannerSize = [self vungleAdSizeForAdSize:[adConfiguration adSize]];
      
    VungleAdNetworkExtras *networkExtras = adConfiguration.extras;
    self.desiredPlacement = [GADMAdapterVungleUtils findPlacement:adConfiguration.credentials.settings networkExtras:networkExtras];
    self.uniquePubRequestID = [networkExtras.UUID copy];

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

- (GADAdSize)vungleAdSizeForAdSize:(GADAdSize)adSize {
  // An array of supported ad sizes.
  GADAdSize shortBannerSize = GADAdSizeFromCGSize(kVNGBannerShortSize);
  NSArray<NSValue *> *potentials = @[
    NSValueFromGADAdSize(kGADAdSizeMediumRectangle), NSValueFromGADAdSize(kGADAdSizeBanner),
    NSValueFromGADAdSize(kGADAdSizeLeaderboard), NSValueFromGADAdSize(shortBannerSize)
  ];

  GADAdSize closestSize = GADClosestValidSizeForAdSizes(adSize, potentials);
  CGSize size = CGSizeFromGADAdSize(closestSize);
  if (size.height == kGADAdSizeBanner.size.height) {
    if (size.width < kGADAdSizeBanner.size.width) {
      return shortBannerSize;
    }
    return kGADAdSizeBanner;
  }
  if (size.height == kGADAdSizeLeaderboard.size.height) {
    return kGADAdSizeLeaderboard;
  }
  if (size.height == kGADAdSizeMediumRectangle.size.height) {
    return kGADAdSizeMediumRectangle;
  }

  return kGADAdSizeInvalid;
}

- (void)loadAd {
  NSError *error = [[GADMAdapterVungleRouter sharedInstance] loadAd:self.desiredPlacement
                                                       withDelegate:self];
  if (error) {
    _adLoadCompletionHandler(nil, error);
  }
}

- (void)loadFrame {
  view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _bannerSize.size.width, _bannerSize.size.height)];
}

- (NSError *)renderAd {
  return [[GADMAdapterVungleRouter sharedInstance] renderBannerAdInView:view
                                                               delegate:self
                                                                 extras:[_adConfiguration extras]
                                                         forPlacementID:self.desiredPlacement];
}

- (void)cleanUp {
  if (_didBannerFinishPresenting) {
    return;
  }
  _didBannerFinishPresenting = YES;

  [[GADMAdapterVungleRouter sharedInstance] completeBannerAdViewForPlacementID:self];
  [[GADMAdapterVungleRouter sharedInstance] removeDelegate:self];
  view = nil;
}

#pragma mark - GADMAdapterVungleDelegate delegates

- (NSString *)bidResponse {
    return [_adConfiguration bidResponse];
}

- (GADAdSize)bannerAdSize {
  return _bannerSize;
}

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error {
  if (!isSuccess) {
    _adLoadCompletionHandler(nil, error);
    return;
  }
  [self loadAd];
}

- (void)adAvailable {
  if (_isAdLoaded) {
    // Already invoked an ad load callback.
    return;
  }
  _isAdLoaded = YES;
  [self loadFrame];
    
  if (_adLoadCompletionHandler) {
    _delegate = _adLoadCompletionHandler(self, nil);
  }

  if (!_delegate) {
    [[GADMAdapterVungleRouter sharedInstance] removeDelegate:self];
    return;
  }
    
  self.bannerState = BannerRouterDelegateStateWillPlay;
  NSError *error = [self renderAd];
  if (error) {
    [_delegate didFailToPresentWithError:error];
    return;
  }
}

- (void)adNotAvailable:(nonnull NSError *)error {
  if (_isAdLoaded) {
    // Already invoked an ad load callback.
    return;
  }
  _adLoadCompletionHandler(nil, error);
}

- (void)willShowAd {
  self.bannerState = BannerRouterDelegateStatePlaying;
}

- (void)didViewAd {
  // Do nothing.
}

- (void)willCloseAd {
  self.bannerState = BannerRouterDelegateStateClosing;
  // This callback is fired when the banner itself is destroyed/removed, not when the user returns
  // to the app screen after clicking on an ad. Do not map to adViewWillDismissScreen:.
}

- (void)didCloseAd {
  self.bannerState = BannerRouterDelegateStateClosed;
  // This callback is fired when the banner itself is destroyed/removed, not when the user returns
  // to the app screen after clicking on an ad. Do not map to adViewDidDismissScreen:.
}

- (void)trackClick {
  [_delegate reportClick];
}

- (void)willLeaveApplication {
  [_delegate willBackgroundApplication];
}

- (void)rewardUser {
  // Do nothing.
}

@end
