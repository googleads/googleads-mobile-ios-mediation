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

#import "GADMAdapterIronSourceBannerAdDelegate.h"
#import "GADMAdapterIronSourceBannerAd.h"
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceUtils.h"
#import "GADMediationAdapterIronSource.h"

@interface GADMAdapterIronSourceBannerAd ()

// The completion handler to call when the ad loading succeeds or fails.
@property(copy, nonatomic) GADMediationBannerLoadCompletionHandler bannerAdLoadCompletionHandler;

// An ad event delegate to invoke when ad rendering events occur.
@property(weak, nonatomic) id<GADMediationBannerAdEventDelegate> bannerAdEventDelegate;

/// Holds the ID of the ad instance to be presented.
@property(nonatomic, copy) NSString *instanceID;

/// Holds the state of the ad instance to be presented.
@property(nonatomic, copy) NSString *instanceState;

/// Holds the banner view for the ad instance.
@property (nonatomic, strong) ISDemandOnlyBannerView *iSDemandOnlyBannerView;

@end

@implementation GADMAdapterIronSourceBannerAd

#pragma mark - InstanceMap and Delegate initialization

// The class-level instance mapping from instance id to object reference
static NSMapTable<NSString *, GADMAdapterIronSourceBannerAd *> *bannerAdapterDelegates = nil;
// The class-level delegate handling callbacks for all instances
static GADMAdapterIronSourceBannerAdDelegate *bannerDelegate = nil;

+ (void)initialize {
    bannerAdapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsWeakMemory];
    bannerDelegate = [[GADMAdapterIronSourceBannerAdDelegate alloc] init];
}

#pragma mark - Load functionality

- (void)loadBannerAdForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
    _bannerAdLoadCompletionHandler = completionHandler;
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
                                                                          @"Banner 'appKey' parameter is missing. Make sure that appKey server parameter is added.");
        _bannerAdLoadCompletionHandler(nil, error);
        return;
    }
    
    if (credentials[GADMAdapterIronSourceInstanceId]) {
        self.instanceID = credentials[GADMAdapterIronSourceInstanceId];
    } else {
        [GADMAdapterIronSourceUtils onLog:@"Banner 'instanceID' parameter is missing. Using the default instance ID."];
        self.instanceID = GADMIronSourceDefaultInstanceId;
    }
    
    [[GADMediationAdapterIronSource alloc]
     initIronSourceSDKWithAppKey:applicationKey
     forAdUnits:[NSSet setWithObject:IS_BANNER]];
    if (bannerDelegate == nil) {
        [GADMAdapterIronSourceUtils
         onLog:[NSString
                stringWithFormat:@"Banner requestBannerAdWithDelegate adapterDelegate is null."]];
        return;
    }
    
    GADAdSize adSize = adConfiguration.adSize;
    ISBannerSize *ISBannerSize = [GADMAdapterIronSourceUtils ironSourceAdSizeFromRequestedSize:adSize];
    if (ISBannerSize == nil){
        [GADMAdapterIronSourceUtils
         onLog:[NSString
                stringWithFormat:@"Banner requestBannerAdWithDelegate unable to retrieve banner size for instnace with ID: %@.", self.instanceID]];
        return;
    }
    
    if ([self canLoadBannerInstance]){
        [self setState:GADMAdapterIronSourceInstanceStateLocked];
        [GADMAdapterIronSourceBannerAd setDelegate:self forKey:self.instanceID];
        
        [IronSource destroyISDemandOnlyBannerWithInstanceId:self.instanceID];
        [GADMAdapterIronSourceUtils
         onLog:[NSString
                stringWithFormat:@"Banner set IronSource delegate for instance with ID %@.", self.instanceID]];
        // Even though there is a single static delegate, it handles callbacks for all instances.
        [IronSource setISDemandOnlyBannerDelegate:bannerDelegate forInstanceId:self.instanceID];
        [GADMAdapterIronSourceUtils
         onLog:[NSString
                stringWithFormat:@"Banner loadBanner for instance with ID: %@",self.instanceID]];
        [IronSource loadISDemandOnlyBannerWithInstanceId:self.instanceID viewController:self size:ISBannerSize];
    } else {
        NSString *errorMsg = [NSString stringWithFormat:@"Banner instance with ID: %@ already loaded. Cannot load another one at the same time!", self.instanceID];
        NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(GADMAdapterIronSourceErrorAdAlreadyLoaded, errorMsg);
        [GADMAdapterIronSourceUtils onLog:errorMsg];
        _bannerAdLoadCompletionHandler(nil, error);
        return;
    }
    
}

#pragma mark - Instance map access

+ (void)setDelegate:(GADMAdapterIronSourceBannerAd *)delegate forKey:(NSString *)key {
    @synchronized(bannerAdapterDelegates) {
        [bannerAdapterDelegates setObject:delegate forKey:key];
    }
}

+ (GADMAdapterIronSourceBannerAd *)delegateForKey:(NSString *)key {
    GADMAdapterIronSourceBannerAd *delegate;
    @synchronized(bannerAdapterDelegates) {
        delegate = [bannerAdapterDelegates objectForKey:key];
    }
    return delegate;
}

+ (void)removeDelegateForKey:(NSString *)key {
    [bannerAdapterDelegates removeObjectForKey:key];
}

#pragma mark - Getters and Setters

- (id<GADMediationBannerAdEventDelegate>) getBannerAdEventDelegate{
    return _bannerAdEventDelegate;
}

- (void)setBannerAdEventDelegate:(id<GADMediationBannerAdEventDelegate>_Nullable)eventDelegate{
    _bannerAdEventDelegate = eventDelegate;
}

- (GADMediationBannerLoadCompletionHandler) getLoadCompletionHandler{
    return _bannerAdLoadCompletionHandler;
}

- (void)setBannerView:(ISDemandOnlyBannerView *_Nullable) bannerView{
    _iSDemandOnlyBannerView = bannerView;
}


#pragma mark - Utils methods

- (BOOL)canLoadBannerInstance {
    return ![[self getState] isEqualToString:GADMAdapterIronSourceInstanceStateLocked];
}

#pragma mark - Banner State

- (NSString *)getState {
    return self.instanceState;
}

- (void)setState:(NSString *)state {
    if (state == self.instanceState) {
        return;
    }
    
    [GADMAdapterIronSourceUtils
     onLog:[NSString
            stringWithFormat:@"Banner instance with ID: %@ changing from oldState=%@ to newState=%@",
            self.instanceID, self.instanceState, state]];
    self.instanceState = state;
}

- (UIView *)view {
    return _iSDemandOnlyBannerView;
}

@end
