//
//  GADInMobiExtras.m
//
//  Copyright (c) 2015 InMobi. All rights reserved.
//

#import "GADInMobiExtras.h"

@interface GADInMobiExtras ()
@property(nonatomic, retain) NSString *city, *state, *country;
@property(nonatomic, retain) CLLocation *location;

@end

@implementation GADInMobiExtras

@synthesize additionalParameters;
@synthesize postalCode, areaCode, ageGroup;
@synthesize keywords, interests;
@synthesize age, yearOfBirth;
@synthesize loginId, sessionId;
@synthesize city, state, country, location;
@synthesize educationType;
@synthesize language;

- (void)setLocationWithCity:(NSString *)_city
                      state:(NSString *)_state
                    country:(NSString *)_country {
  self.city = _city;
  self.state = _state;
  self.country = _country;
}

- (void)setLocation:(CLLocation *)_location {
  [IMSdk setLocation:_location];
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
