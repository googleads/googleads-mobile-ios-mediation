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

@property(nonatomic, strong, nonnull) NADNativeClient *normalLoader;
@property(nonatomic, strong, nonnull) NADNativeVideoLoader *videoLoader;

@property(nonatomic, strong, nonnull) NADNativeCompletionBlock normalCompletionBlock;
typedef void (^NADNativeVideoCompletionBlock)(NADNativeVideo *_Nullable ad,
                                              NSError *_Nullable error);
@property(nonatomic, strong, nonnull) NADNativeVideoCompletionBlock videoCompletionBlock;

- (void)fetchNativeAd:(nonnull NSArray *)options
               spotId:(nonnull NSString *)spotId
               apiKey:(nonnull NSString *)apiKey
                extra:(nonnull GADMAdapterNendExtras *)extras;

@end
