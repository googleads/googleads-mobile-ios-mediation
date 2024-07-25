#import "GADMediationAdapterChartboost.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <ChartboostSDK/ChartboostSDK.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterChartboostConstants.h"

typedef void (^AUTChartboostSetUpCompletionBlock)(CHBStartError *);

@interface AUTChartboostAdapterTests : XCTestCase
@end

@implementation AUTChartboostAdapterTests

- (void)testAdapterVersion {
  GADVersionNumber version = [GADMediationAdapterChartboost adapterVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 9999);
}

- (void)testAdSDKVersion {
  GADVersionNumber version = [GADMediationAdapterChartboost adSDKVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 99);
}

- (void)testNetworkExtrasClass {
  XCTAssertNil([GADMediationAdapterChartboost networkExtrasClass]);
}

- (void)testSetUpLowSystemVersion {
  id mockDevice = OCMPartialMock(UIDevice.currentDevice);
  OCMStub([(UIDevice *)mockDevice systemVersion]).andReturn(@"10.0");
  GADMediationServerConfiguration *configuration = [[GADMediationServerConfiguration alloc] init];

  XCTestExpectation *setUpExpectation = [[XCTestExpectation alloc] init];
  [GADMediationAdapterChartboost
      setUpWithConfiguration:configuration
           completionHandler:^(NSError *_Nullable error) {
             XCTAssertEqualObjects(error.domain, GADMAdapterChartboostErrorDomain);
             XCTAssertEqual(error.code, GADMAdapterChartboostErrorMinimumOSVersion);

             [setUpExpectation fulfill];
           }];

  [self waitForExpectations:@[ setUpExpectation ]];
}

- (void)testSetUpCredentialsSuccess {
  id mockChartboost = OCMClassMock([Chartboost class]);
  OCMExpect(ClassMethod([mockChartboost
      startWithAppID:@"app_id"
        appSignature:@"signature"
          completion:[OCMArg
                         checkWithBlock:^BOOL(AUTChartboostSetUpCompletionBlock completionBlock) {
                           completionBlock(nil);
                           return YES;
                         }]]));

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterChartboostAppID : @"app_id", GADMAdapterChartboostAppSignature : @"signature"};

  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = @[ credentials ];

  XCTestExpectation *setUpExpectation = [[XCTestExpectation alloc] init];
  [GADMediationAdapterChartboost setUpWithConfiguration:configuration
                                      completionHandler:^(NSError *_Nullable error) {
                                        XCTAssertNil(error);
                                        [setUpExpectation fulfill];
                                      }];

  [self waitForExpectations:@[ setUpExpectation ]];
  OCMVerifyAll(mockChartboost);
}

- (void)testSetUpWithMultipleCredentialsSuccess {
  id mockChartboost = OCMClassMock([Chartboost class]);
  OCMExpect(ClassMethod([mockChartboost
      startWithAppID:@"app_id"
        appSignature:@"signature"
          completion:[OCMArg
                         checkWithBlock:^BOOL(AUTChartboostSetUpCompletionBlock completionBlock) {
                           completionBlock(nil);
                           return YES;
                         }]]));

  AUTKMediationCredentials *credentials1 = [[AUTKMediationCredentials alloc] init];
  credentials1.settings = @{GADMAdapterChartboostAppID : @"bad_app_id"};

  AUTKMediationCredentials *credentials2 = [[AUTKMediationCredentials alloc] init];
  credentials2.settings = @{GADMAdapterChartboostAppSignature : @"bad_signature"};

  AUTKMediationCredentials *credentials3 = [[AUTKMediationCredentials alloc] init];
  credentials3.settings =
      @{GADMAdapterChartboostAppID : @"app_id", GADMAdapterChartboostAppSignature : @"signature"};

  AUTKMediationCredentials *credentials4 = [[AUTKMediationCredentials alloc] init];
  credentials4.settings = @{
    GADMAdapterChartboostAppID : @"ignored_app_id",
    GADMAdapterChartboostAppSignature : @"ignored_signature"
  };

  // Expectation is that the first two credentials are ignored due to being invalid, third is used,
  // and 4th is ignored because 3 was already valid.
  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = @[ credentials1, credentials2, credentials3, credentials4 ];

  XCTestExpectation *setUpExpectation = [[XCTestExpectation alloc] init];
  [GADMediationAdapterChartboost setUpWithConfiguration:configuration
                                      completionHandler:^(NSError *_Nullable error) {
                                        XCTAssertNil(error);
                                        [setUpExpectation fulfill];
                                      }];

  [self waitForExpectations:@[ setUpExpectation ]];
  OCMVerifyAll(mockChartboost);
}

- (void)testSetUpCredentialsChartboostFailure {
  id mockChartboost = OCMClassMock([Chartboost class]);
  CHBStartError *startError = [[CHBStartError alloc] initWithDomain:@"test_domain"
                                                               code:1
                                                           userInfo:nil];
  XCTAssertNotNil(startError);
  OCMExpect(ClassMethod([mockChartboost
      startWithAppID:@"app_id"
        appSignature:@"signature"
          completion:[OCMArg
                         checkWithBlock:^BOOL(AUTChartboostSetUpCompletionBlock completionBlock) {
                           completionBlock(startError);
                           return YES;
                         }]]));

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterChartboostAppID : @"app_id", GADMAdapterChartboostAppSignature : @"signature"};

  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = @[ credentials ];

  XCTestExpectation *setUpExpectation = [[XCTestExpectation alloc] init];
  [GADMediationAdapterChartboost
      setUpWithConfiguration:configuration
           completionHandler:^(NSError *_Nullable error) {
             XCTAssertEqualObjects(error.domain, GADMAdapterChartboostErrorDomain);
             XCTAssertEqual(error.code, GADMAdapterChartboostErrorInitializationFailure);
             [setUpExpectation fulfill];
           }];

  [self waitForExpectations:@[ setUpExpectation ]];
  OCMVerifyAll(mockChartboost);
}

- (void)testSetUpEmptyCredentials {
  GADMediationServerConfiguration *configuration = [[GADMediationServerConfiguration alloc] init];

  XCTestExpectation *setUpExpectation = [[XCTestExpectation alloc] init];
  [GADMediationAdapterChartboost
      setUpWithConfiguration:configuration
           completionHandler:^(NSError *_Nullable error) {
             XCTAssertEqualObjects(error.domain, GADMAdapterChartboostErrorDomain);
             XCTAssertEqual(error.code, GADMAdapterChartboostErrorInvalidServerParameters);

             [setUpExpectation fulfill];
           }];

  [self waitForExpectations:@[ setUpExpectation ]];
}

- (void)testSetUpCredentialsMissingAppID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterChartboostAppSignature : @"signature"};

  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = @[ credentials ];

  XCTestExpectation *setUpExpectation = [[XCTestExpectation alloc] init];
  [GADMediationAdapterChartboost
      setUpWithConfiguration:configuration
           completionHandler:^(NSError *_Nullable error) {
             XCTAssertEqualObjects(error.domain, GADMAdapterChartboostErrorDomain);
             XCTAssertEqual(error.code, GADMAdapterChartboostErrorInvalidServerParameters);

             [setUpExpectation fulfill];
           }];

  [self waitForExpectations:@[ setUpExpectation ]];
}

- (void)testSetUpCredentialsMissingSignature {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterChartboostAppID : @"app_id"};

  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = @[ credentials ];

  XCTestExpectation *setUpExpectation = [[XCTestExpectation alloc] init];
  [GADMediationAdapterChartboost
      setUpWithConfiguration:configuration
           completionHandler:^(NSError *_Nullable error) {
             XCTAssertEqualObjects(error.domain, GADMAdapterChartboostErrorDomain);
             XCTAssertEqual(error.code, GADMAdapterChartboostErrorInvalidServerParameters);

             [setUpExpectation fulfill];
           }];

  [self waitForExpectations:@[ setUpExpectation ]];
}

@end
