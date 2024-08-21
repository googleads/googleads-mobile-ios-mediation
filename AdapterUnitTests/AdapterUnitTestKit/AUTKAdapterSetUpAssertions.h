#import <XCTest/XCTest.h>

#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

/// Waits for adapter set up and asserts that the adapter was set up without any error.
void AUTKWaitAndAssertAdapterSetUpWithConfiguration(Class<GADMediationAdapter> adapterClass,
                                                    GADMediationServerConfiguration *configuration);

/// Waits for adapter set up and asserts that the adapter was set up without any error.
void AUTKWaitAndAssertAdapterSetUpWithCredentials(Class<GADMediationAdapter> adapterClass,
                                                  GADMediationCredentials *credentials);

/// Waits for adapter set up and asserts that the adapter was set up without any error.
void AUTKWaitAndAssertAdapterSetUpWithCredentialsArray(
    Class<GADMediationAdapter> adapterClass, NSArray<GADMediationCredentials *> *credentialsArray);

/// Waits for adapter set up and asserts that the adapter was fail to set up with the expected
/// error.
void AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
    Class<GADMediationAdapter> adapterClass, GADMediationServerConfiguration *configuration,
    NSError *expectedError);

/// Waits for adapter set up and asserts that the adapter was fail to set up with the expected
/// error.
void AUTKWaitAndAssertAdapterSetUpFailureWithCredentials(Class<GADMediationAdapter> adapterClass,
                                                         GADMediationCredentials *credentials,
                                                         NSError *expectedError);

/// Waits for adapter set up and asserts that the adapter was fail to set up with the expected
/// error.
void AUTKWaitAndAssertAdapterSetUpFailureWithCredentialsArray(
    Class<GADMediationAdapter> adapterClass, NSArray<GADMediationCredentials *> *credentialsArray,
    NSError *expectedError);

/// Asserts that two versions are equal.
void AUTKAssertEqualVersion(GADVersionNumber version1, GADVersionNumber version2);

NS_ASSUME_NONNULL_END
