//
//  GADVpadnNativeAd.m
//  VponAdapter
//
//  Created by EricChien on 2018/10/24.
//  Copyright © 2018 Vpon. All rights reserved.
//

#import "GADVpadnNativeAd.h"

@interface GADVpadnNativeAd () <VpadnMediaViewDelegate> {
    dispatch_queue_t _lockQueue;
    GADNativeAdImage *_mappedIcon;
}

@property (nonatomic, strong) VpadnNativeAd *nativeAd;
@property (nonatomic, strong) VpadnMediaView *mappedMediaView;
@property (nonatomic, copy) NSDictionary *extras;

@property (nonatomic, assign) id<GADVpadnNativeAdDelegate> delegate;

@end

@implementation GADVpadnNativeAd

- (instancetype)initWithNativeAd:(VpadnNativeAd *)nativeAd adOptions:(GADNativeAdViewAdOptions *)options delegate:(id<GADVpadnNativeAdDelegate>)delegate {
    if (!nativeAd) {
        return nil;
    }
    self = [super init];
    if (self) {
        _delegate = delegate;
        _nativeAd = nativeAd;
        
        _mappedMediaView = [[VpadnMediaView alloc] initWithNativeAd:_nativeAd];
        _mappedMediaView.delegate = self;
        
        if (_nativeAd.socialContext) {
            _extras = @{@"socialContext" : _nativeAd.socialContext};
        } else {
            _extras = @{};
        }
    }
    return self;
}

- (void) loadImages {
    if (!_nativeAd.icon) {
        [_delegate onGADVpadnNativeAdDidImageLoaded:self];
    } else {
        [self loadImageWithURL:_nativeAd.icon.url callback:^(UIImage *image) {
            if (image) {
                self->_mappedIcon = [[GADNativeAdImage alloc] initWithImage:image];
            }
            [self->_delegate onGADVpadnNativeAdDidImageLoaded:self];
        }];
    }
}

- (void) loadImageWithURL:(nonnull NSURL *)url callback:(void (^)(UIImage *))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSData *imageData = [NSData dataWithContentsOfURL:url];
        UIImage *image = [UIImage imageWithData:imageData];
        if (image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(image);
            });
        } else {
            callback(nil);
        }
    });
}

#pragma mark - GADMediatedUnifiedNativeAd

- (NSString *)headline {
    return self.nativeAd.title;
}

- (NSArray *)images {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(36, 36), NO, 0.0);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return @[[[GADNativeAdImage alloc] initWithImage:img]];
}

- (NSString *)body {
    return self.nativeAd.body;
}

- (GADNativeAdImage *)icon {
    return _mappedIcon;
}

- (NSString *)callToAction {
    return self.nativeAd.callToAction;
}

- (NSDecimalNumber *)starRating {
    return nil;
}

- (NSString *)advertiser {
    return nil;
}

- (NSString *)store {
    return nil;
}

- (NSString *)price {
    return nil;
}

- (NSDictionary *)extraAssets {
    return self.extras;
}

/// Media view.
- (UIView *GAD_NULLABLE_TYPE)mediaView {
    return _mappedMediaView;
}

- (UIView *GAD_NULLABLE_TYPE)adChoicesView {
    return nil;
}

- (BOOL)hasVideoContent {
    return YES;
}

#pragma mark - GADMediatedNativeAdDelegate

- (void) didRenderInView:(UIView *)view clickableAssetViews:(NSDictionary<GADNativeAssetIdentifier,UIView *> *)clickableAssetViews nonclickableAssetViews:(NSDictionary<GADNativeAssetIdentifier,UIView *> *)nonclickableAssetViews viewController:(UIViewController *)viewController {
    [_nativeAd registerViewForInteraction:view withViewController:viewController];
}

- (void)mediatedNativeAd:(id<GADMediationNativeAd>)mediatedNativeAd didUntrackView:(UIView *)view {
    [_nativeAd unregisterView];
}

- (void) didRecordClickOnAssetWithName:(GADNativeAssetIdentifier)assetName view:(UIView *)view viewController:(UIViewController *)viewController {
    [_nativeAd clickHandler:view];
}

@end
