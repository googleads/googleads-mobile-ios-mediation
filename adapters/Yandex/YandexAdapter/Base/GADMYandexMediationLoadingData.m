/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import "GADMYandexMediationLoadingData.h"

@implementation GADMYandexMediationLoadingData

- (instancetype)initWithBlockID:(NSString *)blockID
                       location:(nullable CLLocation *)location
{
    self = [super init];
    if (self != nil) {
        _blockID = [blockID copy];
        _location = location;
    }
    return self;
}

@end
