//
//  GADMAdapterNendUtils.m
//  NendAdapter
//
//  Copyright © 2018 F@N Communications. All rights reserved.
//

#import "GADMAdapterNendUtils.h"

@import NendAd;
@import GoogleMobileAds;

@implementation GADMAdapterNendUtils

+ (NADUserFeature *)getUserFeatureFromMediationRequest:(id<GADMediationAdRequest>)request {
  if (!request) {
    return nil;
  }
  NADUserFeature *feature = [NADUserFeature new];
  if (request.userGender == kGADGenderMale) {
    feature.gender = NADGenderMale;
  } else if (request.userGender == kGADGenderFemale) {
    feature.gender = NADGenderFemale;
  }
  if (request.userBirthday) {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:request.userBirthday];
    [feature setBirthdayWithYear:components.year month:components.month day:components.day];
  }
  return feature;
}

@end
