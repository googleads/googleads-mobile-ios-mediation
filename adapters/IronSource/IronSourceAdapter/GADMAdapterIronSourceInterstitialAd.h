// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

/// Adapter for communicating with the IronSource Network to fetch interstitial ads.
@interface GADMAdapterIronSourceInterstitialAd : NSObject <GADMediationInterstitialAd>

/// Initializes a new instance with adConfiguration and completionHandler.
- (void)loadInterstitialForAdConfiguration:(GADMediationInterstitialAdConfiguration *_Nullable)adConfiguration
                         completionHandler:(GADMediationInterstitialLoadCompletionHandler _Nullable )
completionHandler;

#pragma mark - Instance map Access

// Add a delegate to the instance map
+ (void)setDelegate:(GADMAdapterIronSourceInterstitialAd *_Nonnull)delegate forKey:(NSString *_Nonnull)key;

// Retrieve a delegate from the instance map
+ (GADMAdapterIronSourceInterstitialAd *_Nonnull)delegateForKey:(NSString *_Nonnull)key;

// Remove a delegate from the instance map
+ (void)removeDelegateForKey:(NSString *_Nonnull)key;

#pragma mark - Getters and Setters

/// Get the interstitial event delegate for Admob mediation.
- (id<GADMediationInterstitialAdEventDelegate>_Nullable) getInterstitialAdEventDelegate;

/// Set the interstitial event delegate for Admob mediation.
- (void)setInterstitialAdEventDelegate:(id<GADMediationInterstitialAdEventDelegate>_Nullable)eventDelegate;

/// Get the interstitial Admob mediation load completion handler.
- (GADMediationInterstitialLoadCompletionHandler _Nullable) getLoadCompletionHandler;

/// Set the ad instance state
- (void)setState:(NSString *_Nullable)state;

/// Get the ad instance state
- (NSString *_Nullable)getState;

@end
