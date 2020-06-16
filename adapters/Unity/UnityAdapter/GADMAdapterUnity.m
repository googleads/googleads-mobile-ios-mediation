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

#import "GADMAdapterUnity.h"
#import "GADUnityError.h"
#import "GADMAdapterUnityBannerAd.h"
#import "GADMAdapterUnityConstants.h"
#import "GADMUnityInterstitialAd.h"
#import "GADMAdapterUnityUtils.h"
#import "GADMediationAdapterUnity.h"

@interface GADMAdapterUnity (){
    /// Connector from Google Mobile Ads SDK to receive ad configurations.
    __weak id<GADMAdNetworkConnector> _networkConnector;
    
    /// Game ID of Unity Ads network.
    NSString *_gameID;
    
    /// Placement ID of Unity Ads network.
    NSString *_placementID;
    
    /// Unity Ads Banner wrapper
    GADMAdapterUnityBannerAd *_bannerAd;
    
    /// Unity Ads Interstitial Ad wrapper
    GADMUnityInterstitialAd *_interstitialAd;
        
}

@end

@implementation GADMAdapterUnity

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
    return [GADMediationAdapterUnity class];
}

+ (NSString *)adapterVersion {
    return kGADMAdapterUnityVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    return Nil;
}

- (void)stopBeingDelegate {
    if (_bannerAd != nil) {
        [_bannerAd stopBeingDelegate];
    }
}

- (void)initializeWithGameID:(NSString *)gameID {
    if ([UnityAds isInitialized]) {
        return;
    }
    // Metadata needed by Unity Ads SDK before initialization.
    GADMUnityConfigureMediationService();
    // Initializing Unity Ads with |gameID|.
//    [UnityAds initialize:gameID testMode:NO enablePerPlacementLoad:YES];
    [UnityAds initialize:gameID testMode:NO enablePerPlacementLoad:YES initializationDelegate:self];
    [UnityAds addDelegate:self];
}

#pragma mark Interstitial Methods

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
    if (!connector) {
        return nil;
    }
    _networkConnector = connector;
    self = [super init];
    return self;
}

- (void)getInterstitial {
    id<GADMAdNetworkConnector> strongConnector = _networkConnector;
    _gameID = [[[strongConnector credentials] objectForKey:kGADMAdapterUnityGameID] copy];
    _interstitialAd = [[GADMUnityInterstitialAd alloc] initWithGADMAdNetworkConnector:strongConnector adapter:self];
    [self initializeWithGameID:_gameID];
    [_interstitialAd getInterstitial];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
    id<GADMAdNetworkConnector> strongConnector = _networkConnector;
    [strongConnector adapterWillPresentInterstitial:self];
    [_interstitialAd presentInterstitialFromRootViewController:rootViewController];
}

#pragma mark Banner Methods

- (void)getBannerWithSize:(GADAdSize)adSize {
    id<GADMAdNetworkConnector> strongConnector = _networkConnector;
    if (!strongConnector) {
        NSLog(@"Adapter Error: No GADMAdNetworkConnector found.");
        return;
    }
    _gameID = [strongConnector.credentials[kGADMAdapterUnityGameID] copy];
    _placementID = [strongConnector.credentials[kGADMAdapterUnityPlacementID] copy];
    if (!_gameID || !_placementID) {
        NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(
                                                                     GADMAdapterUnityErrorInvalidServerParameters, @"Game ID and Placement ID cannot be nil.");
        [strongConnector adapter:self didFailAd:error];
        return;
    }
    
    _bannerAd = [[GADMAdapterUnityBannerAd alloc] initWithGADMAdNetworkConnector:strongConnector
                                                                         adapter:self];
    [self initializeWithGameID:_gameID];
    [_bannerAd loadBannerWithSize:adSize];
}

#pragma mark GADMAdapterUnityDataProvider Methods

- (NSString *)getGameID {
    return _gameID;
}

- (NSString *)getPlacementID {
    return _placementID;
}

- (void)didFailToLoadWithError:(nonnull NSError *)error {
    id<GADMAdNetworkConnector> strongConnector = _networkConnector;
    if (strongConnector != nil) {
        [strongConnector adapter:self didFailAd:error];
    }
}

#pragma mark - Unity Delegate Methods

- (void)unityAdsPlacementStateChanged:(NSString *)placementID
                             oldState:(UnityAdsPlacementState)oldState
                             newState:(UnityAdsPlacementState)newState {
}

- (void)unityAdsDidFinish:(NSString *)placementID withFinishState:(UnityAdsFinishState)state {
    if ([placementID isEqualToString:_placementID]) {
        id<GADMAdNetworkConnector> strongNetworkConnector = _networkConnector;
        if (strongNetworkConnector) {
            [strongNetworkConnector adapterDidDismissInterstitial:self];
        }
    }
}

- (void)unityAdsReady:(NSString *)placementID {
}

- (void)unityAdsDidClick:(NSString *)placementID {
    id<GADMAdNetworkConnector> strongNetworkConnector = _networkConnector;
    // The Unity Ads SDK doesn't provide an event for leaving the application, so the adapter assumes
    // that a click event indicates the user is leaving the application for a browser or deeplink, and
    // notifies the Google Mobile Ads SDK accordingly.
    if (strongNetworkConnector && [placementID isEqualToString:_placementID]) {
        [strongNetworkConnector adapterDidGetAdClick:self];
        [strongNetworkConnector adapterWillLeaveApplication:self];
    }
}

- (void)unityAdsDidError:(UnityAdsError)error withMessage:(NSString *)message {
    id<GADMAdNetworkConnector> strongNetworkConnector = _networkConnector;
    if (strongNetworkConnector) {
        [strongNetworkConnector adapterWillDismissInterstitial:self];
        [strongNetworkConnector adapterDidDismissInterstitial:self];
    }
}

- (void)unityAdsDidStart:(nonnull NSString *)placementID {
    // nothing to do
}


// UnityAdsInitialization Delegate methods
- (void)initializationComplete {
    NSLog(@"Unity Ads initialized successfully");
}

- (void)initializationFailed:(UnityAdsInitializationError)error withMessage:(nonnull NSString *)message {
    id<GADMAdNetworkConnector> strongConnector = _networkConnector;
    if (strongConnector) {
        NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorAdInitializationFailure, message);
        [strongConnector adapter:self didFailAd:error];
        
    }
}

@end
