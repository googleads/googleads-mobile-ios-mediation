#import "GADMediationAdapterVungle.h"
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleRouter.h"
#import "VungleAdNetworkExtras.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <VungleAdsSDK/VungleAdsSDK.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

static NSString *const kAppID1 = @"AppId1";
static NSString *const kAppID2 = @"AppId2";

@interface AUTLiftoffMonetizeAdapterTests : XCTestCase

@end

@implementation AUTLiftoffMonetizeAdapterTests

- (void)testAdapterVersion {
  GADVersionNumber version = [GADMediationAdapterVungle adapterVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 9999);
}

- (void)testAdSDKVersion {
  GADVersionNumber version = [GADMediationAdapterVungle adSDKVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 99);
}

- (void)testSetupInitiatesLiftoffSdk {
  id vungleRouterMock = OCMClassMock([GADMAdapterVungleRouter class]);
  OCMStub([vungleRouterMock sharedInstance]).andReturn(vungleRouterMock);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVungleApplicationID : kAppID1};

  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterVungle class], credentials);
  OCMVerify([vungleRouterMock initWithAppId:kAppID1 delegate:nil]);
}

- (void)testSetupInitiatesLiftoffSdkWithAnyOneAppIdWhenThereAreMultipleAppIds {
  id vungleRouterMock = OCMClassMock([GADMAdapterVungleRouter class]);
  OCMStub([vungleRouterMock sharedInstance]).andReturn(vungleRouterMock);
  AUTKMediationCredentials *credentials1 = [[AUTKMediationCredentials alloc] init];
  credentials1.settings = @{GADMAdapterVungleApplicationID : kAppID1};
  AUTKMediationCredentials *credentials2 = [[AUTKMediationCredentials alloc] init];
  credentials2.settings = @{GADMAdapterVungleApplicationID : kAppID2};

  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray([GADMediationAdapterVungle class],
                                                    @[ credentials1, credentials2 ]);
  OCMVerify([vungleRouterMock initWithAppId:[OCMArg checkWithBlock:^(id value) {
                                return ([@[ kAppID1, kAppID2 ] containsObject:value]);
                              }]
                                   delegate:nil]);
}

- (void)testSetupFailsWithNoAppId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{};
  NSError *expectedError = [NSError errorWithDomain:GADMAdapterVungleErrorDomain
                                               code:GADMAdapterVungleErrorInvalidServerParameters
                                           userInfo:nil];

  AUTKWaitAndAssertAdapterSetUpFailureWithCredentials([GADMediationAdapterVungle class],
                                                      credentials, expectedError);
}

- (void)testCollectSignals {
  GADRTBRequestParameters *parameters = [[GADRTBRequestParameters alloc] init];
  NSString *expectedSignalsToken = @"signals_token";
  OCMStub([OCMClassMock([VungleAds class]) getBiddingToken]).andReturn(expectedSignalsToken);

  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Token returned."];
  GADMediationAdapterVungle *adapter = [[GADMediationAdapterVungle alloc] init];
  [adapter
      collectSignalsForRequestParameters:parameters
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertEqualObjects(signals, expectedSignalsToken);
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];
}

- (void)testNetworkExtrasClass {
  XCTAssertEqual([GADMediationAdapterVungle networkExtrasClass], [VungleAdNetworkExtras class]);
}

@end
