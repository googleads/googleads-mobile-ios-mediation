#import <XCTest/XCTest.h>

#import <GoogleMobileAds/GoogleMobileAds.h>

#import "AUTKMediationAdEventDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/// Waits and asserts for a banner ad load without any error.
AUTKMediationBannerAdEventDelegate *AUTKWaitAndAssertLoadBannerAd(
    id<GADMediationAdapter> adapter, GADMediationBannerAdConfiguration *configuration);

/// Waits and asserts for a banner ad load failure with the expected error.
void AUTKWaitAndAssertLoadBannerAdFailure(id<GADMediationAdapter> adapter,
                                          GADMediationBannerAdConfiguration *configuration,
                                          NSError *expectedError);

NS_ASSUME_NONNULL_END
