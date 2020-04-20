//
//  GADInMobiExtras.m
//
//  Copyright (c) 2015 InMobi. All rights reserved.
//

#import "GADInMobiExtras.h"

@implementation GADInMobiExtras

@synthesize additionalParameters;
@synthesize postalCode, areaCode, ageGroup;
@synthesize keywords, interests;
@synthesize age, yearOfBirth;
@synthesize loginId, sessionId;
@synthesize educationType;
@synthesize language;

- (void)setLocationWithCity:(nullable NSString *)city
                      state:(nullable NSString *)state
                    country:(nullable NSString *)country {
  _city = city;
  _state = state;
  _country = country;
}

- (void)setLocation:(nonnull CLLocation *)location {
  _location = location;
  [IMSdk setLocation:location];
}

- (void)setEducationType:(IMSDKEducation)newEducationType {
  [IMSdk setEducation:newEducationType];
}

- (void)setAgeGroup:(IMSDKAgeGroup)newAgeGroup {
  [IMSdk setAgeGroup:newAgeGroup];
}

- (void)setLogLevel:(IMSDKLogLevel)logLevel {
  [IMSdk setLogLevel:logLevel];
}

@end
