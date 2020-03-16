//
//  GADMAdapterNendNativeVideoAd.m
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import "GADMAdapterNendNativeVideoAd.h"
#import "GADMAdapterNendNativeAdLoader.h"

@interface GADMAdapterNendNativeVideoAd () <NADNativeVideoDelegate, NADNativeVideoViewDelegate>

@property(nonatomic, strong) NADNativeVideo *videoAd;
@property(nonatomic, strong) NADNativeVideoView *nendMediaView;
@property(nonatomic, strong) GADNativeAdImage *mappedIcon;
@property(nonatomic, strong) NSDecimalNumber *userRating;

@end

@implementation GADMAdapterNendNativeVideoAd

- (instancetype)initWithVideo:(NADNativeVideo *)ad {
    self = [super init];
    if (self) {
        _videoAd = ad;
        _videoAd.delegate = self;

        _nendMediaView = [NADNativeVideoView new];
        _nendMediaView.delegate = self;

        _mappedIcon = [[GADNativeAdImage alloc] initWithImage:ad.logoImage];
        _userRating = [[NSDecimalNumber alloc] initWithFloat:ad.userRating];
    }
    return self;
}

- (BOOL)hasVideoContent {
    return self.videoAd.hasVideo;
}

- (UIView *)mediaView {
    return self.nendMediaView;
}

- (CGFloat)mediaContentAspectRatio {
    if (self.videoAd.hasVideo) {
        if (self.videoAd.orientation == 1) {
            return 9.0f / 16.0f;
        } else {
            return 16.0 / 9.0f;
        }
    }
    return 0.0f;
}

- (NSString *)advertiser {
    return self.videoAd.advertiserName;
}

- (NSString *)headline {
    return self.videoAd.title;
}

- (NSArray *)images {
    return nil;
}

- (NSString *)body {
    return self.videoAd.explanation;
}

- (GADNativeAdImage *)icon {
    return self.mappedIcon;
}

- (NSString *)callToAction {
    return self.videoAd.callToAction;
}

- (NSDecimalNumber *)starRating {
    return self.userRating;
}

- (NSString *)store {
    return nil;
}

- (NSString *)price {
    return nil;
}

- (NSDictionary *)extraAssets {
    return nil;
}

- (UIView *)adChoicesView {
    return nil;
}

- (void)didRenderInView:(UIView *)view clickableAssetViews:(NSDictionary<GADUnifiedNativeAssetIdentifier,UIView *> *)clickableAssetViews nonclickableAssetViews:(NSDictionary<GADUnifiedNativeAssetIdentifier,UIView *> *)nonclickableAssetViews viewController:(UIViewController *)viewController
{
    self.nendMediaView.frame = view.frame;
    [self.videoAd registerInteractionViews:clickableAssetViews.allValues];
    self.nendMediaView.videoAd = self.videoAd;
}

- (void)didUntrackView:(UIView *)view {
    [self.videoAd unregisterInteractionViews];
}

- (BOOL)handlesUserImpressions
{
    return YES;
}

- (BOOL)handlesUserClicks
{
    return YES;
}

#pragma mark - NADNativeVideoDelegate
- (void)nadNativeVideoDidImpression:(NADNativeVideo *)ad
{
    //Note : Adapter report click event here,
    //       but Google-Mobile-Ads-SDK does'n send event to App...
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordImpression:self];
}

- (void)nadNativeVideoDidClickAd:(NADNativeVideo *)ad
{
    //Note : Adapter report click event here,
    //       but Google-Mobile-Ads-SDK does'n send event to App...
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordClick:self];
    
    // It's OK to reach event to App.
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillLeaveApplication:self];
}

- (void)nadNativeVideoDidClickInformation:(NADNativeVideo *)ad
{
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillLeaveApplication:self];
}

#pragma mark - NADNativeVideoViewDelegate
- (void)nadNativeVideoViewDidStartPlay:(NADNativeVideoView *)videoView
{
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidPlayVideo:self];
}

- (void)nadNativeVideoViewDidStopPlay:(NADNativeVideoView *)videoView
{
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidPauseVideo:self];
}

- (void)nadNativeVideoViewDidStartFullScreenPlaying:(NADNativeVideoView *)videoView
{
    // Do nothing here.
}

- (void)nadNativeVideoViewDidStopFullScreenPlaying:(NADNativeVideoView *)videoView
{
    // Do nothing here.
}

- (void)nadNativeVideoViewDidOpenFullScreen:(NADNativeVideoView *)videoView
{
    // Do nothing here.
}

- (void)nadNativeVideoViewDidCloseFullScreen:(NADNativeVideoView *)videoView
{
    // Do nothing here.
}

- (void)nadNativeVideoViewDidCompletePlay:(NADNativeVideoView *)videoView
{
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidEndVideoPlayback:self];
}

- (void)nadNativeVideoViewDidFailToPlay:(NADNativeVideoView *)videoView
{
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidEndVideoPlayback:self];
}

@end
