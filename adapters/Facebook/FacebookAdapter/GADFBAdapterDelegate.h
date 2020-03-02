// Copyright 2016 Google Inc.
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

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <Foundation/Foundation.h>

@protocol GADMAdNetworkAdapter;
@protocol GADMAdNetworkConnector;

/// Delegate for listening to notifications from Facebook Audience Network.
@interface GADFBAdapterDelegate
    : NSObject <FBAdViewDelegate, FBInterstitialAdDelegate, FBRewardedVideoAdDelegate>

/// Facebook Audience Network banner views can have flexible width. Set this property to the desired
/// banner view's size. Set to CGSizeZero if resizing is not desired.
@property(nonatomic, assign) CGSize finalBannerSize;

/// Initializes a new instance with |adapter| and |connector|.
- (nonnull instancetype)initWithAdapter:(nonnull id<GADMAdNetworkAdapter>)adapter
                              connector:(nonnull id<GADMAdNetworkConnector>)connector
    NS_DESIGNATED_INITIALIZER;

/// Unavailable.
- (nonnull instancetype)init NS_UNAVAILABLE;

@end
