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

@import Foundation;
@import GoogleMobileAds;
@import UnityAds;

#import "GADMAdapterUnityProtocol.h"

typedef void (^UnitySingletonCompletion)(UnityAdsError *error, NSString *message);

@interface GADMAdapterUnitySingleton : NSObject

@property (nonatomic, strong) UnitySingletonCompletion completeBlock;
@property NSMutableSet<NSString*>* placementsInUse;

/// Shared instance.
+ (instancetype)sharedInstance;

/// Configures a reward-based video ad with provided |gameID| and |adapterDelegate| and returns
/// YES if successful; otherwise returns NO.

- (void)initializeWithGameID:(NSString *)gameID
                    completeBlock:(UnitySingletonCompletion)completeBlock;

@end
