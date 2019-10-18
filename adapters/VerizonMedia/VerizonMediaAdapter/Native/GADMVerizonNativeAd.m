//
//  GADMerizonNativeAd.m
//
// @copyright Copyright (c) 2019 Verizon. All rights reserved.
//

#import "GADMVerizonNativeAd.h"
#import <VerizonAdsCore/VerizonAdsCore.h>
#import <VerizonAdsVerizonNativeController/VASNativeTextComponent.h>
#import <VerizonAdsVerizonNativeController/VASNativeImageComponent.h>

@interface GADMVerizonNativeAd() <GADMediatedNativeAdDelegate>

@property (nonatomic, readonly) VASNativeAd *nativeAd;

@end

@implementation GADMVerizonNativeAd

@synthesize price, store;

- (instancetype)initWithNativeAd:(VASNativeAd *)nativeAd {
    self = [super init];
    if (self) {
        _nativeAd = nativeAd;
    }
    return self;
}

- (NSString *)stringForComponent:(NSString *)componentId {
    id<VASComponent> component = [self.nativeAd component:componentId];
    if ([component conformsToProtocol:@protocol(VASNativeTextComponent)]) {
        return ((id<VASNativeTextComponent>)component).text;
    }
    return nil;
}

- (GADNativeAdImage *)imageForComponent:(NSString *)componentId {
    GADNativeAdImage *GADImage;
    id<VASComponent> component = [self.nativeAd.rootBundle component:componentId];
    if ([component conformsToProtocol:@protocol(VASNativeImageComponent)]) {
        UIImageView *imageView = (UIImageView *)((id<VASNativeImageComponent>)component).view;
        if ([imageView isKindOfClass:[UIImageView class]]) {
            UIImage *image = imageView.image;
            if (image) {
                GADImage = [[GADNativeAdImage alloc] initWithImage:image];
            }
        }
    }
    
    return GADImage;
}

- (nullable NSString *)headline {
    return [self stringForComponent:@"title"];
}

- (nullable NSString *)body {
    return [self stringForComponent:@"body"];
}

- (nullable NSString *)callToAction {
    return [self stringForComponent:@"callToAction"];
}

- (nullable NSString *)advertiser {
    return [self stringForComponent:@"disclaimer"];
}

- (nullable UIView *)mediaView {
    id<VASViewComponent> videoComponent = (id<VASViewComponent>)[self.nativeAd component:@"video"];
    if ([videoComponent conformsToProtocol:@protocol(VASViewComponent)]) {
        return videoComponent.view;
    }
    return nil;
}

- (BOOL)hasVideoContent {
    return self.mediaView != nil;
}

- (nullable NSArray<GADNativeAdImage *> *)images {
    GADNativeAdImage *mainImage = [self imageForComponent:@"mainImage"];
    return mainImage ? @[mainImage] :  nil;
}

- (GADNativeAdImage *)icon {
    return [self imageForComponent:@"iconImage"];
}

- (NSDecimalNumber *)starRating {
    NSString *ratingString = [self stringForComponent:@"rating"];
    if (ratingString.length > 0) {
        NSInteger stars = 0;
        NSInteger total = 0;
        NSScanner *scanner = [NSScanner scannerWithString:ratingString];
        
        NSMutableCharacterSet *set = [[NSMutableCharacterSet alloc] init];
        [set formUnionWithCharacterSet:[NSCharacterSet letterCharacterSet]];
        [set formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [scanner setCharactersToBeSkipped:set];
        
        if ([scanner scanInteger:&stars] && [scanner scanInteger:&total]) {
            return [NSDecimalNumber decimalNumberWithString: [NSString stringWithFormat:@"%ld.%ld", (long)stars, (long)total]];
        }
    }
    
    return nil;
}

- (nullable NSDictionary *)extraAssets {
    return nil;
}

- (void)didRecordImpression {
    [self.nativeAd fireImpression];
}

- (nullable id<GADMediatedNativeAdDelegate>)mediatedNativeAdDelegate {
    return self;
}

- (void)didRecordClickOnAssetWithName:(GADUnifiedNativeAssetIdentifier)assetName
                                 view:(UIView *)view
                       viewController:(UIViewController *)viewController {
    [self.nativeAd invokeDefaultAction];
}

- (void)didUntrackView:(nullable UIView *)view {
    [self.nativeAd destroy];
}

@end
