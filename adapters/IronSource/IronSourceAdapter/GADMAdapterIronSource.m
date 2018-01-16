// Copyright 2017 Google Inc.
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

NSString *const kGADMAdapterIronSourceInterstitialPlacement = @"interstitialPlacement";

@interface GADMAdapterIronSource () {
    
    //Connector from Google Mobile Ads SDK to receive interstitial ad configurations.
    __weak id<GADMAdNetworkConnector> _interstitialConnector;
    
    //IronSource rewarded video placement name
    NSString *_interstitialPlacementName;
}

@end

@implementation GADMAdapterIronSource

#pragma mark Admob GADMAdNetworkConnector

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

- (void)getInterstitial {
    id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
    
    NSString *applicationKey = @"";
    if ([[strongConnector credentials] objectForKey:kGADMAdapterIronSourceAppKey]) {
        applicationKey = [[strongConnector credentials] objectForKey:kGADMAdapterIronSourceAppKey];
    }
    
    if ([[strongConnector credentials] objectForKey:kGADMAdapterIronSourceIsTestEnabled] != nil) {
        self.isTestEnabled = [[[strongConnector credentials] objectForKey:kGADMAdapterIronSourceIsTestEnabled] boolValue];
    } else {
        self.isTestEnabled = NO;
    }
    
    _interstitialPlacementName = @"";
    if ([[strongConnector credentials] objectForKey:kGADMAdapterIronSourceInterstitialPlacement]) {
        _interstitialPlacementName = [[strongConnector credentials] objectForKey:kGADMAdapterIronSourceInterstitialPlacement];
    }
    
    NSString *log = [NSString stringWithFormat:@"getInterstitial params: appKey=%@, self.isTestEnabled=%d,  _interstitialPlacementName=%@", applicationKey, self.isTestEnabled,_interstitialPlacementName];
    [self onLog:log];
    
    if (![self isEmpty:applicationKey]) {
        
        [IronSource setInterstitialDelegate:self];
        [self initIronSourceSDKWithAppKey:applicationKey adUnit:IS_INTERSTITIAL];
        [self loadInterstitialAd];
    } else {
        
        NSError *error = [self createErrorWith:@"IronSource Adapter failed to getInterstitial"
                                     andReason:@"appKey parameter is missing"
                                 andSuggestion:@"make sure that 'appKey' server parameter is added"];
        
        [strongConnector adapter:self didFailAd:error];
    }
    
    [self onLog:@"getInterstitial"];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
    [self onLog:@"presentInterstitialFromRootViewController"];
    
    if (_interstitialPlacementName) {
        [IronSource showInterstitialWithViewController:rootViewController placement:_interstitialPlacementName];
    } else {
        [IronSource showInterstitialWithViewController:rootViewController];
    }
}

#pragma mark Admob Banner

- (void)getBannerWithSize:(GADAdSize)adSize {
    [self showBannersNotSupportedError];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
    [self showBannersNotSupportedError];
    return YES;
}

- (void)showBannersNotSupportedError {
    // IronSource Adapter doesn't support banner ads.
    NSError *error = [self createErrorWith:@"IronSource Adapter doesn't support banner ads" andReason:@"" andSuggestion:@""];
    [_interstitialConnector adapter:self didFailAd:error];
}

#pragma mark Interstitial Utils Methods

- (void)loadInterstitialAd {
    [self onLog:@"loadInterstitialAd"];
    
    if ([IronSource hasInterstitial]) {
        [_interstitialConnector adapterDidReceiveInterstitial:self];
    } else {
        [IronSource loadInterstitial];
    }
}

#pragma mark IronSource Interstitial Delegates implementation

/**
 * @discussion Called after an interstitial has been loaded
 */
- (void)interstitialDidLoad {
    [self onLog:@"interstitialDidLoad"];
    
    [_interstitialConnector adapterDidReceiveInterstitial:self];
}

/**
 * @discussion Called after an interstitial has attempted to load but failed.
 *
 *             You can learn about the reason by examining the ‘error’ value
 */

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
