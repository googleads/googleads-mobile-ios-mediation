#import <XCTest/XCTest.h>

#import <GoogleMobileAds/GoogleMobileAds.h>

#import "AUTKMediationAdEventDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/// Waits and asserts for a rewarded interstitial ad load without any error.
AUTKMediationRewardedAdEventDelegate *AUTKWaitAndAssertLoadRewardedInterstitialAd(
    id<GADMediationAdapter> adapter, GADMediationRewardedAdConfiguration *configuration);

/// Waits and asserts for a rewarded interstitial ad load failure with the expected error.
void AUTKWaitAndAssertLoadRewardedInterstitialAdFailure(id<GADMediationAdapter> adapter,
                                            GADMediationRewardedAdConfiguration *configuration,
                                            NSError *expectedError);

NS_ASSUME_NONNULL_END
