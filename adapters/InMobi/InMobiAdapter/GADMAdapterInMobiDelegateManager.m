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

#import "GADMAdapterInMobiDelegateManager.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiUtils.h"

@implementation GADMAdapterInMobiDelegateManager {
  /// Stores rewarded ad delegate with placement identifier as a key.
  NSMapTable<NSNumber *, id<IMInterstitialDelegate>> *_rewardedAdapterDelegates;

  /// Serializes ivar usage.
  dispatch_queue_t _lockQueue;
}

+ (nonnull GADMAdapterInMobiDelegateManager *)sharedInstance {
  static GADMAdapterInMobiDelegateManager *sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[GADMAdapterInMobiDelegateManager alloc] init];
  });
  return sharedInstance;
}

- (nonnull instancetype)init {
  self = [super init];
  if (self) {
    _rewardedAdapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                      valueOptions:NSPointerFunctionsWeakMemory];
    _lockQueue = dispatch_queue_create("inMobi-rewardedAdapterDelegates", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (void)addDelegate:(nonnull id<IMInterstitialDelegate>)delegate
    forPlacementIdentifier:(NSNumber *)placementIdentifier {
  dispatch_async(_lockQueue, ^{
    GADMAdapterInMobiMapTableSetObjectForKey(self->_rewardedAdapterDelegates, placementIdentifier,
                                             delegate);
  });
}

- (void)removeDelegateForPlacementIdentifier:(nonnull NSNumber *)placementIdentifier {
  dispatch_async(_lockQueue, ^{
    GADMAdapterInMobiMapTableRemoveObjectForKey(self->_rewardedAdapterDelegates,
                                                placementIdentifier);
  });
}

- (BOOL)containsDelegateForPlacementIdentifier:(nonnull NSNumber *)placementIdentifier {
  __block BOOL containsDelegateForPlacementIdentifier = NO;
  dispatch_sync(_lockQueue, ^{
    if ([self->_rewardedAdapterDelegates objectForKey:placementIdentifier]) {
      containsDelegateForPlacementIdentifier = YES;
    }
  });

  return containsDelegateForPlacementIdentifier;
}

@end
