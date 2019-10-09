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

- (nonnull instancetype)initWithNativeAd:(nonnull ALNativeAd *)nativeAd NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype)init NS_UNAVAILABLE;

@end
