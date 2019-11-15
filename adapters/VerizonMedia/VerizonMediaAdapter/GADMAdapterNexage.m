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

- (id)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super initWithGADMAdNetworkConnector:connector];
  if (self) {
    [self initializeVASAds];
  }
  return self;
}

- (void)initializeVASAds {
  // Position.
  NSDictionary *credentials = [self.connector credentials];
  if (credentials[kGADNexagePosition]) {
    self.placementID = credentials[kGADNexagePosition];
  }

  if (![VASAds.sharedInstance isInitialized]) {
    // Site ID.
    NSString *siteID = credentials[kGADNexageDCN];
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
