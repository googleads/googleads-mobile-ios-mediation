//
//  GADMAdapterNendNativeVideoAd.m
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import "GADMAdapterNendNativeVideoAd.h"

@implementation GADMAdapterNendNativeVideoAd {
  /// nend video ad.
  NADNativeVideo *_videoAd;

  /// nend media view.
  NADNativeVideoView *_nendMediaView;

  /// Mapped icon.
  GADNativeAdImage *_mappedIcon;

  /// User rating.
  NSDecimalNumber *_userRating;
}

- (nonnull instancetype)
    initWithVideo:(nonnull NADNativeVideo *)ad
         delegate:(nonnull id<NADNativeVideoDelegate, NADNativeVideoViewDelegate>)delegate {
  self = [super init];
  if (self) {
    _videoAd = ad;
    _videoAd.delegate = delegate;

    _nendMediaView = [[NADNativeVideoView alloc] init];
    _nendMediaView.delegate = delegate;

    _mappedIcon = [[GADNativeAdImage alloc] initWithImage:ad.logoImage];
    _userRating = [[NSDecimalNumber alloc] initWithFloat:ad.userRating];
  }
  return self;
}

- (BOOL)hasVideoContent {
  return _videoAd.hasVideo;
}

- (nullable UIView *)mediaView {
  return _nendMediaView;
}

- (CGFloat)mediaContentAspectRatio {
  if (_videoAd.hasVideo) {
    if (_videoAd.orientation == 1) {
      return 9.0f / 16.0f;
    } else {
      return 16.0 / 9.0f;
    }
  }
  return 0.0f;
}

- (nullable NSString *)advertiser {
  return _videoAd.advertiserName;
}

- (nullable NSString *)headline {
  return _videoAd.title;
}

- (nullable NSArray<GADNativeAdImage *> *)images {
  return nil;
}

- (nullable NSString *)body {
  return _videoAd.explanation;
}

- (nullable GADNativeAdImage *)icon {
  return _mappedIcon;
}

- (nullable NSString *)callToAction {
  return _videoAd.callToAction;
}

- (nullable NSDecimalNumber *)starRating {
  return _userRating;
}

- (nullable NSString *)store {
  return nil;
}

- (nullable NSString *)price {
  return nil;
}

- (nullable NSDictionary<NSString *, id> *)extraAssets {
  return nil;
}

- (nullable UIView *)adChoicesView {
  return nil;
}

- (void)didRenderInView:(nonnull UIView *)view
       clickableAssetViews:
           (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(nonnull UIViewController *)viewController {
  for (UIView *subview in view.subviews) {
    if ([subview isKindOfClass:[GADMediaView class]]) {
      _nendMediaView.bounds = subview.bounds;
      break;
    }
  }

  [_videoAd registerInteractionViews:clickableAssetViews.allValues];
  _nendMediaView.videoAd = _videoAd;
}

- (void)didUntrackView:(nullable UIView *)view {
  [_videoAd unregisterInteractionViews];
}

- (BOOL)handlesUserImpressions {
  return YES;
}

- (BOOL)handlesUserClicks {
  return YES;
}

@end
