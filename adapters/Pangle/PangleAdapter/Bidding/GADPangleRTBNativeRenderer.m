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
#import <PAGAdSDK/PAGAdSDK.h>
#include <stdatomic.h>
#import "GADMAdapterPangleUtils.h"
#import "GADMediationAdapterPangleConstants.h"

@interface GADPangleRTBNativeRenderer () <PAGLNativeAdDelegate> {
  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationNativeLoadCompletionHandler _loadCompletionHandler;
  /// The Pangle native ad.
  PAGLNativeAd *_nativeAd;
  /// The Pangle related view.
  PAGLNativeAdRelatedView *_relatedView;
  /// An ad event delegate to invoke when ad rendering events occur.
  id<GADMediationNativeAdEventDelegate> _delegate;
}

@end

@implementation GADPangleRTBNativeRenderer
@synthesize icon = _icon;

- (void)renderNativeAdForAdConfiguration:
            (nonnull GADMediationNativeAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationNativeLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _loadCompletionHandler = ^id<GADMediationNativeAdEventDelegate>(
      _Nullable id<GADMediationNativeAd> ad, NSError *_Nullable error) {
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
    NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(
        GADPangleErrorInvalidServerParameters,
        [NSString stringWithFormat:@"%@ cannot be nil.", GADMAdapterPanglePlacementID]);
    _loadCompletionHandler(nil, error);
    return;
  }

  _relatedView = [[PAGLNativeAdRelatedView alloc] init];

  PAGNativeRequest *request = [PAGNativeRequest request];
  request.adString = adConfiguration.bidResponse;

  __weak typeof(self) weakSelf = self;
  [PAGLNativeAd loadAdWithSlotID:placementId
                         request:request
               completionHandler:^(PAGLNativeAd *_Nullable nativeAd, NSError *_Nullable error) {
                 __strong typeof(weakSelf) strongSelf = weakSelf;

                 if (error) {
                   if (strongSelf->_loadCompletionHandler) {
                     strongSelf->_loadCompletionHandler(nil, error);
                   }
                   return;
                 }

                 [strongSelf->_relatedView refreshWithNativeAd:nativeAd];

                 strongSelf->_nativeAd = nativeAd;
                 strongSelf->_nativeAd.delegate = strongSelf;
                 strongSelf->_nativeAd.rootViewController = adConfiguration.topViewController;

                 if (strongSelf->_loadCompletionHandler) {
                   id<GADMediationNativeAdEventDelegate> delegate =
                       strongSelf->_loadCompletionHandler(strongSelf, nil);
                   strongSelf->_delegate = delegate;
                 }
               }];
}

#pragma mark - GADMediationNativeAd

- (GADNativeAdImage *)icon {
  if (!_icon) {
    if (_nativeAd.data.icon && _nativeAd.data.icon.imageURL != nil) {
      _icon = [self imageWithUrlString:_nativeAd.data.icon.imageURL];
    }
  }
  return _icon;
}

- (UIView *)mediaView {
  return _relatedView.mediaView;
}

- (UIView *)adChoicesView {
  return _relatedView.logoADImageView;
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
  return nil;
}

- (NSArray<GADNativeAdImage *> *)images {
  return nil;
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

- (NSDictionary<NSString *, id> *)extraAssets {
  return nil;
}

- (void)didUntrackView:(UIView *)view {
  [_nativeAd unregisterView];
}

- (BOOL)hasVideoContent {
  return YES;
}

- (BOOL)handlesUserClicks {
  return YES;
}

- (BOOL)handlesUserImpressions {
  return YES;
}

- (GADNativeAdImage *)imageWithUrlString:(NSString *)urlString {
  NSURL *url = [NSURL URLWithString:urlString];
  NSData *data = [NSData dataWithContentsOfURL:url];
  UIImage *image = [UIImage imageWithData:data];
  return [[GADNativeAdImage alloc] initWithImage:image];
}

- (void)didRenderInView:(nonnull UIView *)view
       clickableAssetViews:
           (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(nonnull UIViewController *)viewController {
  [_nativeAd registerContainer:view withClickableViews:clickableAssetViews.allValues];
}

#pragma mark - PAGLNativeAdDelegate

- (void)adDidShow:(PAGLNativeAd *)ad {
  id<GADMediationNativeAdEventDelegate> delegate = _delegate;
  [delegate reportImpression];
}

- (void)adDidClick:(PAGLNativeAd *)ad {
  id<GADMediationNativeAdEventDelegate> delegate = _delegate;
  [delegate reportClick];
}

@end
