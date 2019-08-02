//
//  InMobiMediatedUnifiedNativeAd.h
//  InMobiAdapter
//
//  Created by Niranjan Agrawal on 1/22/16.
//
//

#import <Foundation/Foundation.h>
#import <InMobiSDK/IMNative.h>
#import "GADMAdapterInMobi.h"

@class InMobiMediatedUnifiedNativeAd;

@protocol InMobiMediatedUnifiedNativeAdDelegate <NSObject>
- (void)inmobiMediatedUnifiedNativeAdSuccessful:(nullable InMobiMediatedUnifiedNativeAd *)ad;
- (void)inmobiMediatedUnifiedNativeAdFailed;
@end

@interface InMobiMediatedUnifiedNativeAd : NSObject <GADMediatedUnifiedNativeAd>

- (nullable instancetype)initWithInMobiUnifiedNativeAd:(nullable IMNative *)unifiedNativeAd
                                           withAdapter:(nullable GADMAdapterInMobi *)adapter
                                   shouldDownloadImage:(BOOL)shouldDownloadImage
                                             withCache:(nullable NSCache *)imageCache;

@property(nonatomic, strong, nullable) GADMAdapterInMobi *adapter;
@end
