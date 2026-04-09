// Copyright 2026 Google LLC
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

#import <AppLovinSDK/AppLovinSDK.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

/// Renderer for AppLovin waterfall interstitial ad. Loads and shows an interstitial ad and handles
/// ad lifecycle events.
@interface GADMWaterfallAppLovinInterstitialRenderer : NSObject <GADMediationInterstitialAd>

/// Initializes the renderer with the ad configuration.
- (nonnull instancetype)initWithAdConfiguration:
    (nonnull GADMediationInterstitialAdConfiguration *)adConfiguration;
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Loads an AppLovin interstitial ad. Expected to be called exactly once.
- (void)loadAdWithCompletion:(GADMediationInterstitialLoadCompletionHandler _Nonnull)completion;

@end
