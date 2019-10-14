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

#import "GADMAdapterAppLovinMediationManager.h"
#import "GADMAdapterAppLovinUtils.h"

@implementation GADMAdapterAppLovinMediationManager {
  /// A set of zone identifiers used to request interstitial ads from AppLovin.
  NSMutableSet<NSString *> *_requestedInterstitialZoneIdentifiers;

  /// A set of zone identifiers used to request rewarded ads from AppLovin.
  NSMutableSet<NSString *> *_requestedRewardedZoneIdentifiers;

  /// Serializes ivar usage.
  dispatch_queue_t _lockQueue;
}

+ (nonnull GADMAdapterAppLovinMediationManager *)sharedInstance {
  static GADMAdapterAppLovinMediationManager *sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[GADMAdapterAppLovinMediationManager alloc] init];
  });
  return sharedInstance;
}

- (nonnull instancetype)init {
  self = [super init];
  if (self) {
    _requestedRewardedZoneIdentifiers = [[NSMutableSet alloc] init];
    _requestedInterstitialZoneIdentifiers = [[NSMutableSet alloc] init];
    _lockQueue = dispatch_queue_create("applovin-mediationManager", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (BOOL)containsAndAddInterstitialZoneIdentifier:(nonnull NSString *)zoneIdentifier {
  __block BOOL containsZone = NO;
  zoneIdentifier = [zoneIdentifier copy];
  dispatch_sync(_lockQueue, ^{
    containsZone = [self->_requestedInterstitialZoneIdentifiers containsObject:zoneIdentifier];
    GADMAdapterAppLovinMutableSetAddObject(self->_requestedInterstitialZoneIdentifiers,
                                           zoneIdentifier);
  });
  return containsZone;
}

- (void)removeInterstitialZoneIdentifier:(nonnull NSString *)zoneIdentifier {
  dispatch_async(_lockQueue, ^{
    GADMAdapterAppLovinMutableSetRemoveObject(self->_requestedInterstitialZoneIdentifiers,
                                              zoneIdentifier);
  });
}

- (void)removeRewardedZoneIdentifier:(nonnull NSString *)zoneIdentifier {
  dispatch_async(_lockQueue, ^{
    GADMAdapterAppLovinMutableSetRemoveObject(self->_requestedRewardedZoneIdentifiers,
                                              zoneIdentifier);
  });
}

- (BOOL)containsAndAddRewardedZoneIdentifier:(nonnull NSString *)zoneIdentifier {
  __block BOOL containsZone = NO;
  zoneIdentifier = [zoneIdentifier copy];
  dispatch_sync(_lockQueue, ^{
    containsZone = [self->_requestedRewardedZoneIdentifiers containsObject:zoneIdentifier];
    GADMAdapterAppLovinMutableSetAddObject(self->_requestedRewardedZoneIdentifiers, zoneIdentifier);
  });
  return containsZone;
}

@end
