#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMoPubNetworkExtras : NSObject <GADAdNetworkExtras>

/// Holds the privacy icon size in points for the MoPub's native ad.
/// Valid sizes are between 10 and 30. Defaults to 20.
@property(assign) float privacyIconSize;

/// Minimum ad size allowed for MoPub banner ads. Defaults to CGSizeZero.
@property(assign) CGSize minimumBannerSize;

/// Custom reward data for MoPub rewarded video ads.
@property(nonatomic, copy, nullable) NSString *customRewardData;

@end
