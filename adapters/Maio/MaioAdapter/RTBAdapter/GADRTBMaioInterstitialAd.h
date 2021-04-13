//
//  GADRTBMaioInterstitialAd.h
//  Adapter
//
//  Created by i-mobile on 2020/11/18.
//  Copyright © 2020 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADRTBMaioInterstitialAd : NSObject <GADMediationInterstitialAd>

- (nonnull instancetype)initWithAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration;
- (void)loadInterstitialWithCompletionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler;

@end
