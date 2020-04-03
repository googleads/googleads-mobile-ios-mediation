//
//  GADMAdapterNendAdUnitMapper.m
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import "GADMAdapterNendAdUnitMapper.h"

@implementation GADMAdapterNendAdUnitMapper

+ (BOOL)validateApiKey:(nonnull NSString *)apiKey spotId:(nonnull NSString *)spotId {
  if (!apiKey || apiKey.length == 0 || !spotId || spotId.length == 0) {
    return false;
  }
  return true;
}

+ (nonnull NSString *)mappingAdUnitId:(nonnull id<GADMAdNetworkConnector>)connector
                             paramKey:(nonnull NSString *)paramKey {
  return [connector credentials][paramKey];
}

@end
