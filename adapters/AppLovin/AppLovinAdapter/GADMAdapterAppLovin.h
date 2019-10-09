//
//  GADMAdapterAppLovin.h
//
//
//  Created by Thomas So on 1/10/18.
//
//

#import <AppLovinSDK/AppLovinSDK.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

/// An adapter class that requests ads from AppLovin SDK.
@interface GADMAdapterAppLovin : NSObject <GADMAdNetworkAdapter>

/// Connector from Google Mobile Ads SDK to receive ad configurations.
@property(nonatomic, weak, nullable, readonly) id<GADMAdNetworkConnector> connector;

/// An AppLovin interstitial ad.
@property(nonatomic, nullable) ALAd *interstitialAd;

/// An AppLovin banner ad view.
@property(nonatomic, readonly, nullable) ALAdView *adView;

/// The AppLovin zone identifier used to load an ad.
@property(nonatomic, readonly, nullable) NSString *zoneIdentifier;

@end
