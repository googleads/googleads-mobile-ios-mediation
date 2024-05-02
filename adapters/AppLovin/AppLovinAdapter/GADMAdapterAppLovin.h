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
#import <GoogleMobileAds/GoogleMobileAds.h>

/// An adapter class that requests ads from AppLovin SDK.
@interface GADMAdapterAppLovin : NSObject <GADMAdNetworkAdapter>

/// Connector from Google Mobile Ads SDK to receive ad configurations.
@property(nonatomic, weak, nullable, readonly) id<GADMAdNetworkConnector> connector;

/// An AppLovin interstitial ad.
@property(nonatomic, nullable) ALAd *interstitialAd;

/// An AppLovin banner ad view.
@property(nonatomic, readonly, nullable) ALAdView *adView;

/// The AppLovin zone identifier used to load an ad.
@property(nonatomic, readonly, nullable) NSString *zoneIdentifier;

/// The AdMob UI settings.
@property(nonatomic, copy, nonnull, readonly) NSDictionary<NSString *, id> *settings;

@end
