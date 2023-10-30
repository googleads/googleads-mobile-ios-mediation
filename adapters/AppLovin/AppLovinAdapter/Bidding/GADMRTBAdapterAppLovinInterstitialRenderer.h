// Copyright 2018 Google LLC
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
#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMRTBAdapterAppLovinInterstitialRenderer : NSObject <GADMediationInterstitialAd>

/// Callback object to notify the Google Mobile Ads SDK if ad rendering succeeded or failed.
@property(nonatomic, copy, nonnull, readonly)
    GADMediationInterstitialLoadCompletionHandler adLoadCompletionHandler;

/// Delegate to notify the Google Mobile Ads SDK of interstitial presentation events.
@property(nonatomic, weak, nullable) id<GADMediationInterstitialAdEventDelegate> delegate;

/// An AppLovin interstitial ad.
@property(nonatomic, nullable) ALAd *ad;

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)handler;
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Loads an AppLovin interstitial ad.
- (void)loadAd;

@end
