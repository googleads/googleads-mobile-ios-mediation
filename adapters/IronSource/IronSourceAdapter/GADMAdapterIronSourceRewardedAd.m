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

#import "GADMAdapterIronSourceRewardedAd.h"
#import <IronSource/IronSource.h>
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceRewardedAdDelegate.h"
#import "GADMAdapterIronSourceUtils.h"
#import "GADMediationAdapterIronSource.h"

@interface GADMAdapterIronSourceRewardedAd ()

// The completion handler to call when the ad loading succeeds or fails.
@property(copy, nonatomic)
    GADMediationRewardedLoadCompletionHandler rewardedVideoAdLoadCompletionHandler;

// An ad event delegate to invoke when ad rendering events occur.
@property(weak, nonatomic) id<GADMediationRewardedAdEventDelegate> rewardedVideoAdEventDelegate;

/// Holds the ID of the ad instance to be presented.
@property(nonatomic, copy) NSString *instanceID;

/// Holds the state of the ad instance to be presented.
@property(nonatomic, copy) NSString *instanceState;

@end

@implementation GADMAdapterIronSourceRewardedAd

#pragma mark - InstanceMap and Delegate initialization
// The class-level instance mapping from instance id to object reference
static NSMapTable<NSString *, GADMAdapterIronSourceRewardedAd *> *rewardedAdapterDelegates = nil;
// The class-level delegate handling callbacks for all instances
static GADMAdapterIronSourceRewardedAdDelegate *rewardedDelegate = nil;

+ (void)initialize {
  rewardedAdapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn
                                                   valueOptions:NSPointerFunctionsWeakMemory];
  rewardedDelegate = [[GADMAdapterIronSourceRewardedAdDelegate alloc] init];
}

#pragma mark - Load functionality

- (void)loadRewardedAdForConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                     completionHandler:
                         (GADMediationRewardedLoadCompletionHandler)completionHandler {
  _rewardedVideoAdLoadCompletionHandler = completionHandler;
  // Default instance state
  self.instanceState = GADMAdapterIronSourceInstanceStateStart;

  NSDictionary *credentials = [adConfiguration.credentials settings];
  NSString *applicationKey = credentials[GADMAdapterIronSourceAppKey];
  if (applicationKey != nil && ![GADMAdapterIronSourceUtils isEmpty:applicationKey]) {
    applicationKey = credentials[GADMAdapterIronSourceAppKey];
  } else {
    NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(
        GADMAdapterIronSourceErrorInvalidServerParameters,
        @"Missing or invalid IronSource application key.");
    _rewardedVideoAdLoadCompletionHandler(nil, error);
    return;
  }

  if (credentials[GADMAdapterIronSourceInstanceId]) {
    self.instanceID = credentials[GADMAdapterIronSourceInstanceId];
  } else {
    [GADMAdapterIronSourceUtils onLog:@"Missing or invalid IronSource rewarded ad Instance ID. "
                                      @"Using the default instance ID."];
    self.instanceID = GADMIronSourceDefaultInstanceId;
  }

    [[GADMediationAdapterIronSource alloc]
        initIronSourceSDKWithAppKey:applicationKey
                         forAdUnits:[NSSet setWithObject:IS_BANNER] completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Failed to initialize IronSource SDK: %@", error);
            _rewardedVideoAdLoadCompletionHandler(nil, error);
        } else {
            NSLog(@"IronSource SDK initialized successfully");
            [self loadRewardedAdAfterInit:adConfiguration completionHandler:completionHandler];
        }
    }];
}

- (void)loadRewardedAdAfterInit:(GADMediationRewardedAdConfiguration *)adConfiguration
                  completionHandler:
(GADMediationRewardedLoadCompletionHandler)completionHandler{
    if (rewardedDelegate == nil) {
      [GADMAdapterIronSourceUtils
          onLog:[NSString stringWithFormat:@"IronSource adapter rewarded delegate is null."]];
      return;
    }

    if ([self canLoadRewardedVideoInstance]) {
      [self setState:GADMAdapterIronSourceInstanceStateLocked];
      GADMAdapterIronSourceMapTableSetObjectForKey(rewardedAdapterDelegates, self.instanceID, self);
      [GADMAdapterIronSourceUtils
          onLog:[NSString stringWithFormat:@"Loading IronSource rewarded ad with Instance ID: %@",
                                           self.instanceID]];

      [GADMAdapterIronSourceUtils setWatermarkWithAdConfiguration:adConfiguration];
      NSString *bidResponse = adConfiguration.bidResponse;
      if(bidResponse) {
        [IronSource loadISDemandOnlyRewardedVideoWithAdm:self.instanceID adm:bidResponse];
      } else{
        [IronSource loadISDemandOnlyRewardedVideo:self.instanceID];
      }
    } else {
      NSString *errorMsg =
          [NSString stringWithFormat:
                        @"IronSource rewarded ad with Instance ID: '%@' already loaded. Cannot load "
                        @"another one at the same time!",
                        self.instanceID];
      NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(
          GADMAdapterIronSourceErrorAdAlreadyLoaded, errorMsg);
      [GADMAdapterIronSourceUtils onLog:errorMsg];
      _rewardedVideoAdLoadCompletionHandler(nil, error);
      return;
    }
}

#pragma mark - Instance map access

+ (void)setDelegate:(GADMAdapterIronSourceRewardedAd *)delegate forKey:(NSString *)instanceID {
  @synchronized(rewardedAdapterDelegates) {
    GADMAdapterIronSourceMapTableSetObjectForKey(rewardedAdapterDelegates, instanceID, delegate);
  }
}

+ (GADMAdapterIronSourceRewardedAd *)delegateForKey:(NSString *)key {
  GADMAdapterIronSourceRewardedAd *delegate;
  @synchronized(rewardedAdapterDelegates) {
    delegate = [rewardedAdapterDelegates objectForKey:key];
  }

  return delegate;
}

+ (void)removeDelegateForKey:(NSString *)key {
  GADMAdapterIronSourceMapTableRemoveObjectForKey(rewardedAdapterDelegates, key);
}

#pragma mark - Getters and Setters

- (id<GADMediationRewardedAdEventDelegate>)getRewardedAdEventDelegate {
  return _rewardedVideoAdEventDelegate;
}

- (void)setRewardedAdEventDelegate:(nullable id<GADMediationRewardedAdEventDelegate>)eventDelegate {
  _rewardedVideoAdEventDelegate = eventDelegate;
}

- (GADMediationRewardedLoadCompletionHandler)getLoadCompletionHandler {
  return _rewardedVideoAdLoadCompletionHandler;
}

#pragma mark - Utils methods

- (BOOL)canLoadRewardedVideoInstance {
  if ([[self getState] isEqualToString:GADMAdapterIronSourceInstanceStateLocked]) {
    return false;
  }

  GADMAdapterIronSourceRewardedAd *adInstance =
      [GADMAdapterIronSourceRewardedAd delegateForKey:self.instanceID];
  if (adInstance == nil) {
    return true;
  }

  NSString *currentInstanceState = [adInstance getState];
  if ([currentInstanceState isEqualToString:GADMAdapterIronSourceInstanceStateLocked] ||
      [currentInstanceState isEqualToString:GADMAdapterIronSourceInstanceStateShowing]) {
    return false;
  }

  return true;
}

#pragma mark - GADMediationRewardedAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"Showing IronSource rewarded ad for Instance ID: %@",
                                       self.instanceID]];
  [IronSource showISDemandOnlyRewardedVideo:viewController instanceId:self.instanceID];
}

#pragma mark - Rewarded State

- (NSString *)getState {
  return self.instanceState;
}

- (void)setState:(NSString *)state {
  if (state == self.instanceState) {
    return;
  }

  [GADMAdapterIronSourceUtils
      onLog:[NSString
                stringWithFormat:
                    @"RewardedVideo instance with ID %@: changing from oldState=%@ to newState=%@",
                    self.instanceID, self.instanceState, state]];
  self.instanceState = state;
}

@end
