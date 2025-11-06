#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMAdapterFyberNativeAd : NSObject <GADMediationNativeAd>

/// Dedicated initializer to create a new instance of a native ad.
- (nonnull instancetype)initWithAdConfiguration:(nonnull GADMediationNativeAdConfiguration *)adConfiguration;

/// Unavailable.
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Loads a native ad from the DT Exchange SDK.
- (void)loadNativeAdWithCompletionHandler:(nonnull GADMediationNativeLoadCompletionHandler)completionHandler;

@end
