//
//  InMobiMediatedNativeAppInstallAd.h
//  InMobiAdapter
//
//  Created by Niranjan Agrawal on 1/22/16.
//
//

#import "GADMAdapterInMobi.h"
#import <Foundation/Foundation.h>
#import <InMobiSDK/IMNative.h>

@class InMobiMediatedNativeAppInstallAd;

@protocol InMobiMediatedNativeAppInstallAdDelegate<NSObject>
- (void)inmobiMediatedNativeAppInstallAdSuccessful:(nullable InMobiMediatedNativeAppInstallAd *)ad;
- (void)inmobiMediatedNativeAppInstallAdFailed;
@end

@interface InMobiMediatedNativeAppInstallAd : NSObject<GADMediatedNativeAppInstallAd>

- (nullable instancetype)initWithInMobiNativeAppInstallAd:(nullable IMNative *)nativeInstallAd
                                              withAdapter:(nullable GADMAdapterInMobi *)adapter
                                      shouldDownloadImage:(BOOL)shouldDownloadImage
                                                withCache:(nullable NSCache *)imageCache;

@property(nonatomic, weak, nullable) GADMAdapterInMobi *adapter;
@end
