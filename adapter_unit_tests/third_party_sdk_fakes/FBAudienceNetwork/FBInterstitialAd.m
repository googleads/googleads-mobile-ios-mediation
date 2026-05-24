#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBInterstitialAd.h"
#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBTestProperties.h"

@implementation FBInterstitialAd

- (nonnull instancetype)initWithPlacementID:(nonnull NSString *)placementID {
  self = [super init];
  return self;
}

- (void)loadAdWithBidPayload:(nonnull NSString *)bidPayload {
  if (FBTestProperties.sharedInstance.shouldAdLoadSucceed) {
    if ([_delegate respondsToSelector:@selector(interstitialAdDidLoad:)]) {
      [_delegate interstitialAdDidLoad:self];
    }
  } else {
    if ([_delegate respondsToSelector:@selector(interstitialAd:didFailWithError:)]) {
      [_delegate interstitialAd:self didFailWithError:FBFakeError()];
    }
  }
}

- (BOOL)showAdFromRootViewController:(nullable UIViewController *)rootViewController {
  if (rootViewController) {
    [rootViewController presentViewController:[[UIViewController alloc] init]
                                     animated:NO
                                   completion:nil];
    return YES;
  }
  return NO;
}

- (void)adClick {
  if ([_delegate respondsToSelector:@selector(interstitialAdDidClick:)]) {
    [_delegate interstitialAdDidClick:self];
  }
}

- (void)logImpression {
  if ([_delegate respondsToSelector:@selector(interstitialAdWillLogImpression:)]) {
    [_delegate interstitialAdWillLogImpression:self];
  }
}

- (void)closeAd {
  if ([_delegate respondsToSelector:@selector(interstitialAdWillClose:)]) {
    [_delegate interstitialAdWillClose:self];
  }

  if ([_delegate respondsToSelector:@selector(interstitialAdDidClose:)]) {
    [_delegate interstitialAdDidClose:self];
  }
}

@end
