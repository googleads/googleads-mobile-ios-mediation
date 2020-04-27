//
//  GADMAdapterNendNativeVideoAd.m
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import "GADMAdapterNendNativeVideoAd.h"
#import "GADMAdapterNendNativeAdLoader.h"

@interface GADMAdapterNendNativeVideoAd () <NADNativeVideoDelegate, NADNativeVideoViewDelegate>

@end

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

- (nonnull instancetype)initWithVideo:(nonnull NADNativeVideo *)ad {
  self = [super init];
  if (self) {
    _videoAd = ad;
    _videoAd.delegate = self;

    _nendMediaView = [[NADNativeVideoView alloc] init];
    _nendMediaView.delegate = self;

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

- (nullable NSArray *)images {
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

- (nullable NSDictionary *)extraAssets {
  return nil;
}

- (nullable UIView *)adChoicesView {
  return nil;
}

- (void)didRenderInView:(nonnull UIView *)view
       clickableAssetViews:
           (nonnull NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (nonnull NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(nonnull UIViewController *)viewController {
  _nendMediaView.frame = view.frame;
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

#pragma mark - NADNativeVideoDelegate
- (void)nadNativeVideoDidImpression:(nonnull NADNativeVideo *)ad {
  // Note : Adapter report click event here,
  //       but Google-Mobile-Ads-SDK does'n send event to App...
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordImpression:self];
}

- (void)nadNativeVideoDidClickAd:(nonnull NADNativeVideo *)ad {
  // Note : Adapter report click event here,
  //       but Google-Mobile-Ads-SDK does'n send event to App...
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordClick:self];

  // It's OK to reach event to App.
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillLeaveApplication:self];
}

- (void)nadNativeVideoDidClickInformation:(nonnull NADNativeVideo *)ad {
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillLeaveApplication:self];
}

#pragma mark - NADNativeVideoViewDelegate
- (void)nadNativeVideoViewDidStartPlay:(nonnull NADNativeVideoView *)videoView {
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidPlayVideo:self];
}

- (void)nadNativeVideoViewDidStopPlay:(nonnull NADNativeVideoView *)videoView {
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidPauseVideo:self];
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
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidEndVideoPlayback:self];
}

- (void)nadNativeVideoViewDidFailToPlay:(nonnull NADNativeVideoView *)videoView {
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidEndVideoPlayback:self];
}

@end
