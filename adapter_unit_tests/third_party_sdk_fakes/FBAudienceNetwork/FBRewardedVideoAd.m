#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBRewardedVideoAd.h"
#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBTestProperties.h"

NS_ASSUME_NONNULL_BEGIN


@implementation FBRewardedVideoAd

- ( instancetype)initWithPlacementID:( NSString *)placementID {
  if (!FBTestProperties.sharedInstance.shouldRewardedVideoAdInitializationSucceed) {
    return nil;
  }
  self = [super init];
  return self;
}

- (void)loadAd {
  NSAssert(NO, @"Meta Audience Network only supports bidding ads. -loadAdWithBidPayload must be "
               @"used instead.");
}

- (void)loadAdWithBidPayload:( NSString *)bidPayload {
  id<FBRewardedVideoAdDelegate> delegate = _delegate;
  if (FBTestProperties.sharedInstance.shouldAdLoadSucceed) {
    if ([delegate respondsToSelector:@selector(rewardedVideoAdDidLoad:)]) {
      [delegate rewardedVideoAdDidLoad:self];
    }
  } else {
    if ([delegate respondsToSelector:@selector(rewardedVideoAd:didFailWithError:)]) {
      [delegate rewardedVideoAd:self didFailWithError:FBFakeError()];
    }
  }
}

- (BOOL)showAdFromRootViewController:( UIViewController *)rootViewController {
  if (rootViewController) {
    [rootViewController presentViewController:[[UIViewController alloc] init]
                                     animated:NO
                                   completion:nil];
    return YES;
  }
  return NO;
}

- (void)adClick {
  id<FBRewardedVideoAdDelegate> delegate = _delegate;
  if ([delegate respondsToSelector:@selector(rewardedVideoAdDidClick:)]) {
    [delegate rewardedVideoAdDidClick:self];
  }
}

- (void)logImpression {
  id<FBRewardedVideoAdDelegate> delegate = _delegate;
  if ([delegate respondsToSelector:@selector(rewardedVideoAdWillLogImpression:)]) {
    [delegate rewardedVideoAdWillLogImpression:self];
  }
}

- (void)closeAd {
  id<FBRewardedVideoAdDelegate> delegate = _delegate;
  if ([delegate respondsToSelector:@selector(rewardedVideoAdWillClose:)]) {
    [delegate rewardedVideoAdWillClose:self];
  }
  if ([delegate respondsToSelector:@selector(rewardedVideoAdDidClose:)]) {
    [delegate rewardedVideoAdDidClose:self];
  }
}

- (void)completeRewardedVideo {
  id<FBRewardedVideoAdDelegate> delegate = _delegate;
  if ([delegate respondsToSelector:@selector(rewardedVideoAdVideoComplete:)]) {
    [delegate rewardedVideoAdVideoComplete:self];
  }
}

@end

NS_ASSUME_NONNULL_END
