// Copyright 2019 Google LLC
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

#import "GADMRTBAdapterAppLovinBannerRenderer.h"

/// AppLovin Banner Delegate wrapper. AppLovin banner protocols are implemented in a separate class
/// to avoid a retain cycle, as the AppLovin SDK keep a strong reference to its delegate.
@interface GADMAppLovinRTBBannerDelegate
    : NSObject <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdViewEventDelegate>

- (nonnull instancetype)initWithParentRenderer:
    (nonnull GADMRTBAdapterAppLovinBannerRenderer *)parentRenderer;

@end
