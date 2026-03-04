#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/DTBiOSSDK/DTBAdBannerDispatcher.h"

/// Category to add methods to be used for testing.
@interface DTBAdBannerDispatcher (Testing)
- (void)impressionFired;
- (void)adClicked;
@end
