//
//  GADMediationAdapterNendNativeAdLoader.m
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import "GADMediationAdapterNendNativeAdLoader.h"

#import <stdatomic.h>

#import "GADMAdapterNend.h"
#import "GADMAdapterNendAdUnitMapper.h"
#import "GADMAdapterNendConstants.h"
#import "GADMAdapterNendExtras.h"
#import "GADMAdapterNendNativeAd.h"
#import "GADMAdapterNendNativeVideoAd.h"
#import "GADMAdapterNendUtils.h"
#import "GADMediationAdapterNend.h"

@interface GADMediationAdapterNendNativeAdLoader () <NADNativeDelegate,
                                                     NADNativeVideoDelegate,
                                                     NADNativeVideoViewDelegate>
@end

@implementation GADMediationAdapterNendNativeAdLoader {
  /// The completion handler to call when ad loading succeeds or fails.
  GADMediationNativeLoadCompletionHandler _completionHandler;

  /// Native ad configuration of the ad request.
  GADMediationNativeAdConfiguration *_adConfiguration;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  /// Intentionally keeping a strong reference to the delegate because this is returned from the
  /// GMA SDK, not set on the GMA SDK.
  id<GADMediationNativeAdEventDelegate> _adEventDelegate;

  /// nend native ad loader.
  NADNativeClient *_normalLoader;

  /// nend native video ad loader.
  NADNativeVideoLoader *_videoLoader;
}

- (instancetype)initWithAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)loadNativeAdWithCompletionHandler:
    (GADMediationNativeLoadCompletionHandler)completionHandler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationNativeLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];

  _completionHandler = ^id<GADMediationNativeAdEventDelegate>(_Nullable id<GADMediationNativeAd> ad,
                                                              NSError *_Nullable error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }

    id<GADMediationNativeAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(ad, error);
    }
    originalCompletionHandler = nil;
    return delegate;
  };

  NSString *spotId = _adConfiguration.credentials.settings[GADMAdapterNendSpotID];
  NSString *apiKey = _adConfiguration.credentials.settings[GADMAdapterNendApiKey];

  if (![GADMAdapterNendAdUnitMapper isValidAPIKey:apiKey spotId:spotId.integerValue]) {
    NSError *error = GADMAdapterNendErrorWithCodeAndDescription(
        GADMAdapterNendInvalidServerParameters, @"Spot ID and/or API key must not be nil.");
    _completionHandler(nil, error);
    return;
  }

  GADMAdapterNendExtras *extras = _adConfiguration.extras;

  if (extras && extras.nativeType == GADMAdapterNendNativeTypeVideo) {
    _videoLoader = [[NADNativeVideoLoader alloc] initWithSpotID:spotId.integerValue
                                                         apiKey:apiKey
                                                    clickAction:NADNativeVideoClickActionLP];
    _videoLoader.mediationName = GADMAdapterNendMediationName;
    _videoLoader.userId = extras.userId;

    __weak GADMediationAdapterNendNativeAdLoader *weakSelf = self;
    [_videoLoader loadAdWithCompletionHandler:^(NADNativeVideo *_Nullable nativeAd,
                                                NSError *_Nullable error) {
      GADMediationAdapterNendNativeAdLoader *strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }

      if (error) {
        strongSelf->_completionHandler(nil, error);
        return;
      }
      GADMAdapterNendNativeVideoAd *unifiedAd =
          [[GADMAdapterNendNativeVideoAd alloc] initWithVideo:nativeAd delegate:strongSelf];
      strongSelf->_adEventDelegate = strongSelf->_completionHandler(unifiedAd, nil);
    }];
  } else {
    _normalLoader = [[NADNativeClient alloc] initWithSpotID:spotId.integerValue apiKey:apiKey];

    __weak GADMediationAdapterNendNativeAdLoader *weakSelf = self;
    [_normalLoader loadWithCompletionBlock:^(NADNative *_Nullable ad, NSError *_Nullable error) {
      GADMediationAdapterNendNativeAdLoader *strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }

      if (error) {
        strongSelf->_completionHandler(nil, error);
        return;
      }

      [strongSelf
          createAdapterNendNativeAdForNativeAd:ad
                             completionHandler:^(GADMAdapterNendNativeAd *_Nullable nativeAd,
                                                 NSError *_Nullable error) {
                               if (error) {
                                 strongSelf->_completionHandler(nil, error);
                                 return;
                               }

                               strongSelf->_adEventDelegate =
                                   strongSelf->_completionHandler(nativeAd, nil);
                             }];
    }];
  }
}

- (void)createAdapterNendNativeAdForNativeAd:(nonnull NADNative *)ad
                           completionHandler:(void (^)(GADMAdapterNendNativeAd *_Nullable nativeAd,
                                                       NSError *_Nullable error))completionHandler {
  // It is possible for nend native ads to have no logo and image if using nend's text-only format.
  if (!ad.logoUrl && !ad.imageUrl) {
    ad.delegate = self;
    GADMAdapterNendNativeAd *unifiedAd = [[GADMAdapterNendNativeAd alloc] initWithNativeAd:ad
                                                                                      logo:nil
                                                                                     image:nil];
    completionHandler(unifiedAd, nil);
    return;
  }

  dispatch_group_t assetLoadingGroup = dispatch_group_create();
  __block GADNativeAdImage *logoImage = nil;
  __block GADNativeAdImage *adImage = nil;

  GADNativeAdImageAdLoaderOptions *imageOptions = [self imageAdLoaderOptions];
  if (imageOptions.disableImageLoading && ad.logoUrl) {
    logoImage = [[GADNativeAdImage alloc] initWithURL:[NSURL URLWithString:ad.logoUrl] scale:1.0f];
  } else {
    dispatch_group_enter(assetLoadingGroup);
    [ad loadLogoImageWithCompletionBlock:^(UIImage *_Nullable logo) {
      if (logo) {
        logoImage = [[GADNativeAdImage alloc] initWithImage:logo];
      }
      dispatch_group_leave(assetLoadingGroup);
    }];
  }

  dispatch_group_enter(assetLoadingGroup);
  [ad loadAdImageWithCompletionBlock:^(UIImage *_Nullable image) {
    if (!image) {
      NSError *imageError = GADMAdapterNendErrorWithCodeAndDescription(
          GADMAdapterNendErrorLoadingImages, @"Failed to load image assets.");
      completionHandler(nil, imageError);
      return;
    }

    adImage = [[GADNativeAdImage alloc] initWithImage:image];
    dispatch_group_leave(assetLoadingGroup);
  }];

  dispatch_group_notify(assetLoadingGroup, dispatch_get_main_queue(), ^{
    ad.delegate = self;
    GADMAdapterNendNativeAd *unifiedAd = [[GADMAdapterNendNativeAd alloc] initWithNativeAd:ad
                                                                                      logo:logoImage
                                                                                     image:adImage];
    completionHandler(unifiedAd, nil);
  });
}

- (nonnull GADNativeAdImageAdLoaderOptions *)imageAdLoaderOptions {
  NSPredicate *predicate =
      [NSPredicate predicateWithFormat:@"class == %@", [GADNativeAdImageAdLoaderOptions class]];
  return (GADNativeAdImageAdLoaderOptions *)[_adConfiguration.options
             filteredArrayUsingPredicate:predicate]
      .firstObject;
}

#pragma mark - NADNativeDelegate
- (void)nadNativeDidImpression:(nonnull NADNative *)ad {
  [_adEventDelegate reportImpression];
}

- (void)nadNativeDidClickAd:(nonnull NADNative *)ad {
  [_adEventDelegate reportClick];
  [_adEventDelegate willBackgroundApplication];
}

- (void)nadNativeDidClickInformation:(nonnull NADNative *)ad {
  [_adEventDelegate willBackgroundApplication];
}

#pragma mark - NADNativeVideoDelegate
- (void)nadNativeVideoDidImpression:(nonnull NADNativeVideo *)ad {
  [_adEventDelegate reportImpression];
}

- (void)nadNativeVideoDidClickAd:(nonnull NADNativeVideo *)ad {
  [_adEventDelegate reportClick];
  [_adEventDelegate willBackgroundApplication];
}

- (void)nadNativeVideoDidClickInformation:(nonnull NADNativeVideo *)ad {
  [_adEventDelegate willBackgroundApplication];
}

#pragma mark - NADNativeVideoViewDelegate
- (void)nadNativeVideoViewDidStartPlay:(nonnull NADNativeVideoView *)videoView {
  [_adEventDelegate didPlayVideo];
}

- (void)nadNativeVideoViewDidStopPlay:(nonnull NADNativeVideoView *)videoView {
  [_adEventDelegate didPauseVideo];
}

- (void)nadNativeVideoViewDidStartFullScreenPlaying:(nonnull NADNativeVideoView *)videoView {
  // Do nothing here.
}

- (void)nadNativeVideoViewDidStopFullScreenPlaying:(nonnull NADNativeVideoView *)videoView {
  // Do nothing here.
}

- (void)nadNativeVideoViewDidOpenFullScreen:(nonnull NADNativeVideoView *)videoView {
  // Do nothing here.
}

- (void)nadNativeVideoViewDidCloseFullScreen:(nonnull NADNativeVideoView *)videoView {
  // Do nothing here.
}

- (void)nadNativeVideoViewDidCompletePlay:(nonnull NADNativeVideoView *)videoView {
  [_adEventDelegate didEndVideo];
}

- (void)nadNativeVideoViewDidFailToPlay:(nonnull NADNativeVideoView *)videoView {
  [_adEventDelegate didEndVideo];
}

@end
