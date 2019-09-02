#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMRTBInterstitialRendererTapjoy : NSObject

/// Asks the receiver to render the ad configuration.
- (void)renderInterstitialForAdConfig:(nonnull GADMediationInterstitialAdConfiguration *)adConfig
                    completionHandler:
                        (nonnull GADMediationInterstitialLoadCompletionHandler)handler;

@end
