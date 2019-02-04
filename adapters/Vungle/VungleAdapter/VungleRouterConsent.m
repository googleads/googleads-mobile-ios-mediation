//
//  VungleRouterConsent.m
//  VungleAdapter
//
//  Created by Vungle on 5/18/18.
//  Copyright © 2018 Vungle. All rights reserved.
//

#import "VungleRouterConsent.h"
#import <VungleSDK/VungleSDK.h>

static VungleConsentStatus currentConsentStatus = 0;

@implementation VungleRouterConsent
+ (BOOL)updateConsentStatus:(VungleConsentStatus)consentStatus {
  VungleSDK *sdk = [VungleSDK sharedSDK];
  if (consentStatus > 0) {
    currentConsentStatus = consentStatus;
    [sdk updateConsentStatus:consentStatus consentMessageVersion:@""];
    return YES;
  }
  return NO;
}

+ (VungleConsentStatus)getConsentStatus {
  return currentConsentStatus;
}

@end
