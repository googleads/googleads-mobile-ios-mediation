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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol GADMAdNetworkAdapter;
@protocol GADMAdNetworkConnector;

/// Creates and manages a Facebook Audience Network interstitial.
@interface GADFBInterstitialAd : NSObject

/// Initializes a new instance with |connector| and |adapter|.
- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector
                                       adapter:(id<GADMAdNetworkAdapter>)adapter
    NS_DESIGNATED_INITIALIZER;

/// Unavailable.
- (instancetype)init __unavailable;

/// Starts fetching an interstitial from Facebook's Audience Network.
- (void)getInterstitial;

/// Stops the receiver from delegating any notifications from Facebook's Audience Network.
- (void)stopBeingDelegate;

/// Present a full screen interstitial from |rootViewController|.
- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController;

@end
