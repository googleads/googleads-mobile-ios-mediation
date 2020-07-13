//
//  GADMAdapterInMobiUnifiedNativeAd.h
//  InMobiAdapter
//
//  Created by Niranjan Agrawal on 1/22/16.
//
//

#import <Foundation/Foundation.h>
#import <InMobiSDK/IMNative.h>
#import "GADMAdapterInMobi.h"

@class GADMAdapterInMobiUnifiedNativeAd;

@interface GADMAdapterInMobiUnifiedNativeAd : NSObject <GADMediatedUnifiedNativeAd>

/// Initializes a new instance with |connector| and |adapter|.
- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                               adapter:(nonnull id<GADMAdNetworkAdapter>)adapter
    NS_DESIGNATED_INITIALIZER;

/// Unavailable.
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Requests a native ad from InMobi.
- (void)requestNativeAdWithOptions:(nullable NSArray<GADAdLoaderOptions *> *)options;

@end
