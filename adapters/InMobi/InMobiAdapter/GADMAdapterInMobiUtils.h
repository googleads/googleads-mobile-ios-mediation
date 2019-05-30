//
//  GADMAdapterInMobiUtils.h
//  Adapter
//  Copyright © 2019 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
@import GoogleMobileAds;

NS_ASSUME_NONNULL_BEGIN

@interface GADMAdapterInMobiUtils : NSObject

+ (NSInteger)getAdMobErrorCode:(NSInteger)inmobiErrorCode;

@end

NS_ASSUME_NONNULL_END
