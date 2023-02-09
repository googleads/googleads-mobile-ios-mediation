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


NS_ASSUME_NONNULL_BEGIN

@interface GADMAdapterIronSourceBannerAd : NSObject 

/// Initializes a new instance with |adConfiguration| and |completionHandler|.
- (instancetype)initWithGADMediationBannerConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                                      completionHandler:(GADMediationBannerLoadCompletionHandler)
                                                        completionHandler NS_DESIGNATED_INITIALIZER;

/// Unavailable.
- (instancetype)init __unavailable;

- (void)renderBannerForAdConfig:(nonnull GADMediationBannerAdConfiguration *)adConfig
              completionHandler:(nonnull GADMediationBannerLoadCompletionHandler)handler;

@end

NS_ASSUME_NONNULL_END
