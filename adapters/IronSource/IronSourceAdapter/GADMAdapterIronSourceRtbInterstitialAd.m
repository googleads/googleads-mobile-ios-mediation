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

#import "GADMAdapterIronSourceRtbInterstitialAd.h"
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceInterstitialAdDelegate.h"
#import "GADMAdapterIronSourceUtils.h"
#import "GADMediationAdapterIronSource.h"



@interface IronSourceRtbInterstitialAdDelegate : NSObject
@property (nonatomic,   weak) GADMAdapterIronSourceRtbInterstitialAd *parentAdapter;
@property (nonatomic, strong) GADMediationInterstitialLoadCompletionHandler delegate;
@property (nonatomic, strong) id<GADMediationInterstitialAdEventDelegate>  gadIsDelegate;



- (instancetype)initWithParentAdapter:(GADMAdapterIronSourceRtbInterstitialAd *)parentAdapter andNotify:(GADMediationInterstitialLoadCompletionHandler)delegate;
@end

@interface GADMAdapterIronSourceRtbInterstitialAd ()

// An ad event delegate to invoke when ad rendering events occur.
@property(weak, nonatomic) id<GADMediationInterstitialAdEventDelegate> interstitialAdEventDelegate;

/// Holds the ID of the ad instance to be presented.
@property(nonatomic, copy) NSString *instanceID;

/// Holds the state of the ad instance to be presented.
@property (nonatomic, strong) IronSourceRtbInterstitialAdDelegate *biddingInterstitialAdDelegate;

@end


@implementation GADMAdapterIronSourceRtbInterstitialAd

#pragma mark InstanceMap and Delegate initialization
// The class-level delegate handling callbacks for all instances

+ (void)initialize {
    // interstitialAdapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn
    //                                                     // valueOptions:NSPointerFunctionsWeakMemory];
    // interstitialDelegate = [[IronSourceRtbInterstitialAdDelegate alloc] init];
    
}

#pragma mark - Load functionality

- (void)loadInterstitialForAdConfiguration:
(GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
(GADMediationInterstitialLoadCompletionHandler)completionHandler {
    _interstitalAdLoadCompletionHandler = completionHandler;
    
    NSDictionary *credentials = [adConfiguration.credentials settings];
    NSString *applicationKey = credentials[GADMAdapterIronSourceAppKey];
    
    if (applicationKey != nil && ![GADMAdapterIronSourceUtils isEmpty:applicationKey]) {
        applicationKey = credentials[GADMAdapterIronSourceAppKey];
    } else {
        NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(
                                                                          GADMAdapterIronSourceErrorInvalidServerParameters,
                                                                          @"Missing or invalid IronSource application key.");
        
        _interstitalAdLoadCompletionHandler(nil, error);
        return;
    }
    
    if (credentials[GADMAdapterIronSourceInstanceId]) {
        self.instanceID = credentials[GADMAdapterIronSourceInstanceId];
    } else {
        [GADMAdapterIronSourceUtils onLog:@"Missing or invalid IronSource interstitial ad Instance ID. "
         @"Using the default instance ID."];
        self.instanceID = GADMIronSourceDefaultInstanceId;
    }
    
    NSString *bidResponse = adConfiguration.bidResponse;
    
    NSString *watermarkString = [[NSString alloc] initWithData:adConfiguration.watermark encoding:NSUTF8StringEncoding];
    
    [IronSource setMetaDataWithKey:@"google_water_mark" value:watermarkString];
    
    
    ISAInterstitialAdRequest *adRequest = [[[ISAInterstitialAdRequestBuilder alloc] initWithInstanceId: self.instanceID adm: bidResponse] build];
    
    [ISAInterstitialAdLoader loadAdWithAdRequest: adRequest delegate: self];
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"Showing IronSource interstitial ad for Instance ID: %@",
            self.instanceID]];
    if (!self.biddingISAInterstitialAd){
        if (self.interstitialAdEventDelegate){
            NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(
                                                                              GADMAdapterIronSourceErrorFailedToShow,
                                                                              @"the ad is nil");
            [self.interstitialAdEventDelegate didFailToPresentWithError:error];
        }
        [GADMAdapterIronSourceUtils
            onLog:[NSString stringWithFormat:@"Failed to show due to ad not loaded, for Instance ID: %@",
                                             self.instanceID]];
        return;
    }
    
    [self.biddingISAInterstitialAd setDelegate:self];
    [self.biddingISAInterstitialAd showFromViewController:viewController ];
}


- (void)interstitialAd:(nonnull ISAInterstitialAd *)interstitialAd didFailToShowWithError:(nonnull NSError *)error {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (!self.interstitialAdEventDelegate){
        return;
    }
    [self.interstitialAdEventDelegate didFailToPresentWithError:error];
}

- (void)interstitialAdDidLoad:(nonnull ISAInterstitialAd *)interstitialAd {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    self.biddingISAInterstitialAd = interstitialAd;
    if (!self.interstitalAdLoadCompletionHandler){
        return;
    }
    
    self.interstitialAdEventDelegate = self.interstitalAdLoadCompletionHandler(self, nil);
}

- (void)interstitialAdDidFailToLoadWithError:(nonnull NSError *)error {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (!self.interstitalAdLoadCompletionHandler){
        return;
    }
    self.interstitalAdLoadCompletionHandler(nil, error);
    
}

- (void)interstitialAdDidShow:(nonnull ISAInterstitialAd *)interstitialAd {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (!self.interstitialAdEventDelegate){
        return;
    }
    [self.interstitialAdEventDelegate willPresentFullScreenView];
    [self.interstitialAdEventDelegate reportImpression];
    
}

- (void)interstitialAdDidClick:(nonnull ISAInterstitialAd *)interstitialAd {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (!self.interstitialAdEventDelegate){
        return;
    }
    
    [self.interstitialAdEventDelegate reportClick];
}

- (void)interstitialAdDidDismiss:(nonnull ISAInterstitialAd *)interstitialAd {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (!self.interstitialAdEventDelegate){
        return;
    }
    [self.interstitialAdEventDelegate willDismissFullScreenView];
    [self.interstitialAdEventDelegate didDismissFullScreenView];
}


@end
