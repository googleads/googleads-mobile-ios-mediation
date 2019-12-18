//
//  GADMAdapterNexage.m
//
// @copyright Copyright (c) 2018 Verizon. All rights reserved.
//

#import "GADMAdapterNexage.h"
#import <VerizonAdsCore/VASAds+Private.h>
#import <VerizonAdsCore/VASPEXRegistry.h>
#import <VerizonAdsURIExperience/VerizonAdsURIExperience.h>
#import "GADMAdapterVerizonConstants.h"
#import "GADMAdapterVerizonUtils.h"
#import "GADMVerizonPrivacy_Internal.h"

@implementation GADMAdapterNexage

- (id)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super initWithGADMAdNetworkConnector:connector];
  if (self) {
    NSDictionary<NSString *, id> *credentials = [connector credentials];
    if (credentials[kGADNexagePosition]) {
      self.placementID = credentials[kGADNexagePosition];
    }
    NSString *siteID = credentials[kGADNexageDCN];
    GADMAdapterVerizonInitializeVASAdsWithSiteID(siteID);
  }
  return self;
}

@end
