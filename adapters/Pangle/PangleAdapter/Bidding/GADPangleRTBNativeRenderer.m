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

@property (nonatomic, strong) GADMediationNativeAdConfiguration *adConfig;
@property (nonatomic, copy) GADMediationNativeLoadCompletionHandler loadCompletionHandler;

@property (nonatomic, strong) BUNativeAd *nativeAd;

@property (nonatomic, weak) id<GADMediationNativeAdEventDelegate> delegate;

@property(nonatomic, nullable) NSArray<GADNativeAdImage *> *images;
@property(nonatomic, nullable) GADNativeAdImage *icon;

@end

@implementation GADPangleRTBNativeRenderer
@synthesize images = _images,icon = _icon;

- (void)renderNativeAdForAdConfiguration:(nonnull GADMediationNativeAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
    self.adConfig  = adConfiguration;
    self.loadCompletionHandler = completionHandler;
    NSString *slotId = self.adConfig.credentials.settings[GADMAdapterPanglePlacementID] ?: @"";
    if (PangleIsEmptyString(slotId)) {
        NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorInvalidRequest, [NSString stringWithFormat:@"%@ cannot be nil.",GADMAdapterPanglePlacementID]);
        self.loadCompletionHandler(nil, error);
        return;
    }
    BUAdSlot *slot = [[BUAdSlot alloc]init];
    slot.ID = slotId;
    self.nativeAd = [[BUNativeAd alloc]initWithSlot:slot];
    
    self.nativeAd.delegate = self;
    [self.nativeAd setMopubAdMarkUp:adConfiguration.bidResponse];
}

//MARK;--GADMediationNativeAd
- (NSString *)headline {
    if (self.nativeAd && self.nativeAd.data) {
        return self.nativeAd.data.AdTitle;
    }
    return nil;
}

- (NSString *)body {
    if (self.nativeAd && self.nativeAd.data) {
        return self.nativeAd.data.AdDescription;
    }
    return nil;
}

- (NSString *)callToAction {
    if (self.nativeAd && self.nativeAd.data) {
        return self.nativeAd.data.buttonText;
    }
    return nil;
}

- (NSDecimalNumber *)starRating {
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%ld",self.nativeAd.data.score]];
}

- (NSString *)store {
    return nil;
}

- (NSString *)price {
    return nil;
}

- (NSString *)advertiser {
    if (self.nativeAd && self.nativeAd.data) {
        return self.nativeAd.data.AdTitle;
    }
    return nil;
}

- (NSDictionary<NSString *,id> *)extraAssets {
    if (self.nativeAd) {
        return @{BUDNativeAdTranslateKey:self.nativeAd};
    }
    return nil;
}

//MARK:--BUNativeAdDelegate
/**
 This method is called when native ad material loaded successfully.
 */
- (void)nativeAdDidLoad:(BUNativeAd *)nativeAd view:(UIView *_Nullable)view {
    if (self.loadCompletionHandler) {
        self.delegate = self.loadCompletionHandler(self,nil);
    }
    BUMaterialMeta *data = nativeAd.data;
    // main image of the ad
    if (data.imageAry && data.imageAry.count && data.imageAry[0].imageURL != nil){
        self.images = @[[self p_getImage:data.imageAry[0].imageURL disableLoading:NO]];
    }
    
    // icon image of the ad
    if (data.icon && data.icon.imageURL != nil){
        self.icon = [self p_getImage:self.nativeAd.data.icon.imageURL disableLoading:NO];
    }
}

- (void)nativeAd:(BUNativeAd *)nativeAd didFailWithError:(NSError *_Nullable)error {
    if (self.loadCompletionHandler) {
        self.loadCompletionHandler(nil, error);
    }
}

- (void)nativeAdDidBecomeVisible:(BUNativeAd *)nativeAd {
    [self.delegate reportImpression];
}

- (void)nativeAdDidCloseOtherController:(BUNativeAd *)nativeAd interactionType:(BUInteractionType)interactionType {
    
}

- (void)nativeAdDidClick:(BUNativeAd *)nativeAd withView:(UIView *_Nullable)view {
    [self.delegate reportClick];
}

- (void)nativeAd:(BUNativeAd *_Nullable)nativeAd dislikeWithReason:(NSArray<BUDislikeWords *> *_Nullable)filterWords {
    
}

- (void)nativeAd:(BUNativeAd *_Nullable)nativeAd adContainerViewDidRemoved:(UIView *)adContainerView {
    
}



//MARK:--other
- (GADNativeAdImage *)p_getImage:(NSString *)urlString disableLoading:(Boolean)disableImageLoading {
    GADNativeAdImage *image;
    if (disableImageLoading) {
        // here will only return a image url, the publisher need to load the image from the url
        image = [[GADNativeAdImage alloc] initWithURL:[NSURL URLWithString:urlString] scale:[UIScreen mainScreen].scale];
    } else {
        image = [[GADNativeAdImage alloc] initWithImage:[self p_loadImage:self.nativeAd.data.imageAry[0].imageURL]];
    }
    return image;
}

- (UIImage *)p_loadImage:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *image = [UIImage imageWithData: data];
    return image;
}

@end
