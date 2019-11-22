//
//  GADMAdapterNendNativeAd.m
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import "GADMAdapterNendNativeAd.h"
#import "GADMAdapterNend.h"
#import "GADMAdapterNendConstants.h"
#import "GADNendNativeAdLoader.h"

@interface GADMAdapterNendNativeAd () <NADNativeDelegate>

@property(nonatomic, strong) NADNative *nativeAd;
@property(nonatomic, strong) GADNativeAdImage *mappedIcon;
@property(nonatomic, strong) NSArray *mappedImages;
@property(nonatomic, strong) UILabel *advertisingExplicitlyView;

@end

@implementation GADMAdapterNendNativeAd

- (instancetype)initWithNormal:(NADNative *)ad
                          logo:(nullable GADNativeAdImage *)logo
                         image:(nullable GADNativeAdImage *)image {
    self = [super init];
    if (self) {
        _nativeAd = ad;
        _nativeAd.delegate = self;
        _advertisingExplicitlyView = [UILabel new];
        _advertisingExplicitlyView.text = [_nativeAd prTextForAdvertisingExplicitly:NADNativeAdvertisingExplicitlyPR];
        
        if (logo) {
            _mappedIcon = logo;
        }
        if (image) {
            _mappedImages = [NSArray arrayWithObject:image];
        }
    }
    return self;
}

- (BOOL)hasVideoContent {
    return false;
}

- (UIView *)mediaView {
    return nil;
}

- (NSString *)advertiser {
    return self.nativeAd.promotionName;
}

- (NSString *)headline {
    return self.nativeAd.shortText;
}

- (NSArray *)images {
    return self.mappedImages;
}

- (NSString *)body {
    return self.nativeAd.longText;
}

- (GADNativeAdImage *)icon {
    return self.mappedIcon;
}

- (NSString *)callToAction {
    return self.nativeAd.actionButtonText;
}

- (NSDecimalNumber *)starRating {
    return nil;
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
    return self.advertisingExplicitlyView;
}

- (void)didRenderInView:(UIView *)view clickableAssetViews:(NSDictionary<GADUnifiedNativeAssetIdentifier,UIView *> *)clickableAssetViews nonclickableAssetViews:(NSDictionary<GADUnifiedNativeAssetIdentifier,UIView *> *)nonclickableAssetViews viewController:(UIViewController *)viewController
{
    [self.nativeAd activateAdView:view withPrLabel:self.adChoicesView];
}

- (BOOL)handlesUserImpressions
{
    return [GADNendNativeAdLoader handlesUserImpressions];
}

- (BOOL)handlesUserClicks
{
    return [GADNendNativeAdLoader handlesUserClicks];
}

#pragma mark - NADNativeDelegate
- (void)nadNativeDidImpression:(NADNative *)ad
{
    //Note : Adapter report click event here,
    //       but Google-Mobile-Ads-SDK does'n send event to App...
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordImpression:self];
}

- (void)nadNativeDidClickAd:(NADNative *)ad
{
    //Note : Adapter report click event here,
    //       but Google-Mobile-Ads-SDK does'n send event to App...
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordClick:self];
    
    // It's OK to reach event to App.
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillLeaveApplication:self];
}

- (void)nadNativeDidClickInformation:(NADNative *)ad
{
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillLeaveApplication:self];
}

@end
