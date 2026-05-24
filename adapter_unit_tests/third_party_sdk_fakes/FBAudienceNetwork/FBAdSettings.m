#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBAdSettings.h"

#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBTestProperties.h"

@implementation FBAdSettings

static NSString *FBService;
static BOOL FBMixedAudience;

+ (nullable NSString *)bidderToken {
  return FBTestProperties.sharedInstance.bidderToken;
}

+ (nullable NSString *)mediationService {
  return FBService;
}

+ (void)setMediationService:(nonnull NSString *)service {
  FBService = service;
}

+ (BOOL)isMixedAudience {
  return FBMixedAudience;
}

+ (void)setMixedAudience:(BOOL)mixedAudience {
  FBMixedAudience = mixedAudience;
}

+ (void)resetSettings {
  FBService = nil;
  FBMixedAudience = NO;
}

@end
