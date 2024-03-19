// Copyright 2024 Google LLC
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

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

/// Class for loading and showing Liftoff Monetize (fka Vungle) app open ads.
@interface GADMediationVungleAppOpenAd : NSObject <GADMediationAppOpenAd>

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationAppOpenAdConfiguration *)adConfiguration
      loadCompletionHandler:(nonnull GADMediationAppOpenLoadCompletionHandler)loadCompletionHandler;

/// Constructor is unavailable. Please use initWithAdConfiguration:completionHandler:.
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Requests an app open ad from Liftoff Monetize.
- (void)requestAppOpenAd;

@end
