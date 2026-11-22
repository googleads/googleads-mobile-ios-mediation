#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBTestProperties.h"

NSError *_Nonnull FBFakeError() {
  NSString *fakeErrorDomain = @"com.fake.facebook.audience.network";
  NSInteger fakeErrorCode = 12345;
  return [[NSError alloc] initWithDomain:fakeErrorDomain code:fakeErrorCode userInfo:nil];
}

@implementation FBTestProperties

/**
 * A helper function that sets all the properties to their default values.
 */
static void FBResetInstanceState(FBTestProperties * properties) {
    if (!properties) return;

    properties->_bidderToken = @"bidderToken";
    properties->_shouldAdLoadSucceed = YES;
    properties->_shouldFBNativeAdBaseInstantiateNativeAd = YES;
    properties->_shouldRewardedVideoAdInitializationSucceed = YES;
    properties->_shouldFBAdInitializationSucceed = YES;
    properties->_FBAdInitializationResultMessage = @"FBAdInitializationResultMessage";
    properties->_nativeAdHeadline = @"nativeAdHeadline";
    properties->_nativeAdAdvertiserName = @"nativeAdAdvertiserName";
    properties->_nativeAdSocialContext = @"nativeAdSocialContext";
    properties->_nativeAdCallToAction = @"nativeAdCallToAction";
    properties->_nativeAdBodyText = @"nativeAdBodyText";
    properties->_nativeAdIconImage = [UIImage imageNamed:@"UIBarButtonSystemItemDone"];
}

+ (nonnull FBTestProperties *)sharedInstance {
  static dispatch_once_t onceToken;
  static FBTestProperties *sharedInstance;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[FBTestProperties alloc] init];
  });
  return sharedInstance;
}

- (nonnull instancetype)init {
  self = [super init];
  if (self) {
    FBResetInstanceState(self);
  }
  return self;
}

- (void)resetToDefault {
  FBResetInstanceState(self);
}

@end
