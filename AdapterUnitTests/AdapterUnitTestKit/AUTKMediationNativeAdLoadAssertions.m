#import "AUTKMediationNativeAdLoadAssertions.h"
#import "AUTKConstants.h"

AUTKMediationNativeAdEventDelegate *AUTKWaitAndAssertLoadNativeAd(
    id<GADMediationAdapter> adapter, GADMediationNativeAdConfiguration *configuration) {
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Load a native ad."];

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [[AUTKMediationNativeAdEventDelegate alloc] init];
  GADMediationNativeLoadCompletionHandler completionHandler =
      ^(id<GADMediationNativeAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNotNil(ad);
        XCTAssertNil(error);
        if (!error) {
          eventDelegate.nativeAd = ad;
        }
        [expectation fulfill];
        return eventDelegate;
      };

  [adapter loadNativeAdForAdConfiguration:configuration completionHandler:completionHandler];
  XCTWaiterResult result = [XCTWaiter waitForExpectations:@[ expectation ]
                                                  timeout:AUTKExpectationTimeout];
  XCTAssertEqual(result, XCTWaiterResultCompleted);
  return eventDelegate;
}

void AUTKWaitAndAssertLoadNativeAdFailure(id<GADMediationAdapter> adapter,
                                          GADMediationNativeAdConfiguration *configuration,
                                          NSError *expectedError) {
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Fail to load a native ad."];

  GADMediationNativeLoadCompletionHandler completionHandler =
      ^(id<GADMediationNativeAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, expectedError.domain);
        XCTAssertEqual(error.code, expectedError.code);

        [expectation fulfill];
        return [[AUTKMediationNativeAdEventDelegate alloc] init];
      };
  [adapter loadNativeAdForAdConfiguration:configuration completionHandler:completionHandler];
  XCTWaiterResult result = [XCTWaiter waitForExpectations:@[ expectation ]
                                                  timeout:AUTKExpectationTimeout];
  XCTAssertEqual(result, XCTWaiterResultCompleted);
}
