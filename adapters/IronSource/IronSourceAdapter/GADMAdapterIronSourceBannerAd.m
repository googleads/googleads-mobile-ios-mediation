//
//  GADMAdapterIronSourceBannerAd.m
//  ISMedAdapters
//
//  Created by alond on 11/12/2022.
//  Copyright © 2022 ironSource Ltd. All rights reserved.
//

#import "GADMAdapterIronSourceBannerAd.h"
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceBannerDelegate.h"
#import "GADMAdapterIronSourceUtils.h"
#import "GADMediationAdapterIronSource.h"
#import "ISMediationManager.h"

@interface GADMAdapterIronSourceBannerAd () <GADMediationBannerAd,GADMAdapterIronSourceBannerDelegate,ISDemandOnlyBannerDelegate>

// The completion handler to call when the ad loading succeeds or fails.
@property(copy, nonatomic) GADMediationBannerLoadCompletionHandler adLoadCompletionHandler;

// Ad configuration for the ad to be rendered.
@property(weak, nonatomic) GADMediationAdConfiguration *adConfiguration;

// An ad event delegate to invoke when ad rendering events occur.
@property(weak, nonatomic) id<GADMediationBannerAdEventDelegate> adEventDelegate;

/// Holds the ID of the ad instance to be presented.
@property(nonatomic, copy) NSString *instanceID;

/// Holds the state of the ad instance to be presented.
@property(nonatomic, copy) NSString *instanceState;

@property (nonatomic, strong) ISDemandOnlyBannerView *iSDemandOnlyBannerView;

@end

@implementation GADMAdapterIronSourceBannerAd

- (instancetype)initWithGADMediationBannerConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                                      completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
    self = [super init];
    if (self) {
        _adLoadCompletionHandler = completionHandler;
        _adConfiguration = adConfiguration;
        // Default instance ID
        self.instanceID = GADMIronSourceDefaultInstanceId;
        // Default instance state
        self.instanceState = GADMAdapterIronSourceInstanceStateStart;
    }
    
    return self;
}

- (void)renderBannerForAdConfig:(nonnull GADMediationBannerAdConfiguration *)adConfig
              completionHandler:(nonnull GADMediationBannerLoadCompletionHandler)handler {
    _adConfiguration = adConfig;
    NSDictionary *credentials = [_adConfiguration.credentials settings];
    
    /* Parse application key */
    NSString *applicationKey = @"";
    if (credentials[GADMAdapterIronSourceAppKey]) {
        applicationKey = credentials[GADMAdapterIronSourceAppKey];
    }
    
    if ([GADMAdapterIronSourceUtils isEmpty:applicationKey]) {
        NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(
                                                                          GADMAdapterIronSourceErrorInvalidServerParameters,
                                                                          @"'appKey' parameter is missing. Make sure that appKey' server parameter is added.");
        _adLoadCompletionHandler(nil, error);
        return;
    }
    
    if (credentials[GADMAdapterIronSourceInstanceId]) {
        self.instanceID = credentials[GADMAdapterIronSourceInstanceId];
    }
    
    [[ISMediationManager sharedManager]
     initIronSourceSDKWithAppKey:applicationKey
     forAdUnits:[NSSet setWithObject:IS_BANNER]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ISMediationManager *sharedManager = [ISMediationManager sharedManager];
        [sharedManager initIronSourceSDKWithAppKey:applicationKey
                                        forAdUnits:[NSSet setWithObject:IS_BANNER]];
        GADAdSize adSize = adConfig.adSize;
        ISBannerSize *ISBannerSize = [GADMAdapterIronSourceUtils ironSourceAdSizeFromRequestedSize:adSize];
        [[ISMediationManager sharedManager]loadBannerAdWithDelegate:self viewController:self instanceID:_instanceID bannerSize:ISBannerSize];
    });
}

- (void)bannerDidFailToLoadWithError:(NSError *)error
                          instanceId:(NSString *)instanceId {
    [_adEventDelegate didFailToPresentWithError:error];
}

- (void)bannerDidLoad:(ISDemandOnlyBannerView *)bannerView
           instanceId:(NSString *)instanceId {
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"bannerDidLoad for Instance ID: %@", instanceId]];
    _iSDemandOnlyBannerView = bannerView;
    _adEventDelegate = _adLoadCompletionHandler(self, nil);
}

- (void)bannerDidShow:(NSString *)instanceId {
    [_adEventDelegate reportImpression];
}

- (void)bannerWillLeaveApplication:(NSString *)instanceId {
    [_adEventDelegate willDismissFullScreenView];
}

- (void)didClickBanner:(NSString *)instanceId {
    [GADMAdapterIronSourceUtils
     onLog:[NSString stringWithFormat:@"Did click Banner for Instance ID: %@",
            instanceId]];
    [_adEventDelegate reportClick];
}

- (NSString *)getState {
    return self.instanceState;
}

- (void)setState:(NSString *)state {
    [GADMAdapterIronSourceUtils
     onLog:[NSString
            stringWithFormat:@"Banner Instance setState: changing from oldState=%@ to newState=%@",
            self.instanceState, state]];
    self.instanceState = state;
}

- (UIView *)view {
    return _iSDemandOnlyBannerView;
}

@end
