#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBNativeAdBase.h"
#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBNativeAd.h"
#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBNativeBannerAd.h"
#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBTestProperties.h"

@implementation FBNativeAdBase {
  BOOL _registered;
}

+ (nullable instancetype)nativeAdWithPlacementId:(nonnull NSString *)placementId
                                      bidPayload:(nonnull NSString *)bidPayload
                                           error:(NSError *__autoreleasing _Nullable *_Nullable)
                                                     error {
  if (FBTestProperties.sharedInstance.shouldFBNativeAdBaseInstantiateNativeAd) {
    return [FBNativeAd nativeAdWithPlacementId:placementId bidPayload:bidPayload error:error];
  } else {
    return [FBNativeBannerAd nativeAdWithPlacementId:placementId bidPayload:bidPayload error:error];
  }
}

- (void)loadAdWithBidPayload:(nonnull NSString *)bidPayload {
  // Do nothing.
}

- (void)unregisterView {
  _registered = NO;
}

- (BOOL)isRegistered {
  return _registered;
}

- (nullable NSString *)headline {
  return FBTestProperties.sharedInstance.nativeAdHeadline;
}

- (nullable NSString *)advertiserName {
  return FBTestProperties.sharedInstance.nativeAdAdvertiserName;
}

- (nullable NSString *)socialContext {
  return FBTestProperties.sharedInstance.nativeAdSocialContext;
}

- (nullable NSString *)callToAction {
  return FBTestProperties.sharedInstance.nativeAdCallToAction;
}

- (nullable NSString *)bodyText {
  return FBTestProperties.sharedInstance.nativeAdBodyText;
}

- (nullable UIImage *)iconImage {
  return FBTestProperties.sharedInstance.nativeAdIconImage;
}

@end
