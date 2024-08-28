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
- (void)loadInterstitialForAdConfiguration:
            (nullable GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:(nullable GADMediationInterstitialLoadCompletionHandler)
                                               completionHandler
isIronSourceInitieted:(BOOL)ironSourceInitieted;

#pragma mark - Instance map Access

// Add a delegate to the instance map
+ (void)setDelegate:(nonnull GADMAdapterIronSourceInterstitialAd *)delegate
             forKey:(nonnull NSString *)key;

// Retrieve a delegate from the instance map
+ (nonnull GADMAdapterIronSourceInterstitialAd *)delegateForKey:(nonnull NSString *)key;

// Remove a delegate from the instance map
+ (void)removeDelegateForKey:(nonnull NSString *)key;

#pragma mark - Getters and Setters

/// Get the interstitial event delegate for Admob mediation.
- (nullable id<GADMediationInterstitialAdEventDelegate>)getInterstitialAdEventDelegate;

/// Set the interstitial event delegate for Admob mediation.
- (void)setInterstitialAdEventDelegate:
    (nullable id<GADMediationInterstitialAdEventDelegate>)eventDelegate;

/// Get the interstitial Admob mediation load completion handler.
- (nullable GADMediationInterstitialLoadCompletionHandler)getLoadCompletionHandler;

/// Set the ad instance state
- (void)setState:(nullable NSString *)state;

/// Get the ad instance state
- (nullable NSString *)getState;

@end
