/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import "GADMYandexNativeAd.h"
#import "GADMYandexNativeAdBinder.h"
#import "GADMYandexNativeAdViewProvider.h"
#import "GADMYandexNativeExtraAssets.h"
#import "GADMYandexNativeAdImageFactory.h"
#import "GADMYandexNativeAdView.h"
#import "GADMYandexFeedbackButtonConfigurator.h"

@interface GADMYandexNativeAd () <YMANativeAdDelegate>

@property (nonatomic, strong, readonly) id<YMANativeAd> nativeAd;
@property (nonatomic, strong, readonly) GADMYandexNativeAdBinder *binder;
@property (nonatomic, strong, readonly) GADMYandexNativeAdImageFactory *nativeAdImageFactory;
@property (nonatomic, strong, readonly) GADMYandexNativeAdViewProvider *adViewProvider;
@property (nonatomic, strong, readonly) YMANativeMediaView *yandexMediaView;
@property (nonatomic, strong, readonly) UIButton *feedbackButton;
@property (nonatomic, strong, readonly) GADMYandexFeedbackButtonConfigurator *feedbackButtonConfiguator;

@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, weak) UIView<GADMYandexNativeAdView> *adView;

@end

@implementation GADMYandexNativeAd

- (instancetype)initWithNativeAd:(id<YMANativeAd>)nativeAd binder:(GADMYandexNativeAdBinder *)binder
{
    YMANativeMediaView *mediaView = [[YMANativeMediaView alloc] init];
    UIButton *feedbackButton = [[UIButton alloc] init];
    GADMYandexNativeAdImageFactory *nativeAdImageFactory = [[GADMYandexNativeAdImageFactory alloc] init];
    GADMYandexNativeAdViewProvider *adViewProvider = [[GADMYandexNativeAdViewProvider alloc] init];
    return [self initWithBinder:binder
           nativeAdImageFactory:nativeAdImageFactory
                 adViewProvider:adViewProvider
                       nativeAd:nativeAd
                yandexMediaView:mediaView
                 feedbackButton:feedbackButton
      feedbackButtonConfiguator:[[GADMYandexFeedbackButtonConfigurator alloc] init]];
}

- (instancetype)initWithBinder:(GADMYandexNativeAdBinder *)binder
          nativeAdImageFactory:(GADMYandexNativeAdImageFactory *)nativeAdImageFactory
                adViewProvider:(GADMYandexNativeAdViewProvider *)adViewProvider
                      nativeAd:(id<YMANativeAd>)nativeAd
               yandexMediaView:(YMANativeMediaView *)mediaView
                feedbackButton:(UIButton *)feedbackButton
     feedbackButtonConfiguator:(GADMYandexFeedbackButtonConfigurator *)feedbackButtonConfiguator
{
    self = [super init];
    if (self != nil) {
        _binder = binder;
        _nativeAdImageFactory = nativeAdImageFactory;
        _adViewProvider = adViewProvider;
        _yandexMediaView = mediaView;
        _feedbackButton = feedbackButton;
        _feedbackButtonConfiguator = feedbackButtonConfiguator;

        _nativeAd = nativeAd;
        _nativeAd.delegate = self;
    }
    return self;
}

#pragma mark - GADMediationNativeAd

- (BOOL)handlesUserClicks
{
    return YES;
}

- (BOOL)handlesUserImpressions
{
    return YES;
}

#pragma mark - GADMediatedUnifiedNativeAd

- (NSString *)advertiser
{
    return self.nativeAd.adAssets.sponsored;
}

- (NSString *)headline
{
    return self.nativeAd.adAssets.title;
}

- (NSArray *)images
{
    GADNativeAdImage *image =
        [self.nativeAdImageFactory imageWithYandexNativeAdImage:self.nativeAd.adAssets.image];
    return image != nil ? @[image] : @[];
}

- (NSString *)body
{
    return self.nativeAd.adAssets.body;
}

- (GADNativeAdImage *)icon
{
    YMANativeAdAssets *assets = self.nativeAd.adAssets;
    YMANativeAdImage *icon = assets.icon ?: assets.favicon;
    return [self.nativeAdImageFactory imageWithYandexNativeAdImage:icon];
}

- (NSString *)callToAction
{
    return self.nativeAd.adAssets.callToAction;
}

- (NSDecimalNumber *)starRating
{
    NSNumber *rating = self.nativeAd.adAssets.rating;
    return rating == nil ? nil : [NSDecimalNumber decimalNumberWithDecimal:[rating decimalValue]];
}

- (NSString *)store
{
    return self.nativeAd.adAssets.domain;
}

- (NSString *)price
{
    return self.nativeAd.adAssets.price;
}

- (NSDictionary<NSString *, id> *)extraAssets
{
    NSMutableDictionary *assets = [NSMutableDictionary dictionary];
    YMANativeAdAssets *adAssets = self.nativeAd.adAssets;
    assets[kGADMYandexNativeAgeExtraAsset] = adAssets.age;
    assets[kGADMYandexNativeReviewCountExtraAsset] = adAssets.reviewCount;
    assets[kGADMYandexNativeWarningExtraAsset] = adAssets.warning;
    return [assets copy];
}

- (UIView *)mediaView
{
    return self.yandexMediaView;
}

- (UIView *)adChoicesView
{
    UIButton *feedbackView = nil;
    if (self.nativeAd.adAssets.feedbackAvailable) {
        [self.feedbackButtonConfiguator configureFeedbackButton:self.feedbackButton];
        feedbackView = self.feedbackButton;
    }
    return feedbackView;
}

- (BOOL)hasVideoContent
{
    YMANativeAdAssets *adAssets = self.nativeAd.adAssets;
    return adAssets.media != nil || adAssets.image != nil;
}

- (CGFloat)mediaContentAspectRatio
{
    CGFloat result = 0.f;
    YMANativeAdAssets *adAssets = self.nativeAd.adAssets;
    if (adAssets.media != nil) {
        result = adAssets.media.aspectRatio;
    }
    else if (adAssets.image.size.height != 0.f) {
        result = adAssets.image.size.width / adAssets.image.size.height;
    }

    return result;
}

- (void)didRenderInView:(UIView *)view
    clickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
 nonclickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
         viewController:(UIViewController *)viewController
{
    self.viewController = viewController;
    self.adView = [self.adViewProvider adViewWithView:view];
    [self.binder bindToView:view
                    adMobAd:self
            yandexMediaView:self.yandexMediaView
             feedbackButton:self.feedbackButton
        clickableAssetViews:clickableAssetViews
     nonclickableAssetViews:nonclickableAssetViews];
}

- (void)didUntrackView:(UIView *)view
{
    [self.binder unbind];
}

#pragma mark - YMANativeAdDelegate

- (UIViewController *)viewControllerForPresentingModalView
{
    return nil;
}

- (void)nativeAdWillLeaveApplication:(id<YMANativeAd>)ad
{
    [self.delegate reportClick];
}

- (void)nativeAd:(id<YMANativeAd>)ad willPresentScreen:(UIViewController *)viewController
{
    [self.delegate reportClick];
    [self.delegate willPresentFullScreenView];
}

- (void)nativeAd:(id<YMANativeAd>)ad didDismissScreen:(UIViewController *)viewController
{
    [self.delegate willDismissFullScreenView];
    [self.delegate didDismissFullScreenView];
}

- (void)nativeAd:(id<YMANativeAd>)ad didTrackImpressionWithData:(id<YMAImpressionData>)impressionData
{
    [self.delegate reportImpression];
}

- (void)closeNativeAd:(id<YMANativeAd>)ad
{
    if ([self.adView respondsToSelector:@selector(closeAdView)]) {
        [self.adView closeAdView];
    }
}

@end
