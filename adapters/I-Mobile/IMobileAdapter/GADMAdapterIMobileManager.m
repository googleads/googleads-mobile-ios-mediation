// Copyright 2020 Google LLC
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

#import "GADMAdapterIMobileManager.h"

#import "GADMAdapterIMobileUtils.h"
#import "GADMediationAdapterIMobile.h"

@interface GADMAdapterIMobileManager () <IMobileSdkAdsDelegate>
@end

@implementation GADMAdapterIMobileManager {
  /// Stores interstitial ad delegates with the i-mobile Spot ID as a key.
  NSMapTable<NSString *, id<IMobileSdkAdsDelegate>> *_adapterDelegates;

  /// Serializes ivar usage.
  dispatch_queue_t _lockQueue;
}

+ (nonnull GADMAdapterIMobileManager *)sharedInstance {
  static GADMAdapterIMobileManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (nonnull instancetype)init {
  self = [super init];
  if (self) {
    _adapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                              valueOptions:NSPointerFunctionsWeakMemory];
    _lockQueue =
        dispatch_queue_create("iMobile-interstitialAdapterDelegates", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (void)addDelegate:(nonnull id<IMobileSdkAdsDelegate>)adapterDelegate
          forSpotID:(nonnull NSString *)spotId {
  dispatch_async(_lockQueue, ^{
    GADMAdapterIMobileMapTableSetObjectForKey(self->_adapterDelegates, spotId, adapterDelegate);
  });
}

- (void)removeDelegateForSpotID:(nonnull NSString *)spotId {
  dispatch_async(_lockQueue, ^{
    GADMAdapterIMobileMapTableRemoveObjectForKey(self->_adapterDelegates, spotId);
  });
}

- (nullable id<IMobileSdkAdsDelegate>)getDelegateForSpotID:(nonnull NSString *)spotId {
  __block id<IMobileSdkAdsDelegate> delegate = nil;
  dispatch_sync(_lockQueue, ^{
    delegate = [self->_adapterDelegates objectForKey:spotId];
  });
  return delegate;
}

- (nullable NSError *)requestInterstitialAdForSpotId:(nonnull NSString *)spotId
                                            delegate:(nonnull id<IMobileSdkAdsDelegate>)delegate {
  // i-mobile does not support requesting for multiple interstitial ads using the same Spot ID.
  if ([self getDelegateForSpotID:spotId]) {
    NSString *errorMessage =
        [NSString stringWithFormat:@"An ad is already loading for spot ID: %@", spotId];
    NSError *error = GADMAdapterIMobileErrorWithCodeAndDescription(
        GADMAdapterIMobileErrorAdAlreadyLoaded, errorMessage);
    return error;
  }

  GADMAdapterIMobileLog(@"Requesting interstitial ad with Spot ID: %@.", spotId);
  [self addDelegate:delegate forSpotID:spotId];

  if ([ImobileSdkAds getStatusBySpotID:spotId] == IMOBILESDKADS_STATUS_READY) {
    [delegate imobileSdkAdsSpot:spotId didReadyWithValue:IMOBILESDKADS_READY_AD];
    return nil;
  }

  [ImobileSdkAds setSpotDelegate:spotId delegate:self];
  [ImobileSdkAds startBySpotID:spotId];
  return nil;
}

#pragma mark - IMobileSdkAdsDelegate

- (void)imobileSdkAdsSpot:(NSString *)spotId didReadyWithValue:(ImobileSdkAdsReadyResult)value {
  id<IMobileSdkAdsDelegate> delegate = [self getDelegateForSpotID:spotId];
  if (delegate) {
    [delegate imobileSdkAdsSpot:spotId didReadyWithValue:value];
  }
}

- (void)imobileSdkAdsSpot:(NSString *)spotId didFailWithValue:(ImobileSdkAdsFailResult)value {
  id<IMobileSdkAdsDelegate> delegate = [self getDelegateForSpotID:spotId];
  if (delegate) {
    [self removeDelegateForSpotID:spotId];
    [delegate imobileSdkAdsSpot:spotId didFailWithValue:value];
  }
}

- (void)imobileSdkAdsSpotDidClick:(NSString *)spotId {
  id<IMobileSdkAdsDelegate> delegate = [self getDelegateForSpotID:spotId];
  if (delegate) {
    [delegate imobileSdkAdsSpotDidClick:spotId];
  }
}

- (void)imobileSdkAdsSpotDidClose:(NSString *)spotId {
  id<IMobileSdkAdsDelegate> delegate = [self getDelegateForSpotID:spotId];
  if (delegate) {
    [self removeDelegateForSpotID:spotId];
    [delegate imobileSdkAdsSpotDidClose:spotId];
  }
}

@end
