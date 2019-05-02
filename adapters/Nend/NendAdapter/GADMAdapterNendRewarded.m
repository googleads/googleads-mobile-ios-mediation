//
//  GADMAdapterNendRewarded.m
//  NendAdapter
//
//  Copyright © 2017 F@N Communications. All rights reserved.
//

#import "GADMAdapterNendRewarded.h"
#import "GADMediationAdapterNend.h"

@implementation GADMAdapterNendRewarded

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterNend class];
}

@end
