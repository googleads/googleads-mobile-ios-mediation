//
//  GADMAdapterMyTargetUtils.m
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 28.09.17.
//  Copyright © 2017 Mail.Ru Group. All rights reserved.
//

#import "GADMAdapterMyTargetUtils.h"
#import "GADMAdapterMyTargetConstants.h"

#define guard(CONDITION) \
  if (CONDITION) {       \
  }

@implementation GADMAdapterMyTargetUtils

static BOOL _isLogEnabled = YES;

+ (BOOL)isLogEnabled {
  return _isLogEnabled;
}

+ (void)setLogEnabled:(BOOL)isLogEnabled {
  _isLogEnabled = isLogEnabled;
}

+ (NSError *)errorWithDescription:(NSString *)description {
  NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description};
  NSError *error = [NSError errorWithDomain:kGADMAdapterMyTargetErrorDomain
                                       code:1000
                                   userInfo:userInfo];
  return error;
}

+ (NSString *)noAdWithReason:(NSString *)reason {
  NSMutableString *description = [kGADMAdapterMyTargetErrorNoAd mutableCopy];
  if (reason && ![reason isEqualToString:@""]) {
    [description appendFormat:@": %@", reason];
  }
  return description;
}

+ (NSUInteger)slotIdFromCredentials:(NSDictionary *)credentials {
  id slotIdValue = [credentials objectForKey:kGADMAdapterMyTargetSlotIdKey];
  guard(slotIdValue) else return 0;

  NSUInteger slotId = 0;
  if ([slotIdValue isKindOfClass:[NSString class]]) {
    NSNumberFormatter *formatString = [[NSNumberFormatter alloc] init];
    NSString *slotIdString = (NSString *)slotIdValue;
    NSNumber *slotIdNumber = [formatString numberFromString:slotIdString];
    slotId = slotIdNumber ? [slotIdNumber unsignedIntegerValue] : 0;
  } else if ([slotIdValue isKindOfClass:[NSNumber class]]) {
    NSNumber *slotIdNumber = (NSNumber *)slotIdValue;
    slotId = [slotIdNumber unsignedIntegerValue];
  }
  return slotId;
}

+ (void)fillCustomParams:(MTRGCustomParams *)customParams
           withConnector:(id<GADMediationAdRequest>)connector {
  id<GADMediationAdRequest> strongConnector = connector;
  guard(strongConnector && customParams) else return;
  customParams.gender = [GADMAdapterMyTargetUtils genderFromAdmobGender:strongConnector.userGender];
  customParams.age = [GADMAdapterMyTargetUtils ageFromBirthday:strongConnector.userBirthday];
}

+ (MTRGGender)genderFromAdmobGender:(GADGender)admobGender;
{
  MTRGGender gender = MTRGGenderUnknown;
  switch (admobGender) {
    case kGADGenderMale:
      gender = MTRGGenderMale;
      break;
    case kGADGenderFemale:
      gender = MTRGGenderFemale;
      break;
    default:
      gender = MTRGGenderUnspecified;
      break;
  }
  return gender;
}

+ (NSNumber *)ageFromBirthday:(NSDate *)birthday {
  guard(birthday) else return nil;
  NSCalendar *calendar =
      [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  NSDateComponents *components = [calendar components:NSCalendarUnitYear
                                             fromDate:birthday
                                               toDate:[NSDate date]
                                              options:0];
  return [NSNumber numberWithInteger:components.year];
}

+ (BOOL)isSize:(GADAdSize)size1 equalToSize:(GADAdSize)size2 {
  // for compatibility with iPhone X
  return ceilf(size1.size.width) == ceilf(size2.size.width) &&
         ceilf(size1.size.height) == ceilf(size2.size.height);
}

+ (GADNativeAdImage *)nativeAdImageWithImageData:(MTRGImageData *)imageData {
  guard(imageData) else return nil;

  GADNativeAdImage *nativeAdImage = nil;
  if (imageData.image) {
    nativeAdImage = [[GADNativeAdImage alloc] initWithImage:imageData.image];
  } else if (imageData.url) {
    NSURL *url = [NSURL URLWithString:imageData.url];
    nativeAdImage = [[GADNativeAdImage alloc] initWithURL:url scale:1.0];
  }
  return nativeAdImage;
}

@end
