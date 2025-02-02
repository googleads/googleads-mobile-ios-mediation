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

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <AppLovinSDK/AppLovinSDK.h>

@interface GADMAdapterAppLovinExtras : NSObject<GADAdNetworkExtras>

/// Use this to mute audio for video ads. Must be set on each ad request.
@property(nonatomic, assign) BOOL muteAudio __deprecated_msg(
    "The `muteAudio` property is deprecated, use GADMobileAds.sharedInstance.applicationMuted instead.");

@end
