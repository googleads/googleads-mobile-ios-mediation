/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

@class YMANativeMediaView;

NS_ASSUME_NONNULL_BEGIN

@interface GADMYandexMediaViewBinder : NSObject

- (void)bindMediaView:(YMANativeMediaView *)mediaView aspectRatio:(CGFloat)aspectRatio;

- (void)unbind;

@end

NS_ASSUME_NONNULL_END
