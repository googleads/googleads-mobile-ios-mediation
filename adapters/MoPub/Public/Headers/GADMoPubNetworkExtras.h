#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMoPubNetworkExtras : NSObject<GADAdNetworkExtras>

/// Holds the privacy icon size in points for the MoPub's native ad.
@property(assign) float privacyIconSize;

@end
