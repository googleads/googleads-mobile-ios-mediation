// Copyright 2016 Google Inc.
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

#import "GADMAdapterIronSourceRewarded.h"

NSString *const kGADMAdapterIronSourceRewardedVideoPlacement = @"rewardedVideoPlacement";

@interface GADMAdapterIronSourceRewarded () {
    // Connector from Google Mobile Ads SDK to receive rewarded video ad configurations.
    __weak id<GADMRewardBasedVideoAdNetworkConnector> _rewardbasedVideoAdConnector;

    // IronSource rewardedVideo placement name
    NSString *_rewardedVideoPlacementName;
}

@end

@implementation GADMAdapterIronSourceRewarded

static BOOL initRewardedVideoSuccessfully;

#pragma mark Admob GADMRewardBasedVideoAdNetworkAdapter
- (instancetype)init {
    self = [super init];
    if (self) {
        [self onLog:@"general RV init"];
    }
    return self;
}

- (instancetype)initWithRewardBasedVideoAdNetworkConnector: (id<GADMRewardBasedVideoAdNetworkConnector>)connector {
    if (!connector) {
        return nil;
    }
    self = [super init];
    if (self) {
        _rewardbasedVideoAdConnector = connector;
        [self onLog:@"RV init"];
    }
    return self;
}

- (void)setUp {
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
    
    NSString *applicationKey = @"";
    if ([[strongConnector credentials] objectForKey:kGADMAdapterIronSourceAppKey]) {
        applicationKey = [[strongConnector credentials] objectForKey:kGADMAdapterIronSourceAppKey];
    }
    
    if ([[strongConnector credentials] objectForKey:kGADMAdapterIronSourceIsTestEnabled] != nil) {
        self.isTestEnabled = [[[strongConnector credentials] objectForKey:kGADMAdapterIronSourceIsTestEnabled] boolValue];
    } else {
        self.isTestEnabled = NO;
    }
    
    _rewardedVideoPlacementName = @"";
    if ([[strongConnector credentials] objectForKey:kGADMAdapterIronSourceRewardedVideoPlacement]) {
        _rewardedVideoPlacementName = [[strongConnector credentials] objectForKey:kGADMAdapterIronSourceRewardedVideoPlacement];
    }

    if (![self isEmpty:applicationKey]) {
        NSString *log = [NSString stringWithFormat:@"setUp params: appKey=%@, self.isTestEnabled=%d, _rewardedVideoPlacementName=%@", applicationKey, self.isTestEnabled, _rewardedVideoPlacementName];
        [self onLog:log];
        
        [IronSource setRewardedVideoDelegate:self];
        
        if (!initRewardedVideoSuccessfully) {
            [self initIronSourceSDKWithAppKey:applicationKey adUnit:IS_REWARDED_VIDEO];
            initRewardedVideoSuccessfully = YES;
        }
        
        [self requestRewardBasedVideoAd];
    } else {
        NSString *log = [NSString stringWithFormat:@"Fail to setup, appKey parameter is missing"];
        [self onLog:log];
        
        NSError *error = [self createErrorWith:@"IronSource Adapter failed to setUp"
                                     andReason:@"appKey parameter is missing"
                                 andSuggestion:@"make sure that 'appKey' server parameter is added"];
        
        [strongConnector adapter:self didFailToSetUpRewardBasedVideoAdWithError:error];
    }
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
    [self onLog:@"presentRewardBasedVideoAdWithRootViewController"];
    
    if ([self isEmpty:_rewardedVideoPlacementName]) {
        [IronSource showRewardedVideoWithViewController:viewController];
    } else {
        [IronSource showRewardedVideoWithViewController:viewController placement:_rewardedVideoPlacementName];
    }
}

#pragma mark RewardBasedVideo Utils Methods

-(void)initIronSourceSDKWithAppKey:(NSString *)appKey adUnit:(NSString *)adUnit {
    [super initIronSourceSDKWithAppKey:appKey adUnit:adUnit];
    
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
    [strongConnector adapterDidSetUpRewardBasedVideoAd:self];
}

- (void)requestRewardBasedVideoAd {
    [self onLog:@"requestRewardBasedVideoAd"];
    if([IronSource hasRewardedVideo]) {
        [self onLog:@"reward based video ad is available"];
        id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
        [strongConnector adapterDidReceiveRewardBasedVideoAd:self];
    }
}

#pragma mark IronSource Rewarded Video Delegate implementation

/*!
 * @discussion Invoked when there is a change in the ad availability status.
 *
 *              hasAvailableAds - value will change to YES when rewarded videos are available.
 *              You can then show the video by calling showRV(). Value will change to NO when no videos are available.
 */
- (void)rewardedVideoHasChangedAvailability:(BOOL)available {
    [self onLog: [NSString stringWithFormat:@"%@ - %i" , @"rewardedVideoHasChangedAvailability: " , available]];
    
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
    if (available) {
        [strongConnector adapterDidReceiveRewardBasedVideoAd:self];
    } else {
        NSError* AvailableAdsError = [self createErrorWith:@"IronSource network isn't available" andReason:@"Network fill issue" andSuggestion:@"Please talk with your PM and check that your network configuration are according to the documentation."];
        [strongConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:AvailableAdsError];
    }
}

/*!
* @discussion Invoked when the user completed the video and should be rewarded.
*
*              If using server-to-server callbacks you may ignore these events and wait for the callback from the IronSource server.
*              placementInfo - IronSourcePlacementInfo - an object contains the placement's reward name and amount
*/
- (void)didReceiveRewardForPlacement:(ISPlacementInfo *)placementInfo {
    [self onLog:@"didReceiveRewardForPlacement"];
    
    GADAdReward *reward;
    if (placementInfo) {
        NSString * rewardName = [placementInfo rewardName];
        NSNumber * rewardAmount = [placementInfo rewardAmount];
        reward = [[GADAdReward alloc] initWithRewardType:rewardName
                                            rewardAmount:[NSDecimalNumber decimalNumberWithDecimal:[rewardAmount decimalValue]]];
        
        id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
        [strongConnector adapter: self didRewardUserWithReward:reward];
        
    } else {
        [self onLog:@"ironSourceRVAdRewarded - did not receive placement info"];
    }
}

/*!
 * @discussion Invoked when an Ad failed to display.
 *
 *          error - NSError which contains the reason for the failure.
 *          The error contains error.code and error.localizedDescription
 */
- (void)rewardedVideoDidFailToShowWithError:(NSError *)error {
    [self onLog:[NSString stringWithFormat:@"rewardedVideoDidFailToShowWithError: %@",error.localizedDescription]];
}

/*!
 * @discussion Invoked when the RewardedVideo ad view has opened.
 */
- (void)rewardedVideoDidOpen {
    [self onLog:@"rewardedVideoDidOpen"];
    
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
    [strongConnector adapterDidOpenRewardBasedVideoAd:self];
    [strongConnector adapterDidStartPlayingRewardBasedVideoAd:self];
}

/*!
 * @discussion Invoked when the user is about to return to the application after closing the RewardedVideo ad.
 */
- (void)rewardedVideoDidClose {
    [self onLog:@"rewardedVideoDidClose"];
    
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
    [strongConnector adapterDidCloseRewardBasedVideoAd:self];
}

/*!
 * @discussion Invoked when the video ad starts playing.
 *
 *             Available for: AdColony, Vungle, AppLovin, UnityAds
 */
- (void)rewardedVideoDidStart {
    [self onLog:@"rewardedVideoDidStart"];
}

/*!
 * @discussion Invoked when the video ad finishes playing.
 *
 *             Available for: AdColony, Flurry, Vungle, AppLovin, UnityAds.
 */
- (void)rewardedVideoDidEnd {
    [self onLog:@"rewardedVideoDidEnd"];
}

/*!
 * @discussion Invoked after a video has been clicked.
 */
- (void)didClickRewardedVideo:(ISPlacementInfo *)placementInfo {
    [self onLog:@"didClickRewardedVideo"];
    
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
    [strongConnector adapterDidGetAdClick:self];
    [strongConnector adapterWillLeaveApplication:self];
}

@end
