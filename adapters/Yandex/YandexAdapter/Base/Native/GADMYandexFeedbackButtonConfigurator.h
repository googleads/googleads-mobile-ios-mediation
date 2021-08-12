/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <UIKit/UIKit.h>

@class GADMYandexResourceBundleProvider;

NS_ASSUME_NONNULL_BEGIN

@interface GADMYandexFeedbackButtonConfigurator : NSObject

- (instancetype)initWithBundleProvider:(GADMYandexResourceBundleProvider *)bundleProvider;

- (void)configureFeedbackButton:(UIButton *)feedbackButton;

@end

NS_ASSUME_NONNULL_END
