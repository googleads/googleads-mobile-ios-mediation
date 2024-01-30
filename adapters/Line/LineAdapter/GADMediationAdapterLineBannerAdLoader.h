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

/// A loader that loads a banner ad from FiveAd SDK.
@interface GADMediationAdapterLineBannerAdLoader
    : NSObject <GADMediationBannerAd, FADLoadDelegate, FADCustomLayoutEventListener>

- (nonnull instancetype)init NS_UNAVAILABLE;

/// Initializes the banner ad loader with the provided configuration and the load completion
/// handler.
///
/// @param adConfiguration banner ad configuration.
/// @param completionHandler called  after loading the banner ad or encountering an error.
- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
      loadCompletionHandler:(nonnull GADMediationBannerLoadCompletionHandler)completionHandler;

/// Loads a banner ad and then calls the load completion handler provided in the initializer.
- (void)loadAd;

@end
