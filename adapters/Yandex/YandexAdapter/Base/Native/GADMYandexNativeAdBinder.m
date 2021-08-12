/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <YandexMobileAds/YandexMobileNativeAds.h>
#import "GADMYandexNativeAdBinder.h"
#import "GADMYandexCallToActionBinder.h"
#import "GADMYandexMediaViewBinder.h"
#import "GADMYandexNativeAssets.h"
#import "GADMYandexNativeAdAssetViewsExtracting.h"
#import "GADMYandexNativeAssetViewBinder.h"
#import "GADMYandexNativeAdViewProvider.h"
#import "GADMYandexNativeAdView.h"
#import "YMANativeAdBinding.h"

@interface GADMYandexNativeAdBinder ()

@property (nonatomic, strong, readonly) id<YMANativeAd> nativeAd;
@property (nonatomic, strong, readonly) id<GADMYandexNativeAdAssetViewsExtracting> assetViewsExtractor;
@property (nonatomic, strong, readonly) GADMYandexCallToActionBinder *callToActionBinder;
@property (nonatomic, strong, readonly) GADMYandexMediaViewBinder *mediaViewBinder;
@property (nonatomic, strong, readonly) GADMYandexNativeAssetViewBinder *yandexAssetViewBinder;
@property (nonatomic, strong, readonly) GADMYandexNativeAdViewProvider *adViewProvider;

@property (nonatomic, strong) id<GADMediatedUnifiedNativeAd> adMobAd;

@end

@implementation GADMYandexNativeAdBinder

- (instancetype)initWithNativeAd:(id<YMANativeAd>)nativeAd
             assetViewsExtractor:(id<GADMYandexNativeAdAssetViewsExtracting>)assetViewsExtractor
{
    return [self initWithNativeAd:nativeAd
              assetViewsExtractor:assetViewsExtractor
               callToActionBinder:[[GADMYandexCallToActionBinder alloc] init]
                  mediaViewBinder:[[GADMYandexMediaViewBinder alloc] init]
            yandexAssetViewBinder:[[GADMYandexNativeAssetViewBinder alloc] init]
                   adViewProvider:[[GADMYandexNativeAdViewProvider alloc] init]];
}

- (instancetype)initWithNativeAd:(id<YMANativeAd>)nativeAd
             assetViewsExtractor:(id<GADMYandexNativeAdAssetViewsExtracting>)assetViewsExtractor
              callToActionBinder:(GADMYandexCallToActionBinder *)callToActionBinder
                 mediaViewBinder:(GADMYandexMediaViewBinder *)mediaViewBinder
           yandexAssetViewBinder:(GADMYandexNativeAssetViewBinder *)yandexAssetViewBinder
                  adViewProvider:(GADMYandexNativeAdViewProvider *)adViewProvider
{
    self = [super init];
    if (self != nil) {
        _nativeAd = nativeAd;
        _assetViewsExtractor = assetViewsExtractor;
        _callToActionBinder = callToActionBinder;
        _mediaViewBinder = mediaViewBinder;
        _yandexAssetViewBinder = yandexAssetViewBinder;
        _adViewProvider = adViewProvider;
    }
    return self;
}

- (void)bindToView:(UIView *)view
        adMobAd:(id<GADMediatedUnifiedNativeAd>)adMobAd
        yandexMediaView:(YMANativeMediaView *)mediaView
        feedbackButton:(UIButton *)feedbackButton
        clickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
        nonclickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
{
    self.adMobAd = adMobAd;
    NSDictionary *assetViews = [self.assetViewsExtractor assetViewsInAdView:view
                                                            yandexMediaView:mediaView
                                                             feedbackButton:feedbackButton
                                                        clickableAssetViews:clickableAssetViews
                                                     nonclickableAssetViews:nonclickableAssetViews
                                                                   nativeAd:self.nativeAd];
    [self bindToView:view adMobAd:adMobAd yandexMediaView:mediaView feedbackButton:feedbackButton assetViews:assetViews];
}

- (void)bindToView:(UIView *)view
           adMobAd:(id<GADMediatedUnifiedNativeAd>)adMobAd
   yandexMediaView:(YMANativeMediaView *)mediaView
    feedbackButton:(UIButton *)feedbackButton
        assetViews:(NSDictionary *)assetViews
{
    if ([self.nativeAd respondsToSelector:@selector(bindAdToView:assetViews:error:)] == NO) {
        NSLog(@"Failed to bind native ad: incorrect Yandex native ad");
        return;
    }

    NSError *error = nil;
    [(id<YMANativeAdBinding>)self.nativeAd bindAdToView:view assetViews:assetViews error:&error];
    if (error == nil) {
        [self.callToActionBinder bindWithView:assetViews[kGADMYandexNativeCallToActionAsset]];
        [self.mediaViewBinder bindMediaView:mediaView aspectRatio:adMobAd.mediaContentAspectRatio];
        UIView<GADMYandexNativeAdView> *adView = [self.adViewProvider adViewWithView:view];
        [self.yandexAssetViewBinder bindWithAdView:adView];
    }
    else {
        NSLog(@"Failed to bind native ad:%@", error.localizedDescription);
    }
}

- (void)unbind
{
    [self.callToActionBinder unbind];
    [self.mediaViewBinder unbind];
    [self.yandexAssetViewBinder unbind];
    self.adMobAd = nil;
}

@end
