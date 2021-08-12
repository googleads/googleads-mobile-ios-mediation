/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GADMYandexMediationLoadingData : NSObject

@property (nonatomic, copy, readonly) NSString *blockID;
@property (nonatomic, strong, readonly, nullable) CLLocation *location;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithBlockID:(NSString *)blockID
                       location:(nullable CLLocation *)location;

@end

NS_ASSUME_NONNULL_END
