//
//  GADMAdapterIronSourceBannerAd.h
//  ISMedAdapters
//
//  Created by alond on 11/12/2022.
//  Copyright © 2022 ironSource Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/IronSource.h>




@interface GADMAdapterIronSourceBannerAd : NSObject 

/// Initializes a new instance with |adConfiguration| and |completionHandler|.
- (instancetype)initWithGADMediationBannerConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                                      completionHandler:(GADMediationBannerLoadCompletionHandler)
                                                        completionHandler NS_DESIGNATED_INITIALIZER;

/// Unavailable.
- (instancetype)init __unavailable;

- (void)renderBannerForAdConfig:(nonnull GADMediationBannerLoadCompletionHandler)handler;

@end


