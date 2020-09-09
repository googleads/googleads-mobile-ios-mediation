//
//  GADMAdapterNendAdUnitMapper.h
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMAdapterNendAdUnitMapper : NSObject

+ (BOOL)isValidAPIKey:(nonnull NSString *)apiKey spotId:(NSInteger)spotId;

@end
