//
//  GADInMobiExtras.h
//
//  Copyright (c) 2015 InMobi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GADExtras.h>
#import <GoogleMobileAds/GADRequest.h>
#import <InMobiSDK/IMSdk.h>

@interface GADInMobiExtras : NSObject <GADAdNetworkExtras>

#pragma mark Optional Parameters for targeted advertising during an Ad Request

/**
 * Age of the user may be used to deliver more relevant ads.
 */
@property(nonatomic, assign) NSUInteger age;
/**
 * Age group of the user to deliver more relevant ads.
 */
@property(nonatomic, assign) IMSDKAgeGroup ageGroup;
/**
 * Postal code of the user may be used to deliver more relevant ads.
 */
@property(nonatomic, copy, nullable) NSString *postalCode;
/**
 * Area code of the user may be used to deliver more relevant ads.
 */
@property(nonatomic, copy, nullable) NSString *areaCode;
/**
 * Education of the user may be used to deliver more relevant ads.
 */
@property(nonatomic, assign) IMSDKEducation educationType;
/**
Set InMobi SDK logLevel.
 */
@property(nonatomic, assign) IMSDKLogLevel logLevel;
/**
 * Year of birth of the user may be used to deliver more relevant ads.
 */
@property(nonatomic, assign) NSInteger yearOfBirth;
/**
 * Language preference of the user may be used to deliver more relevant ads.
 */
@property(nonatomic, copy, nullable) NSString *language;

#pragma mark Setting Contextual Information
/**
 * Use contextually relevant strings to deliver more relevant ads.
 * Example: @"offers sale shopping"
 */
@property(nonatomic, copy, nullable) NSString *keywords;
/**
 * Use contextually relevant strings to deliver more relevant ads.
 * Example: @"cars bikes racing"
 */
@property(nonatomic, copy, nullable) NSString *interests;
/**
 * Provide additional values to be passed in the ad request as key-value pair.
 */
@property(nonatomic, retain, nullable) NSDictionary<NSString *, id> *additionalParameters;

#pragma mark Setting User Location
/**
 * Provide user's city in the format "city-state-country" for
 * city-level targetting.
 */
- (void)setLocationWithCity:(nullable NSString *)_city
                      state:(nullable NSString *)_state
                    country:(nullable NSString *)_country;

/**
 * Provide the user's location to the SDK for targetting purposes
 */
- (void)setLocation:(nonnull CLLocation *)location;

#pragma mark Setting User IDs
/**
 * User ids such as facebook, twitter, etc may be provided to deliver more
 * relevant ids.
 */
@property(nonatomic, copy, nullable) NSString *loginId;
/**
 * Useful for maintaining different sessions with same login id.
 */
@property(nonatomic, copy, nullable) NSString *sessionId;

@property(nonatomic, copy, nullable, readonly) NSString *city;
@property(nonatomic, copy, nullable, readonly) NSString *state;
@property(nonatomic, copy, nullable, readonly) NSString *country;
@property(nonatomic, strong, nonnull, readonly) CLLocation *location;

@end
