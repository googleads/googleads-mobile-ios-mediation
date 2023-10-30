// Copyright 2015 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GADExtras.h>
#import <GoogleMobileAds/GADRequest.h>
#import <InMobiSDK/InMobiSDK-Swift.h>

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
 * Set InMobi SDK logLevel.
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
@property(nonatomic, copy, nullable) NSDictionary<NSString *, id> *additionalParameters;

#pragma mark Setting User Location

/**
 * The city of user.
 */
@property(nonatomic, nullable, readonly) NSString *city;

/**
 * The state of user.
 */
@property(nonatomic, nullable, readonly) NSString *state;

/**
 * The country of user.
 */
@property(nonatomic, nullable, readonly) NSString *country;

/**
 * The location of user.
 */
@property(nonatomic, copy, nullable) CLLocation *location;

/**
 * Provide user's city in the format "city-state-country" for
 * city-level targeting.
 */
- (void)setLocationWithCity:(nullable NSString *)city
                      state:(nullable NSString *)state
                    country:(nullable NSString *)country;

@end
