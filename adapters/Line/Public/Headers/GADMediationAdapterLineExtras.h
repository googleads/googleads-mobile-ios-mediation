// Copyright 2023 Google LLC.
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

/// The ad audio states.
typedef NS_ENUM(NSUInteger, GADMediationAdapterLineAdAudio) {
  /// The unset state.
  GADMediationAdapterLineAdAudioUnset,
  /// The muted state.
  GADMediationAdapterLineAdAudioMuted,
  /// The unmuted state.
  GADMediationAdapterLineAdAudioUnmuted
};

@interface GADMediationAdapterLineExtras : NSObject <GADAdNetworkExtras>

/// The width of the native media view.
@property(nonatomic) CGFloat nativeAdVideoWidth;

/// The initial audio state for banner, interstitial, and rewarded ad is presented. If this property
/// is set to GADMediationAdapterLineAdAudioSettingUnset, then the value of
/// GADMobileAds.sharedInstance.applicationMuted will be respected. The default value is
/// GADMediationAdapterLineAdAudioSettingUnset.
///
/// For native ad, use GADVideoOptions.
@property(nonatomic) GADMediationAdapterLineAdAudio adAudio;

@end
