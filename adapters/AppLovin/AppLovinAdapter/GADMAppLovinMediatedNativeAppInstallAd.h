//
//  GADMAppLovinMediatedNativeAppInstallAd.h
//  SDK Network Adapters Test App
//
//  Created by Santosh Bagadi on 4/12/18.
//  Copyright © 2018 AppLovin Corp. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <AppLovinSDK/AppLovinSDK.h>

@interface GADMAppLovinMediatedNativeAppInstallAd : NSObject<GADMediatedNativeAppInstallAd>

- (instancetype)initWithNativeAd:(ALNativeAd *)nativeAd NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end
