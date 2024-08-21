#import "GADMediationAdapterAppLovin.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <AppLovinSDK/AppLovinSDK.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterAppLovinConstant.h"

@interface AUTAppLovinAdapterTests : XCTestCase

@end

@implementation AUTAppLovinAdapterTests

- (void)testAdapterVersion {
  GADVersionNumber version = [GADMediationAdapterAppLovin adapterVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 9999);
}

- (void)testAdSDKVersion {
  GADVersionNumber version = [GADMediationAdapterAppLovin adSDKVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 99);
}

- (void)testSetUp {
  // AppLovin expects an SDK Key of 86 characters
  NSString *testSdkKey =
      @"21345678901234567890123456789012345678901234567890123456789012345678901234567890123456";
  id appLovinSdkMock = OCMClassMock([ALSdk class]);
  OCMExpect([appLovinSdkMock setPluginVersion:GADMAdapterAppLovinAdapterVersion]);
  OCMStub(ClassMethod([appLovinSdkMock sharedWithKey:testSdkKey settings:OCMArg.any]))
      .andReturn(appLovinSdkMock);
  OCMStub([appLovinSdkMock initializeSdkWithCompletionHandler:OCMArg.any])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(ALSdkConfiguration *configuration);
        [invocation getArgument:&completionHandler atIndex:2];
        completionHandler(nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterAppLovinSDKKey : testSdkKey};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterAppLovin class], credentials);
  OCMVerifyAll(appLovinSdkMock);
}

- (void)testSetUpWithMultipleSdkKeys {
  // AppLovin expects an SDK Key of 86 characters.
  // To properly test this scenario, these SDK keys should be different from the other test cases.
  NSString *testSdkKey1 =
      @"65432109876543210987654321098765432109876543210987654321098765432109876543210987654321";
  NSString *testSdkKey2 =
      @"01234567890123456789012345678901234567890123456789012345678901234567890123456789012345";

  id appLovinSdkMock = OCMClassMock([ALSdk class]);
  OCMExpect([appLovinSdkMock setPluginVersion:GADMAdapterAppLovinAdapterVersion]);
  OCMStub(ClassMethod([appLovinSdkMock sharedWithKey:OCMArg.any settings:OCMArg.any]))
      .andReturn(appLovinSdkMock);
  OCMStub([appLovinSdkMock initializeSdkWithCompletionHandler:OCMArg.any])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(ALSdkConfiguration *configuration);
        [invocation getArgument:&completionHandler atIndex:2];
        completionHandler(nil);
      });

  AUTKMediationCredentials *credentials1 = [[AUTKMediationCredentials alloc] init];
  credentials1.settings = @{GADMAdapterAppLovinSDKKey : testSdkKey1};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterAppLovin class], credentials1);
  AUTKMediationCredentials *credentials2 = [[AUTKMediationCredentials alloc] init];
  credentials2.settings = @{GADMAdapterAppLovinSDKKey : testSdkKey2};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterAppLovin class], credentials2);

  OCMVerify(times(2), [appLovinSdkMock initializeSdkWithCompletionHandler:OCMArg.any]);
}

- (void)testSetUpFailureWithInvalidSdkKey {
  NSString *testSdkKey = @"notValid";
  NSError *error = [[NSError alloc] initWithDomain:GADMAdapterAppLovinErrorDomain
                                              code:GADMAdapterAppLovinErrorMissingSDKKey
                                          userInfo:nil];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterAppLovinSDKKey : testSdkKey};
  AUTKWaitAndAssertAdapterSetUpFailureWithCredentials([GADMediationAdapterAppLovin class],
                                                      credentials, error);
}

- (void)testSetUpFailureWithMissingSdkKey {
  NSError *error = [[NSError alloc] initWithDomain:GADMAdapterAppLovinErrorDomain
                                              code:GADMAdapterAppLovinErrorMissingSDKKey
                                          userInfo:nil];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  AUTKWaitAndAssertAdapterSetUpFailureWithCredentials([GADMediationAdapterAppLovin class],
                                                      credentials, error);
}

- (void)testCollectSignalsForRequestParametersSuccess {
  GADMediationAdapterAppLovin *adapter = [[GADMediationAdapterAppLovin alloc] init];
  id appLovinSdkMock = OCMClassMock([ALSdk class]);
  id adServiceMock = OCMClassMock([ALAdService class]);
  OCMStub([appLovinSdkMock adService]).andReturn(adServiceMock);
  OCMStub([adServiceMock bidToken]).andReturn(@"token");

  XCTestExpectation *signalsExpectation = [[XCTestExpectation alloc] init];

  AUTKRTBRequestParameters *parameters = [[AUTKRTBRequestParameters alloc] init];
  AUTKRTBMediationSignalsConfiguration *configuration =
      [[AUTKRTBMediationSignalsConfiguration alloc] init];
  parameters.configuration = configuration;
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  configuration.credentials = @[ credentials ];

  // AppLovin expects an SDK Key of 86 characters
  NSString *sdkKey =
      @"12345678901234567890123456789012345678901234567890123456789012345678901234567890123456";

  credentials.settings = @{@"sdkKey" : sdkKey};

  OCMStub(ClassMethod([appLovinSdkMock sharedWithKey:sdkKey
                                            settings:GADMediationAdapterAppLovin.SDKSettings]))
      .andReturn(appLovinSdkMock);

  [adapter
      collectSignalsForRequestParameters:parameters
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertEqualObjects(signals, @"token");
                         XCTAssertNil(error);
                         [signalsExpectation fulfill];
                       }];

  [self waitForExpectations:@[ signalsExpectation ]];
}

- (void)testCollectSignalsForRequestParametersEmptyToken {
  GADMediationAdapterAppLovin *adapter = [[GADMediationAdapterAppLovin alloc] init];
  id appLovinSdkMock = OCMClassMock([ALSdk class]);
  id adServiceMock = OCMClassMock([ALAdService class]);
  OCMStub([appLovinSdkMock adService]).andReturn(adServiceMock);
  OCMStub([adServiceMock bidToken]).andReturn(@"");

  XCTestExpectation *signalsExpectation = [[XCTestExpectation alloc] init];

  AUTKRTBRequestParameters *parameters = [[AUTKRTBRequestParameters alloc] init];
  AUTKRTBMediationSignalsConfiguration *configuration =
      [[AUTKRTBMediationSignalsConfiguration alloc] init];
  parameters.configuration = configuration;
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  configuration.credentials = @[ credentials ];

  // AppLovin expects an SDK Key of 86 characters
  NSString *sdkKey =
      @"12345678901234567890123456789012345678901234567890123456789012345678901234567890123456";
  credentials.settings = @{@"sdkKey" : sdkKey};

  OCMStub(ClassMethod([appLovinSdkMock sharedWithKey:sdkKey
                                            settings:GADMediationAdapterAppLovin.SDKSettings]))
      .andReturn(appLovinSdkMock);

  [adapter
      collectSignalsForRequestParameters:parameters
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(signals);
                         XCTAssertTrue(error.description.length > 0);
                         XCTAssertEqual(error.code, GADMAdapterAppLovinErrorEmptyBidToken);
                         [signalsExpectation fulfill];
                       }];

  [self waitForExpectations:@[ signalsExpectation ]];
}

- (void)testCollectSignalsNativeFormatError {
  GADMediationAdapterAppLovin *adapter = [[GADMediationAdapterAppLovin alloc] init];

  XCTestExpectation *signalsExpectation = [[XCTestExpectation alloc] init];

  AUTKRTBRequestParameters *parameters = [[AUTKRTBRequestParameters alloc] init];
  AUTKRTBMediationSignalsConfiguration *configuration =
      [[AUTKRTBMediationSignalsConfiguration alloc] init];
  parameters.configuration = configuration;
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  configuration.credentials = @[ credentials ];
  credentials.format = GADAdFormatNative;

  [adapter
      collectSignalsForRequestParameters:parameters
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(signals);
                         XCTAssertTrue(error.description.length > 0);
                         XCTAssertEqual(error.code, GADMAdapterAppLovinErrorUnsupportedAdFormat);
                         [signalsExpectation fulfill];
                       }];

  [self waitForExpectations:@[ signalsExpectation ]];
}

- (void)testCollectSignalsNilSdkKey {
  GADMediationAdapterAppLovin *adapter = [[GADMediationAdapterAppLovin alloc] init];

  XCTestExpectation *signalsExpectation = [[XCTestExpectation alloc] init];

  AUTKRTBRequestParameters *parameters = [[AUTKRTBRequestParameters alloc] init];
  AUTKRTBMediationSignalsConfiguration *configuration =
      [[AUTKRTBMediationSignalsConfiguration alloc] init];
  parameters.configuration = configuration;
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  configuration.credentials = @[ credentials ];
  credentials.settings = @{};

  [adapter
      collectSignalsForRequestParameters:parameters
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(signals);
                         XCTAssertTrue(error.description.length > 0);
                         XCTAssertEqual(error.code,
                                        GADMAdapterAppLovinErrorInvalidServerParameters);
                         [signalsExpectation fulfill];
                       }];

  [self waitForExpectations:@[ signalsExpectation ]];
}

- (void)testCollectSignalsInvalidSdkKey {
  GADMediationAdapterAppLovin *adapter = [[GADMediationAdapterAppLovin alloc] init];

  XCTestExpectation *signalsExpectation = [[XCTestExpectation alloc] init];

  AUTKRTBRequestParameters *parameters = [[AUTKRTBRequestParameters alloc] init];
  AUTKRTBMediationSignalsConfiguration *configuration =
      [[AUTKRTBMediationSignalsConfiguration alloc] init];
  parameters.configuration = configuration;
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  configuration.credentials = @[ credentials ];

  NSString *sdkKey = @"123";

  credentials.settings = @{@"sdkKey" : sdkKey};

  [adapter
      collectSignalsForRequestParameters:parameters
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(signals);
                         XCTAssertTrue(error.description.length > 0);
                         XCTAssertEqual(error.code,
                                        GADMAdapterAppLovinErrorInvalidServerParameters);
                         [signalsExpectation fulfill];
                       }];

  [self waitForExpectations:@[ signalsExpectation ]];
}

@end
