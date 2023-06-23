// Copyright 2023 Google LLC
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

#import <FiveAd/FiveAd.h>
#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

/// A loader that loads an interstitial ad from FiveAd SDK.
@interface GADMediationAdapterLineInterstitialAdLoader
    : NSObject <GADMediationInterstitialAd, FADLoadDelegate, FADAdViewEventListener>

- (nonnull instancetype)init NS_UNAVAILABLE;

/// Initializes the interstitial ad loader with the provided configuration and the load completion
/// handler.
///
/// @param adConfiguration interstitial ad configuration.
/// @param completionHandler called by the adapter after loading the interstitial ad or encountering
/// an error.
- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
      loadCompletionHandler:
          (nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler;

/// Loads an interstitial ad and then calls the load completion handler provided in the initializer.
- (void)loadAd;

@end
