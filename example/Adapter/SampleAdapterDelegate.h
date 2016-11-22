//
// Copyright (C) 2016 Google, Inc.
//
// SampleAdapterDelegate.h
// Sample Ad Network Adapter
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

@import Foundation;

#import "SampleAdapterProtocol.h"

@protocol GADMAdNetworkAdapter;
@protocol GADMAdNetworkConnector;
@protocol GADMRewardBasedVideoAdNetworkAdapter;
@protocol GADMRewardBasedVideoAdNetworkConnector;

@interface SampleAdapterDelegate : NSObject

/// Returns a SampleAdapterDelegate with an adapter and connector.
- (instancetype)initWithAdapter:(id<GADMAdNetworkAdapter, SampleAdapterDataProvider>)adapter
                      connector:(id<GADMAdNetworkConnector>)connector NS_DESIGNATED_INITIALIZER;

/// Returns a SampleAdapterDelegate with a reward-based video ad adapter and reward-based video ad
/// connector.
- (instancetype)initWithRewardBasedVideoAdAdapter:(id<GADMRewardBasedVideoAdNetworkAdapter>)adapter
                      rewardBasedVideoAdconnector:
                          (id<GADMRewardBasedVideoAdNetworkConnector>)connector
    NS_DESIGNATED_INITIALIZER;

/// Unavailable.
- (instancetype)init NS_UNAVAILABLE;

@end
