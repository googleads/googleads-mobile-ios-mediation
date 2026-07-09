#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/DTBiOSSDK/DTBAdBannerDispatcher+Testing.h"

#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/DTBiOSSDK/DTBTestProperties.h"

@implementation DTBAdBannerDispatcher (Testing)

- (void)impressionFired {
  id<DTBAdBannerDispatcherDelegate> delegate = [self valueForKey:@"_delegate"];
  [delegate impressionFired];
}

- (void)adClicked {
  id<DTBAdBannerDispatcherDelegate> delegate = [self valueForKey:@"_delegate"];
  [delegate adClicked];
}
@end


@implementation DTBAdBannerDispatcher {
  id<DTBAdBannerDispatcherDelegate> _delegate;
  CGRect _frame;
}

- (instancetype)initWithAdFrame:(CGRect)frame delegate:(id<DTBAdBannerDispatcherDelegate>)delegate {
  self = [super init];
  if (self) {
    _delegate = delegate;
    _frame = frame;
  }
  return self;
}

- (void)fetchBannerAd:(nonnull NSString*)htmlString {
  if (DTBTestProperties.sharedInstance.shouldBannerAdLoadSucceed) {
    [_delegate adDidLoad:[[UIView alloc] initWithFrame:_frame]];
  } else {
    [_delegate adFailedToLoad:[[UIView alloc] initWithFrame:_frame] errorCode:1];
  }
}

@end
