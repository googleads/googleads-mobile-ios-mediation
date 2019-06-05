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
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceUtils.h"

@interface ISMediationManager ()

@property(nonatomic)
NSMapTable<NSString *, id<GADMAdapterIronSourceDelegate>>
*_rewardedAdapterDelegates;
@property(nonatomic)
NSMapTable<NSString *, id<GADMAdapterIronSourceInterstitialDelegate>>
*_interstitialAdapterDelegates;

@end

@implementation ISMediationManager

+ (instancetype)sharedManager {
    static ISMediationManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (instancetype)init {
    if (self = [super init]) {
        self._rewardedAdapterDelegates =
        [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                              valueOptions:NSPointerFunctionsWeakMemory];
        self._interstitialAdapterDelegates =
        [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                              valueOptions:NSPointerFunctionsWeakMemory];
        [IronSource setMediationType:[NSString stringWithFormat:@"%@%@SDK%@",
                                      kGADMAdapterIronSourceMediationName,kGADMAdapterIronSourceAdapterVersion,[GADMAdapterIronSourceUtils getAdMobSDKVersion]]];
    }
    return self;
}

- (void)initIronSourceSDKWithAppKey:(NSString *)appKey forAdUnits:(NSSet *)adUnits {
    if([adUnits member:@[IS_INTERSTITIAL]] != nil){
        static dispatch_once_t onceTokenIS;
        dispatch_once(&onceTokenIS, ^{
            [IronSource setISDemandOnlyInterstitialDelegate:self];
            [IronSource initISDemandOnly:appKey adUnits:@[IS_INTERSTITIAL]];
        });
    }
    if([adUnits member:@[IS_REWARDED_VIDEO]] != nil){
        static dispatch_once_t onceTokenRV;
        dispatch_once(&onceTokenRV, ^{
            [IronSource setISDemandOnlyRewardedVideoDelegate:self];
            [IronSource initISDemandOnly:appKey adUnits:@[IS_REWARDED_VIDEO]];
        });
    }
}

- (void)loadRewardedAdWithDelegate:
(id<GADMAdapterIronSourceDelegate>)delegate instanceID:(NSString *)instanceID {
    id<GADMAdapterIronSourceDelegate> adapterDelegate = delegate;
    
    if (adapterDelegate == nil) {
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:
                                           @"loadRewardedAdWithDelegate adapterDelegate is null"]];
        return;
    }
    if([self canLoadRewardedVideoInstance:instanceID]){
        [self changeInstanceState:adapterDelegate forRVState:kInstanceLockedState];
        [self addRewardedDelegate:adapterDelegate forInstanceID:instanceID];
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager - loadRewardedVideo for instance Id %@", instanceID]];
        [IronSource loadISDemandOnlyRewardedVideo:instanceID];
    }
    
    else {
        NSError *Error = [GADMAdapterIronSourceUtils
                          createErrorWith:@"instance already exists"
                          andReason:@"couldn't load another one in the same time!"
                          andSuggestion:nil];
        [adapterDelegate rewardedVideoDidFailToLoadWithError:Error instanceId:instanceID];
    }
}

- (void)presentRewardedAdFromViewController:(nonnull UIViewController *)viewController
                                 instanceID:(NSString *)instanceID {
    [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager - showRewardedVideo for instance Id %@", instanceID]];
    [IronSource showISDemandOnlyRewardedVideo:viewController instanceId:instanceID];
}

- (void)requestInterstitialAdWithDelegate:
(id<GADMAdapterIronSourceInterstitialDelegate>)delegate
                               instanceID:(NSString *)instanceID{
    id<GADMAdapterIronSourceInterstitialDelegate> adapterDelegate = delegate;
    if (adapterDelegate == nil) {
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:
                                           @"requestInterstitialAdWithDelegate adapterDelegate is null"]];
        return;
    }
    if([self canLoadInterstitialInstance:instanceID]){
        [self changeInstanceState:adapterDelegate forISState:kInstanceLockedState];
        [self addInterstitialDelegate:adapterDelegate forInstanceID:instanceID];
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager - loadInterstitial  for instance Id %@", instanceID]];
        [IronSource loadISDemandOnlyInterstitial:instanceID];
    }
    else {
        NSError *Error = [GADMAdapterIronSourceUtils
                          createErrorWith:@"instance already exists"
                          andReason:@"couldn't load another one in the same time!"
                          andSuggestion:nil];
        [adapterDelegate interstitialDidFailToLoadWithError:Error instanceId:instanceID];
    }
}

- (void)presentInterstitialAdFromViewController:(nonnull UIViewController *)viewController
                                     instanceID:(NSString *)instanceID{
    [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager - showInterstitial for instance Id %@", instanceID]];
    [IronSource showISDemandOnlyInterstitial:viewController instanceId:instanceID];
}

#pragma mark ISDemandOnlyRewardedDelegate

- (void)rewardedVideoAdRewarded:(NSString *)instanceId {
    [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager got rewardedVideoAdRewarded for instance %@",instanceId]];
    id<GADMAdapterIronSourceDelegate> delegate =
    [self getRewardedDelegateForInstanceID:instanceId];
    if (delegate) {
        [delegate rewardedVideoAdRewarded:instanceId];
    }else {
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager - rewardedVideoAdRewarded adapterDelegate is null"]];
    }
}

- (void)rewardedVideoDidFailToShowWithError:(NSError *)error instanceId:(NSString *)instanceId {
    [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager got rewardedVideoDidFailToShowWithError for instance %@ with error %@", instanceId, error]];
    id<GADMAdapterIronSourceDelegate> delegate =
    [self getRewardedDelegateForInstanceID:instanceId];
    if (delegate) {
        [self changeInstanceState:delegate forRVState:kInstanceCanLoadState];
        [delegate rewardedVideoDidFailToShowWithError:error instanceId:instanceId];
    }else {
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager - rewardedVideoDidFailToShowWithError adapterDelegate is null"]];
    }
}

- (void)rewardedVideoDidOpen:(NSString *)instanceId {
    [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager got rewardedVideoDidOpen for instance %@",instanceId]];
    id<GADMAdapterIronSourceDelegate> delegate =
    [self getRewardedDelegateForInstanceID:instanceId];
    if (delegate) {
        [delegate rewardedVideoDidOpen:instanceId];
    }else {
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager - rewardedVideoDidOpen adapterDelegate is null"]];
    }
}

- (void)rewardedVideoDidClose:(NSString *)instanceId {
    [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager got rewardedVideoDidClose for instance %@",instanceId]];
    id<GADMAdapterIronSourceDelegate> delegate =
    [self getRewardedDelegateForInstanceID:instanceId];
    if (delegate) {
        [self changeInstanceState:delegate forRVState:kInstanceCanLoadState];
        [delegate rewardedVideoDidClose:instanceId];
    }else {
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager - rewardedVideoDidClose adapterDelegate is null"]];
    }
}

- (void)rewardedVideoDidClick:(NSString *)instanceId {
    [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager got rewardedVideoDidClick for instance %@",instanceId]];
    
    id<GADMAdapterIronSourceDelegate> delegate =
    [self getRewardedDelegateForInstanceID:instanceId];
    if (delegate) {
        [delegate rewardedVideoDidClick:instanceId];
    }else {
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager - rewardedVideoDidClick adapterDelegate is null"]];
    }
}

- (void)rewardedVideoDidLoad:(NSString *)instanceId{
    [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager got rewardedVideoDidLoad for instance %@",instanceId]];
    
    id<GADMAdapterIronSourceDelegate> delegate = [self getRewardedDelegateForInstanceID:instanceId];
    if(delegate){
        [delegate rewardedVideoDidLoad:instanceId];
    }else {
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager - rewardedVideoDidLoad adapterDelegate is null"]];
    }
}

- (void)rewardedVideoDidFailToLoadWithError:(NSError *)error instanceId:(NSString *)instanceId{
    [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager got rewardedVideoDidFailToLoadWithError for instance %@ with error %@", instanceId, error]];
    id<GADMAdapterIronSourceDelegate> delegate = [self getRewardedDelegateForInstanceID:instanceId];
    if(delegate){
        [self changeInstanceState:delegate forRVState:kInstanceCanLoadState];
        [delegate rewardedVideoDidFailToLoadWithError:error instanceId:instanceId];
    }else {
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager - rewardedVideoDidFailToLoadWithError adapterDelegate is null"]];
    }
}

#pragma mark ISDemandOnlyInterstitialDelegate

- (void)interstitialDidLoad:(NSString *)instanceId {
    id<GADMAdapterIronSourceInterstitialDelegate> delegate =
    [self getInterstitialDelegateForInstanceID:instanceId];
    if (delegate) {
        [delegate interstitialDidLoad:instanceId];
    }else {
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager - interstitialDidLoad adapterDelegate is null"]];
    }
}

- (void)interstitialDidFailToLoadWithError:(NSError *)error instanceId:(NSString *)instanceId {
    id<GADMAdapterIronSourceInterstitialDelegate> delegate =
    [self getInterstitialDelegateForInstanceID:instanceId];
    if (delegate) {
        [self changeInstanceState:delegate forISState:kInstanceCanLoadState];
        [delegate interstitialDidFailToLoadWithError:error instanceId:instanceId];
    }else {
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager - interstitialDidFailToLoadWithError adapterDelegate is null"]];
    }
}

- (void)interstitialDidOpen:(NSString *)instanceId {
    id<GADMAdapterIronSourceInterstitialDelegate> delegate =
    [self getInterstitialDelegateForInstanceID:instanceId];
    if (delegate) {
        [delegate interstitialDidOpen:instanceId];
    }else {
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager - interstitialDidOpen adapterDelegate is null"]];
    }
}

- (void)interstitialDidClose:(NSString *)instanceId {
    id<GADMAdapterIronSourceInterstitialDelegate> delegate =
    [self getInterstitialDelegateForInstanceID:instanceId];
    if (delegate) {
        [self changeInstanceState:delegate forISState:kInstanceCanLoadState];
        [delegate interstitialDidClose:instanceId];
    }else {
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager - interstitialDidClose adapterDelegate is null"]];
    }
}

- (void)interstitialDidFailToShowWithError:(NSError *)error instanceId:(NSString *)instanceId {
    id<GADMAdapterIronSourceInterstitialDelegate> delegate =
    [self getInterstitialDelegateForInstanceID:instanceId];
    if (delegate) {
        [self changeInstanceState:delegate forISState:kInstanceCanLoadState];
        [delegate interstitialDidFailToShowWithError:error instanceId:instanceId];
    }else {
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager - interstitialDidFailToShowWithError adapterDelegate is null"]];
    }
}

- (void)didClickInterstitial:(NSString *)instanceId {
    id<GADMAdapterIronSourceInterstitialDelegate> delegate =
    [self getInterstitialDelegateForInstanceID:instanceId];
    if (delegate) {
        [delegate didClickInterstitial:instanceId];
    }else {
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager - didClickInterstitial adapterDelegate is null"]];
    }
}

#pragma Utils methods

- (void)addRewardedDelegate:
(id<GADMAdapterIronSourceDelegate>)adapterDelegate
              forInstanceID:(NSString *)instanceID {
    @synchronized(self._rewardedAdapterDelegates) {
        [self._rewardedAdapterDelegates setObject:adapterDelegate forKey:instanceID];
    }
}

- (id<GADMAdapterIronSourceDelegate>)
getRewardedDelegateForInstanceID:(NSString *)instanceID {
    id<GADMAdapterIronSourceDelegate> delegate;
    @synchronized(self._rewardedAdapterDelegates) {
        delegate = [self._rewardedAdapterDelegates objectForKey:instanceID];
    }
    return delegate;
}

- (void)addInterstitialDelegate:
(id<GADMAdapterIronSourceInterstitialDelegate>)adapterDelegate
                  forInstanceID:(NSString *)instanceID {
    @synchronized(self._interstitialAdapterDelegates) {
        [self._interstitialAdapterDelegates setObject:adapterDelegate forKey:instanceID];
    }
}

- (id< GADMAdapterIronSourceInterstitialDelegate>)
getInterstitialDelegateForInstanceID:(NSString *)instanceID {
    id<GADMAdapterIronSourceInterstitialDelegate> delegate;
    @synchronized(self._interstitialAdapterDelegates) {
        delegate = [self._interstitialAdapterDelegates objectForKey:instanceID];
    }
    return delegate;
}


-(BOOL) canLoadRewardedVideoInstance:(NSString *)instanceID {
    if(![self isISRewardedVideoAdapterRegistered:instanceID]){
        return true;
    }
    
    if([self isRegisteredRewardedVideoAdapterCanLoad:instanceID]){
        return true;
    }
    
    return false;
}

-(BOOL) isRegisteredRewardedVideoAdapterCanLoad: (NSString *)instanceID {
    id<GADMAdapterIronSourceDelegate> adapterDelegate =
    [self getRewardedDelegateForInstanceID:instanceID];
    if(adapterDelegate == nil){
        return true;
    }
    
    if(!([[adapterDelegate getState] isEqualToString:kInstanceCanLoadState])){
        return false;
    }
    
    return true;
}

-(BOOL) isISRewardedVideoAdapterRegistered: (NSString *)instanceID {
    id<GADMAdapterIronSourceDelegate> adapterDelegate =
    [self getRewardedDelegateForInstanceID:instanceID];
    if(adapterDelegate == nil){
        return false;
    }
    
    return true;
}

-(void) changeInstanceState: (id<GADMAdapterIronSourceDelegate>) adapterDelegate forRVState: (NSString *) state {
    id<GADMAdapterIronSourceDelegate> delegate = adapterDelegate;
    if(delegate == nil){
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"changeInstanceState- adapterDelegate is nil"]];
        return;
    }
    [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager change state to %@",state]];
    [delegate setState:state];
}

-(BOOL) canLoadInterstitialInstance:(NSString *)instanceID {
    if(![self isISInterstitialAdapterRegistered:instanceID]){
        return true;
    }
    
    if([self isRegisteredInterstitialAdapterCanLoad:instanceID]){
        return true;
    }
    
    return false;
}

-(BOOL) isRegisteredInterstitialAdapterCanLoad: (NSString *)instanceID {
    id<GADMAdapterIronSourceInterstitialDelegate> adapterDelegate =
    [self getInterstitialDelegateForInstanceID:instanceID];
    if(adapterDelegate == nil){
        return true;
    }
    
    if(!([[adapterDelegate getState] isEqualToString:kInstanceCanLoadState])){
        return false;
    }
    
    return true;
}

-(BOOL) isISInterstitialAdapterRegistered: (NSString *)instanceID {
    id<GADMAdapterIronSourceInterstitialDelegate> adapterDelegate =
    [self getInterstitialDelegateForInstanceID:instanceID];
    if(adapterDelegate == nil){
        return false;
    }
    
    return true;
}

-(void) changeInstanceState: (id<GADMAdapterIronSourceInterstitialDelegate>) adapterDelegate forISState: (NSString *) state {
    id<GADMAdapterIronSourceInterstitialDelegate> delegate = adapterDelegate;
    
    if(delegate == nil){
        [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"changeInstanceState- adapterDelegate is nil"]];
        return;
    }
    [GADMAdapterIronSourceUtils onLog:[NSString stringWithFormat:@"ISMediationManager change state to %@",state]];
    [delegate setState:state];
}

@end
