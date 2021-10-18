//
//  GADMediationAdConfiguration+Settings.h
//  AdMob-TestApp-Local
//
//  Created by Vita Solomina on 2021-10-18.
//  Copyright © 2021 Unity Ads. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

@interface GADMediationAdConfiguration (Settings)
- (NSString *)placementId;
- (NSString *)gameId;
@end

@interface GADMediationServerConfiguration (Settings)
- (NSSet*)gameIds;
@end

NS_ASSUME_NONNULL_END
