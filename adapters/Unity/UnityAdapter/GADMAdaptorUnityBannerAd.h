@import Foundation;
@import GoogleMobileAds;

#import "UnityAds/UADSBanner.h"

/// Creates and manages banner ads.
@interface GADMAdaptorUnityBannerAd : NSObject<UnityAdsBannerDelegate>

/// Initializes a new instance with |connector| and |adapter|.
- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector
                                       adapter:(id<GADMAdNetworkAdapter>)adapter
    NS_DESIGNATED_INITIALIZER;

/// Unavailable.
- (instancetype)init __unavailable;

/// Starts fetching a banner ad for given |adSize|.
- (void)getBannerWithSize:(GADAdSize)adSize;

/// Stops the receiver from delegating any notifications.
- (void)stopBeingDelegate;

@end
