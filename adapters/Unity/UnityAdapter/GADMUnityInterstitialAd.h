//
//  GADMUnityInterstitialAd.h
//  AdMob-TestApp-Local
//
//  Created by Kavya Katooru on 6/10/20.
//  Copyright © 2020 Unity Ads. All rights reserved.
//

#import <Foundation/Foundation.h>
@import GoogleMobileAds;
#import <UnityAds/UnityAds.h>

@protocol GADMAdNetworkAdapter;
@protocol GADMAdNetworkConnector;

@interface GADMUnityInterstitialAd : NSObject

- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                               adapter:(nonnull id<GADMAdNetworkAdapter>)adapter;

/// Requests GADAdapterUnityRouter to fetch interstitial Ad
- (void)getInterstitial;


/// Requests GADAdapterUnityRouter to present interstitial Ad
- (void)presentInterstitialFromRootViewController:(nonnull UIViewController *)rootViewController;
@end
