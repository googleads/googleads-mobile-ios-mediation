#import <XCTest/XCTest.h>

#import <GoogleMobileAds/GoogleMobileAds.h>

#import "AUTKMediationAdEventDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/// Waits and asserts for an interstitial ad load without any error.
AUTKMediationInterstitialAdEventDelegate *AUTKWaitAndAssertLoadInterstitialAd(
    id<GADMediationAdapter> adapter, GADMediationInterstitialAdConfiguration *configuration);

/// Waits and asserts for an interstitial ad load failure with the expected error.
void AUTKWaitAndAssertLoadInterstitialAdFailure(
    id<GADMediationAdapter> adapter, GADMediationInterstitialAdConfiguration *configuration,
    NSError *expectedError);

NS_ASSUME_NONNULL_END
