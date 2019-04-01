// Copyright 2019 Google Inc.
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

#import "ISMediationManager.h"
#import "GADMAdapterIronSourceBase.h"
#import "GADMAdapterIronSourceRewardedAd.h"

@interface ISMediationManager () {
  __weak id<ISAdAvailabilityChangedDelegate> _currentShowingUnityDelegate;
}

@end

@implementation ISMediationManager

+ (instancetype)shared {
  static ISMediationManager *sharedMyManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedMyManager = [[self alloc] init];
  });
  return sharedMyManager;
}

- (instancetype)init {
  if (self = [super init]) {
    self.adapterDelegates = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)addDelegate:(id<ISAdAvailabilityChangedDelegate>)adapterDelegate {
  [self.adapterDelegates setObject:adapterDelegate forKey:[adapterDelegate getInstanceID]];
}

- (void)removeDelegateForInstanceID:(NSString *)InstanceID {
  [self.adapterDelegates removeObjectForKey:InstanceID];
}

- (void)adAvailabilityChangedWithInstanceID:(NSString *)instanceID available:(BOOL)available {
  for (NSString *delegateInstanceID in self.adapterDelegates.allKeys) {
    id<ISAdAvailabilityChangedDelegate> delegate =
        [self.adapterDelegates objectForKey:delegateInstanceID];
    if (!delegate) {
      [self.adapterDelegates removeObjectForKey:delegateInstanceID];
      continue;
    }
    if ([instanceID isEqualToString:delegateInstanceID]) {
      if (available) {
        [delegate adReady];
      } else {
        NSError *error = [self
            createErrorWith:[NSString
                                stringWithFormat:@"Rewarded Ad not avilable for Insatnce ID: %@",
                                                 instanceID]
                  andReason:@"No Ad avialable"
              andSuggestion:nil];
        [delegate didFailToLoadWithError:error];
        [self.adapterDelegates removeObjectForKey:delegateInstanceID];
      }
    }
  }
}

- (void)requestRewardedAdWithDelegate:(id<ISAdAvailabilityChangedDelegate>)delegate {
  NSString *instanceID = [delegate getInstanceID];
  NSError *availableAdsError =
      [self createErrorWith:@"A request is already in processing for same instance ID"
                  andReason:@"Can't make a new request for the same instance ID"
              andSuggestion:nil];
  NSDictionary *adapterDelegates = [self adapterDelegates];
  NSString *playingInstanceID = [_currentShowingUnityDelegate getInstanceID];
  [IronSource setISDemandOnlyRewardedVideoDelegate:self];
  if ([adapterDelegates objectForKey:instanceID] ||
      [playingInstanceID isEqualToString:instanceID]) {
    [delegate didFailToLoadWithError:availableAdsError];
    return;
  } else {
    id<ISAdAvailabilityChangedDelegate> __weak weakSelf = delegate;
    [self addDelegate:weakSelf];
  }

  if ([IronSource hasISDemandOnlyRewardedVideo:instanceID]) {
    [delegate adReady];
  }
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController
                         delegate:(id<ISAdAvailabilityChangedDelegate>)delegate {
  NSString *instanceID = [delegate getInstanceID];
  [IronSource setISDemandOnlyRewardedVideoDelegate:self];

  if ([IronSource hasISDemandOnlyRewardedVideo:instanceID]) {
    // The reward based video ad is available, present the ad.
    [IronSource showISDemandOnlyRewardedVideo:viewController instanceId:instanceID];
    _currentShowingUnityDelegate = delegate;
  } else {
    // Because publishers are expected to check that an ad is available before trying to show one,
    // the above conditional should always hold true. If for any reason the adapter is not ready to
    // present an ad, however, it should log an error with reason for failure.
    NSError *error = [self createErrorWith:@"No Ad to show for this instance ID"
                                 andReason:nil
                             andSuggestion:nil];
    [delegate rewardedVideoDidFailToShowWithError:error instanceId:instanceID];
  }
  [[ISMediationManager shared] removeDelegateForInstanceID:instanceID];
}

- (void)didClickRewardedVideo:(ISPlacementInfo *)placementInfo instanceId:(NSString *)instanceId {
  [_currentShowingUnityDelegate didClickRewardedVideo:placementInfo instanceId:instanceId];
}

- (void)didReceiveRewardForPlacement:(ISPlacementInfo *)placementInfo
                          instanceId:(NSString *)instanceId {
  [_currentShowingUnityDelegate didReceiveRewardForPlacement:placementInfo instanceId:instanceId];
}

- (void)rewardedVideoDidClose:(NSString *)instanceId {
  [_currentShowingUnityDelegate rewardedVideoDidClose:instanceId];
  _currentShowingUnityDelegate = nil;
}

- (void)rewardedVideoDidFailToShowWithError:(NSError *)error instanceId:(NSString *)instanceId {
  for (NSString *delegateInstanceID in self.adapterDelegates.allKeys) {
    id<ISAdAvailabilityChangedDelegate> delegate =
        [self.adapterDelegates objectForKey:delegateInstanceID];
    if (!delegate) {
      continue;
    }
    if ([instanceId isEqualToString:delegateInstanceID]) {
      [delegate rewardedVideoDidFailToShowWithError:error instanceId:instanceId];
      [self removeDelegateForInstanceID:instanceId];
    }
  }
}

- (void)rewardedVideoDidOpen:(NSString *)instanceId {
  [_currentShowingUnityDelegate rewardedVideoDidOpen:instanceId];
}

- (void)rewardedVideoHasChangedAvailability:(BOOL)available instanceId:(NSString *)instanceId {
  [self adAvailabilityChangedWithInstanceID:instanceId available:available];
}

- (NSError *)createErrorWith:(NSString *)description
                   andReason:(NSString *)reason
               andSuggestion:(NSString *)suggestion {
  NSDictionary *userInfo = @{
    NSLocalizedDescriptionKey : NSLocalizedString(description, nil),
    NSLocalizedFailureReasonErrorKey : NSLocalizedString(reason, nil),
    NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(suggestion, nil)
  };

  return [NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:userInfo];
}

@end
