#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBAudienceNetworkAds.h"
#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBAdInitResults.h"
#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBTestProperties.h"

@implementation FBAudienceNetworkAds

+ (void)initializeWithSettings:(nullable FBAdInitSettings *)settings
             completionHandler:(nullable void (^)(FBAdInitResults *results))completionHandler {
  completionHandler([[FBAdInitResults alloc] init]);
}

@end
