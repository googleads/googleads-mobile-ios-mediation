/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import "GADMYandexFeedbackButtonConfigurator.h"
#import "GADMYandexResourceBundleProvider.h"

static NSString *const kGADMYandexFeedbackButtonTitle = @"⋮";
static NSString *const kGADMYandexFeedbackButtonFontName = @"AppleSDGothicNeo-Bold";
static CGFloat const kGADMYandexFeedbackButtonFontSize = 30.f;
static CGFloat const kGADMYandexFeedbackButtonSize = 30.f;
static NSString *const kGADMYandexFeedbackImage = @"gadm_yandex_feedback_view";

@interface GADMYandexFeedbackButtonConfigurator ()

@property (nonatomic, strong, readonly) GADMYandexResourceBundleProvider *bundleProvider;

@end

@implementation GADMYandexFeedbackButtonConfigurator

- (instancetype)init
{
    return [self initWithBundleProvider:[[GADMYandexResourceBundleProvider alloc] init]];
}

- (instancetype)initWithBundleProvider:(GADMYandexResourceBundleProvider *)bundleProvider
{
    self = [super init];
    if (self != nil) {
        _bundleProvider = bundleProvider;
    }
    return self;
}

- (void)configureFeedbackButton:(UIButton *)feedbackButton
{
    NSBundle *bundle = [self.bundleProvider resourceBundle];
    UIImage *image = [UIImage imageNamed:kGADMYandexFeedbackImage inBundle:bundle compatibleWithTraitCollection:nil];
    if (image != nil) {
        [self configureImageFeedbackButton:feedbackButton image:image];
    }
    else {
        [self configureTextFeedbackButton:feedbackButton];
    }
    feedbackButton.frame = CGRectMake(0.f, 0.f, kGADMYandexFeedbackButtonSize, kGADMYandexFeedbackButtonSize);
}

#pragma mark - Private

- (void)configureImageFeedbackButton:(UIButton *)feedbackButton image:(UIImage *)image
{
    [feedbackButton setImage:image forState:UIControlStateNormal];
    [feedbackButton setTitle:nil forState:UIControlStateNormal];
}

- (void)configureTextFeedbackButton:(UIButton *)feedbackButton
{
    [feedbackButton setImage:nil forState:UIControlStateNormal];
    [feedbackButton setTitle:kGADMYandexFeedbackButtonTitle forState:UIControlStateNormal];
    [feedbackButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    feedbackButton.titleLabel.font = [UIFont fontWithName:kGADMYandexFeedbackButtonFontName
                                                     size:kGADMYandexFeedbackButtonFontSize];
}

@end
