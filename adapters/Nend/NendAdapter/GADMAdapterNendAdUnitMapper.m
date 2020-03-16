//
//  GADMAdapterNendAdUnitMapper.m
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import "GADMAdapterNendAdUnitMapper.h"

@implementation GADMAdapterNendAdUnitMapper

+ (BOOL)validateApiKey:(NSString *)apiKey spotId:(NSString *)spotId {
    if (!apiKey || apiKey.length == 0 || !spotId || spotId.length == 0) {
        return false;
    }
    return true;
}

+ (NSString *)mappingAdUnitId:(id<GADMAdNetworkConnector>)connector
                     paramKey:(NSString *)paramKey {
    return [connector credentials][paramKey];
}


@end
