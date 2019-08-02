//
//  GADInMobiExtras.h
//
//  Copyright (c) 2015 InMobi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GADExtras.h>
#import <GoogleMobileAds/GADRequest.h>
#import <InMobiSDK/IMSdk.h>

@interface GADInMobiExtras : NSObject<GADAdNetworkExtras>

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
@property(nonatomic, copy) NSString *postalCode;
/**
 * Area code of the user may be used to deliver more relevant ads.
 */
@property(nonatomic, copy) NSString *areaCode;
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
@property(nonatomic, copy) NSString *language;

#pragma mark Setting Contextual Information
/**
 * Use contextually relevant strings to deliver more relevant ads.
 * Example: @"offers sale shopping"
 */
@property(nonatomic, copy) NSString *keywords;
/**
 * Use contextually relevant strings to deliver more relevant ads.
 * Example: @"cars bikes racing"
 */
@property(nonatomic, copy) NSString *interests;
/**
 * Provide additional values to be passed in the ad request as key-value pair.
 */
@property(nonatomic, retain) NSDictionary *additionalParameters;

#pragma mark Setting User Location
/**
 * Provide user's city in the format "city-state-country" for
 * city-level targetting.
 */
- (void)setLocationWithCity:(NSString *)_city state:(NSString *)_state country:(NSString *)_country;

/**
 * Provide the user's location to the SDK for targetting purposes
 */
- (void)setLocation:(CLLocation *)location;

#pragma mark Setting User IDs
/**
 * User ids such as facebook, twitter, etc may be provided to deliver more
 * relevant ids.
 */
@property(nonatomic, copy) NSString *loginId;
/**
 * Useful for maintaining different sessions with same login id.
 */
@property(nonatomic, copy) NSString *sessionId;

@property(nonatomic, copy, readonly) NSString *city;
@property(nonatomic, copy, readonly) NSString *state;
@property(nonatomic, copy, readonly) NSString *country;
@property(nonatomic, strong, readonly) CLLocation *location;

@end
