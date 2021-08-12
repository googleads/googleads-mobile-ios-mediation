/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <UIKit/UIKit.h>
#import <YandexMobileAds/YandexMobileNativeAds.h>
#import "GADMYandexNativeAdAssetViewsExtractor.h"
#import "GADMYandexNativeAssets.h"
#import "GADMYandexNativeAdViewProvider.h"
#import "GADMYandexNativeAdRatingViewExtractor.h"
#import "GADMYandexNativeAdView.h"

@interface GADMYandexNativeAdAssetViewsExtractor ()

@property (nonatomic, strong, readonly) GADMYandexNativeAdRatingViewExtractor *ratingViewExtractor;
@property (nonatomic, strong, readonly) GADMYandexNativeAdViewProvider *adViewProvider;

@end

@implementation GADMYandexNativeAdAssetViewsExtractor

- (instancetype)init
{
    return [self initWithRatingViewExtractor:[[GADMYandexNativeAdRatingViewExtractor alloc] init]
                              adViewProvider:[[GADMYandexNativeAdViewProvider alloc] init]];
}

- (instancetype)initWithRatingViewExtractor:(GADMYandexNativeAdRatingViewExtractor *)ratingViewExtractor
                             adViewProvider:(GADMYandexNativeAdViewProvider *)adViewProvider
{
    self = [super init];
    if (self != nil) {
        _ratingViewExtractor = ratingViewExtractor;
        _adViewProvider = adViewProvider;
    }
    return self;
}

#pragma mark - GADMYandexNativeAdAssetViewsExtracting

- (NSDictionary *)assetViewsInAdView:(UIView *)adView
                     yandexMediaView:(YMANativeMediaView *)mediaView
                      feedbackButton:(UIButton *)feedbackButton
                 clickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
              nonclickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
                            nativeAd:(id<YMANativeAd>)nativeAd
{
    NSMutableDictionary *adMobAssetViews = [nonclickableAssetViews mutableCopy];
    [adMobAssetViews addEntriesFromDictionary:clickableAssetViews];
    UIView<GADMYandexNativeAdView> *adapterAdView = [self.adViewProvider adViewWithView:adView];
    return [self assetViewsInAdView:adapterAdView
                    yandexMediaView:mediaView
                     feedbackButton:feedbackButton
                    adMobAssetViews:[adMobAssetViews copy]
                           nativeAd:nativeAd];
}

#pragma mark - Private

- (NSDictionary *)assetViewsInAdView:(UIView<GADMYandexNativeAdView> *)adView
                     yandexMediaView:(YMANativeMediaView *)yandexMediaView
                      feedbackButton:(UIButton *)feedbackButton
                     adMobAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)adMobAssetViews
                            nativeAd:(id<YMANativeAd>)nativeAd
{
    NSMutableDictionary *views = [NSMutableDictionary dictionary];
    [views addEntriesFromDictionary:[self adMobSupportedViewsWithAssetViews:adMobAssetViews nativeAd:nativeAd]];
    [views addEntriesFromDictionary:[self yandexSupportedViewsWithAdView:adView]];
    views[kGADMYandexNativeRatingAsset] = [self.ratingViewExtractor ratingViewWithAdView:adView
                                                                              assetViews:adMobAssetViews];
    views[kGADMYandexNativeMediaAsset] = yandexMediaView;
    views[kGADMYandexNativeFeedbackAsset] = feedbackButton;
    return [views copy];
}

- (NSDictionary *)adMobSupportedViewsWithAssetViews:(NSDictionary *)assetViews
                                           nativeAd:(id<YMANativeAd>)nativeAd
{
    NSMutableDictionary *adMobViews = [NSMutableDictionary dictionary];
    adMobViews[kGADMYandexNativeBodyAsset] = assetViews[GADNativeBodyAsset];
    adMobViews[kGADMYandexNativeCallToActionAsset] = assetViews[GADNativeCallToActionAsset];
    adMobViews[kGADMYandexNativeDomainAsset] = assetViews[GADNativeStoreAsset];
    adMobViews[kGADMYandexNativeTitleAsset] = assetViews[GADNativeHeadlineAsset];
    adMobViews[kGADMYandexNativePriceAsset] = assetViews[GADNativePriceAsset];
    adMobViews[kGADMYandexNativeSponsoredAsset] = assetViews[GADNativeAdvertiserAsset];

    YMANativeAdAssets *assets = nativeAd.adAssets;
    if (assets.icon != nil) {
        adMobViews[kGADMYandexNativeIconAsset] = assetViews[GADNativeIconAsset];
    }
    else if (assets.favicon != nil) {
        adMobViews[kGADMYandexNativeFaviconAsset] = assetViews[GADNativeIconAsset];
    }
    return [adMobViews copy];
}

- (NSDictionary *)yandexSupportedViewsWithAdView:(UIView<GADMYandexNativeAdView> *)adView
{
    NSMutableDictionary *views = [NSMutableDictionary dictionary];
    if ([adView respondsToSelector:@selector(nativeAgeLabel)]) {
        views[kGADMYandexNativeAgeAsset] = adView.nativeAgeLabel;
    }
    if ([adView respondsToSelector:@selector(nativeReviewCountLabel)]) {
        views[kGADMYandexNativeReviewCountAsset] = adView.nativeReviewCountLabel;
    }
    if ([adView respondsToSelector:@selector(nativeWarningLabel)]) {
        views[kGADMYandexNativeWarningAsset] = adView.nativeWarningLabel;
    }
    return [views copy];
}

@end
