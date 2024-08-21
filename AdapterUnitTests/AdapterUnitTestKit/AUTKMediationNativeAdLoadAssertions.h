#import <XCTest/XCTest.h>

#import <GoogleMobileAds/GoogleMobileAds.h>

#import "AUTKMediationAdEventDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/// Waits and asserts for a native ad load without any error.
AUTKMediationNativeAdEventDelegate *AUTKWaitAndAssertLoadNativeAd(
    id<GADMediationAdapter> adapter, GADMediationNativeAdConfiguration *configuration);

/// Waits and asserts for a native ad load failure with the expected error.
void AUTKWaitAndAssertLoadNativeAdFailure(id<GADMediationAdapter> adapter,
                                          GADMediationNativeAdConfiguration *configuration,
                                          NSError *expectedError);

NS_ASSUME_NONNULL_END
