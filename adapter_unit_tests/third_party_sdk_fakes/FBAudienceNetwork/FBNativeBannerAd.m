#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBNativeBannerAd.h"
#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBTestProperties.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBNativeBannerAd {
  UIView *_registeredView;
  UIImageView *_registeredIconImageView;
  UIViewController *_registeredViewController;
  NSArray<UIView *> *_registeredClickableViews;
}

+ (nullable instancetype)nativeAdWithPlacementId:(nonnull NSString *)placementId
                                      bidPayload:(nonnull NSString *)bidPayload
                                           error:(NSError *__autoreleasing *)error {
  return [[FBNativeBannerAd alloc] initWithPlacementID:placementId];
}

- (instancetype)initWithPlacementID:(nonnull NSString *)placementID {
  self = [super init];
  return self;
}

- (void)registerViewForInteraction:(nonnull UIView *)view
                     iconImageView:(nonnull UIImageView *)iconImageView
                    viewController:(nullable UIViewController *)viewController
                    clickableViews:(nullable NSArray<UIView *> *)clickableViews {
  [super setRegistered:YES];
  _registeredView = view;
  _registeredIconImageView = iconImageView;
  _registeredViewController = viewController;
  _registeredClickableViews = clickableViews;
}

- (void)unregisterView {
  [super setRegistered:NO];
  _registeredView = nil;
  _registeredIconImageView = nil;
  _registeredViewController = nil;
  _registeredClickableViews = nil;
}

- (void)loadAdWithBidPayload:(nonnull NSString *)bidPayload {
  if (FBTestProperties.sharedInstance.shouldAdLoadSucceed) {
    if ([_delegate respondsToSelector:@selector(nativeBannerAdDidLoad:)]) {
      [_delegate nativeBannerAdDidLoad:self];
    }
  } else {
    if ([_delegate respondsToSelector:@selector(nativeBannerAd:didFailWithError:)]) {
      [_delegate nativeBannerAd:self didFailWithError:FBFakeError()];
    }
  }
}

- (void)adClick {
  if ([_delegate respondsToSelector:@selector(nativeBannerAdDidClick:)]) {
    [_delegate nativeBannerAdDidClick:self];
  }
}

- (void)logImpression {
  if ([_delegate respondsToSelector:@selector(nativeBannerAdWillLogImpression:)]) {
    [_delegate nativeBannerAdWillLogImpression:self];
  }
}

@end

NS_ASSUME_NONNULL_END
