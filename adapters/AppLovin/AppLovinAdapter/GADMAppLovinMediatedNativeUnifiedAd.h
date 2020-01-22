//
//  GADMAppLovinMediatedNativeUnifiedAd.h
//  SDK Network Adapters Test App
//
//  Created by Santosh Bagadi on 4/12/18.
//  Copyright © 2018 AppLovin Corp. All rights reserved.
//

#import <AppLovinSDK/AppLovinSDK.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMAppLovinMediatedNativeUnifiedAd : NSObject <GADMediatedUnifiedNativeAd>

/// Initializes an AppLovin mediated unified native ad.
- (nonnull instancetype)initWithNativeAd:(nonnull ALNativeAd *)nativeAd
                               mainImage:(nonnull UIImage *)mainImage
                               iconImage:(nonnull UIImage *)iconImage NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype)init NS_UNAVAILABLE;

@end
