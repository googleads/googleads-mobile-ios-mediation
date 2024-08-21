#import "AUTKMediationAppOpenAdLoadAssertions.h"
#import "AUTKConstants.h"

AUTKMediationAppOpenAdEventDelegate *AUTKWaitAndAssertLoadAppOpenAd(
    id<GADMediationAdapter> adapter, GADMediationAppOpenAdConfiguration *configuration) {
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Load an app open ad."];

  AUTKMediationAppOpenAdEventDelegate *eventDelegate =
      [[AUTKMediationAppOpenAdEventDelegate alloc] init];
  GADMediationAppOpenLoadCompletionHandler completionHandler =
      ^(id<GADMediationAppOpenAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNotNil(ad);
        XCTAssertNil(error);
        if (!error) {
          eventDelegate.appOpenAd = ad;
        }
        [expectation fulfill];
        return eventDelegate;
      };

  [adapter loadAppOpenAdForAdConfiguration:configuration completionHandler:completionHandler];
  XCTWaiterResult result = [XCTWaiter waitForExpectations:@[ expectation ]
                                                  timeout:AUTKExpectationTimeout];
  XCTAssertEqual(result, XCTWaiterResultCompleted);
  return eventDelegate;
}

void AUTKWaitAndAssertLoadAppOpenAdFailure(id<GADMediationAdapter> adapter,
                                           GADMediationAppOpenAdConfiguration *configuration,
                                           NSError *expectedError) {
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Fail to load an app open ad."];

  GADMediationAppOpenLoadCompletionHandler completionHandler =
      ^(id<GADMediationAppOpenAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, expectedError.domain);
        XCTAssertEqual(error.code, expectedError.code);

        [expectation fulfill];
        return [[AUTKMediationAppOpenAdEventDelegate alloc] init];
      };
  [adapter loadAppOpenAdForAdConfiguration:configuration completionHandler:completionHandler];
  XCTWaiterResult result = [XCTWaiter waitForExpectations:@[ expectation ]
                                                  timeout:AUTKExpectationTimeout];
  XCTAssertEqual(result, XCTWaiterResultCompleted);
}
