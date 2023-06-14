// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterIronSourceInterstitialAd.h"
#import "GADMAdapterIronSourceInterstitialAdDelegate.h"
#import "GADMAdapterIronSourceConstants.h"
#import "GADMediationAdapterIronSource.h"
#import "GADMAdapterIronSourceUtils.h"
#import <IronSource/IronSource.h>

@interface GADMAdapterIronSourceInterstitialAd ()

// The completion handler to call when the ad loading succeeds or fails.
@property(copy, nonatomic) GADMediationInterstitialLoadCompletionHandler interstitalAdLoadCompletionHandler;

// An ad event delegate to invoke when ad rendering events occur.
@property(weak, nonatomic) id<GADMediationInterstitialAdEventDelegate> interstitialAdEventDelegate;

/// Holds the ID of the ad instance to be presented.
@property(nonatomic, copy) NSString *instanceID;

/// Holds the state of the ad instance to be presented.
@property(nonatomic, copy) NSString *instanceState;

@end

@implementation GADMAdapterIronSourceInterstitialAd

#pragma mark InstanceMap and Delegate initialization
// The class-level instance mapping from instance id to object reference
static NSMapTable<NSString *, GADMAdapterIronSourceInterstitialAd *> *interstitialAdapterDelegates = nil;
// The class-level delegate handling callbacks for all instances
static GADMAdapterIronSourceInterstitialAdDelegate *interstitialDelegate = nil;

+ (void)initialize {
    interstitialAdapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsWeakMemory];
    interstitialDelegate = [[GADMAdapterIronSourceInterstitialAdDelegate alloc] init];
}

#pragma mark - Load functionality

- (void)loadInterstitialForAdConfiguration:(GADMediationInterstitialAdConfiguration*)adConfiguration
                         completionHandler:(GADMediationInterstitialLoadCompletionHandler)
completionHandler {
    
    _interstitalAdLoadCompletionHandler = completionHandler;
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
                                                                          @"Interstitial 'appKey' parameter is missing. Make sure that appKey' server parameter is added.");
        _interstitalAdLoadCompletionHandler(nil, error);
        return;
    }
    
    if (credentials[GADMAdapterIronSourceInstanceId]) {
        self.instanceID = credentials[GADMAdapterIronSourceInstanceId];
    } else {
        [GADMAdapterIronSourceUtils onLog:@"Interstitial 'instanceID' parameter is missing. Using the default instanceID."];
        self.instanceID = GADMIronSourceDefaultInstanceId;
    }
    
    [[GADMediationAdapterIronSource alloc]
     initIronSourceSDKWithAppKey:applicationKey
     forAdUnits:[NSSet setWithObject:IS_INTERSTITIAL]];
    
    if (interstitialDelegate == nil) {
        [GADMAdapterIronSourceUtils
         onLog:[NSString
                stringWithFormat:@"Interstitial adapterDelegate is null."]];
        return;
    }
    if ([self canLoadInterstitialInstance]) {
        [self setState:GADMAdapterIronSourceInstanceStateLocked];
        [interstitialAdapterDelegates setObject:self forKey:self.instanceID];
        [GADMAdapterIronSourceUtils
         onLog:[NSString
                stringWithFormat:@"Interstitial loadInterstitial for instance with ID: %@",
                self.instanceID]];
        [IronSource loadISDemandOnlyInterstitial:self.instanceID];
    } else {
        NSString *errorMsg = [NSString stringWithFormat:@"Intestitial instance with ID %@ already loaded. Cannot load another one at the same time!", self.instanceID];
        NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(
                                                                          GADMAdapterIronSourceErrorAdAlreadyLoaded,
                                                                          errorMsg);
        [GADMAdapterIronSourceUtils onLog:errorMsg];
        _interstitalAdLoadCompletionHandler(nil, error);
        return;
    }
}

#pragma mark - Instance map access

+ (void)setDelegate:(GADMAdapterIronSourceInterstitialAd *)delegate forKey:(NSString *)key {
    @synchronized(interstitialAdapterDelegates) {
        [interstitialAdapterDelegates setObject:delegate forKey:key];
    }
}

+ (GADMAdapterIronSourceInterstitialAd *)delegateForKey:(NSString *)key {
    GADMAdapterIronSourceInterstitialAd *delegate;
    @synchronized(interstitialAdapterDelegates) {
        delegate = [interstitialAdapterDelegates objectForKey:key];
    }
    return delegate;
}

+ (void)removeDelegateForKey:(NSString *)key {
    [interstitialAdapterDelegates removeObjectForKey:key];
}

#pragma mark - Getters and Setters

- (id<GADMediationInterstitialAdEventDelegate>) getInterstitialAdEventDelegate{
    return _interstitialAdEventDelegate;
}

- (void)setInterstitialAdEventDelegate:(id<GADMediationInterstitialAdEventDelegate>_Nullable)eventDelegate{
    _interstitialAdEventDelegate = eventDelegate;
}

- (GADMediationInterstitialLoadCompletionHandler) getLoadCompletionHandler{
    return _interstitalAdLoadCompletionHandler;
}

#pragma mark - Utils methods

- (BOOL)canLoadInterstitialInstance {
    return ![[self getState] isEqualToString:GADMAdapterIronSourceInstanceStateLocked];
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"Interstitial show interstitial for instance with ID: %@",
            self.instanceID]];
    [IronSource showISDemandOnlyInterstitial:viewController instanceId:self.instanceID];}

- (void)setState:(NSString *)state {
    if (state == self.instanceState) {
        return;
    }
    
    [GADMAdapterIronSourceUtils
     onLog:[NSString
            stringWithFormat:@"Interstitial instance with ID: %@ changing from oldState=%@ to newState=%@",
            self.instanceID, self.instanceState, state]];
    self.instanceState = state;
}

- (NSString *)getState {
    return self.instanceState;
}

@end
