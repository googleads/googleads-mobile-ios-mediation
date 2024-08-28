//
//  GADMAdapterIronSourceRtbInterstitialAd.h
//  ISMedAdapters
//
//  Created by Jonathan Benedek on 12/08/2024.
//  Copyright © 2024 ironSource Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/IronSource.h>

#ifndef GADMAdapterIronSourceRtbInterstitialAd_h
#define GADMAdapterIronSourceRtbInterstitialAd_h


/// Adapter for communicating with the IronSource Network to fetch interstitial ads.
@interface GADMAdapterIronSourceRtbInterstitialAd : NSObject <GADMediationInterstitialAd,ISAInterstitialAdDelegate, ISAInterstitialAdLoaderDelegate>

@property(copy, nonatomic)
GADMediationInterstitialLoadCompletionHandler _Nullable interstitalAdLoadCompletionHandler;
@property (nonatomic, strong) ISAInterstitialAd * _Nullable biddingISAInterstitialAd;

/// Initializes a new instance with adConfiguration and completionHandler.
- (void)loadInterstitialForAdConfiguration:
            (nullable GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:(nullable GADMediationInterstitialLoadCompletionHandler)
                                               completionHandler;

#pragma mark - Instance map Access

// Retrieve a delegate from the instance map
//+ (nonnull GADMAdapterIronSourceInterstitialAd *)delegateForKey:(nonnull NSString *)key;


#pragma mark - Getters and Setters


/// Set the interstitial event delegate for Admob mediation.
- (void)setInterstitialAdEventDelegate:
    (nullable id<GADMediationInterstitialAdEventDelegate>)eventDelegate;

@end

#endif /* GADMAdapterIronSourceRtbInterstitialAd_h */
