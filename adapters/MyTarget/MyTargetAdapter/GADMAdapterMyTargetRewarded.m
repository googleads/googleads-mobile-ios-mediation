//
//  GADMAdapterMyTargetRewarded.m
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 29.09.17.
//  Copyright © 2017 Mail.Ru Group. All rights reserved.
//

#import "GADMAdapterMyTargetRewarded.h"
#import "GADMediationAdapterMyTarget.h"

@implementation GADMAdapterMyTargetRewarded

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterMyTarget class];
}

@end
