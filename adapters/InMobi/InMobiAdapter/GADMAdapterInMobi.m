//
//  GADMAdapterInMobi.m
//
//  Copyright (c) 2015 InMobi. All rights reserved.
//

#import "GADMAdapterInMobi.h"

#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMediationAdapterInMobi.h"


@implementation GADMAdapterInMobi {

}

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterInMobi class];
}

+ (nonnull NSString *)adapterVersion {
  return GADMAdapterInMobiVersion;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADInMobiExtras class];
}

@end
