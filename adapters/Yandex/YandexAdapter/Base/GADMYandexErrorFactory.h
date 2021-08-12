/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kGADMYandexMediationErrorDomain;

typedef NS_ENUM(NSInteger, kGADMYandexMediationErrorCode) {
    kGADMYandexMediationErrorCodeNilBlockID
};

@interface GADMYandexErrorFactory : NSObject

+ (NSError *)nilBlockIDError;

@end

NS_ASSUME_NONNULL_END


