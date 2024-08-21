#import <XCTest/XCTest.h>

#import <GoogleMobileAds/GoogleMobileAds.h>

#import "AUTKMediationAdEventDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/// Waits and asserts for an app open ad load without any error.
AUTKMediationAppOpenAdEventDelegate *AUTKWaitAndAssertLoadAppOpenAd(
    id<GADMediationAdapter> adapter, GADMediationAppOpenAdConfiguration *configuration);

/// Waits and asserts for an app open ad load failure with the expected error.
void AUTKWaitAndAssertLoadAppOpenAdFailure(id<GADMediationAdapter> adapter,
                                           GADMediationAppOpenAdConfiguration *configuration,
                                           NSError *expectedError);

NS_ASSUME_NONNULL_END
