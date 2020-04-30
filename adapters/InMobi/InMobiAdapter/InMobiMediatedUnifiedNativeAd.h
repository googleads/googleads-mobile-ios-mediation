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
- (void)inmobiMediatedUnifiedNativeAdSuccessful:(nonnull InMobiMediatedUnifiedNativeAd *)ad;
- (void)inmobiMediatedUnifiedNativeAdFailed;
@end

@interface InMobiMediatedUnifiedNativeAd : NSObject <GADMediatedUnifiedNativeAd>

/// InMobi network adapter.
@property(nonatomic, strong, readonly, nullable) GADMAdapterInMobi *adapter;

/// Initializes the unified native ad renderer.
- (nonnull instancetype)initWithInMobiUnifiedNativeAd:(nonnull IMNative *)unifiedNativeAd
                                              adapter:(nonnull GADMAdapterInMobi *)adapter
                                  shouldDownloadImage:(BOOL)shouldDownloadImage
                                                cache:(nonnull NSCache *)imageCache;

@end
