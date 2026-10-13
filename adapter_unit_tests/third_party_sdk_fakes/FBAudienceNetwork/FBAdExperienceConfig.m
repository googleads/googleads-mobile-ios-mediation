#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBAdExperienceConfig.h"

FBAdExperienceType const FBAdExperienceTypeRewarded = @"FBAdExperienceTypeRewarded";
FBAdExperienceType const FBAdExperienceTypeInterstitial = @"FBAdExperienceTypeInterstitial";
FBAdExperienceType const FBAdExperienceTypeRewardedInterstitial =
    @"FBAdExperienceTypeRewardedInterstitial";

@implementation FBAdExperienceConfig

- (nonnull instancetype)initWithAdExperienceType:(nonnull FBAdExperienceType)adExperienceType {
  self = [super init];
  if (self) {
    _adExperienceType = adExperienceType;
  }
  return self;
}

#pragma mark - NSCopying

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
  return [[FBAdExperienceConfig alloc] initWithAdExperienceType:_adExperienceType];
}

@end
