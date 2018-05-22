//
//  VungleRouterConsent.m
//  VungleAdapter
//
//  Created by Vungle on 5/18/18.
//  Copyright © 2018 Vungle. All rights reserved.
//

#import "VungleRouterConsent.h"

static VungleConsentStatus currentConsentSataus = 0;

@implementation VungleRouterConsent
+ (void)updateConsentStatus:(VungleConsentStatus)consentStatus {
  currentConsentSataus = consentStatus;
  VungleSDK *sdk = [VungleSDK sharedSDK];
  if (sdk.initialized && consentStatus > 0) {
    [sdk updateConsentStatus:consentStatus];
  }
}

+ (VungleConsentStatus)getConsentStatus {
  return currentConsentSataus;
}

@end
