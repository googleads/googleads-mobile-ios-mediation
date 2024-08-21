#import "GADMediationAdapterPangle.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <OCMock/OCMock.h>
#import <PAGAdSDK/PAGAdSDK.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterPangleConstants.h"
#import "GADPangleNetworkExtras.h"

@interface GADMediationAdapterPangle (Tests)
+ (void)setCOPPA;
@end

@interface AUTPangleAdapterTests : XCTestCase
@end

static NSString *const kApplicationID = @"12345";

@implementation AUTPangleAdapterTests {
  /// Mock for PAGConfig.
  id _configMock;

  /// Mock for PAGSdk;
  id _sdkMock;
}

- (void)setUp {
  _configMock = OCMClassMock([PAGConfig class]);
  _sdkMock = OCMClassMock([PAGSdk class]);
}

- (void)tearDown {
  OCMVerifyAll(_configMock);
  OCMVerifyAll(_sdkMock);
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
}

- (void)testAdSdkVersionIfPangleVersionHasFourPartsReturnsTheVersion {
  id pagSdkClassMock = OCMClassMock([PAGSdk class]);
  OCMStub(ClassMethod([pagSdkClassMock SDKVersion])).andReturn(@"1.2.3.4");

  GADVersionNumber expectedSdkVersion = {.majorVersion = 1, .minorVersion = 2, .patchVersion = 304};
  AUTKAssertEqualVersion([GADMediationAdapterPangle adSDKVersion], expectedSdkVersion);
}

- (void)testAdSdkVersionIfPangleVersionHasLessThanFourPartsReturnsZeros {
  id pagSdkClassMock = OCMClassMock([PAGSdk class]);
  OCMStub(ClassMethod([pagSdkClassMock SDKVersion])).andReturn(@"1.2.3");

  GADVersionNumber expectedSdkVersion = {0};
  AUTKAssertEqualVersion([GADMediationAdapterPangle adSDKVersion], expectedSdkVersion);
}

- (void)testAdSdkVersionIfPangleVersionHasMoreThanFourPartsReturnsZeros {
  id pagSdkClassMock = OCMClassMock([PAGSdk class]);
  OCMStub(ClassMethod([pagSdkClassMock SDKVersion])).andReturn(@"1.2.3.4.5");

  GADVersionNumber expectedSdkVersion = {0};
  AUTKAssertEqualVersion([GADMediationAdapterPangle adSDKVersion], expectedSdkVersion);
}

- (void)testAdapterVersion {
  GADVersionNumber version = GADMediationAdapterPangle.adapterVersion;

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 99999);
}

- (void)testSetUpWithConfiguration {
  OCMStub(ClassMethod([_configMock shareConfig])).andReturn(_configMock);
  OCMExpect([_configMock setAppID:kApplicationID]);
  OCMExpect([_configMock setGDPRConsent:PAGGDPRConsentTypeDefault]);
  OCMExpect([_configMock setDoNotSell:PAGDoNotSellTypeDefault]);
  NSString *expectedUserDataString =
      [NSString stringWithFormat:@"[{\"name\":\"mediation\",\"value\":\"google\"},{\"name\":"
                                 @"\"adapter_version\",\"value\":\"%@\"}]",
                                 GADMAdapterPangleVersion];
  OCMExpect([_configMock setUserDataString:expectedUserDataString]);
  OCMStub(ClassMethod([_sdkMock startWithConfig:_configMock completionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(YES, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterPangleAppID : kApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterPangle class], credentials);
}

- (void)testSetUpWithMultipleAppIDsSucceedWithOneOfTheIDs {
  NSString *applicationID2 = @"applicationID2";
  OCMStub(ClassMethod([_configMock shareConfig])).andReturn(_configMock);
  OCMStub([_configMock setAppID:[OCMArg checkWithBlock:^BOOL(id value) {
                         return [kApplicationID isEqualToString:value] ||
                                [applicationID2 isEqualToString:value];
                       }]]);
  OCMExpect([_configMock setGDPRConsent:PAGGDPRConsentTypeDefault]);
  OCMExpect([_configMock setDoNotSell:PAGDoNotSellTypeDefault]);
  NSString *expectedUserDataString =
      [NSString stringWithFormat:@"[{\"name\":\"mediation\",\"value\":\"google\"},{\"name\":"
                                 @"\"adapter_version\",\"value\":\"%@\"}]",
                                 GADMAdapterPangleVersion];
  OCMExpect([_configMock setUserDataString:expectedUserDataString]);
  OCMStub(ClassMethod([_sdkMock startWithConfig:_configMock completionHandler:OCMOCK_ANY]))
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
}

- (void)testSetUpWithConfigurationFailureForMissingAppID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorInvalidServerParameters
                                                  userInfo:nil];
  AUTKWaitAndAssertAdapterSetUpFailureWithCredentials([GADMediationAdapterPangle class],
                                                      credentials, expectedError);
}

- (void)testNetworkExtras {
  XCTAssertEqual([GADMediationAdapterPangle networkExtrasClass], [GADPangleNetworkExtras class]);
  XCTAssertTrue([[GADMediationAdapterPangle networkExtrasClass]
      conformsToProtocol:@protocol(GADAdNetworkExtras)]);
}

- (void)testCollectSignals {
  NSString *expectedUserDataString = @"userString";
  GADPangleNetworkExtras *extras = [[GADPangleNetworkExtras alloc] init];
  [extras setUserDataString:expectedUserDataString];
  GADRTBRequestParameters *parameters = [[GADRTBRequestParameters alloc] init];
  [parameters setValue:extras forKey:@"extras"];
  OCMStub(ClassMethod([_configMock shareConfig])).andReturn(_configMock);
  OCMExpect([_configMock setUserDataString:expectedUserDataString]);
  NSString *expectedToken = @"token";
  OCMStub([_sdkMock getBiddingToken:OCMOCK_ANY completion:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(NSString *bidderToken);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(expectedToken);
      });

  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Token returned."];
  GADMediationAdapterPangle *adapter = [[GADMediationAdapterPangle alloc] init];
  [adapter
      collectSignalsForRequestParameters:parameters
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertEqualObjects(signals, expectedToken);
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];
}

- (void)testForUnspecifiedChildDirectedTreatment {
  OCMStub(ClassMethod([_configMock shareConfig])).andReturn(_configMock);
  OCMExpect([_configMock setChildDirected:PAGChildDirectedTypeDefault]);

  [GADMediationAdapterPangle setCOPPA];
}

- (void)testForChildDirectedTreatment {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  OCMStub(ClassMethod([_configMock shareConfig])).andReturn(_configMock);
  OCMExpect([_configMock setChildDirected:PAGChildDirectedTypeChild]);

  [GADMediationAdapterPangle setCOPPA];
}

- (void)testForNoChildDirectedTreatment {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMStub(ClassMethod([_configMock shareConfig])).andReturn(_configMock);
  OCMExpect([_configMock setChildDirected:PAGChildDirectedTypeNonChild]);

  [GADMediationAdapterPangle setCOPPA];
}

@end
