// Copyright 2019 Google LLC.
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

#import "GADMAdapterAppLovin.h"

/// AppLovin banner delegate wrapper. AppLovin banner protocols are implemented in a separate class
/// to avoid a retain cycle, as the AppLovin SDK keeps a strong reference to its delegate.
@interface GADMAdapterAppLovinBannerDelegate
    : NSObject <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdViewEventDelegate>

/// Initializes a banner ad delegate with parent adapter. Here parent adapter is a wrapper to the
/// AppLovin's banner ad and is used to request and present banner ads from AppLovin SDK.
- (nonnull instancetype)initWithParentAdapter:(nonnull GADMAdapterAppLovin *)parentAdapter;

@end
