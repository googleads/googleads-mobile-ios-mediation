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

#import "GADMAdapterIronSource.h"

// IronSource mediation network adapter version.
NSString *const kGADMAdapterIronSourceVersion = @"6.7.3.0";
// IronSource internal reporting const
NSString *const kGADMMediationName = @"AdMob";
// IronSource parameters keys
NSString *const kGADMAdapterIronSourceAppKey = @"appKey";
NSString *const kGADMAdapterIronSourceIsTestEnabled = @"isTestEnabled";
NSString *const kGADMAdapterIronSourceRewardedVideoPlacement = @"rewardedVideoPlacement";
NSString *const kGADMAdapterIronSourceInterstitialPlacement = @"interstitialPlacement";

@interface GADMAdapterIronSource () {
    //Connector from Google Mobile Ads SDK to receive rewarded video ad configurations.
    __weak id<GADMRewardBasedVideoAdNetworkConnector> _rewardbasedVideoAdConnector;
    
    //Connector from Google Mobile Ads SDK to receive interstitial ad configurations.
    __weak id<GADMAdNetworkConnector> _interstitialConnector;
    
    //Yes if we want to show adapter logs
    BOOL _isTestEnabled;
    
    //IronSource rewarded video placement name
    NSString* _interstitialPlacementName;
    
    //IronSource interstitial placement name
    NSString* _rewardedVideoPlacementName;
}

@end

@implementation GADMAdapterIronSource

#pragma mark Admob GADMRewardBasedVideoAdNetworkAdapter

+ (NSString *)adapterVersion {
    return kGADMAdapterIronSourceVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    return [GADMIronSourceExtras class];
}

- (instancetype)initWithRewardBasedVideoAdNetworkConnector: (id<GADMRewardBasedVideoAdNetworkConnector>)connector {
    if (!connector) {
        return nil;
    }
    self = [super init];
    if (self) {
        _rewardbasedVideoAdConnector = connector;
    }
    return self;
}

- (void)setUp {
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
    
    NSString* applicationKey = @"";
    if ([[strongConnector credentials] objectForKey:kGADMAdapterIronSourceAppKey]) {
        applicationKey = [[strongConnector credentials] objectForKey:kGADMAdapterIronSourceAppKey];
    }
    
    if ([[strongConnector credentials] objectForKey:kGADMAdapterIronSourceIsTestEnabled] != nil) {
        _isTestEnabled = [[[strongConnector credentials] objectForKey:kGADMAdapterIronSourceIsTestEnabled] boolValue];
    } else {
        _isTestEnabled = NO;
    }
    
    _rewardedVideoPlacementName = @"";
    if ([[strongConnector credentials] objectForKey:kGADMAdapterIronSourceRewardedVideoPlacement]) {
        _rewardedVideoPlacementName = [[strongConnector credentials] objectForKey:kGADMAdapterIronSourceRewardedVideoPlacement];
    }
    
    _interstitialPlacementName = @"";
    if ([[strongConnector credentials] objectForKey:kGADMAdapterIronSourceInterstitialPlacement]) {
        _interstitialPlacementName = [[strongConnector credentials] objectForKey:kGADMAdapterIronSourceInterstitialPlacement];
    }
    
    [self onLog:[NSString stringWithFormat:@"setUp params: appKey=%@, _isTestEnabled=%d, _rewardedVideoPlacementName=%@, _interstitialPlacementName=%@", applicationKey, _isTestEnabled, _rewardedVideoPlacementName, _interstitialPlacementName]];
    
    if (applicationKey && applicationKey.length > 0) {
        [IronSource setRewardedVideoDelegate:self];
        [self initIronSourceSDKWithAppKey:applicationKey adUnit:IS_REWARDED_VIDEO];
        [self requestRewardBasedVideoAd];
    } else {
        NSError* error = [self createErrorWith:@"IronSource Adapter failed to setUp" andReason:@"appKey parameter is missing" andSuggestion:@"make sure that 'appKey' server parameter is added"];
        [strongConnector adapter:self didFailToSetUpRewardBasedVideoAdWithError:error];
    }
    
    [self onLog:@"setUp"];
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
    [self onLog:@"presentRewardBasedVideoAdWithRootViewController"];
    
    if ([self isEmpty:_rewardedVideoPlacementName]) {
        [IronSource showRewardedVideoWithViewController:viewController];
    } else {
        [IronSource showRewardedVideoWithViewController:viewController placement:_rewardedVideoPlacementName];
    }
}

- (void)stopBeingDelegate {
    [self onLog:@"stopBeingDelegate"];
}

- (void)getBannerWithSize:(GADAdSize)adSize {
    [self showBannersNotSupportedError];
}

- (void)getInterstitial {
    id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
    
    NSString* applicationKey = @"";
    if ([[strongConnector credentials] objectForKey:kGADMAdapterIronSourceAppKey]) {
        applicationKey = [[strongConnector credentials] objectForKey:kGADMAdapterIronSourceAppKey];
    }
    
    if ([[strongConnector credentials] objectForKey:kGADMAdapterIronSourceIsTestEnabled] != nil) {
        _isTestEnabled = [[[strongConnector credentials] objectForKey:kGADMAdapterIronSourceIsTestEnabled] boolValue];
    } else {
        _isTestEnabled = NO;
    }
    
    _rewardedVideoPlacementName = @"";
    if ([[strongConnector credentials] objectForKey:kGADMAdapterIronSourceRewardedVideoPlacement]) {
        _rewardedVideoPlacementName = [[strongConnector credentials] objectForKey:kGADMAdapterIronSourceRewardedVideoPlacement];
    }
    
    _interstitialPlacementName = @"";
    if ([[strongConnector credentials] objectForKey:kGADMAdapterIronSourceInterstitialPlacement]) {
        _interstitialPlacementName = [[strongConnector credentials] objectForKey:kGADMAdapterIronSourceInterstitialPlacement];
    }
    
    [self onLog:[NSString stringWithFormat:@"getInterstitial params: appKey=%@, _isTestEnabled=%d, _rewardedVideoPlacementName=%@, _interstitialPlacementName=%@", applicationKey, _isTestEnabled, _rewardedVideoPlacementName, _interstitialPlacementName]];
    
    if (applicationKey && applicationKey.length > 0) {
        [IronSource setInterstitialDelegate:self];
        [self initIronSourceSDKWithAppKey:applicationKey adUnit:IS_INTERSTITIAL];
        [self loadInterstitialAd];
    } else {
        NSError* error = [self createErrorWith:@"IronSource Adapter failed to getInterstitial" andReason:@"appKey parameter is missing" andSuggestion:@"make sure that 'appKey' server parameter is added"];
        [strongConnector adapter:self didFailAd:error];
    }
    
    [self onLog:@"getInterstitial"];
}


- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
    if (!connector) {
        return nil;
    }
    self = [super init];
    if (self) {
        _interstitialConnector = connector;
    }
    return self;
}


- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
    [self showBannersNotSupportedError];
    return YES;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
    [self onLog:@"presentInterstitialFromRootViewController"];
    
    if (_interstitialPlacementName) {
        [IronSource showInterstitialWithViewController:rootViewController placement:_interstitialPlacementName];
    } else {
        [IronSource showInterstitialWithViewController:rootViewController];
    }
}

#pragma mark Utils Methods

-(void) initIronSourceSDKWithAppKey:(NSString*)appKey adUnit:(NSString*)adUnit {
    // 1 - We are not sending user ID from adapters anymore,
    //     the IronSource SDK will take care of this identifier
    
    // 2 - We assume the init is always successful (we will fail in load if needed)
    
    [ISConfigurations getConfigurations].plugin = kGADMMediationName;
    [ISConfigurations getConfigurations].pluginVersion = kGADMAdapterIronSourceVersion;
    
    NSString* admobVersion = [[NSString alloc] initWithBytes:GoogleMobileAdsVersionString
                                                      length:strlen((char*)GoogleMobileAdsVersionString) encoding:NSASCIIStringEncoding];
    
    [ISConfigurations getConfigurations].pluginFrameworkVersion = admobVersion;
    
    [IronSource initWithAppKey:appKey adUnits:@[adUnit]];
    
    [self onLog:@"initIronSourceSDKWithAppKey"];
    
    if ([adUnit isEqualToString:IS_REWARDED_VIDEO]) {
        id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
        [strongConnector adapterDidSetUpRewardBasedVideoAd:self];
    } else if ([adUnit isEqualToString:IS_INTERSTITIAL]) {
        // we don't need to send any callbacks
    }
}

- (void)requestRewardBasedVideoAd {
    [self onLog:@"requestRewardBasedVideoAd"];
    if([IronSource hasRewardedVideo]) {
        [self onLog:@"reward based video ad is available"];
        id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
        [strongConnector adapterDidReceiveRewardBasedVideoAd:self];
    }
}

- (void)loadInterstitialAd {
    [self onLog:@"loadInterstitialAd"];
    
    if ([IronSource hasInterstitial]) {
        [_interstitialConnector adapterDidReceiveInterstitial:self];
    } else {
        [IronSource loadInterstitial];
    }
}

- (void) onLog: (NSString *) log {
    if(_isTestEnabled) {
        NSLog(@"IronSourceAdapter: %@" , log);
    }
}

-(BOOL) isEmpty: (id) thing
{
    return thing == nil
    || [thing isKindOfClass:[NSNull class]]
    || ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
    || ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
    
}

- (NSError*) createErrorWith:(NSString*)description andReason:(NSString*)reason andSuggestion:(NSString*)suggestion {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: NSLocalizedString(description, nil),
                               NSLocalizedFailureReasonErrorKey: NSLocalizedString(reason, nil),
                               NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(suggestion, nil)
                               };
    
    return [NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:userInfo];
}

- (void)showBannersNotSupportedError {
    // IronSource Adapter doesn't support banner ads.
    NSError* error = [self createErrorWith:@"IronSource Adapter doesn't support banner ads" andReason:@"" andSuggestion:@""];
    [_interstitialConnector adapter:self didFailAd:error];
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
 *          The error contains error.code and error.message.
 */
- (void)rewardedVideoDidFailToShowWithError:(NSError *)error {
    [self onLog:@"rewardedVideoDidFailToShowWithError:"];
}

/*!
 * @discussion Invoked when the RewardedVideo ad view has opened.
 *
 */
- (void)rewardedVideoDidOpen {
    [self onLog:@"rewardedVideoDidOpen"];
    
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
    [strongConnector adapterDidOpenRewardBasedVideoAd:self];
    [strongConnector adapterDidStartPlayingRewardBasedVideoAd:self];
}

/*!
 * @discussion Invoked when the user is about to return to the application after closing the RewardedVideo ad.
 *
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

- (void)didClickRewardedVideo:(ISPlacementInfo *)placementInfo {
    [self onLog:@"didClickRewardedVideo"];
    
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
    [strongConnector adapterDidGetAdClick:self];
    [strongConnector adapterWillLeaveApplication:self];
}

#pragma mark IronSource Interstitial Delegates implementation

- (void)interstitialDidLoad {
    [self onLog:@"interstitialDidLoad"];
    
    [_interstitialConnector adapterDidReceiveInterstitial:self];
}

- (void)interstitialDidFailToLoadWithError:(NSError *)error {
    [self onLog:[NSString stringWithFormat:@"interstitialDidFailToLoadWithError: %@", error.localizedDescription]];
    
    if (!error) {
        error = [self createErrorWith:@"network load error"
                            andReason:@"IronSource network failed to load"
                        andSuggestion:@"Please check that your network configuration are according to the documentation."];
    }
    
    [_interstitialConnector adapter:self didFailAd:error];
}

/*!
 * @discussion Called each time the Interstitial window is about to open
 */
- (void)interstitialDidOpen {
    [self onLog:@"interstitialDidOpen"];
    
    [_interstitialConnector adapterWillPresentInterstitial:self];
}

/*!
 * @discussion Called each time the Interstitial window is about to close
 */
- (void)interstitialDidClose {
    [self onLog:@"interstitialDidClose"];
    
    id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
    [strongConnector adapterWillDismissInterstitial:self];
    [strongConnector adapterDidDismissInterstitial:self];
}

/*!
 * @discussion Called each time the Interstitial window has opened successfully.
 */
- (void)interstitialDidShow {
    [self onLog:@"interstitialDidShow"];
}

/*!
 * @discussion Called if showing the Interstitial for the user has failed.
 *
 *              You can learn about the reason by examining the ‘error’ value
 */
- (void)interstitialDidFailToShowWithError:(NSError *)error {
    [self onLog:[NSString stringWithFormat:@"interstitialDidFailToShowWithError: %@", error.localizedDescription]];
    
    if (!error) {
        error = [self createErrorWith:@"Interstitial show error"
                            andReason:@"IronSource network failed to show an interstitial ad"
                        andSuggestion:@"Please check that your configurations are according to the documentation."];
    }
    
    [_interstitialConnector adapter:self didFailAd:error];
}

/*!
 * @discussion Called each time the end user has clicked on the Interstitial ad.
 */
- (void)didClickInterstitial{
    [self onLog:@"didClickInterstitial"];
    
    id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
    [strongConnector adapterDidGetAdClick:self];
    [strongConnector adapterWillLeaveApplication:self];
}

@end
