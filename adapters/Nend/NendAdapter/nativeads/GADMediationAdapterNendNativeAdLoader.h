//
//  GADMediationAdapterNendNativeAdLoader.h
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMediationAdapterNendNativeAdLoader : NSObject

/// Initializes a new instance with |adConfiguration|.
- (nonnull instancetype)initWithAdConfiguration:
    (nonnull GADMediationNativeAdConfiguration *)adConfiguration NS_DESIGNATED_INITIALIZER;

/// Unavailable.
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Requests a native ad from nend with |completionHandler|.
- (void)loadNativeAdWithCompletionHandler:
    (nonnull GADMediationNativeLoadCompletionHandler)completionHandler;

@end
