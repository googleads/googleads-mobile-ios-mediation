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
static NSString *currentConsentMessageVersion = @"";

@implementation VungleRouterConsent
+ (void)updateConsentStatus:(VungleConsentStatus)status consentMessageVersion:(NSString *)version {
  currentConsentStatus = status;
  currentConsentMessageVersion = version;
  VungleSDK *sdk = [VungleSDK sharedSDK];
  if (sdk.initialized && status > 0) {
    [sdk updateConsentStatus:status consentMessageVersion:version];
  }
}

+ (VungleConsentStatus)getConsentStatus {
  return currentConsentStatus;
}

+ (NSString *)getConsentMessageVersion {
  return currentConsentMessageVersion;
}
@end
