#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

#import "GADMoPubNetworkExtras.h"
#import "MPNativeAd.h"

@interface MoPubAdapterMediatedNativeAd : NSObject <GADMediatedUnifiedNativeAd>

- (nonnull instancetype)initWithMoPubNativeAd:(nonnull MPNativeAd *)mopubNativeAd
                         mappedImages:(nullable NSMutableDictionary<NSString *, GADNativeAdImage *> *)downloadedImages
                  nativeAdViewOptions:(nonnull GADNativeAdViewAdOptions *)nativeAdViewOptions
                        networkExtras:(nullable GADMoPubNetworkExtras *)networkExtras;

@end
