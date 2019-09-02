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

static NSMutableDictionary<NSString *, NSString *> *consentObj;

@implementation GADMInMobiConsent
+ (void)updateGDPRConsent:(nonnull NSDictionary<NSString *, NSString *> *)consent {
  if ([GADMAdapterInMobi isAppInitialised]) {
    [IMSdk updateGDPRConsent:consent];
  }
  consentObj = [consent mutableCopy];
}

+ (nullable NSDictionary<NSString *, NSString *> *)consent {
  return consentObj;
}
@end
