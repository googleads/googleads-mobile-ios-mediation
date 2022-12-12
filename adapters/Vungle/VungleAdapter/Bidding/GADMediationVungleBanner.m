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
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleBiddingRouter.h"
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
    
  /// UIView to send to Google's view property and for Vungle to mount the ad
  UIView *_bannerView;
}

@synthesize desiredPlacement;
@synthesize bannerState;
@synthesize uniquePubRequestID;
@synthesize isRefreshedForBannerAd;
@synthesize isRequestingBannerAdForRefresh;
@synthesize view;
@synthesize isAdLoaded;

- (void)dealloc {
    [self cleanUp];
}

- (nonnull instancetype)initWithAdConfiguration:(nonnull GADMediationBannerAdConfiguration*)adConfiguration
                              completionHandler:(nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    _bannerSize = GADMAdapterVungleAdSizeForAdSize([adConfiguration adSize]);
      
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
    NSString *errorMessage = [NSString stringWithFormat:@"The requested banner size: %@ is not supported by Vungle SDK.", NSStringFromGADAdSize(_bannerSize)];
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(GADMAdapterVungleErrorBannerSizeMismatch, errorMessage);
    _adLoadCompletionHandler(nil, error);
    return;
  }

  if (!self.desiredPlacement.length) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(GADMAdapterVungleErrorInvalidServerParameters,
                                                                  @"Missing or invalid Placement ID configured for this ad source instance in the AdMob or Ad Manager UI.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  if (![[GADMAdapterVungleBiddingRouter sharedInstance] isSDKInitialized]) {
    NSString *appID = [GADMAdapterVungleUtils findAppID:_adConfiguration.credentials.settings];
    [[GADMAdapterVungleBiddingRouter sharedInstance] initWithAppId:appID delegate:self];
    return;
  }

  [self loadAd];
}

- (void)loadAd {
  NSError *error = [[GADMAdapterVungleBiddingRouter sharedInstance] loadAdWithDelegate:self];
  if (error) {
    _adLoadCompletionHandler(nil, error);
  }
}

- (NSError *)renderAd {
  VungleAdNetworkExtras *extras = (VungleAdNetworkExtras *)[_adConfiguration extras];
  NSMutableDictionary *options = nil;
  if (extras) {
    options = [[NSMutableDictionary alloc] init];
    if (extras.muteIsSet) {
      GADMAdapterVungleMutableDictionarySetObjectForKey(options, VunglePlayAdOptionKeyStartMuted,
                                                        @(extras.muted));
    }
    if (extras.userId) {
      GADMAdapterVungleMutableDictionarySetObjectForKey(options, VunglePlayAdOptionKeyUser,
                                                        extras.userId);
    }
    if (extras.flexViewAutoDismissSeconds) {
      GADMAdapterVungleMutableDictionarySetObjectForKey(options,
                                                        VunglePlayAdOptionKeyFlexViewAutoDismissSeconds,
                                                        @(extras.flexViewAutoDismissSeconds));
    }
  }
  NSError *bannerError = nil;
  [VungleSDK.sharedSDK addAdViewToView:_bannerView
                           withOptions:options
                           placementID:self.desiredPlacement
                              adMarkup:[self bidResponse]
                                 error:&bannerError];
  return bannerError;
}

- (void)cleanUp {
  if (_didBannerFinishPresenting) {
    return;
  }
  _didBannerFinishPresenting = YES;

  [VungleSDK.sharedSDK finishDisplayingAd:self.desiredPlacement adMarkup:self.bidResponse];
  [[GADMAdapterVungleBiddingRouter sharedInstance] removeDelegate:self];
  _bannerView = nil;
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
  _bannerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _bannerSize.size.width, _bannerSize.size.height)];
  self.bannerState = BannerRouterDelegateStateWillPlay;
  NSError *error = [self renderAd];
  if (error) {
    _adLoadCompletionHandler(nil, error);
    return;
  }
    
  if (_adLoadCompletionHandler) {
    _delegate = _adLoadCompletionHandler(self, nil);
  }

  if (!_delegate) {
    [[GADMAdapterVungleBiddingRouter sharedInstance] removeDelegate:self];
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

- (void)didShowAd {
  // Do nothing.
}

#pragma mark GADMediationBannerAd

- (UIView *)view {
  return _bannerView;
}

@end
