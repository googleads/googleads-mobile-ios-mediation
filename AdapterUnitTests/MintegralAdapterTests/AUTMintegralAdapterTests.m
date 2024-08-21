#import "GADMediationAdapterMintegral.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <MTGSDK/MTGSDK.h>
#import <MTGSDKBidding/MTGBiddingSDK.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterMintegralExtras.h"
#import "GADMediationAdapterMintegralConstants.h"

@interface MTGSDK (Test)
+ (void)setChannelFlag:(NSString *)pluginNumber;
@end

@interface MintegralAdapterTests : XCTestCase
@end

@implementation MintegralAdapterTests {
  id _mintegralMock;
}

- (void)setUp {
  [super setUp];
  _mintegralMock = OCMClassMock([MTGSDK class]);
  OCMStub(ClassMethod([_mintegralMock sharedInstance])).andReturn(_mintegralMock);
}

- (void)testExtras {
  XCTAssertEqual([GADMediationAdapterMintegral networkExtrasClass],
                 [GADMAdapterMintegralExtras class]);
}

- (void)testSetUp {
  NSString *appID = @"123";
  NSString *APIKey = @"456";
  OCMExpect([_mintegralMock setAppID:appID ApiKey:APIKey]);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralAppID : appID, GADMAdapterMintegralAppKey : APIKey};

  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterMintegral class], credentials);
  OCMVerifyAll(_mintegralMock);
}

- (void)testSetUpWithMultipleAppIDsAndSucceedWithRandomID {
  NSString *appID1 = @"123";
  NSString *appID2 = @"456";
  NSString *APIKey = @"789";
  id appIDCheckingBlock = [OCMArg checkWithBlock:^BOOL(id obj) {
    NSString *appID = (NSString *)obj;
    return [appID isEqualToString:appID1] || [appID isEqualToString:appID2];
  }];
  OCMExpect([_mintegralMock setAppID:appIDCheckingBlock ApiKey:APIKey]);

  AUTKMediationCredentials *credentials1 = [[AUTKMediationCredentials alloc] init];
  credentials1.settings =
      @{GADMAdapterMintegralAppID : appID1, GADMAdapterMintegralAppKey : APIKey};
  AUTKMediationCredentials *credentials2 = [[AUTKMediationCredentials alloc] init];
  credentials2.settings =
      @{GADMAdapterMintegralAppID : appID2, GADMAdapterMintegralAppKey : APIKey};

  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray([GADMediationAdapterMintegral class],
                                                    @[ credentials1, credentials2 ]);
  OCMVerifyAll(_mintegralMock);
}

- (void)testSetUpWithMultipleAPIKeysAndSucceedWithRandomAPIKey {
  NSString *appID = @"123";
  NSString *APIKey1 = @"456";
  NSString *APIKey2 = @"789";
  id APIKeyCheckingBlock = [OCMArg checkWithBlock:^BOOL(id obj) {
    NSString *APIKey = (NSString *)obj;
    return [APIKey isEqualToString:APIKey1] || [APIKey isEqualToString:APIKey2];
  }];
  OCMExpect([_mintegralMock setAppID:appID ApiKey:APIKeyCheckingBlock]);

  AUTKMediationCredentials *credentials1 = [[AUTKMediationCredentials alloc] init];
  credentials1.settings =
      @{GADMAdapterMintegralAppID : appID, GADMAdapterMintegralAppKey : APIKey1};
  AUTKMediationCredentials *credentials2 = [[AUTKMediationCredentials alloc] init];
  credentials2.settings =
      @{GADMAdapterMintegralAppID : appID, GADMAdapterMintegralAppKey : APIKey2};

  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray([GADMediationAdapterMintegral class],
                                                    @[ credentials1, credentials2 ]);
  OCMVerifyAll(_mintegralMock);
}

- (void)testSetUpFailureForMissingAppID {
  NSString *APIKey = @"456";
  NSError *expectedError = [[NSError alloc]
      initWithDomain:GADMAdapterMintegralErrorDomain
                code:GADMintegralErrorInvalidServerParameters
            userInfo:@{
              NSLocalizedDescriptionKey :
                  @"Mintegral mediation configurations did not contain a valid App ID or App Key.",
              NSLocalizedFailureReasonErrorKey :
                  @"Mintegral mediation configurations did not contain a valid App ID or App Key."
            }];
  OCMReject([_mintegralMock setAppID:OCMOCK_ANY ApiKey:OCMOCK_ANY]);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralAppKey : APIKey};

  AUTKWaitAndAssertAdapterSetUpFailureWithCredentials([GADMediationAdapterMintegral class],
                                                      credentials, expectedError);
  OCMVerifyAll(_mintegralMock);
}

- (void)testSetUpFailureForMissingApiKey {
  NSString *appID = @"123";
  NSError *expectedError = [[NSError alloc]
      initWithDomain:GADMAdapterMintegralErrorDomain
                code:GADMintegralErrorInvalidServerParameters
            userInfo:@{
              NSLocalizedDescriptionKey :
                  @"Mintegral mediation configurations did not contain a valid App ID or App Key.",
              NSLocalizedFailureReasonErrorKey :
                  @"Mintegral mediation configurations did not contain a valid App ID or App Key."
            }];
  OCMReject([_mintegralMock setAppID:OCMOCK_ANY ApiKey:OCMOCK_ANY]);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralAppID : appID};

  AUTKWaitAndAssertAdapterSetUpFailureWithCredentials([GADMediationAdapterMintegral class],
                                                      credentials, expectedError);
  OCMVerifyAll(_mintegralMock);
}

- (void)testAdSDKVersion {
  NSString *versionString = @"1.2.3";
  GADVersionNumber expectedVersion = {.majorVersion = 1, .minorVersion = 2, .patchVersion = 3};
  OCMStub(ClassMethod([_mintegralMock sdkVersion])).andReturn(versionString);

  GADVersionNumber version = [GADMediationAdapterMintegral adSDKVersion];

  AUTKAssertEqualVersion(version, expectedVersion);
}

- (void)testAdSDKVersionWithoutPatchVersion {
  NSString *versionString = @"1.2";
  GADVersionNumber expectedVersion = {0};
  OCMStub(ClassMethod([_mintegralMock sdkVersion])).andReturn(versionString);

  GADVersionNumber version = [GADMediationAdapterMintegral adSDKVersion];

  AUTKAssertEqualVersion(version, expectedVersion);
}

- (void)testAdSDKVersionWithExtraVersion {
  NSString *versionString = @"1.2.3.4";
  GADVersionNumber expectedVersion = {0};
  OCMStub(ClassMethod([_mintegralMock sdkVersion])).andReturn(versionString);

  GADVersionNumber version = [GADMediationAdapterMintegral adSDKVersion];

  AUTKAssertEqualVersion(version, expectedVersion);
}

- (void)testAdapterVersion {
  GADVersionNumber version = [GADMediationAdapterMintegral adapterVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  // Patch version between x.y.0.0 ~x.y.99.99
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 990099);
}

- (void)testCollectSignals {
  NSString *expectedSignals = @"12345";
  id mockBiddingSDK = OCMClassMock([MTGBiddingSDK class]);
  OCMStub(ClassMethod([mockBiddingSDK buyerUID])).andReturn(expectedSignals);
  GADRTBRequestParameters *parameters = [[GADRTBRequestParameters alloc] init];
  GADMediationAdapterMintegral *adapter = [[GADMediationAdapterMintegral alloc] init];
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Signals collected."];

  [adapter
      collectSignalsForRequestParameters:parameters
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertEqualObjects(signals, expectedSignals);
                         XCTAssertNil(error);
                         [expectation fulfill];
                       }];

  [self waitForExpectations:@[ expectation ]];
}

- (void)testAdMobChannel {
  NSString *pluginNumber = @"Y+H6DFttYrPQYcIBiQKwJQKQYrN=";
  OCMExpect(ClassMethod([_mintegralMock setChannelFlag:pluginNumber]));

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralAppID : @"123", GADMAdapterMintegralAppKey : @"123"};

  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterMintegral class], credentials);
  OCMVerifyAll(_mintegralMock);
}

@end
