@import Foundation;

#import "GADMoPubNetworkExtras.h"
#import "MPNativeAd.h"

@interface MoPubAdapterMediatedNativeAd : NSObject <GADMediatedNativeAppInstallAd>

- (instancetype)initWithMoPubNativeAd:(nonnull MPNativeAd *)mopubNativeAd
                         mappedImages:(nullable NSMutableDictionary *)downloadedImages
                  nativeAdViewOptions:(nonnull GADNativeAdViewAdOptions *)nativeAdViewOptions
                        networkExtras:(nullable GADMoPubNetworkExtras *)networkExtras;

@end
