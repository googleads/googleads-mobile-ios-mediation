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
        self.instanceID = GADMIronSourceDefaultRtbInstanceId;
    }
    
    NSString *bidResponse = adConfiguration.bidResponse;
    NSMutableDictionary<NSString *, NSString *> *extraParams= [GADMAdapterIronSourceUtils getExtraParamsWithWatermark:adConfiguration.watermark];
    
    ISAInterstitialAdRequest *adRequest = [[[[ISAInterstitialAdRequestBuilder alloc] initWithInstanceId: self.instanceID adm: bidResponse]withExtraParams:extraParams] build];
    
    [ISAInterstitialAdLoader loadAdWithAdRequest: adRequest delegate: self];
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"Showing IronSource interstitial ad for Instance ID: %@",
            self.instanceID]];
    id<GADMediationInterstitialAdEventDelegate> interstitialDelegate = self.interstitialAdEventDelegate;

    if (!self.biddingISAInterstitialAd){
        if (interstitialDelegate){
            NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(
                                                                              GADMAdapterIronSourceErrorFailedToShow,
                                                                              @"the ad is nil");
            [interstitialDelegate didFailToPresentWithError:error];
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
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"%@ with error= %@", NSStringFromSelector(_cmd), error.localizedDescription]];
    id<GADMediationInterstitialAdEventDelegate> interstitialDelegate = self.interstitialAdEventDelegate;
    if (!interstitialDelegate){
        return;
    }
    [interstitialDelegate didFailToPresentWithError:error];
}

- (void)interstitialAdDidLoad:(nonnull ISAInterstitialAd *)interstitialAd {
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"%@ instanceId= %@ adId= %@", NSStringFromSelector(_cmd),
            interstitialAd.adInfo.instanceId,
            interstitialAd.adInfo.adId]];
    
    self.biddingISAInterstitialAd = interstitialAd;
    if (!self.interstitalAdLoadCompletionHandler){
        return;
    }
    
    self.interstitialAdEventDelegate = self.interstitalAdLoadCompletionHandler(self, nil);
}

- (void)interstitialAdDidFailToLoadWithError:(nonnull NSError *)error {
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"%@ with error= %@ ", NSStringFromSelector(_cmd),
            error.localizedDescription]];
    if (!self.interstitalAdLoadCompletionHandler){
        return;
    }
    self.interstitalAdLoadCompletionHandler(nil, error);
    
}

- (void)interstitialAdDidShow:(nonnull ISAInterstitialAd *)interstitialAd {
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"%@ instanceId= %@ adId= %@", NSStringFromSelector(_cmd),
            interstitialAd.adInfo.instanceId,
            interstitialAd.adInfo.adId]];
    id<GADMediationInterstitialAdEventDelegate> interstitialDelegate = self.interstitialAdEventDelegate;
    if (!interstitialDelegate){
        return;
    }
    [interstitialDelegate willPresentFullScreenView];
    [interstitialDelegate reportImpression];
    
}

- (void)interstitialAdDidClick:(nonnull ISAInterstitialAd *)interstitialAd {
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"%@ instanceId= %@ adId= %@", NSStringFromSelector(_cmd),
            interstitialAd.adInfo.instanceId,
            interstitialAd.adInfo.adId]];
    id<GADMediationInterstitialAdEventDelegate> interstitialDelegate = self.interstitialAdEventDelegate;
    if (!interstitialDelegate){
        return;
    }
    
    [interstitialDelegate reportClick];
}

- (void)interstitialAdDidDismiss:(nonnull ISAInterstitialAd *)interstitialAd {
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"%@ instanceId= %@ adId= %@", NSStringFromSelector(_cmd),
            interstitialAd.adInfo.instanceId,
            interstitialAd.adInfo.adId]];
    id<GADMediationInterstitialAdEventDelegate> interstitialDelegate = self.interstitialAdEventDelegate;
    if (!interstitialDelegate){
        return;
    }
    [interstitialDelegate willDismissFullScreenView];
    [interstitialDelegate didDismissFullScreenView];
}


@end
