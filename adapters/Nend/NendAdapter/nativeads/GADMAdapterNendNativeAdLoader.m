//
//  GADMAdapterNendNativeAdLoader.m
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import "GADMAdapterNendNativeAdLoader.h"

#import <NendAd/NendAd.h>

#import "GADMAdapterNendAdUnitMapper.h"
#import "GADMAdapterNendNativeAd.h"
#import "GADMAdapterNendNativeVideoAd.h"
#import "GADMAdapterNendUtils.h"

@implementation GADMAdapterNendNativeAdLoader {
  /// nend native ad loader.
  NADNativeClient *_normalLoader;

  /// nend native video ad loader.
  NADNativeVideoLoader *_videoLoader;
}

- (void)fetchNativeAd:(nonnull NSArray *)options
               spotId:(nonnull NSString *)spotId
               apiKey:(nonnull NSString *)apiKey
                extra:(nonnull GADMAdapterNendExtras *)extras {
  if (![GADMAdapterNendAdUnitMapper isValidAPIKey:apiKey spotId:spotId]) {
    NSError *error = GADMAdapterNendErrorWithCodeAndDescription(
        kGADErrorInternalError, @"SpotID and apiKey must not be nil.");
    [self didFailToLoadWithError:error];
    return;
  }

  if (extras && extras.nativeType == GADMNendNativeTypeVideo) {
    _videoLoader = [[NADNativeVideoLoader alloc] initWithSpotId:spotId
                                                         apiKey:apiKey
                                                    clickAction:NADNativeVideoClickActionLP];
    _videoLoader.mediationName = kGADMAdapterNendMediationName;
    _videoLoader.userId = extras.userId;

    __weak GADMAdapterNendNativeAdLoader *weakSelf = self;
    [_videoLoader loadAdWithCompletionHandler:^(NADNativeVideo *_Nullable nativeAd,
                                                NSError *_Nullable error) {
      GADMAdapterNendNativeAdLoader *strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }

      if (error) {
        [strongSelf didFailToLoadWithError:error];
        return;
      }
      GADMAdapterNendNativeVideoAd *unifiedAd =
          [[GADMAdapterNendNativeVideoAd alloc] initWithVideo:nativeAd];
      [strongSelf didReceiveUnifiedNativeAd:unifiedAd];
    }];
  } else {
    _normalLoader = [[NADNativeClient alloc] initWithSpotId:spotId apiKey:apiKey];

    __weak GADMAdapterNendNativeAdLoader *weakSelf = self;
    [_normalLoader loadWithCompletionBlock:^(NADNative *_Nullable ad, NSError *_Nullable error) {
      GADMAdapterNendNativeAdLoader *strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }

      if (error) {
        [strongSelf didFailToLoadWithError:error];
        return;
      }
      [strongSelf fetchImageAssets:ad imageOptions:[strongSelf pullImageAdLoaderOptions:options]];
    }];
  }
}

- (void)fetchImageAssets:(nonnull NADNative *)ad
            imageOptions:(nonnull GADNativeAdImageAdLoaderOptions *)imageOptions {
  [self fetchLogo:ad
      disableLoading:imageOptions.disableImageLoading
        imageHandler:^(GADNativeAdImage *_Nullable logo) {
          if (!ad.imageUrl) {
            GADMAdapterNendNativeAd *unifiedAd =
                [[GADMAdapterNendNativeAd alloc] initWithNativeAd:ad logo:nil image:nil];
            [self didReceiveUnifiedNativeAd:unifiedAd];
            return;
          }

          if (imageOptions.disableImageLoading) {
            GADNativeAdImage *adImage =
                [[GADNativeAdImage alloc] initWithURL:[NSURL URLWithString:ad.logoUrl] scale:1.0f];
            GADMAdapterNendNativeAd *unifiedAd =
                [[GADMAdapterNendNativeAd alloc] initWithNativeAd:ad logo:logo image:adImage];
            [self didReceiveUnifiedNativeAd:unifiedAd];
            return;
          }

          [ad loadAdImageWithCompletionBlock:^(UIImage *_Nullable image) {
            if (!image) {
              NSError *imageError = GADMAdapterNendErrorWithCodeAndDescription(
                  kGADErrorInternalError, @"Failed to load image assets.");
              [self didFailToLoadWithError:imageError];
              return;
            }

            GADNativeAdImage *adImage = [[GADNativeAdImage alloc] initWithImage:image];
            GADMAdapterNendNativeAd *unifiedAd =
                [[GADMAdapterNendNativeAd alloc] initWithNativeAd:ad logo:logo image:adImage];
            [self didReceiveUnifiedNativeAd:unifiedAd];
          }];
        }];
}

- (void)fetchLogo:(nonnull NADNative *)ad
    disableLoading:(BOOL)disableLoading
      imageHandler:(void (^)(GADNativeAdImage *_Nullable logo))imageHandler {
  if (!ad.logoUrl) {
    imageHandler(nil);
    return;
  }

  if (disableLoading) {
    imageHandler([[GADNativeAdImage alloc] initWithURL:[NSURL URLWithString:ad.logoUrl]
                                                 scale:1.0f]);
    return;
  }

  [ad loadLogoImageWithCompletionBlock:^(UIImage *_Nullable logo) {
    GADNativeAdImage *image = nil;
    if (logo) {
      image = [[GADNativeAdImage alloc] initWithImage:logo];
    }
    imageHandler(image);
  }];
}

- (void)didFailToLoadWithError:(nonnull NSError *)error {
  [NSException raise:NSInternalInconsistencyException
              format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

- (void)didReceiveUnifiedNativeAd:(nonnull id<GADMediatedUnifiedNativeAd>)ad {
  [NSException raise:NSInternalInconsistencyException
              format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

- (nonnull GADNativeAdImageAdLoaderOptions *)pullImageAdLoaderOptions:(nonnull NSArray *)options {
  NSPredicate *predicate =
      [NSPredicate predicateWithFormat:@"class == %@", [GADNativeAdImageAdLoaderOptions class]];
  return [[options filteredArrayUsingPredicate:predicate] firstObject];
}

@end
