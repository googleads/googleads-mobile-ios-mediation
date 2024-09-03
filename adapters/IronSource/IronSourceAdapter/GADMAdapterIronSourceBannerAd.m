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

#import "GADMAdapterIronSourceBannerAd.h"
#import "GADMAdapterIronSourceBannerAdDelegate.h"
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
@property(nonatomic, strong) ISDemandOnlyBannerView *iSDemandOnlyBannerView;

@end

@implementation GADMAdapterIronSourceBannerAd

#pragma mark - InstanceMap and Delegate initialization

// The class-level instance mapping from instance id to object reference
static NSMapTable<NSString *, GADMAdapterIronSourceBannerAd *> *bannerAdapterDelegates = nil;
// The class-level delegate handling callbacks for all instances
static GADMAdapterIronSourceBannerAdDelegate *bannerDelegate = nil;

+ (void)initialize {
    bannerAdapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn
                                                   valueOptions:NSPointerFunctionsWeakMemory];
    bannerDelegate = [[GADMAdapterIronSourceBannerAdDelegate alloc] init];
}

#pragma mark - Load functionality

- (void)loadBannerAdForAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
                     completionHandler:
(nonnull GADMediationBannerLoadCompletionHandler)completionHandler{
    _bannerAdLoadCompletionHandler = completionHandler;
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
        _bannerAdLoadCompletionHandler(nil, error);
        return;
    }
    
    if (credentials[GADMAdapterIronSourceInstanceId]) {
        self.instanceID = credentials[GADMAdapterIronSourceInstanceId];
    } else {
        [GADMAdapterIronSourceUtils
         onLog:
             @"Missing or invalid IronSource banner ad Instance ID. Using the default instance ID."];
        self.instanceID = GADMIronSourceDefaultInstanceId;
    }
    
    
    [[GADMediationAdapterIronSource alloc]
     initIronSourceSDKWithAppKey:applicationKey
     forAdUnits:[NSSet setWithObject:IS_BANNER] completionHandler:^(NSError * _Nullable error) {
        if (error) {
            [GADMAdapterIronSourceUtils
             onLog:[NSString stringWithFormat:@"Failed to initialize IronSource SDK: %@", error]];
            _bannerAdLoadCompletionHandler(nil, error);
        } else {
            [GADMAdapterIronSourceUtils
             onLog:[NSString stringWithFormat:@"IronSource SDK initialized successfully"]];
            [self loadBannerAdAfterInit:adConfiguration completionHandler:completionHandler];
        }
    }];
    
    
    
}

- (void)loadBannerAdAfterInit:(GADMediationBannerAdConfiguration *)adConfiguration
            completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
    if (bannerDelegate == nil) {
        [GADMAdapterIronSourceUtils
         onLog:[NSString stringWithFormat:@"IronSource adapter banner delegate is null."]];
        return;
    }
    
    GADAdSize adSize = adConfiguration.adSize;
    ISBannerSize *ISBannerSize =
    [GADMAdapterIronSourceUtils ironSourceAdSizeFromRequestedSize:adSize];
    if (ISBannerSize == nil) {
        NSString *errorMessage = [NSString
                                  stringWithFormat:
                                      @"Unsupported ad size requested for IronSource. Requested size: %@, Instance ID: %@",
                                  NSStringFromGADAdSize(adSize), self.instanceID];
        NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(
                                                                          GADMAdapterIronSourceErrorBannerSizeMismatch, errorMessage);
        _bannerAdLoadCompletionHandler(nil, error);
        return;
    }
    
    if ([self canLoadBannerInstance]) {
        [self setState:GADMAdapterIronSourceInstanceStateLocked];
        [GADMAdapterIronSourceBannerAd setDelegate:self forKey:self.instanceID];
        
        [IronSource destroyISDemandOnlyBannerWithInstanceId:self.instanceID];
        [GADMAdapterIronSourceUtils
         onLog:[NSString stringWithFormat:@"Banner set IronSource delegate for instance with ID %@.",
                self.instanceID]];
        // Even though there is a single static delegate, it handles callbacks for all instances.
        [IronSource setISDemandOnlyBannerDelegate:bannerDelegate forInstanceId:self.instanceID];
        [GADMAdapterIronSourceUtils
         onLog:[NSString stringWithFormat:@"Loading IronSource banner ad with Instance ID: %@",
                self.instanceID]];
        [IronSource loadISDemandOnlyBannerWithInstanceId:self.instanceID
                                          viewController:adConfiguration.topViewController
                                                    size:ISBannerSize];
    } else {
        NSString *errorMsg =
        [NSString stringWithFormat:@"IronSource banner ad with Instance ID: '%@' already loaded. "
         @"Cannot load another one at the same time!",
         self.instanceID];
        NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(
                                                                          GADMAdapterIronSourceErrorAdAlreadyLoaded, errorMsg);
        [GADMAdapterIronSourceUtils onLog:errorMsg];
        _bannerAdLoadCompletionHandler(nil, error);
        return;
    }
}

#pragma mark - Instance map access

+ (void)setDelegate:(GADMAdapterIronSourceBannerAd *)delegate forKey:(NSString *)key {
    @synchronized(bannerAdapterDelegates) {
        GADMAdapterIronSourceMapTableSetObjectForKey(bannerAdapterDelegates, key, delegate);
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
    GADMAdapterIronSourceMapTableRemoveObjectForKey(bannerAdapterDelegates, key);
}

#pragma mark - Getters and Setters

- (id<GADMediationBannerAdEventDelegate>)getBannerAdEventDelegate {
    return _bannerAdEventDelegate;
}

- (void)setBannerAdEventDelegate:(nullable id<GADMediationBannerAdEventDelegate>)eventDelegate {
    _bannerAdEventDelegate = eventDelegate;
}

- (GADMediationBannerLoadCompletionHandler)getLoadCompletionHandler {
    return _bannerAdLoadCompletionHandler;
}

- (void)setBannerView:(nullable ISDemandOnlyBannerView *)bannerView {
    _iSDemandOnlyBannerView = bannerView;
}

#pragma mark - Utils methods

- (BOOL)canLoadBannerInstance {
    return ![[self getState] isEqualToString:GADMAdapterIronSourceInstanceStateLocked];
}

#pragma mark - GADMediationBannerAd

- (UIView *)view {
    return _iSDemandOnlyBannerView;
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
     onLog:[NSString stringWithFormat:
            @"Banner instance with ID: %@ changing from oldState=%@ to newState=%@",
            self.instanceID, self.instanceState, state]];
    self.instanceState = state;
}

@end
