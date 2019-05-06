//
//  GADMMaioRewardedAdapter.m
//  GADMMaioAdapter
//
//  Copyright © 2017 i-mobile, Inc. All rights reserved.
//

#import "GADMMaioRewardedAdapter.h"
#import "GADMediationAdapterMaio.h"

@implementation GADMMaioRewardedAdapter

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterMaio class];
}

@end
