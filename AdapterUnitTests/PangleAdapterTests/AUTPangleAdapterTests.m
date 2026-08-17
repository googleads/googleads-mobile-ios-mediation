#import "GADMediationAdapterPangle.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <PAGAdSDK/PAGAdSDK.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterPangleUtils.h"
#import "GADMediationAdapterPangleConstants.h"
#import "GADPangleNetworkExtras.h"

@interface AUTPangleAdapterTests : XCTestCase
@end

static NSString *const kApplicationID = @"12345";
static NSString *const kPangleSdkErrorDomain = @"com.pangle.sdk";
static const NSInteger kPangleBiddingTokenFailureCode = 1005;

@implementation AUTPangleAdapterTests {
  /// Mock for PAGConfig.
  id _configMock;

  /// Mock for PAGSdk.
  id _sdkMock;
}

- (void)setUp {
  [super setUp];
  _configMock = OCMClassMock([PAGConfig class]);
  _sdkMock = OCMClassMock([PAGSdk class]);
  OCMStub(ClassMethod([_configMock shareConfig])).andReturn(_configMock);
}

- (void)tearDown {
  [_configMock stopMocking];
  [_sdkMock stopMocking];

  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  [super tearDown];
}

#pragma mark - Version Tests

- (void)testAdapterVersion {
  GADVersionNumber version = GADMediationAdapterPangle.adapterVersion;

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 99999);
}

- (void)testAdSdkVersionIfPangleVersionHasFourPartsReturnsTheVersion {
  OCMStub(ClassMethod([_sdkMock SDKVersion])).andReturn(@"1.2.3.4");

  GADVersionNumber expectedSdkVersion = {.majorVersion = 1, .minorVersion = 2, .patchVersion = 304};
  AUTKAssertEqualVersion([GADMediationAdapterPangle adSDKVersion], expectedSdkVersion);
}

- (void)testAdSdkVersionIfPangleVersionHasLessThanFourPartsReturnsZeros {
  OCMStub(ClassMethod([_sdkMock SDKVersion])).andReturn(@"1.2.3");

  GADVersionNumber expectedSdkVersion = {0};
  AUTKAssertEqualVersion([GADMediationAdapterPangle adSDKVersion], expectedSdkVersion);
}

- (void)testAdSdkVersionIfPangleVersionHasMoreThanFourPartsReturnsZeros {
  OCMStub(ClassMethod([_sdkMock SDKVersion])).andReturn(@"1.2.3.4.5");

  GADVersionNumber expectedSdkVersion = {0};
  AUTKAssertEqualVersion([GADMediationAdapterPangle adSDKVersion], expectedSdkVersion);
}

- (void)testAdSdkVersionIfPangleVersionIsMalformedReturnsZeros {
  OCMStub(ClassMethod([_sdkMock SDKVersion])).andReturn(@"invalid_version");

  GADVersionNumber expectedSdkVersion = {0};
  AUTKAssertEqualVersion([GADMediationAdapterPangle adSDKVersion], expectedSdkVersion);
}

- (void)testAdSdkVersionIfPangleVersionIsEmptyReturnsZeros {
  OCMStub(ClassMethod([_sdkMock SDKVersion])).andReturn(@"");

  GADVersionNumber expectedSdkVersion = {0};
  AUTKAssertEqualVersion([GADMediationAdapterPangle adSDKVersion], expectedSdkVersion);
}

#pragma mark - SetUp Tests

- (void)testSetUpWithConfiguration {
  OCMExpect([_configMock setAppID:kApplicationID]);
  OCMExpect([_configMock setAdxID:GADMAdapterPangleAdxID]);
  NSString *expectedUserDataString =
      [NSString stringWithFormat:@"[{\"name\":\"mediation\",\"value\":\"google\"},{\"name\":"
                                 @"\"adapter_version\",\"value\":\"%@\"}]",
                                 GADMAdapterPangleVersion];
  OCMExpect([_configMock setUserDataString:expectedUserDataString]);
  OCMExpect(ClassMethod([_sdkMock startWithConfig:_configMock completionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(YES, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterPangleAppID : kApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterPangle class], credentials);

  OCMVerifyAll(_configMock);
  OCMVerifyAll(_sdkMock);
}

- (void)testSetUpWithConfigurationSDKStartFailure {
  OCMExpect([_configMock setAppID:kApplicationID]);
  OCMExpect([_configMock setAdxID:GADMAdapterPangleAdxID]);
  NSError *expectedError = [[NSError alloc] initWithDomain:kPangleSdkErrorDomain
                                                      code:1001
                                                  userInfo:nil];
  OCMExpect(ClassMethod([_sdkMock startWithConfig:_configMock completionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(NO, expectedError);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterPangleAppID : kApplicationID};
  AUTKWaitAndAssertAdapterSetUpFailureWithCredentials([GADMediationAdapterPangle class],
                                                      credentials, expectedError);

  OCMVerifyAll(_configMock);
  OCMVerifyAll(_sdkMock);
}

- (void)testSetUpWithMultipleAppIDsSucceedWithOneOfTheIDs {
  NSString *applicationID2 = @"applicationID2";
  OCMExpect([_configMock setAppID:[OCMArg checkWithBlock:^BOOL(id value) {
                           return [kApplicationID isEqualToString:value] ||
                                  [applicationID2 isEqualToString:value];
                         }]]);
  OCMExpect([_configMock setAdxID:GADMAdapterPangleAdxID]);
  NSString *expectedUserDataString =
      [NSString stringWithFormat:@"[{\"name\":\"mediation\",\"value\":\"google\"},{\"name\":"
                                 @"\"adapter_version\",\"value\":\"%@\"}]",
                                 GADMAdapterPangleVersion];
  OCMExpect([_configMock setUserDataString:expectedUserDataString]);
  OCMExpect(ClassMethod([_sdkMock startWithConfig:_configMock completionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(YES, nil);
      });

  AUTKMediationCredentials *credentials1 = [[AUTKMediationCredentials alloc] init];
  credentials1.settings = @{GADMAdapterPangleAppID : kApplicationID};
  AUTKMediationCredentials *credentials2 = [[AUTKMediationCredentials alloc] init];
  credentials2.settings = @{GADMAdapterPangleAppID : applicationID2};
  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray([GADMediationAdapterPangle class],
                                                    @[ credentials1, credentials2 ]);

  OCMVerifyAll(_configMock);
  OCMVerifyAll(_sdkMock);
}

- (void)testSetUpWithConfigurationFailureForMissingAppID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorInvalidServerParameters
                                                  userInfo:nil];
  AUTKWaitAndAssertAdapterSetUpFailureWithCredentials([GADMediationAdapterPangle class],
                                                      credentials, expectedError);
}

- (void)testSetUpFailureIfChildUserWithTagForChildDirectedTreatment {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterPangleAppID : kApplicationID};
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorChildUser
                                                  userInfo:nil];
  AUTKWaitAndAssertAdapterSetUpFailureWithCredentials([GADMediationAdapterPangle class],
                                                      credentials, expectedError);
}

- (void)testSetUpFailureIfChildUserWithTagForUnderAgeOfConsent {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterPangleAppID : kApplicationID};
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorChildUser
                                                  userInfo:nil];
  AUTKWaitAndAssertAdapterSetUpFailureWithCredentials([GADMediationAdapterPangle class],
                                                      credentials, expectedError);
}

- (void)testSetUpFailureIfChildUserWithAgeRestrictedTreatmentChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterPangleAppID : kApplicationID};
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorChildUser
                                                  userInfo:nil];
  AUTKWaitAndAssertAdapterSetUpFailureWithCredentials([GADMediationAdapterPangle class],
                                                      credentials, expectedError);
}

- (void)testSetUpSuccessIfNonChildUserWithTagForChildDirectedTreatmentNo {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect(ClassMethod([_sdkMock startWithConfig:_configMock completionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(YES, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterPangleAppID : kApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterPangle class], credentials);
}

- (void)testSetUpSuccessIfNonChildUserWithTagForUnderAgeOfConsentNo {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect(ClassMethod([_sdkMock startWithConfig:_configMock completionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(YES, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterPangleAppID : kApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterPangle class], credentials);
}

- (void)testSetUpSuccessIfNonChildUserWithAgeRestrictedTreatmentTeen {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;
  OCMExpect(ClassMethod([_sdkMock startWithConfig:_configMock completionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(YES, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterPangleAppID : kApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterPangle class], credentials);
}

#pragma mark - Signal Collection Tests

- (void)testCollectSignalsSuccess {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  NSString *expectedUserDataString = @"userString";
  GADPangleNetworkExtras *extras = [[GADPangleNetworkExtras alloc] init];
  [extras setUserDataString:expectedUserDataString];
  AUTKRTBRequestParameters *parameters = [[AUTKRTBRequestParameters alloc] init];
  parameters.extras = extras;
  OCMExpect([_configMock setUserDataString:expectedUserDataString]);
  NSString *expectedToken = @"pangle_token";
  OCMExpect(ClassMethod([_sdkMock getBiddingTokenWithRequest:OCMOCK_ANY
                                           completionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(NSString *_Nullable biddingToken,
                                                      NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(expectedToken, nil);
      });

  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Token returned."];
  GADMediationAdapterPangle *adapter = [[GADMediationAdapterPangle alloc] init];
  [adapter
      collectSignalsForRequestParameters:parameters
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertEqualObjects(signals, expectedToken);
                         XCTAssertNil(error);
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];

  OCMVerifyAll(_configMock);
  OCMVerifyAll(_sdkMock);
}

- (void)testCollectSignalsForBannerFormat {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  AUTKRTBRequestParameters *parameters = [[AUTKRTBRequestParameters alloc] init];
  AUTKRTBMediationSignalsConfiguration *signalsConfiguration =
      [[AUTKRTBMediationSignalsConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatBanner;
  signalsConfiguration.credentials = @[ credentials ];
  parameters.configuration = signalsConfiguration;
  parameters.adSize = GADAdSizeBanner;

  NSString *expectedToken = @"pangle_banner_token";
  OCMExpect(ClassMethod([_sdkMock
                getBiddingTokenWithRequest:[OCMArg checkWithBlock:^BOOL(PAGBiddingRequest *req) {
                  return [req.adxID isEqualToString:GADMAdapterPangleAdxID] &&
                         req.bannerSize.size.width == 320 && req.bannerSize.size.height == 50;
                }]
                         completionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(NSString *_Nullable biddingToken,
                                                      NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(expectedToken, nil);
      });

  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Banner token returned."];
  GADMediationAdapterPangle *adapter = [[GADMediationAdapterPangle alloc] init];
  [adapter
      collectSignalsForRequestParameters:parameters
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertEqualObjects(signals, expectedToken);
                         XCTAssertNil(error);
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];

  OCMVerifyAll(_sdkMock);
}

- (void)testCollectSignalsFailure {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  NSString *expectedUserDataString = @"userString";
  GADPangleNetworkExtras *extras = [[GADPangleNetworkExtras alloc] init];
  [extras setUserDataString:expectedUserDataString];
  AUTKRTBRequestParameters *parameters = [[AUTKRTBRequestParameters alloc] init];
  parameters.extras = extras;
  OCMExpect([_configMock setUserDataString:expectedUserDataString]);
  NSError *expectedError = [[NSError alloc] initWithDomain:kPangleSdkErrorDomain
                                                      code:kPangleBiddingTokenFailureCode
                                                  userInfo:nil];
  OCMExpect(ClassMethod([_sdkMock getBiddingTokenWithRequest:OCMOCK_ANY
                                           completionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(NSString *_Nullable biddingToken,
                                                      NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(nil, expectedError);
      });

  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Token returned failure."];
  GADMediationAdapterPangle *adapter = [[GADMediationAdapterPangle alloc] init];
  [adapter
      collectSignalsForRequestParameters:parameters
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(signals);
                         XCTAssertEqual(error.code, kPangleBiddingTokenFailureCode);
                         XCTAssertEqualObjects(error.domain, kPangleSdkErrorDomain);
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];

  OCMVerifyAll(_configMock);
  OCMVerifyAll(_sdkMock);
}

- (void)testCollectSignalsFailureIfChildUserWithTagForChildDirectedTreatment {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  AUTKRTBRequestParameters *parameters = [[AUTKRTBRequestParameters alloc] init];
  GADMediationAdapterPangle *adapter = [[GADMediationAdapterPangle alloc] init];

  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Signals rejected child user."];
  [adapter
      collectSignalsForRequestParameters:parameters
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(signals);
                         XCTAssertEqual(error.code, GADPangleErrorChildUser);
                         XCTAssertEqualObjects(error.domain, GADMAdapterPangleErrorDomain);
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];
}

- (void)testCollectSignalsFailureIfChildUserWithTagForUnderAgeOfConsent {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  AUTKRTBRequestParameters *parameters = [[AUTKRTBRequestParameters alloc] init];
  GADMediationAdapterPangle *adapter = [[GADMediationAdapterPangle alloc] init];

  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Signals rejected under age user."];
  [adapter
      collectSignalsForRequestParameters:parameters
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(signals);
                         XCTAssertEqual(error.code, GADPangleErrorChildUser);
                         XCTAssertEqualObjects(error.domain, GADMAdapterPangleErrorDomain);
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];
}

- (void)testCollectSignalsFailureIfChildUserWithAgeRestrictedTreatmentChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  AUTKRTBRequestParameters *parameters = [[AUTKRTBRequestParameters alloc] init];
  GADMediationAdapterPangle *adapter = [[GADMediationAdapterPangle alloc] init];

  XCTestExpectation *expectation = [[XCTestExpectation alloc]
      initWithDescription:@"Signals rejected age-restricted child user."];
  [adapter
      collectSignalsForRequestParameters:parameters
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(signals);
                         XCTAssertEqual(error.code, GADPangleErrorChildUser);
                         XCTAssertEqualObjects(error.domain, GADMAdapterPangleErrorDomain);
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];
}

#pragma mark - Privacy & Network Extras Tests

- (void)testSetPAConsentValidValues {
  [GADMediationAdapterPangle setPAConsent:0];
  OCMVerify([_configMock setPAConsent:0]);

  [GADMediationAdapterPangle setPAConsent:1];
  OCMVerify([_configMock setPAConsent:1]);
}

- (void)testSetPAConsentInvalidValue {
  OCMReject([_configMock setPAConsent:2]);
  [GADMediationAdapterPangle setPAConsent:2];
}

- (void)testSetGDPRConsent {
  // Verifies calling deprecated/no-op GDPR method does not crash.
  [GADMediationAdapterPangle setGDPRConsent:0];
  [GADMediationAdapterPangle setGDPRConsent:1];
}

- (void)testNetworkExtras {
  XCTAssertEqual([GADMediationAdapterPangle networkExtrasClass], [GADPangleNetworkExtras class]);
  XCTAssertTrue([[GADMediationAdapterPangle networkExtrasClass]
      conformsToProtocol:@protocol(GADAdNetworkExtras)]);
}

@end
