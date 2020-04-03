//
//  GADMAdapterNendAdUnitMapper.h
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMAdapterNendAdUnitMapper : NSObject

+ (BOOL)validateApiKey:(nonnull NSString *)apiKey spotId:(nonnull NSString *)spotId;
+ (nonnull NSString *)mappingAdUnitId:(nonnull id<GADMAdNetworkConnector>)connector
                             paramKey:(nonnull NSString *)paramKey;
@end
