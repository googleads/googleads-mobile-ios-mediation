//
//  GADMAdapterNendAdUnitMapper.h
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import <Foundation/Foundation.h>
@import GoogleMobileAds;

NS_ASSUME_NONNULL_BEGIN

@interface GADMAdapterNendAdUnitMapper : NSObject

+ (BOOL)validateApiKey:(NSString *)apiKey spotId:(NSString *)spotId;
+ (NSString *)mappingAdUnitId:(id<GADMAdNetworkConnector>)connector
paramKey:(NSString *)paramKey;
@end

NS_ASSUME_NONNULL_END
