#import "AUTKMediationBannerAdLoadAssertions.h"
#import "AUTKConstants.h"

AUTKMediationBannerAdEventDelegate *AUTKWaitAndAssertLoadBannerAd(
    id<GADMediationAdapter> adapter, GADMediationBannerAdConfiguration *configuration) {
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Load a banner ad."];

  AUTKMediationBannerAdEventDelegate *eventDelegate =
      [[AUTKMediationBannerAdEventDelegate alloc] init];
  GADMediationBannerLoadCompletionHandler completionHandler =
      ^(id<GADMediationBannerAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNotNil(ad);
        XCTAssertNil(error);
        if (!error) {
          eventDelegate.bannerAd = ad;
        }
        [expectation fulfill];
        return eventDelegate;
      };

  [adapter loadBannerForAdConfiguration:configuration completionHandler:completionHandler];
  XCTWaiterResult result = [XCTWaiter waitForExpectations:@[ expectation ]
                                                  timeout:AUTKExpectationTimeout];
  XCTAssertEqual(result, XCTWaiterResultCompleted);
  return eventDelegate;
}

void AUTKWaitAndAssertLoadBannerAdFailure(id<GADMediationAdapter> adapter,
                                          GADMediationBannerAdConfiguration *configuration,
                                          NSError *expectedError) {
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Fail to load a banner ad."];

  GADMediationBannerLoadCompletionHandler completionHandler =
      ^(id<GADMediationBannerAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, expectedError.domain);
        XCTAssertEqual(error.code, expectedError.code);

        [expectation fulfill];
        return [[AUTKMediationBannerAdEventDelegate alloc] init];
      };
  [adapter loadBannerForAdConfiguration:configuration completionHandler:completionHandler];
  XCTWaiterResult result = [XCTWaiter waitForExpectations:@[ expectation ]
                                                  timeout:AUTKExpectationTimeout];
  XCTAssertEqual(result, XCTWaiterResultCompleted);
}
