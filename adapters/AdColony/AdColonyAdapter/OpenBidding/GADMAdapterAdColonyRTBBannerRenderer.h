

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMAdapterAdColonyRTBBannerRenderer : NSObject <GADMediationBannerAd>

/// Asks the receiver to render the ad configuration.
- (void)renderBannerForAdConfig:(nonnull GADMediationBannerAdConfiguration *)adConfig
              completionHandler:(nonnull GADMediationBannerLoadCompletionHandler)handler;
@end
