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

@interface GADMAdapterMyTargetUtils : NSObject

+ (BOOL)isLogEnabled;
+ (void)setLogEnabled:(BOOL)isLogEnabled;
+ (nonnull NSError *)errorWithDescription:(nonnull NSString *)description;
+ (nonnull NSString *)noAdWithReason:(nonnull NSString *)reason;
+ (NSUInteger)slotIdFromCredentials:(nullable NSDictionary *)credentials;
+ (void)fillCustomParams:(nonnull MTRGCustomParams *)customParams
           withConnector:(nonnull id<GADMediationAdRequest>)connector;
+ (MTRGGender)genderFromAdmobGender:(GADGender)admobGender;
+ (nonnull NSNumber *)ageFromBirthday:(nonnull NSDate *)birthday;
+ (BOOL)isSize:(GADAdSize)size1 equalToSize:(GADAdSize)size2;
+ (nonnull GADNativeAdImage *)nativeAdImageWithImageData:(nonnull MTRGImageData *)imageData;

@end
