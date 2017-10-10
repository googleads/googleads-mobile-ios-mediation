//
//  GADMAdapterMyTargetUtils.h
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 28.09.17.
//  Copyright © 2017 Mail.Ru Group. All rights reserved.
//

@import GoogleMobileAds;
@import MyTargetSDK;

NS_ASSUME_NONNULL_BEGIN

@interface GADMAdapterMyTargetUtils : NSObject

+ (NSError *)errorWithDescription:(NSString *)description;
+ (NSString *)noAdWithReason:(NSString *)reason;
+ (NSUInteger)slotIdFromCredentials:(NSDictionary *)credentials;
+ (void)fillCustomParams:(MTRGCustomParams *)customParams withConnector:(nullable id<GADMediationAdRequest>)connector;
+ (MTRGGender)genderFromAdmobGender:(GADGender)admobGender;
+ (nullable NSNumber *)ageFromBirthday:(NSDate *)birthday;
+ (BOOL)isSize:(GADAdSize)size1 equalToSize:(GADAdSize)size2;

@end

@interface GADMAdapterMyTargetLogger : NSObject

+ (BOOL)isEnabled;
+ (void)setEnabled:(BOOL)isEnabled;

@end

extern void gadm_amt_log_i(NSString *, ...);
extern void gadm_amt_log_d(NSString *, ...);
extern void gadm_amt_log_e(NSString *, ...);

NS_ASSUME_NONNULL_END
