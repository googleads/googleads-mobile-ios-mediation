//
//  GADMAdapterChartboostBanner.h
//  Adapter
//
//  Created by Daniel Barros on 17/07/2019.
//  Copyright © 2019 Google. All rights reserved.
//

@import UIKit;
@import GoogleMobileAds;
#import <Chartboost/CHBBanner.h>
#import "GADMChartboostExtras.h"

NS_ASSUME_NONNULL_BEGIN

@interface GADMAdapterChartboostBanner : NSObject

+ (instancetype)sharedInstance;

/// Initializes a new banner ad instance.
- (void)loadBannerWithSize:(GADAdSize)adSize
                  location:(nonnull NSString *)location
                  delegate:(nullable id<CHBBannerDelegate>)delegate
            viewController:(nullable UIViewController *)viewController
                    extras:(nullable GADMChartboostExtras *)extras;

@end

NS_ASSUME_NONNULL_END
