#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBAdInitResults.h"
#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBTestProperties.h"

@implementation FBAdInitResults

- (instancetype)init {
  self = [super init];
  if (self) {
    _success = [FBTestProperties.sharedInstance shouldFBAdInitializationSucceed];
    _message = [FBTestProperties.sharedInstance FBAdInitializationResultMessage];
  }
  return self;
}

@end
