/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <Foundation/Foundation.h>

@class UIButton;

@interface GADMYandexCallToActionBinder : NSObject

- (void)bindWithView:(UIView *)view;
- (void)unbind;

@end
