// Copyright 2023 Google LLC
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
#import <IronSource/IronSource.h>
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceInterstitialAdDelegate.h"
#import "GADMAdapterIronSourceUtils.h"
#import "GADMediationAdapterIronSource.h"

@interface GADMAdapterIronSourceInterstitialAd ()

// The completion handler to call when the ad loading succeeds or fails.
@property(copy, nonatomic)
    GADMediationInterstitialLoadCompletionHandler interstitalAdLoadCompletionHandler;

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
static NSMapTable<NSString *, GADMAdapterIronSourceInterstitialAd *> *interstitialAdapterDelegates =
    nil;
// The class-level delegate handling callbacks for all instances
static GADMAdapterIronSourceInterstitialAdDelegate *interstitialDelegate = nil;

+ (void)initialize {
  interstitialAdapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn
                                                       valueOptions:NSPointerFunctionsWeakMemory];
  interstitialDelegate = [[GADMAdapterIronSourceInterstitialAdDelegate alloc] init];
}

#pragma mark - Load functionality

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  _interstitalAdLoadCompletionHandler = completionHandler;
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

    _interstitalAdLoadCompletionHandler(nil, error);
    return;
  }

  if (credentials[GADMAdapterIronSourceInstanceId]) {
    self.instanceID = credentials[GADMAdapterIronSourceInstanceId];
  } else {
    [GADMAdapterIronSourceUtils onLog:@"Missing or invalid IronSource interstitial ad Instance ID. "
                                      @"Using the default instance ID."];
    self.instanceID = GADMIronSourceDefaultInstanceId;
  }

  [[GADMediationAdapterIronSource alloc]
      initIronSourceSDKWithAppKey:applicationKey
                       forAdUnits:[NSSet setWithObject:IS_INTERSTITIAL]];

  if (interstitialDelegate == nil) {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:@"IronSource adapter interstitial delegate is null."]];
    return;
  }
  if ([self canLoadInterstitialInstance]) {
    [self setState:GADMAdapterIronSourceInstanceStateLocked];
    GADMAdapterIronSourceMapTableSetObjectForKey(interstitialAdapterDelegates, self.instanceID,
                                                 self);
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:@"Loading IronSource interstitial ad with Instance ID: %@",
                                         self.instanceID]];

    NSString *bidResponse = adConfiguration.bidResponse;
    if(bidResponse) {
      [IronSource loadISDemandOnlyInterstitialWithAdm:self.instanceID adm:bidResponse];
    } else{
      [IronSource loadISDemandOnlyInterstitial:self.instanceID];
    }
  } else {
    NSString *errorMsg = [NSString
        stringWithFormat:
            @"IronSource intestitial ad with Instance ID: '%@' already loaded. Cannot load "
            @"another one at the same time!",
            self.instanceID];
    NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(
        GADMAdapterIronSourceErrorAdAlreadyLoaded, errorMsg);
    [GADMAdapterIronSourceUtils onLog:errorMsg];
    _interstitalAdLoadCompletionHandler(nil, error);
    return;
  }
}

#pragma mark - Instance map access

+ (void)setDelegate:(GADMAdapterIronSourceInterstitialAd *)delegate forKey:(NSString *)key {
  @synchronized(interstitialAdapterDelegates) {
    GADMAdapterIronSourceMapTableSetObjectForKey(interstitialAdapterDelegates, key, delegate);
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
  GADMAdapterIronSourceMapTableRemoveObjectForKey(interstitialAdapterDelegates, key);
}

#pragma mark - Getters and Setters

- (id<GADMediationInterstitialAdEventDelegate>)getInterstitialAdEventDelegate {
  return _interstitialAdEventDelegate;
}

- (void)setInterstitialAdEventDelegate:
    (nullable id<GADMediationInterstitialAdEventDelegate>)eventDelegate {
  _interstitialAdEventDelegate = eventDelegate;
}

- (GADMediationInterstitialLoadCompletionHandler)getLoadCompletionHandler {
  return _interstitalAdLoadCompletionHandler;
}

#pragma mark - Utils methods

- (BOOL)canLoadInterstitialInstance {
  return ![[self getState] isEqualToString:GADMAdapterIronSourceInstanceStateLocked];
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"Showing IronSource interstitial ad for Instance ID: %@",
                                       self.instanceID]];
  [IronSource showISDemandOnlyInterstitial:viewController instanceId:self.instanceID];
}

#pragma mark - Interstitial State

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
                    @"Interstitial instance with ID: %@ changing from oldState=%@ to newState=%@",
                    self.instanceID, self.instanceState, state]];
  self.instanceState = state;
}

@end
