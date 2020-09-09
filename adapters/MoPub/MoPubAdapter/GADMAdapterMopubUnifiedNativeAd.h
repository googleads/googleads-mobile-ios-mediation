#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "GADMoPubNetworkExtras.h"
#import <MoPub/MoPub.h>
#import <MoPub/MPNativeAds.h>

/// MoPub's native ad wrapper.
@interface GADMAdapterMopubUnifiedNativeAd : NSObject <GADMediatedUnifiedNativeAd>

/// Initializes GADMAdapterMopubUnifiedNativeAd class.
- (nonnull instancetype)initWithMoPubNativeAd:(nonnull MPNativeAd *)mopubNativeAd
                                    mainImage:(nullable GADNativeAdImage *)mainImage
                                    iconImage:(nullable GADNativeAdImage *)iconImage
                          nativeAdViewOptions:
                              (nonnull GADNativeAdViewAdOptions *)nativeAdViewOptions
                                networkExtras:(nullable GADMoPubNetworkExtras *)networkExtras;

@end
