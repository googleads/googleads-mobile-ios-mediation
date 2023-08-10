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
#import "GADMAdapterIronSourceRewardedAdDelegate.h"
#import "GADMAdapterIronSourceConstants.h"
#import "GADMediationAdapterIronSource.h"
#import "GADMAdapterIronSourceUtils.h"
#import <IronSource/IronSource.h>

@interface GADMAdapterIronSourceRewardedAd ()

// The completion handler to call when the ad loading succeeds or fails.
@property(copy, nonatomic) GADMediationRewardedLoadCompletionHandler rewardedVideoAdLoadCompletionHandler;

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
    rewardedAdapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsWeakMemory];
    rewardedDelegate = [[GADMAdapterIronSourceRewardedAdDelegate alloc] init];
}


#pragma mark - Load functionality

-(void)loadRewardedAdForConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                    completionHandler:(GADMediationRewardedLoadCompletionHandler) completionHandler {
    
    _rewardedVideoAdLoadCompletionHandler = completionHandler;
    // Default instance state
    self.instanceState = GADMAdapterIronSourceInstanceStateStart;
    NSDictionary *credentials = [adConfiguration.credentials settings];
    
    /* Parse application key */
    NSString *applicationKey = credentials[GADMAdapterIronSourceAppKey];
    if (applicationKey != nil && ![GADMAdapterIronSourceUtils isEmpty:applicationKey]) {
        applicationKey = credentials[GADMAdapterIronSourceAppKey];
    } else {
        NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(
                                                                          GADMAdapterIronSourceErrorInvalidServerParameters,
                                                                          @"RewardedVideo 'appKey' parameter is missing. Make sure that appKey' server parameter is added.");
        _rewardedVideoAdLoadCompletionHandler(nil, error);
        return;
    }
    
    if (credentials[GADMAdapterIronSourceInstanceId]) {
        self.instanceID = credentials[GADMAdapterIronSourceInstanceId];
    } else {
        [GADMAdapterIronSourceUtils onLog:@"RewardedVideo 'instanceID' parameter is missing. Using the default instanceID."];
        self.instanceID = GADMIronSourceDefaultInstanceId;
    }
    
    [[GADMediationAdapterIronSource alloc]
     initIronSourceSDKWithAppKey:applicationKey
     forAdUnits:[NSSet setWithObject:IS_REWARDED_VIDEO]];
    
    if (rewardedDelegate == nil) {
        [GADMAdapterIronSourceUtils
         onLog:[NSString stringWithFormat:@"RewardedVideo adapterDelegate is null."]];
        return;
    }
    
    if ([self canLoadRewardedVideoInstance]) {
        [self setState:GADMAdapterIronSourceInstanceStateLocked];
        [rewardedAdapterDelegates setObject:self forKey:self.instanceID];
        [GADMAdapterIronSourceUtils
         onLog:[NSString
                stringWithFormat:@"RewardedVideo load RewardedVideo for instance with ID: %@",
                self.instanceID]];
        [IronSource loadISDemandOnlyRewardedVideo:self.instanceID];
    } else {
        NSString *errorMsg = [NSString stringWithFormat:@"RewardedVideo instance with ID %@ already loaded. Cannot load another one at the same time!", self.instanceID];
        NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(
                                                                          GADMAdapterIronSourceErrorAdAlreadyLoaded,
                                                                          errorMsg);
        [GADMAdapterIronSourceUtils onLog:errorMsg];
        _rewardedVideoAdLoadCompletionHandler(nil, error);
        return;
    }
}

#pragma mark - Instance map access

+ (void)setDelegate:(GADMAdapterIronSourceRewardedAd *)delegate forKey:(NSString *)instanceID {
    @synchronized(rewardedAdapterDelegates) {
        [rewardedAdapterDelegates setObject:delegate forKey:instanceID];
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
    [rewardedAdapterDelegates removeObjectForKey:key];
}

#pragma mark - Getters and Setters

- (id<GADMediationRewardedAdEventDelegate>) getRewardedAdEventDelegate{
    return _rewardedVideoAdEventDelegate;
}

- (void)setRewardedAdEventDelegate:(id<GADMediationRewardedAdEventDelegate>_Nullable)eventDelegate{
    _rewardedVideoAdEventDelegate = eventDelegate;
}

- (GADMediationRewardedLoadCompletionHandler) getLoadCompletionHandler{
    return _rewardedVideoAdLoadCompletionHandler;
}

#pragma mark - Utils methods

- (BOOL)canLoadRewardedVideoInstance {
    return ![[self getState] isEqualToString:GADMAdapterIronSourceInstanceStateLocked];
}

#pragma mark - GADMediationRewardedAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"RewardedVideo showRewardedVideo for instance with ID: %@",
            self.instanceID]];
    [IronSource showISDemandOnlyRewardedVideo:viewController instanceId:self.instanceID];
}

- (void)setState:(NSString *)state {
    if (state == self.instanceState) {
        return;
    }
    
    [GADMAdapterIronSourceUtils
     onLog:[NSString
            stringWithFormat:@"RewardedVideo instance with ID %@: changing from oldState=%@ to newState=%@",
            self.instanceID, self.instanceState, state]];
    self.instanceState = state;
}

- (NSString *)getState {
    return self.instanceState;
}

@end
