//
//  GADMediationAdapterVerizon.m
//  GoogleAdVASAdapter
//
// @copyright Copyright (c) 2018 Verizon. All rights reserved.
//

#import "GADMediationAdapterVerizon.h"

static NSString *const kGADVerizonPosition = @"placement_id";
static NSString *const kGADVerizonDCN      = @"site_id";
static NSString *const kGADVerizonSiteId   = @"VerizonSiteID";

@implementation GADMediationAdapterVerizon

- (id)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)gadConnector
{
    if (self = [super initWithGADMAdNetworkConnector:gadConnector]) {
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


@end
