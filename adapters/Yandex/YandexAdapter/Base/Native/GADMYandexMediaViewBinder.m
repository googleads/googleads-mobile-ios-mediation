/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <YandexMobileAds/YandexMobileNativeAds.h>
#import <CoreGraphics/CoreGraphics.h>
#import "GADMYandexMediaViewBinder.h"

@interface GADMYandexMediaViewBinder ()

@property (nonatomic, weak) YMANativeMediaView *mediaView;

@end

@implementation GADMYandexMediaViewBinder

- (void)bindMediaView:(YMANativeMediaView *)mediaView aspectRatio:(CGFloat)aspectRatio
{
    self.mediaView = mediaView;
    if (aspectRatio > DBL_EPSILON) {
        mediaView.translatesAutoresizingMaskIntoConstraints = NO;
        UIView *superView = mediaView.superview;
        if (superView != nil) {
            NSArray *constraints = @[
                [mediaView.leadingAnchor constraintEqualToAnchor:superView.leadingAnchor],
                [mediaView.trailingAnchor constraintEqualToAnchor:superView.trailingAnchor],
                [mediaView.topAnchor constraintEqualToAnchor:superView.topAnchor],
                [mediaView.bottomAnchor constraintEqualToAnchor:superView.bottomAnchor],
                [mediaView.widthAnchor constraintEqualToAnchor:mediaView.heightAnchor multiplier:aspectRatio],
            ];
            [NSLayoutConstraint activateConstraints:constraints];
        }
    }
}

- (void)unbind
{
    [self.mediaView removeFromSuperview];
}

@end
