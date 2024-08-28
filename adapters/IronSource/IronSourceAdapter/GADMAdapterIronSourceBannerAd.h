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
#import <IronSource/IronSource.h>

/// Adapter for communicating with the IronSource Network to fetch banner ads.
@interface GADMAdapterIronSourceBannerAd : NSObject <GADMediationBannerAd>

/// Asks the receiver to render the ad configuration.
- (void)loadBannerAdForAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
                     completionHandler:
                         (nonnull GADMediationBannerLoadCompletionHandler)completionHandler
                 isIronSourceInitiated:(BOOL)ironSourceInitiated;

#pragma mark - Instance map Access

// Add a delegate to the instance map
+ (void)setDelegate:(nonnull GADMAdapterIronSourceBannerAd *)delegate
             forKey:(nonnull NSString *)key;

// Retrieve a delegate from the instance map
+ (nonnull GADMAdapterIronSourceBannerAd *)delegateForKey:(nonnull NSString *)key;

// Remove a delegate from the instance map
+ (void)removeDelegateForKey:(nonnull NSString *)key;

#pragma mark - Getters and Setters

/// Get the banner event delegate for Admob mediation.
- (nullable id<GADMediationBannerAdEventDelegate>)getBannerAdEventDelegate;

/// Set the banner event delegate for Admob mediation.
- (void)setBannerAdEventDelegate:(nullable id<GADMediationBannerAdEventDelegate>)eventDelegate;

/// Get the banner Admob mediation load completion handler.
- (nullable GADMediationBannerLoadCompletionHandler)getLoadCompletionHandler;

/// Get the banner Admob mediation load completion handler.
- (void)setBannerView:(nullable ISDemandOnlyBannerView *)bannerView;

/// Set the ad instance state
- (void)setState:(nullable NSString *)state;

/// Get the ad instance state
- (nullable NSString *)getState;

@end
