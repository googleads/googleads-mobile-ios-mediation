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

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface VungleAdNetworkExtras : NSObject<GADAdNetworkExtras>

/*!
 * @brief NSString with user identifier that will be passed if the ad is incentivized.
 * @discussion Optional. The value passed as 'user' in the an incentivized server-to-server call.
 */
@property(nonatomic, copy) NSString *_Nullable userId;

@property(nonatomic, copy) NSString *_Nullable playingPlacement;

/*!
 * @brief NSInteger that will be passed to alter the privacy icon position for native ads.
 * @discussion Optional. topLeft = 1, topRight = 2, bottomLeft = 3, bottomRight = 4
 */
@property(nonatomic, assign) NSInteger nativeAdOptionPosition;

@end
