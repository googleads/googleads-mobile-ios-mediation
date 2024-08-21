#import "AUTKAdapterSetUpAssertions.h"
#import "AUTKAdConfiguration.h"
#import "AUTKConstants.h"

void AUTKWaitAndAssertAdapterSetUpWithConfiguration(
    Class<GADMediationAdapter> adapterClass, GADMediationServerConfiguration *configuration) {
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Set up mediation adapter."];
  [adapterClass setUpWithConfiguration:configuration
                     completionHandler:^(NSError *_Nullable error) {
                       XCTAssertNil(error);
                       [expectation fulfill];
                     }];
  XCTWaiterResult result = [XCTWaiter waitForExpectations:@[ expectation ]
                                                  timeout:AUTKExpectationTimeout];
  XCTAssertEqual(result, XCTWaiterResultCompleted);
}

void AUTKWaitAndAssertAdapterSetUpWithCredentials(Class<GADMediationAdapter> adapterClass,
                                                  GADMediationCredentials *credentials) {
  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray(adapterClass, @[ credentials ]);
}

void AUTKWaitAndAssertAdapterSetUpWithCredentialsArray(
    Class<GADMediationAdapter> adapterClass, NSArray<GADMediationCredentials *> *credentialsArray) {
  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = credentialsArray;
  AUTKWaitAndAssertAdapterSetUpWithConfiguration(adapterClass, configuration);
}

void AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
    Class<GADMediationAdapter> adapterClass, GADMediationServerConfiguration *configuration,
    NSError *expectedError) {
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Fail to set up adapter."];
  [adapterClass setUpWithConfiguration:configuration
                     completionHandler:^(NSError *_Nullable error) {
                       XCTAssertNotNil(error);
                       if (expectedError) {
                         XCTAssertEqualObjects(error.domain, expectedError.domain);
                         XCTAssertEqual(error.code, expectedError.code);
                       }
                       [expectation fulfill];
                     }];
  XCTWaiterResult result = [XCTWaiter waitForExpectations:@[ expectation ]
                                                  timeout:AUTKExpectationTimeout];
  XCTAssertEqual(result, XCTWaiterResultCompleted);
}

void AUTKWaitAndAssertAdapterSetUpFailureWithCredentials(Class<GADMediationAdapter> adapterClass,
                                                         GADMediationCredentials *credentials,
                                                         NSError *expectedError) {
  AUTKWaitAndAssertAdapterSetUpFailureWithCredentialsArray(adapterClass, @[ credentials ],
                                                           expectedError);
}

void AUTKWaitAndAssertAdapterSetUpFailureWithCredentialsArray(
    Class<GADMediationAdapter> adapterClass, NSArray<GADMediationCredentials *> *credentialsArray,
    NSError *expectedError) {
  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = credentialsArray;
  AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(adapterClass, configuration, expectedError);
}

void AUTKAssertEqualVersion(GADVersionNumber version1, GADVersionNumber version2) {
  XCTAssertEqual(version1.majorVersion, version2.majorVersion);
  XCTAssertEqual(version1.minorVersion, version2.minorVersion);
  XCTAssertEqual(version1.patchVersion, version2.patchVersion);
}
