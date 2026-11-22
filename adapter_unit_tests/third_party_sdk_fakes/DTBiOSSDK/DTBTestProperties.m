#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/DTBiOSSDK/DTBTestProperties.h"

#include <stdatomic.h>

@implementation DTBTestProperties

+ (nonnull DTBTestProperties *)sharedInstance {
  static dispatch_once_t onceToken;
  static DTBTestProperties *sharedInstance;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[DTBTestProperties alloc] init];
  });
  return sharedInstance;
}

- (nonnull instancetype)init {
  self = [super init];
  if (self) {
    [self resetToDefault];
  }
  return self;
}

- (void)resetToDefault {
  _shouldBannerAdLoadSucceed = YES;
  _shouldInterstitialAdLoadSucceed = YES;
  _isAdsReady = YES;
  _adSDKVersion = @"aps-ios-4.5.4";
  _bidInfo = @"bidInfo";
  _amznSlots = @"amznSlots";
}

@end
