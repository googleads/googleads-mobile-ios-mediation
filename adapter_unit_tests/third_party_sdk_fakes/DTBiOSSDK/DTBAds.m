#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/DTBiOSSDK/DTBAds.h"

#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/DTBiOSSDK/DTBTestProperties.h"

@implementation DTBAds

+ (nonnull NSString *)version {
  return DTBTestProperties.sharedInstance.adSDKVersion;
}

+ (nonnull DTBAds *)sharedInstance {
  static dispatch_once_t onceToken;
  static DTBAds *sharedInstance;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[DTBAds alloc] init];
  });
  return sharedInstance;
}

- (nonnull instancetype)init {
  self = [super init];
  return self;
}

- (BOOL)isReady {
  return DTBTestProperties.sharedInstance.isAdsReady;
}

@end
