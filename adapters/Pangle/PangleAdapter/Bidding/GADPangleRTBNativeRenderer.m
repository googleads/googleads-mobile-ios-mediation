//
//  GADPangleRTBNativeRenderer.m
//  PangleAdapter
//
//  Created by bytedance on 2022/1/11.
//

#import "GADPangleRTBNativeRenderer.h"
#import "GADMediationAdapterPangleConstants.h"
#import <BUAdSDK/BUAdSDK.h>
#import "GADMAdapterPangleUtils.h"

static NSString *const BUDNativeAdTranslateKey = @"bu_nativeAd";
@interface GADPangleRTBNativeRenderer()<BUNativeAdDelegate>

@end

@implementation GADPangleRTBNativeRenderer {
    /// The completion handler to call when the ad loading succeeds or fails.
    GADMediationNativeLoadCompletionHandler _loadCompletionHandler;
    /// The Pangle native ad.
    BUNativeAd *_nativeAd;
    /// An ad event delegate to invoke when ad rendering events occur.
    id<GADMediationNativeAdEventDelegate> _delegate;
}
@synthesize images = _images,icon = _icon;

- (void)renderNativeAdForAdConfiguration:(nonnull GADMediationNativeAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
    _loadCompletionHandler = completionHandler;
    NSString *slotId = adConfiguration.credentials.settings[GADMAdapterPanglePlacementID] ?: @"";
    if (PangleIsEmptyString(slotId)) {
        NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorSlotIdNil, [NSString stringWithFormat:@"%@ cannot be nil.",GADMAdapterPanglePlacementID]);
        _loadCompletionHandler(nil, error);
        return;
    }
    BUAdSlot *slot = [[BUAdSlot alloc] init];
    slot.ID = slotId;
    _nativeAd = [[BUNativeAd alloc]initWithSlot:slot];
    
    _nativeAd.delegate = self;
    if (![_nativeAd respondsToSelector:@selector(setAdMarkup:)]) {
        NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorVersionLow, @"Pangle SDK version is too low");
        _loadCompletionHandler(nil, error);
        return;
    }
    [_nativeAd setAdMarkup:adConfiguration.bidResponse];
}

#pragma mark --GADMediationNativeAd
- (NSString *)headline {
    if (_nativeAd && _nativeAd.data) {
        return _nativeAd.data.AdTitle;
    }
    return nil;
}

- (NSString *)body {
    if (_nativeAd && _nativeAd.data) {
        return _nativeAd.data.AdDescription;
    }
    return nil;
}

- (NSString *)callToAction {
    if (_nativeAd && _nativeAd.data) {
        return _nativeAd.data.buttonText;
    }
    return nil;
}

- (NSDecimalNumber *)starRating {
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",@(_nativeAd.data.score)]];
}

- (NSString *)store {
    return nil;
}

- (NSString *)price {
    return nil;
}

- (NSString *)advertiser {
    if (_nativeAd && _nativeAd.data) {
        return _nativeAd.data.AdTitle;
    }
    return nil;
}

- (NSDictionary<NSString *,id> *)extraAssets {
    if (_nativeAd) {
        return @{BUDNativeAdTranslateKey:_nativeAd};
    }
    return nil;
}

#pragma mark --BUNativeAdDelegate
- (void)nativeAdDidLoad:(BUNativeAd *)nativeAd view:(UIView *_Nullable)view {
    if (_loadCompletionHandler) {
        _delegate = _loadCompletionHandler(self,nil);
    }
    BUMaterialMeta *data = nativeAd.data;
    // main image of the ad
    if (data.imageAry && data.imageAry.count && data.imageAry[0].imageURL != nil){
        _images = @[[self _getImage:data.imageAry[0].imageURL]];
    }
    
    // icon image of the ad
    if (data.icon && data.icon.imageURL != nil){
        _icon = [self _getImage:_nativeAd.data.icon.imageURL];
    }
}

- (void)nativeAd:(BUNativeAd *)nativeAd didFailWithError:(NSError *_Nullable)error {
    if (_loadCompletionHandler) {
        _loadCompletionHandler(nil, error);
    }
}

- (void)nativeAdDidBecomeVisible:(BUNativeAd *)nativeAd {
    id<GADMediationNativeAdEventDelegate> delegate = _delegate;
    [delegate reportImpression];
}

- (void)nativeAdDidClick:(BUNativeAd *)nativeAd withView:(UIView *_Nullable)view {
    id<GADMediationNativeAdEventDelegate> delegate = _delegate;
    [delegate reportClick];
}

#pragma mark --other
- (GADNativeAdImage *)_getImage:(NSString *)urlString {
    GADNativeAdImage *image = [[GADNativeAdImage alloc] initWithImage:[self p_loadImage:_nativeAd.data.imageAry[0].imageURL]];
    return image;
}

- (UIImage *)p_loadImage:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *image = [UIImage imageWithData: data];
    return image;
}

@end
