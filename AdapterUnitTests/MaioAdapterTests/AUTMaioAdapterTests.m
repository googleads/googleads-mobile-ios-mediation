#import "GADMediationAdapterMaio.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <Maio/Maio-Swift.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

@interface AUTMaioAdapterTests : XCTestCase

@end

@implementation AUTMaioAdapterTests

- (void)testAdapterVersion {
  GADVersionNumber version = [GADMediationAdapterMaio adapterVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 9999);
}

- (void)testAdSDKVersion {
  GADVersionNumber version = [GADMediationAdapterMaio adSDKVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 99);
}

- (void)testSetUp {
  AUTKMediationServerConfiguration *config = [[AUTKMediationServerConfiguration alloc] init];
  AUTKWaitAndAssertAdapterSetUpWithConfiguration([GADMediationAdapterMaio class], config);
}

- (void)testNetworkExtras {
  XCTAssertNil([GADMediationAdapterMaio networkExtrasClass]);
}

- (void)testCollectSignals {
  XCTestExpectation *expectation = [[XCTestExpectation alloc]
      initWithDescription:@"Expect empty signal as Maio dropped bidding support."];
  GADMediationAdapterMaio *adapter = [[GADMediationAdapterMaio alloc] init];
  AUTKRTBRequestParameters *params = [[AUTKRTBRequestParameters alloc] init];

  [adapter
      collectSignalsForRequestParameters:params
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(error);
                         XCTAssertEqualObjects(signals, @"");
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];
}

@end
