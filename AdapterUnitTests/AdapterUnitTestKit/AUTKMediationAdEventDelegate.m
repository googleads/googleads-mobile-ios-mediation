#import "AUTKMediationAdEventDelegate.h"

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-implementations"

@implementation AUTKMediationAdEventDelegate

- (void)reportImpression {
  _reportImpressionInvokeCount += 1;
}

- (void)reportClick {
  _reportClickInvokeCount += 1;
}

- (void)willPresentFullScreenView {
  _willPresentFullScreenViewInvokeCount += 1;
}

- (void)didFailToPresentWithError:(nonnull NSError *)error {
  _didFailToPresentError = error;
}

- (void)willDismissFullScreenView {
  _willDismissFullScreenViewInvokeCount += 1;
}

- (void)didDismissFullScreenView {
  _didDismissFullScreenViewInvokeCount += 1;
}

@end

@implementation AUTKMediationAppOpenAdEventDelegate
@end

@implementation AUTKMediationBannerAdEventDelegate

- (void)willBackgroundApplication {
  // Not implemented as this protocol method was deprecated.
}

@end

@implementation AUTKMediationInterstitialAdEventDelegate

- (void)willBackgroundApplication {
  // Not implemented as this protocol method was deprecated.
}

@end

@implementation AUTKMediationNativeAdEventDelegate

- (void)didPlayVideo {
  _didPlayVideoInvokeCount += 1;
}

- (void)didPauseVideo {
  _didPauseVideoInvokeCount += 1;
}

- (void)didEndVideo {
  _didEndVideoInvokeCount += 1;
}

- (void)didMuteVideo {
  _didMuteVideoInvokeCount += 1;
}

- (void)didUnmuteVideo {
  _didUnmuteVideoInvokeCount += 1;
}

- (void)willBackgroundApplication {
  // Not implemented as this protocol method was deprecated.
}

@end

@implementation AUTKMediationRewardedAdEventDelegate

- (void)didRewardUser {
  _didRewardUserInvokeCount += 1;
}

- (void)didStartVideo {
  _didStartVideoInvokeCount += 1;
}

- (void)didEndVideo {
  _didEndVideoInvokeCount += 1;
}

- (void)didRewardUserWithReward:(nonnull GADAdReward *)reward {
  // Not implemented as this protocol method was deprecated.
}

@end

#pragma GCC diagnostic pop
