/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <UIKit/UIKit.h>

@protocol YMARating;

NS_ASSUME_NONNULL_BEGIN

/**
 This protocol provides methods for rendering YandexMobileAds ad in custom native view classes.
 */
@protocol GADMYandexNativeAdView <NSObject>

@optional

/**
 `UILabel` for information about age restrictions. Required if ad's extra asset value for key kGADMYandexNativeAgeExtraAsset
 is not nil. @see GADMYandexNativeExtraAssets.h for asset keys.
 */
- (nullable UILabel *)nativeAgeLabel;

/**
 `UILabel` for the warning. Required if ad's extra asset value for key kGADMYandexNativeWarningExtraAsset
 is not nil. @see GADMYandexNativeExtraAssets.h for asset keys.
 */
- (nullable UILabel *)nativeWarningLabel;

/**
 `UIView` that implements the YMARating protocol for data on the app rating.
 */
- (nullable UIView<YMARating> *)nativeRatingView;

/**
 `UILabel` for data on the number of app reviews.
 */
- (nullable UILabel *)nativeReviewCountLabel;

/**
 Notifies that the user has chosen a reason for closing the ad and the ad must be hidden.
 The developer must determine what to do with the ad after the reason for closing it is chosen.
 */
- (void)closeAdView;

@end

NS_ASSUME_NONNULL_END
