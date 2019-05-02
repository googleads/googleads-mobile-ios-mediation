//
//  GADMInMobiConsent.m
//  Adapter
//
//  Created by Ankit Pandey on 24/05/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import "GADMInMobiConsent.h"
#import <InMobiSDK/IMSdk.h>
#import "GADMAdapterInMobi.h"

static NSMutableDictionary* consentObj;

@implementation GADMInMobiConsent
+ (void)updateGDPRConsent:(NSDictionary*)consent {
  if ([GADMAdapterInMobi isAppInitialised]) {
    [IMSdk updateGDPRConsent:consent];
  }
  consentObj = [consent mutableCopy];
}

+ (NSMutableDictionary*)getConsent {
  return consentObj;
}
@end
