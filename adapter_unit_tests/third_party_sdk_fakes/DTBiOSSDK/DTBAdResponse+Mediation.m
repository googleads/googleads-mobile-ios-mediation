#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/DTBiOSSDK/DTBAdResponse+Mediation.h"
#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/DTBiOSSDK/DTBTestProperties.h"

@implementation DTBAdResponse

- (nonnull NSString*)bidInfo {
  return DTBTestProperties.sharedInstance.bidInfo;
}

- (nonnull NSString*)amznSlots {
  return DTBTestProperties.sharedInstance.amznSlots;
}

@end
