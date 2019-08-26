//
//  GADMAdapterAdColonyBannerRenderer.h
//


#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

@interface GADMAdapterAdColonyBannerRenderer : NSObject

// Load banner ad with provided configuration
- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler;
@end

NS_ASSUME_NONNULL_END
