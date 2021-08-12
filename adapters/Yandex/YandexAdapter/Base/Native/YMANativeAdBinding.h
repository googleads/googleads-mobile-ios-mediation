/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <YandexMobileAds/YandexMobileNativeAds.h>

NS_ASSUME_NONNULL_BEGIN

@protocol YMANativeAdBinding <YMANativeAd>

/**
 Sets values of all ad assets to native ad view, installs impression and click handlers.
 @param view Root ad view, superview for all asset views.
 @param assetViews Dictionary containing asset keys and views for corresponding assets.
 @param error Binding error. @see YMANativeAdErrors.h for error codes.
 @return YES if binding succeeded, otherwise NO.
 */
- (BOOL)bindAdToView:(UIView *)view assetViews:(NSDictionary<NSString *, UIView *> *)assetViews error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
