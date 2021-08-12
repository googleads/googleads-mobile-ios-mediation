/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <UIKit/UIKit.h>
#import "GADMYandexCallToActionBinder.h"

@interface GADMYandexCallToActionBinder ()

@property (nonatomic, assign) BOOL userInteractionEnabledInitialValue;
@property (nonatomic, weak) UIView *callToAction;

@end

@implementation GADMYandexCallToActionBinder

- (void)bindWithView:(UIView *)view
{
    self.userInteractionEnabledInitialValue = view.isUserInteractionEnabled;
    self.callToAction = view;
    view.userInteractionEnabled = YES;
}

- (void)unbind
{
    self.callToAction.userInteractionEnabled = self.userInteractionEnabledInitialValue;
}

@end
