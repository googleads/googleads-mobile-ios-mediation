//
//  GADMAdapterIronSourceInterstitialAd.h
//  ISMedAdapters
//
//  Created by alond on 13/12/2022.
//  Copyright © 2022 ironSource Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMAdapterIronSourceInterstitialAd : NSObject <GADMediationInterstitialAd>

/// Initializes a new instance with |adConfiguration| and |completionHandler|.
- (instancetype)initWithGADMediationInterstitialAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration
                                              completionHandler:(GADMediationInterstitialLoadCompletionHandler)
                                                                completionHandler NS_DESIGNATED_INITIALIZER;

/// Unavailable.
- (instancetype)init __unavailable;

- (void)requestInterstitial;

@end
