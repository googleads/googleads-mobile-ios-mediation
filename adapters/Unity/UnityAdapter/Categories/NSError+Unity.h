//
//  NSError+Unity.h
//  AdMob-TestApp-Local
//
//  Created by Vita Solomina on 2021-10-18.
//  Copyright © 2021 Unity Ads. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSError (Unity)
+ (NSError *) noValidGameId;
+ (NSError *) unsupportedBannerGADAdSize:(GADAdSize)adSize;
+ (NSError *) adNotAvailablePerPlacement:(NSString*)placementId;
@end

NS_ASSUME_NONNULL_END
