//
//  GADInMobiExtras.m
//
//  Copyright (c) 2015 InMobi. All rights reserved.
//

#import "GADInMobiExtras.h"

@interface GADInMobiExtras ()
@property (nonatomic, retain) NSString *city, *state, *country;
@property (nonatomic, retain) CLLocation *location;

@end

@implementation GADInMobiExtras

@synthesize additionalParameters;
@synthesize postalCode, areaCode, ageGroup, householdIncome;
@synthesize keywords,interests, nationality;
@synthesize income, age, yearOfBirth;
@synthesize loginId, sessionId;
@synthesize city, state, country, location;
@synthesize educationType, ethnicityType;
@synthesize language;

- (void)setLocationWithCity:(NSString *)_city
                      state:(NSString *)_state
                    country:(NSString *)_country {
    self.city = _city;
    self.state = _state;
    self.country = _country;
}

- (void)setLocation:(CLLocation*)_location {
    [IMSdk setLocation:_location];
}
- (void)setEducationType:(IMSDKEducation)newEducationType {
    [IMSdk setEducation:newEducationType];
}

- (void)setEthnicityType:(IMSDKEthnicity)newEthnicityType {
    [IMSdk setEthnicity:newEthnicityType];
}
- (void)setAgeGroup:(IMSDKAgeGroup)newAgeGroup {
    [IMSdk setAgeGroup:newAgeGroup];
}
- (void)setHouseholdIncome:(IMSDKHouseholdIncome)newHouseholdIncome {
    [IMSdk setHouseholdIncome:newHouseholdIncome];
}

- (void)setLogLevel:(IMSDKLogLevel)logLevel{
    [IMSdk setLogLevel:logLevel];
}

//- (void)dealloc {
//    self.additionalParameters = nil;
//    self.postalCode = nil;
//    self.areaCode = nil;
//    self.keywords = nil;
//    self.interests = nil;
//    self.loginId = nil;
//    self.sessionId = nil;
//    self.city = nil;
//    self.state = nil;
//    self.country = nil;
//    self.language = nil;
//    [super dealloc];
//}

@end
