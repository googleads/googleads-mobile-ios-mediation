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

@implementation GADMAdapterNendNativeAdLoader

- (void)fetchNativeAd:(nonnull NSArray *)options
               spotId:(nonnull NSString *)spotId
               apiKey:(nonnull NSString *)apiKey
                extra:(nonnull GADMAdapterNendExtras *)extras {
  if (![GADMAdapterNendAdUnitMapper validateApiKey:apiKey spotId:spotId]) {
    NSError *error = GADMAdapterNendErrorWithCodeAndDescription(
        kGADErrorInternalError, @"SpotID and apiKey must not be nil.");
    [self didFailToLoadWithError:error];
    return;
  }

  [self prepareLoaderCompletionBlocks:options];

  if (extras && extras.nativeType == GADMNendNativeTypeVideo) {
    self.videoLoader = [[NADNativeVideoLoader alloc] initWithSpotId:spotId
                                                             apiKey:apiKey
                                                        clickAction:NADNativeVideoClickActionLP];
    self.videoLoader.mediationName = kGADMAdapterNendMediationName;
    self.videoLoader.userId = extras.userId;

    [self.videoLoader loadAdWithCompletionHandler:self.videoCompletionBlock];
  } else {
    self.normalLoader = [[NADNativeClient alloc] initWithSpotId:spotId apiKey:apiKey];
    [self.normalLoader loadWithCompletionBlock:self.normalCompletionBlock];
  }
}

- (void)prepareLoaderCompletionBlocks:(nonnull NSArray *)options {
  __weak GADMAdapterNendNativeAdLoader *weakSelf = self;
  self.normalCompletionBlock = ^(NADNative *ad, NSError *error) {
    GADMAdapterNendNativeAdLoader *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    if (error) {
      [strongSelf didFailToLoadWithError:error];
    } else {
      [strongSelf fetchImageAssets:ad imageOptions:[strongSelf pullImageAdLoaderOptions:options]];
    }
  };
  self.videoCompletionBlock = ^(NADNativeVideo *_Nullable ad, NSError *_Nullable error) {
    GADMAdapterNendNativeAdLoader *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    if (error) {
      [strongSelf didFailToLoadWithError:error];
    } else {
      GADMAdapterNendNativeVideoAd *unifiedAd =
          [[GADMAdapterNendNativeVideoAd alloc] initWithVideo:ad];
      [strongSelf didReceiveUnifiedNativeAd:unifiedAd];
    }
  };
}

- (void)fetchImageAssets:(NADNative *)ad
            imageOptions:(GADNativeAdImageAdLoaderOptions *)imageOptions {
  [self fetchLogo:ad
      disableLoading:imageOptions.disableImageLoading
        imageHandler:^(GADNativeAdImage *_Nullable logo) {
          if (!ad.imageUrl) {
            GADMAdapterNendNativeAd *unifiedAd =
                [[GADMAdapterNendNativeAd alloc] initWithNormal:ad logo:nil image:nil];
            [self didReceiveUnifiedNativeAd:unifiedAd];
          } else {
            if (imageOptions.disableImageLoading) {
              GADNativeAdImage *adImage =
                  [[GADNativeAdImage alloc] initWithURL:[NSURL URLWithString:ad.logoUrl]
                                                  scale:1.0f];
              GADMAdapterNendNativeAd *unifiedAd =
                  [[GADMAdapterNendNativeAd alloc] initWithNormal:ad logo:logo image:adImage];
              [self didReceiveUnifiedNativeAd:unifiedAd];
            } else {
              [ad loadAdImageWithCompletionBlock:^(UIImage *image) {
                if (image) {
                  GADNativeAdImage *adImage = [[GADNativeAdImage alloc] initWithImage:image];
                  GADMAdapterNendNativeAd *unifiedAd =
                      [[GADMAdapterNendNativeAd alloc] initWithNormal:ad logo:logo image:adImage];
                  [self didReceiveUnifiedNativeAd:unifiedAd];
                } else {
                  NSError *imageError = GADMAdapterNendErrorWithCodeAndDescription(
                      kGADErrorInternalError, @"Failed to load image assets.");
                  [self didFailToLoadWithError:imageError];
                }
              }];
            }
          }
        }];
}

- (void)fetchLogo:(nullable NADNative *)ad
    disableLoading:(BOOL)disableLoading
      imageHandler:(void (^)(GADNativeAdImage *_Nullable logo))imageHandler {
  if (!ad.logoUrl) {
    imageHandler(nil);
  } else {
    if (disableLoading) {
      imageHandler([[GADNativeAdImage alloc] initWithURL:[NSURL URLWithString:ad.logoUrl]
                                                   scale:1.0f]);
    } else {
      [ad loadLogoImageWithCompletionBlock:^(UIImage *logo) {
        if (logo) {
          imageHandler([[GADNativeAdImage alloc] initWithImage:logo]);
        } else {
          imageHandler(nil);
        }
      }];
    }
  }
}

- (void)didFailToLoadWithError:(nonnull NSError *)error {
  [NSException raise:NSInternalInconsistencyException
              format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

- (void)didReceiveUnifiedNativeAd:(nonnull id<GADMediatedUnifiedNativeAd>)ad {
  [NSException raise:NSInternalInconsistencyException
              format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

- (GADNativeAdImageAdLoaderOptions *)pullImageAdLoaderOptions:(NSArray *)options {
  NSPredicate *predicate =
      [NSPredicate predicateWithFormat:@"class == %@", [GADNativeAdImageAdLoaderOptions class]];
  return [[options filteredArrayUsingPredicate:predicate] firstObject];
}

@end
