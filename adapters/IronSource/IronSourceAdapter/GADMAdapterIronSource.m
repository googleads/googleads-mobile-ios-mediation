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

@interface GADMAdapterIronSource () {
    
    //Connector from Google Mobile Ads SDK to receive interstitial ad configurations.
    __weak id<GADMAdNetworkConnector> _interstitialConnector;
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
    NSDictionary *credentials = [strongConnector credentials];

    /* Parse enabling testing mode key for log */
    self.isLogEnabled = strongConnector.testMode;
    
    /* Parse application key */
    NSString *applicationKey = @"";
    if ([credentials objectForKey:kGADMAdapterIronSourceAppKey]) {
        applicationKey = [credentials objectForKey:kGADMAdapterIronSourceAppKey];
    }
    
    /* Parse instance id key */
    if ([credentials objectForKey:kGADMAdapterIronSourceInstanceId]) {
        self.instanceId = [credentials objectForKey:kGADMAdapterIronSourceInstanceId];
    }
    
    NSString *log = [NSString stringWithFormat:@"getInterstitial params: appKey=%@, is testing enabled=%d, instance id: %@", applicationKey, self.isLogEnabled,self.instanceId];
    [self onLog:log];
    
    if (![self isEmpty:applicationKey]) {
        [IronSource setISDemandOnlyInterstitialDelegate:self];
        [self initIronSourceSDKWithAppKey:applicationKey adUnit:IS_INTERSTITIAL];
        [self loadInterstitialAd];
    } else {
        NSError *error = [self createErrorWith:@"IronSource Adapter failed to getInterstitial"
                                     andReason:@"appKey parameter is missing"
                                 andSuggestion:@"make sure that 'appKey' server parameter is added"];
        
        [strongConnector adapter:self didFailAd:error];
    }
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
    [self onLog:[NSString stringWithFormat:@"presentInterstitialFromRootViewController for instance %@",self.instanceId]];
    
    [IronSource showISDemandOnlyInterstitial:rootViewController instanceId:self.instanceId];
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
    [self onLog:[NSString stringWithFormat:@"loadInterstitialAd for instance %@",self.instanceId]];
    
    if ([IronSource hasISDemandOnlyInterstitial:self.instanceId]) {
        [_interstitialConnector adapterDidReceiveInterstitial:self];
    } else {
        [IronSource loadISDemandOnlyInterstitial:self.instanceId];
    }
}

#pragma mark IronSource Interstitial Delegates implementation

/**
 * @discussion Called after an interstitial has been loaded
 */
- (void)interstitialDidLoad:(NSString *)instanceId {
    [self onLog:[NSString stringWithFormat:@"interstitialDidLoad for instance: %@",instanceId]];
    
    // We will notify only changes regarding to the registered instance.
    if (![self.instanceId isEqualToString:instanceId]) {
        return;
    }
    
    [_interstitialConnector adapterDidReceiveInterstitial:self];
}

/**
 * @discussion Called after an interstitial has attempted to load but failed.
 *
 *             You can learn about the reason by examining the ‘error’ value
 */

- (void)interstitialDidFailToLoadWithError:(NSError *)error instanceId:(NSString *)instanceId {
    NSString *log = [NSString stringWithFormat:@"interstitialDidFailToLoadWithError: %@, for instance: %@", error.localizedDescription, instanceId];
    [self onLog:log];
    
    // We will notify only changes regarding to the registered instance.
    if (![self.instanceId isEqualToString:instanceId]) {
        return;
    }
    
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
- (void)interstitialDidOpen:(NSString *)instanceId {
    [self onLog:[NSString stringWithFormat:@"interstitialDidOpen for instance:%@",instanceId]];
    [_interstitialConnector adapterWillPresentInterstitial:self];
}

/*!
 * @discussion Called each time the Interstitial window is about to close
 */
- (void)interstitialDidClose:(NSString *)instanceId {
    [self onLog:[NSString stringWithFormat:@"interstitialDidClose for instance:%@",instanceId]];

    id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
    [strongConnector adapterWillDismissInterstitial:self];
    [strongConnector adapterDidDismissInterstitial:self];
}

/*!
 * @discussion Called each time the Interstitial window has opened successfully.
 */
- (void)interstitialDidShow:(NSString *)instanceId {
    [self onLog:[NSString stringWithFormat:@"interstitialDidShow for instance:%@",instanceId]];
}

/*!
 * @discussion Called if showing the Interstitial for the user has failed.
 *
 *              You can learn about the reason by examining the ‘error’ value
 */
- (void)interstitialDidFailToShowWithError:(NSError *)error instanceId:(NSString *)instanceId {
    [self onLog:[NSString stringWithFormat:@"interstitialDidFailToShowWithError: %@, for instance: %@", error.localizedDescription, instanceId]];
    
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
- (void)didClickInterstitial:(NSString *)instanceId {
    [self onLog:[NSString stringWithFormat:@"didClickInterstitial for instance:%@",instanceId]];
    
    id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
    [strongConnector adapterDidGetAdClick:self];
    [strongConnector adapterWillLeaveApplication:self];
}

@end
