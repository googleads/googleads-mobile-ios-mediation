// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADPangleRTBNativeRenderer.h"
#import "GADMediationAdapterPangleConstants.h"
#import <BUAdSDK/BUAdSDK.h>
#import "GADMAdapterPangleUtils.h"
#include <stdatomic.h>
#import "GADPangleNetworkExtras.h"

static NSString *const BUDNativeAdTranslateKey = @"bu_nativeAd";

@interface GADPangleRTBNativeRenderer()<BUNativeAdDelegate> {
    /// The completion handler to call when the ad loading succeeds or fails.
    GADMediationNativeLoadCompletionHandler _loadCompletionHandler;
    /// The Pangle native ad.
    BUNativeAd *_nativeAd;
    /// The Pangle related view
    BUNativeAdRelatedView *_relatedView;
    /// An ad event delegate to invoke when ad rendering events occur.
    id<GADMediationNativeAdEventDelegate> _delegate;
}

@end

@implementation GADPangleRTBNativeRenderer
@synthesize images = _images,icon = _icon;

- (void)renderNativeAdForAdConfiguration:(nonnull GADMediationNativeAdConfiguration *)adConfiguration
                       completionHandler:(nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block  GADMediationNativeLoadCompletionHandler originalCompletionHandler = [completionHandler copy];
    _loadCompletionHandler = ^id<GADMediationNativeAdEventDelegate> (_Nullable id<GADMediationNativeAd> ad, NSError *_Nullable error) {
        if (atomic_flag_test_and_set(&completionHandlerCalled)) {
            return nil;
        }
        id<GADMediationNativeAdEventDelegate> delegate = nil;
        if (originalCompletionHandler) {
            delegate = originalCompletionHandler(ad, error);
        }
        originalCompletionHandler = nil;
        return delegate;
    };
    
    NSString *placementId = adConfiguration.credentials.settings[GADMAdapterPanglePlacementID] ?: @"";
    if (!placementId.length) {
        NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorInvalidServerParameters,
                                                                      [NSString stringWithFormat:@"%@ cannot be nil.",GADMAdapterPanglePlacementID]
                                                                      );
        _loadCompletionHandler(nil, error);
        return;
    }
    
    GADPangleNetworkExtras *extras = [adConfiguration.extras isKindOfClass:[GADPangleNetworkExtras class]] ? adConfiguration.extras : nil;
    
    BUAdSlot *slot = [[BUAdSlot alloc] init];
    slot.ID = placementId;
    slot.AdType = BUAdSlotAdTypeFeed;
    if (extras && extras.userDataString.length) {
        slot.userData = extras.userDataString;
    }
    _nativeAd = [[BUNativeAd alloc]initWithSlot:slot];
    if (!_nativeAd) {
        NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorInitAd,
                                                                      @"Init ad error, Please check the reason or you could contact Pangle"
                                                                      );
        _loadCompletionHandler(nil, error);
        return;
    }
    _nativeAd.delegate = self;
    [_nativeAd setAdMarkup:adConfiguration.bidResponse];
}

- (BUNativeAdRelatedView *)getRelatedView {
    if (!_relatedView) {
        _relatedView = [[BUNativeAdRelatedView alloc] init];
    }
    return _relatedView;
}

#pragma mark GADMediationNativeAd

- (UIView *)mediaView {
    return [self getRelatedView].videoAdView;
}

- (UIView *)adChoicesView {
    return [self getRelatedView].logoADImageView;
}

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
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%ld",(long)_nativeAd.data.score]];
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

- (GADNativeAdImage *)imageWithUrlString:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *image = [UIImage imageWithData: data];
    return [[GADNativeAdImage alloc] initWithImage:image];
}

#pragma mark BUNativeAdDelegate

- (void)nativeAdDidLoad:(BUNativeAd *)nativeAd view:(UIView *_Nullable)view {
    BUMaterialMeta *materialMeta = nativeAd.data;
    // Set main image of the ad.
    if (materialMeta.imageAry && materialMeta.imageAry.count && materialMeta.imageAry[0].imageURL != nil){
        _images = @[[self imageWithUrlString:materialMeta.imageAry[0].imageURL]];
    }
    
    // Set icon image of the ad.
    if (materialMeta.icon && materialMeta.icon.imageURL != nil){
        _icon = [self imageWithUrlString:_nativeAd.data.icon.imageURL];
    }
    
    [_relatedView refreshData:nativeAd];
    
    if (_loadCompletionHandler) {
        _delegate = _loadCompletionHandler(self,nil);
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

- (void)nativeAd:(BUNativeAd *_Nullable)nativeAd adContainerViewDidRemoved:(UIView *)adContainerView {
    
}

- (void)didRenderInView:(nonnull UIView *)view
       clickableAssetViews:
           (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
         viewController:(nonnull UIViewController *)viewController {
    [_nativeAd registerContainer:view withClickableViews:clickableAssetViews.allValues];
}

@end
