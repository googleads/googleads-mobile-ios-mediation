//
//  GADMAdapterNendNativeAdLoader.h
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GADMAdapterNend.h"
#import "GADMAdapterNendConstants.h"
@import GoogleMobileAds;
@import NendAd;

NS_ASSUME_NONNULL_BEGIN

@protocol GADMAdapterNendNativeAdLoaderDelegate <NSObject>

- (void)didFailToLoadWithError:(NSError *)error;
- (void)didReceiveUnifiedNativeAd:(nonnull id<GADMediationNativeAd>)ad;

@end

@interface GADMAdapterNendNativeAdLoader : NSObject

@property(nonatomic, strong) NADNativeClient *normalLoader;
@property(nonatomic, strong) NADNativeVideoLoader *videoLoader;

@property(nonatomic, strong) NADNativeCompletionBlock normalCompletionBlock;
typedef void (^NADNativeVideoCompletionBlock)(NADNativeVideo * _Nullable ad, NSError * _Nullable error);
@property(nonatomic, strong) NADNativeVideoCompletionBlock videoCompletionBlock;

- (void)fetchNativeAd:(nonnull NSArray *)options
               spotId:(NSString *)spotId
               apiKey:(NSString *)apiKey
                extra:(GADMAdapterNendExtras *)extras;

@end

NS_ASSUME_NONNULL_END
