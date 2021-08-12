/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import "GADMYandexResourceBundleProvider.h"

static NSString *const kGADMYandexMobileAdsBundle = @"YandexMobileAdsBundle";
static NSString *const kGADMYandexBundleExtension = @"bundle";

@interface GADMYandexResourceBundleProvider ()

@property (nonatomic, strong, readonly) NSBundle *mainBundle;

@end

@implementation GADMYandexResourceBundleProvider

- (instancetype)init
{
    return [self initWithMainBundle:[NSBundle mainBundle]];
}

- (instancetype)initWithMainBundle:(NSBundle *)mainBundle
{
    self = [super init];
    if (self != nil) {
        _mainBundle = mainBundle;
    }
    return self;
}

- (NSBundle *)resourceBundle
{
    NSBundle *resourceBundle = nil;
    NSURL *URL = [self.mainBundle URLForResource:kGADMYandexMobileAdsBundle withExtension:kGADMYandexBundleExtension];
    if (URL != nil) {
        resourceBundle = [self bundleWithURL:URL];
    }
    return resourceBundle;
}

#pragma mark - Private

- (NSBundle *)bundleWithURL:(NSURL *)URL
{
    NSBundle *bundle = nil;
    @try {
        bundle = [NSBundle bundleWithURL:URL];
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to load bundle: %@", exception);
    }
    return bundle;
}

@end
