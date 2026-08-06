#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBNativeAd.h"
#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBTestProperties.h"

@implementation FBNativeAd {
  UIView *_registeredView;
  FBMediaView *_registeredMediaView;
  UIImageView *_registeredIconImageView;
  UIViewController *_registeredViewController;
  NSArray<UIView *> *_registeredClickableViews;
}

+ (nullable instancetype)nativeAdWithPlacementId:(nonnull NSString *)placementId
                                      bidPayload:(nonnull NSString *)bidPayload
                                           error:(NSError *__autoreleasing *)error {
  return [[FBNativeAd alloc] initWithPlacementID:placementId];
}

- (nonnull instancetype)initWithPlacementID:(NSString *)placementID {
  self = [super init];
  return self;
}

- (void)registerViewForInteraction:(nonnull UIView *)view
                         mediaView:(nonnull FBMediaView *)mediaView
                     iconImageView:(nullable UIImageView *)iconImageView
                    viewController:(nullable UIViewController *)viewController
                    clickableViews:(nullable NSArray<UIView *> *)clickableViews {
  [super setRegistered:YES];
  _registeredView = view;
  _registeredMediaView = mediaView;
  _registeredIconImageView = iconImageView;
  _registeredViewController = viewController;
  _registeredClickableViews = clickableViews;
}

- (void)unregisterView {
  [super setRegistered:NO];
  _registeredView = nil;
  _registeredMediaView = nil;
  _registeredIconImageView = nil;
  _registeredViewController = nil;
  _registeredClickableViews = nil;
}

- (BOOL)isRegistered {
  return _registeredView || _registeredMediaView || _registeredIconImageView ||
         _registeredViewController || _registeredClickableViews;
}

- (void)loadAdWithBidPayload:(NSString *)bidPayload {
  if (FBTestProperties.sharedInstance.shouldAdLoadSucceed) {
    if ([_delegate respondsToSelector:@selector(nativeAdDidLoad:)]) {
      [_delegate nativeAdDidLoad:self];
    }
  } else {
    if ([_delegate respondsToSelector:@selector(nativeAd:didFailWithError:)]) {
      [_delegate nativeAd:self didFailWithError:FBFakeError()];
    }
  }
}

- (void)adClick {
  if ([_delegate respondsToSelector:@selector(nativeAdDidClick:)]) {
    [_delegate nativeAdDidClick:self];
  }
}

- (void)logImpression {
  if ([_delegate respondsToSelector:@selector(nativeAdWillLogImpression:)]) {
    [_delegate nativeAdWillLogImpression:self];
  }
}

@end
