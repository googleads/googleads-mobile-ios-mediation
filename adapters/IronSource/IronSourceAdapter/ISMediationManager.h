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

#import <Foundation/Foundation.h>
@import GoogleMobileAds;
#import <IronSource/IronSource.h>
#import "GADMAdapterIronSourceBase.h"

@protocol ISAdAvailabilityChangedDelegate
- (void)adReady;
- (void)didFailToLoadWithError:(NSError *)error;
- (NSString *)getInstanceID;
- (void)didClickRewardedVideo:(ISPlacementInfo *)placementInfo instanceId:(NSString *)instanceId;
- (void)rewardedVideoDidClose:(NSString *)instanceId;
- (void)rewardedVideoDidOpen:(NSString *)instanceId;
- (void)rewardedVideoDidFailToShowWithError:(NSError *)error instanceId:(NSString *)instanceId;
- (void)didReceiveRewardForPlacement:(ISPlacementInfo *)placementInfo
                          instanceId:(NSString *)instanceId;
@end

@interface ISMediationManager : NSObject <ISDemandOnlyRewardedVideoDelegate>

+ (instancetype)shared;
- (void)addDelegate:(id<ISAdAvailabilityChangedDelegate>)adapterDelegate;
- (void)removeDelegateForInstanceID:(NSString *)instanceID;
- (void)adAvailabilityChangedWithInstanceID:(NSString *)instanceID available:(BOOL)available;
- (void)requestRewardedAdWithDelegate:(id<ISAdAvailabilityChangedDelegate>)delegate;
- (void)presentFromViewController:(nonnull UIViewController *)viewController
                         delegate:(id<ISAdAvailabilityChangedDelegate>)delegate;
@property(nonatomic) NSMutableDictionary *adapterDelegates;
@property(nonatomic, getter=isIronSourceRewardedInitialized) BOOL ironSourceRewardedInitialized;

@end
