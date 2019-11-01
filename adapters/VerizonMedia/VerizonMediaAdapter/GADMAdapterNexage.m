//
//  GADMAdapterNexage.m
//
// @copyright Copyright (c) 2018 Verizon. All rights reserved.
//

#import "GADMAdapterNexage.h"
#import "GADMAdapterVerizonConstants.h"
#import "GADMVerizonConsent_Internal.h"
#import <VerizonAdsCore/VASPEXRegistry.h>
#import <VerizonAdsCore/VASAds+Private.h>
#import <VerizonAdsURIExperience/VerizonAdsURIExperience.h>

@implementation GADMAdapterNexage

- (id)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)gadConnector {
  if (self = [super initWithGADMAdNetworkConnector:gadConnector]) {
    [self initializeVASAds];
  }
  return self;
}

- (void)initializeVASAds {
  // Position.
  NSDictionary *credentials = [self.connector credentials];
  if (credentials[kGADMAdapterVerizonMediaPosition]) {
    self.placementID = credentials[kGADMAdapterVerizonMediaPosition];
  }

  if (!VASAds.sharedInstance.initialized) {
    // Site ID.
    NSString *siteID = credentials[kGADMAdapterVerizonMediaDCN];
    if (!siteID.length) {
      siteID = [[NSBundle mainBundle] objectForInfoDictionaryKey:kGADMAdapterVerizonMediaSiteID];
    }
    [VASStandardEdition initializeWithSiteId:siteID];
  }

  if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0) {
    VASAds.logLevel = VASLogLevelError;
    self.vasAds = VASAds.sharedInstance;
    [GADMVerizonConsent.sharedInstance updateConsentInfo];
  }
}

@end
