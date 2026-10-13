#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBAdView.h"
#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBTestProperties.h"

@implementation FBAdView

- (nullable instancetype)initWithPlacementID:(nonnull NSString *)placementID
                                  bidPayload:(nonnull NSString *)bidPayload
                          rootViewController:(id)rootViewController
                                       error:(NSError *__autoreleasing _Nullable *_Nullable)error {
  self = [super initWithFrame:CGRectZero];
  return self;
}

- (void)loadAdWithBidPayload:(nonnull NSString *)bidPayload {
  if (FBTestProperties.sharedInstance.shouldAdLoadSucceed) {
    if ([_delegate respondsToSelector:@selector(adViewDidClick:)]) {
      [_delegate adViewDidLoad:self];
    }
  } else {
    if ([_delegate respondsToSelector:@selector(adView:didFailWithError:)]) {
      [_delegate adView:self didFailWithError:FBFakeError()];
    }
  }
}

- (void)adClick {
  if ([_delegate respondsToSelector:@selector(adViewDidClick:)]) {
    [_delegate adViewDidClick:self];
  }
}

- (void)logImpression {
  if ([_delegate respondsToSelector:@selector(adViewWillLogImpression:)]) {
    [_delegate adViewWillLogImpression:self];
  }
}

- (void)presentModalView {
  if ([_delegate respondsToSelector:@selector(viewControllerForPresentingModalView)]) {
    UIViewController *presenterViewController = [_delegate viewControllerForPresentingModalView];
    [presenterViewController presentViewController:[[UIViewController alloc] init]
                                          animated:NO
                                        completion:nil];
  }
}

@end
