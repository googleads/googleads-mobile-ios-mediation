#import "AUTKMediationInterstitialAdLoadAssertions.h"
#import "AUTKConstants.h"

AUTKMediationInterstitialAdEventDelegate *_Nullable AUTKWaitAndAssertLoadInterstitialAd(
    id<GADMediationAdapter> adapter, GADMediationInterstitialAdConfiguration *configuration) {
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Load an interstitial ad."];

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [[AUTKMediationInterstitialAdEventDelegate alloc] init];
  GADMediationInterstitialLoadCompletionHandler completionHandler =
      ^(id<GADMediationInterstitialAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNotNil(ad);
        XCTAssertNil(error);
        if (!error) {
          eventDelegate.interstitialAd = ad;
        }
        [expectation fulfill];
        return eventDelegate;
      };

  [adapter loadInterstitialForAdConfiguration:configuration completionHandler:completionHandler];
  XCTWaiterResult result = [XCTWaiter waitForExpectations:@[ expectation ]
                                                  timeout:AUTKExpectationTimeout];
  return result == XCTWaiterResultCompleted ? eventDelegate : nil;
}

void AUTKWaitAndAssertLoadInterstitialAdFailure(
    id<GADMediationAdapter> adapter, GADMediationInterstitialAdConfiguration *configuration,
    NSError *expectedError) {
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Fail to load an interstitial ad."];

  GADMediationInterstitialLoadCompletionHandler completionHandler =
      ^(id<GADMediationInterstitialAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNil(ad);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, expectedError.domain);
        XCTAssertEqual(error.code, expectedError.code);

        [expectation fulfill];
        return [[AUTKMediationInterstitialAdEventDelegate alloc] init];
      };
  [adapter loadInterstitialForAdConfiguration:configuration completionHandler:completionHandler];
  (void)[XCTWaiter waitForExpectations:@[ expectation ] timeout:AUTKExpectationTimeout];
}
