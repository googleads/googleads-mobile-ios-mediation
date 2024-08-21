#import <XCTest/XCTest.h>

#import <GoogleMobileAds/GoogleMobileAds.h>

#import "AUTKMediationAdEventDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/// Waits and asserts for a rewarded ad load without any error.
AUTKMediationRewardedAdEventDelegate *AUTKWaitAndAssertLoadRewardedAd(
    id<GADMediationAdapter> adapter, GADMediationRewardedAdConfiguration *configuration);

/// Waits and asserts for a rewarded ad load failure with the expected error.
void AUTKWaitAndAssertLoadRewardedAdFailure(id<GADMediationAdapter> adapter,
                                            GADMediationRewardedAdConfiguration *configuration,
                                            NSError *expectedError);

NS_ASSUME_NONNULL_END
