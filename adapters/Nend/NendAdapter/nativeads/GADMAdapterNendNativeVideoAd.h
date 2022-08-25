//
//  GADMAdapterNendNativeVideoAd.h
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <NendAd/NendAd.h>

@interface GADMAdapterNendNativeVideoAd : NSObject <GADMediationNativeAd>

- (nonnull instancetype)
    initWithVideo:(nonnull NADNativeVideo *)ad
         delegate:(nonnull id<NADNativeVideoDelegate, NADNativeVideoViewDelegate>)delegate;

@end
