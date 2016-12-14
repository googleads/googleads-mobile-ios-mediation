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

#import "GADMAdapterTapjoy.h"
#import "GADMTapjoyExtras.h"
#import <Tapjoy/TJPlacement.h>
#import <Tapjoy/Tapjoy.h>

NSString *const kGADMAdapterTapjoyVersion = @"11.9.0.0";

@interface GADMAdapterTapjoy () <TJPlacementVideoDelegate, TJPlacementDelegate> {
    // Connector from Google Mobile Ads SDK to receive ad configurations.
    __weak id<GADMRewardBasedVideoAdNetworkConnector> _rewardBasedVideoAdConnector;
    TJPlacement *_placement;
    BOOL _isRequesting;
}
@end

@implementation GADMAdapterTapjoy

+ (NSString *)adapterVersion {
    return kGADMAdapterTapjoyVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    return [GADMTapjoyExtras class];
}

#pragma mark Rewardbased video

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:
(id<GADMRewardBasedVideoAdNetworkConnector>)connector {
    if (!connector) {
        return nil;
    }
    self = [super init];
    if (self) {
        _rewardBasedVideoAdConnector = connector;
    }
    return self;
}


- (void)setUp {
    NSString *sdkKey = [[_rewardBasedVideoAdConnector credentials] objectForKey:@"sdkKey"];
    NSString *placementName = [[_rewardBasedVideoAdConnector credentials] objectForKey:@"placementName"];
    
    if (!sdkKey.length || !placementName.length) {
        NSError *adapterError = [NSError errorWithDomain:@"com.google.mediation.tapjoy" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Did not receive valid Tapjoy server parameters"}];
        [_rewardBasedVideoAdConnector adapter:self didFailToSetUpRewardBasedVideoAdWithError:adapterError];
        return;
    }
    
    // if not yet connected, wait for connect response before requesting placement
    if (![Tapjoy isConnected]) {
        [self setupListeners];
        GADMTapjoyExtras *extras = [_rewardBasedVideoAdConnector networkExtras];
        NSMutableDictionary *connectOptions = [[NSMutableDictionary alloc] init];
        [connectOptions setObject:@(extras.debugEnabled) forKey:TJC_OPTION_ENABLE_LOGGING];
        
        [Tapjoy connect:sdkKey options:connectOptions];
    }
    else {
        [_rewardBasedVideoAdConnector adapterDidSetUpRewardBasedVideoAd:self];
    }
}

- (void)setupListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tjcConnectSuccess:)
                                                 name:TJC_CONNECT_SUCCESS
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tjcConnectFail:)
                                                 name:TJC_CONNECT_FAILED
                                               object:nil];
}

-(void)tjcConnectSuccess:(NSNotification*)notifyObj
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TJC_CONNECT_SUCCESS object:nil];
    
    [_rewardBasedVideoAdConnector adapterDidSetUpRewardBasedVideoAd:self];
}

- (void)tjcConnectFail:(NSNotification*)notifyObj
{
    NSError *adapterError = [NSError errorWithDomain:@"com.google.mediation.tapjoy" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Tapjoy Connect did not succeed."}];
    [_rewardBasedVideoAdConnector adapter:self didFailToSetUpRewardBasedVideoAdWithError:adapterError];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TJC_CONNECT_FAILED object:nil];
    
}

- (void)initPlacement {
    NSString *videoPlacementName = [[_rewardBasedVideoAdConnector credentials] objectForKey:@"placementName"];
    _placement = [TJPlacement placementWithName:videoPlacementName mediationAgent:@"admob" mediationId:nil delegate:self];
    _placement.adapterVersion = @"1.0.0";
    _placement.videoDelegate = self;
    
    _isRequesting = YES;
    [_placement requestContent];
}

- (void)requestRewardBasedVideoAd {
    NSString *videoPlacementName = [[_rewardBasedVideoAdConnector credentials] objectForKey:@"placementName"];
    
    if (!videoPlacementName.length) {
        NSError *adapterError = [NSError errorWithDomain:@"com.google.mediation.tapjoy" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Tapjoy placement name empty or missing"}];
        [_rewardBasedVideoAdConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:adapterError];
        return;
    }
    
    // If incoming placement name is different from the one already preloaded, create new placement
    if (_placement && ![videoPlacementName isEqualToString:_placement.placementName]) {
        [self initPlacement];
    }
    // If content is already available from previous request, fire success
    else if (_placement && _placement.contentReady) {
        [_rewardBasedVideoAdConnector adapterDidReceiveRewardBasedVideoAd:self];
    }
    else {
        // If we're not already in the middle of a request, send new placement request
        if (!_isRequesting) {
            [self initPlacement];
        }
    }
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
    [_placement showContentWithViewController:viewController];
}

- (void)stopBeingDelegate {
    _placement.delegate = nil;
    _placement.videoDelegate = nil;
}

#pragma mark - TJPlacementDelegate methods
- (void)requestDidSucceed:(TJPlacement*)placement{
    if (!placement.contentAvailable) {
        _isRequesting = NO;
        NSError *adapterError = [NSError errorWithDomain:@"com.google.mediation.tapjoy" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Tapjoy Video not available"}];
        [_rewardBasedVideoAdConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:adapterError];
    }
}

- (void)requestDidFail:(TJPlacement*)placement error:(NSError*)error{
    _isRequesting = NO;
    NSError *adapterError = [NSError errorWithDomain:@"com.google.mediation.tapjoy" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Tapjoy Video failed to load"}];
    [_rewardBasedVideoAdConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:adapterError];
}

- (void)contentIsReady:(TJPlacement*)placement{
    _isRequesting = NO;
    
    [_rewardBasedVideoAdConnector adapterDidReceiveRewardBasedVideoAd:self];
}
- (void)contentDidAppear:(TJPlacement*)placement{
    [_rewardBasedVideoAdConnector adapterDidOpenRewardBasedVideoAd:self];
}

- (void)contentDidDisappear:(TJPlacement*)placement{
    [_rewardBasedVideoAdConnector adapterDidCloseRewardBasedVideoAd:self];
    
    //preload on dismiss
    _isRequesting = YES;
    [_placement requestContent];
}

#pragma mark Tapjoy Video
- (void)videoDidStart:(TJPlacement*)placement{
    [_rewardBasedVideoAdConnector adapterDidStartPlayingRewardBasedVideoAd:self];
}

- (void)videoDidComplete:(TJPlacement*)placement{
    //Tapjoy only supports fixed rewards and doesn't provide a reward type or amount
    GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:@"" rewardAmount:[NSDecimalNumber zero]];
    [_rewardBasedVideoAdConnector adapter:self didRewardUserWithReward:reward];
}

- (void)videoDidFail:(TJPlacement*)placement error:(NSString*)errorMsg{
    NSError *adapterError = [NSError errorWithDomain:@"com.google.mediation.tapjoy" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Tapjoy Video playback failed"}];
    [_rewardBasedVideoAdConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:adapterError];
}

@end
