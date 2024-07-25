#import "GADMediationAdapterUnity.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <UnityAds/UnityAds.h>

#import "AUTUnityTestCase.h"
#import "GADMAdapterUnityConstants.h"

@interface AUTUnityAdapterTests : AUTUnityTestCase
@end

@implementation AUTUnityAdapterTests

- (void)testAdapterSetUp {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterUnityGameID : AUTUnityGameID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterUnity class], credentials);
}

- (void)testAdapterVersion {
  GADVersionNumber version = GADMediationAdapterUnity.adapterVersion;

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 999);
}

- (void)testAdSDKVersion {
  id unityAdClassMock = OCMClassMock([UnityAds class]);
  OCMStub(ClassMethod([unityAdClassMock getVersion])).andReturn(@"1.2.3");

  GADVersionNumber expectedAdapterSDKVersion = {
      .majorVersion = 1, .minorVersion = 2, .patchVersion = 3};
  AUTKAssertEqualVersion([GADMediationAdapterUnity adSDKVersion], expectedAdapterSDKVersion);
}

- (void)testNetworkExtrasClass {
  XCTAssertNil([GADMediationAdapterUnity networkExtrasClass]);
}

- (void)testSignalCollections {
  id unityAdsMock = OCMClassMock([UnityAds class]);
  OCMStub(ClassMethod([unityAdsMock getToken:OCMOCK_ANY])).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained void (^completionHandler)(NSString *_Nullable token);
    [invocation getArgument:&completionHandler atIndex:2];
    completionHandler(@"token");
  });

  GADMediationAdapterUnity *adapter = [[GADMediationAdapterUnity alloc] init];
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Signal collection."];
  [adapter
      collectSignalsForRequestParameters:OCMOCK_ANY
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(error);
                         XCTAssertEqualObjects(signals, @"token");
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];
}

- (void)testNilSignalCollections {
  id unityAdsMock = OCMClassMock([UnityAds class]);
  OCMStub(ClassMethod([unityAdsMock getToken:OCMOCK_ANY])).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained void (^completionHandler)(NSString *_Nullable token);
    [invocation getArgument:&completionHandler atIndex:2];
    completionHandler(nil);
  });

  GADMediationAdapterUnity *adapter = [[GADMediationAdapterUnity alloc] init];
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Nil signal collection."];
  [adapter
      collectSignalsForRequestParameters:OCMOCK_ANY
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(error);
                         XCTAssertEqualObjects(signals, @"");
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];
}

@end
