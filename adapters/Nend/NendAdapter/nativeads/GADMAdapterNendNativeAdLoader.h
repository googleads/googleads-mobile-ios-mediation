//
//  GADMAdapterNendNativeAdLoader.h
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <NendAd/NendAd.h>

#import "GADMAdapterNend.h"
#import "GADMAdapterNendConstants.h"

@protocol GADMAdapterNendNativeAdLoaderDelegate <NSObject>

- (void)didFailToLoadWithError:(nonnull NSError *)error;
- (void)didReceiveUnifiedNativeAd:(nonnull id<GADMediationNativeAd>)ad;

@end

@interface GADMAdapterNendNativeAdLoader : NSObject

typedef void (^NADNativeVideoCompletionBlock)(NADNativeVideo *_Nullable ad,
NSError *_Nullable error);

- (void)fetchNativeAd:(nonnull NSArray *)options
               spotId:(nonnull NSString *)spotId
               apiKey:(nonnull NSString *)apiKey
               extra:(nonnull GADMAdapterNendExtras *)extras;

@end
