//
//  GADMAdapterUnityRouter.h
//  AdMob-TestApp-Local
//
//  Created by Kavya Katooru on 6/10/20.
//  Copyright © 2020 Unity Ads. All rights reserved.
//
@import Foundation;
@import GoogleMobileAds;
@import UnityAds;

#import "GADMAdapterUnityProtocol.h"

@interface GADMAdapterUnityRouter : NSObject
- (id)initializeWithGameID:(NSString *)gameID;

/// Requests a reward-based video ad with |adapterDelegate|.
- (void)requestRewardedAdWithDelegate:
    (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)adapterDelegate;

/// Presents a reward-based video ad for |viewController| with |adapterDelegate|.
- (void)presentRewardedAdForViewController:(UIViewController *)viewController
                                  delegate:
                                      (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)
                                          adapterDelegate;

/// Configures an interstitial ad with provided |gameID| and |adapterDelegate|.
- (void)requestInterstitialAdWithDelegate:
    (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)adapterDelegate;

/// Presents an interstitial ad for |viewController| with |adapterDelegate|.
- (void)presentInterstitialAdForViewController:(UIViewController *)viewController
                                      delegate:(id<GADMAdapterUnityDataProvider,
                                                   UnityAdsExtendedDelegate>)adapterDelegate;
@end

