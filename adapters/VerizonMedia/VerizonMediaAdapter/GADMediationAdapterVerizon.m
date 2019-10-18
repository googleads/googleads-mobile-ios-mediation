//
//  GADMediationAdapterVerizon.m
//
// @copyright Copyright (c) 2018 Verizon. All rights reserved.
//

#import "GADMediationAdapterVerizon.h"
#import "GADMVerizonMediaConstants.h"
#import "GADMVerizonConsent_Internal.h"

@implementation GADMediationAdapterVerizon

- (id)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)gadConnector
{
    if (self = [super initWithGADMAdNetworkConnector:gadConnector]) {
        [self initializeVASAds];
    }
    return self;
}

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:(id<GADMRewardBasedVideoAdNetworkConnector>)rewardConnector
{
    if (self = [super initWithRewardBasedVideoAdNetworkConnector:rewardConnector]) {
        [self initializeVASAds];
    }
    return self;
}

- (void)initializeVASAds
{
    //Position
    NSDictionary *credentials = [self.connector credentials];
    if(credentials[kGADVerizonPosition] != nil)
    {
        self.placementID = credentials[kGADVerizonPosition];
    }
    
    //Site ID
    NSString *siteId = credentials[kGADVerizonDCN];
    if (siteId.length == 0) {
        siteId = [[NSBundle mainBundle] objectForInfoDictionaryKey:kGADVerizonSiteId];
    }
    
    if([[UIDevice currentDevice] systemVersion].floatValue >= 8.0) {
        VASAds.logLevel = VASLogLevelError;
        
        if([VASAds sharedInstance].initialized == NO) {
            [VASStandardEdition initializeWithSiteId:siteId];
        }
        self.vasAds = [VASAds sharedInstance];
    }
}

- (void)initializeVASSDKWithAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
{
    NSDictionary *settings = adConfiguration.credentials.settings;
    if(settings[kGADVerizonPosition] != nil) {
        self.placementID = settings[kGADVerizonPosition];
    }

    NSString *siteId = settings[kGADVerizonDCN];
    if (siteId.length == 0) {
        siteId = [[NSBundle mainBundle] objectForInfoDictionaryKey:kGADVerizonSiteId];
    }
    
    if([[UIDevice currentDevice] systemVersion].floatValue >= 8.0) {
        VASAds.logLevel = VASLogLevelError;
        
        if([VASAds sharedInstance].initialized == NO) {
            [VASStandardEdition initializeWithSiteId:siteId];
        }
        self.vasAds = [VASAds sharedInstance];
        [GADMVerizonConsent.sharedInstance updateConsentInfo];
    }
}

@end
