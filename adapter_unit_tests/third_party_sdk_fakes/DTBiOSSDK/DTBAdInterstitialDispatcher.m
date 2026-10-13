#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/DTBiOSSDK/DTBAdInterstitialDispatcher+Testing.h"

#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/DTBiOSSDK/DTBTestProperties.h"

@implementation DTBAdInterstitialDispatcher (Testing)

- (void)impressionFired {
  [self.delegate impressionFired];
}

- (void)adClicked {
  [self.delegate adClicked];
}

@end

@implementation DTBAdInterstitialDispatcher

- (instancetype)initWithDelegate:(id<DTBAdInterstitialDispatcherDelegate>)delegate {
  self = [super init];
  if (self) {
    _delegate = delegate;
  }
  return self;
}

- (void)fetchAd:(NSString *)bidInfo {
  if (DTBTestProperties.sharedInstance.shouldInterstitialAdLoadSucceed) {
    [_delegate interstitialDidLoad:self];
  } else {
    [_delegate interstitial:self didFailToLoadAdWithErrorCode:SampleErrorCodeUnknown];
  }
}

- (void)showFromController:(nonnull UIViewController *)controller {
  [self interstitialWillAppear];
}

- (void)interstitialWillAppear {
  [_delegate interstitialWillPresentScreen:self];
  [self interstitialDidAppear];
}

- (void)interstitialDidAppear {
  [_delegate interstitialDidPresentScreen:self];
}

- (void)interstitialWillDisappear {
  [_delegate interstitialWillDismissScreen:self];
}

- (void)interstitialDidDisappear {
  [_delegate interstitialDidDismissScreen:self];
}

- (void)impressionFired {
  [_delegate impressionFired];
}

- (void)adClicked {
  [_delegate adClicked];
}

@end
