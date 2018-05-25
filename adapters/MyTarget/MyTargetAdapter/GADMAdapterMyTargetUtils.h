//
//  GADMAdapterMyTargetUtils.h
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 28.09.17.
//  Copyright © 2017 Mail.Ru Group. All rights reserved.
//

@import GoogleMobileAds;
@import MyTargetSDK;

#define MTRGLogInfo()                                                                    \
  if ([GADMAdapterMyTargetUtils isLogEnabled]) {                                         \
    NSLog(@"[%@ info] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd)); \
  }
#define MTRGLogDebug(format, ...)                               \
  if ([GADMAdapterMyTargetUtils isLogEnabled]) {                \
    NSLog(@"[%@ debug] %@", NSStringFromClass([self class]),    \
          [NSString stringWithFormat:(format), ##__VA_ARGS__]); \
  }
#define MTRGLogError(message)                                            \
  if ([GADMAdapterMyTargetUtils isLogEnabled]) {                         \
    NSLog(@"[%@ error] %@", NSStringFromClass([self class]), (message)); \
  }

NS_ASSUME_NONNULL_BEGIN

@interface GADMAdapterMyTargetUtils : NSObject

+ (BOOL)isLogEnabled;
+ (void)setLogEnabled:(BOOL)isLogEnabled;
+ (NSError *)errorWithDescription:(NSString *)description;
+ (NSString *)noAdWithReason:(NSString *)reason;
+ (NSUInteger)slotIdFromCredentials:(NSDictionary *)credentials;
+ (void)fillCustomParams:(MTRGCustomParams *)customParams
           withConnector:(nullable id<GADMediationAdRequest>)connector;
+ (MTRGGender)genderFromAdmobGender:(GADGender)admobGender;
+ (nullable NSNumber *)ageFromBirthday:(NSDate *)birthday;
+ (BOOL)isSize:(GADAdSize)size1 equalToSize:(GADAdSize)size2;
+ (nullable GADNativeAdImage *)nativeAdImageWithImageData:(nullable MTRGImageData *)imageData;

@end

NS_ASSUME_NONNULL_END
