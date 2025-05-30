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

- (void)testSignalCollectionsBanner {
  id unityAdsMock = OCMClassMock([UnityAds class]);
  OCMStub(ClassMethod([unityAdsMock getTokenWith:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(NSString *_Nullable token);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(@"token");
      });

  GADMediationAdapterUnity *adapter = [[GADMediationAdapterUnity alloc] init];
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Signal collection."];

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatBanner;
  AUTKRTBMediationSignalsConfiguration *config =
      [[AUTKRTBMediationSignalsConfiguration alloc] init];
  config.credentials = @[ credentials ];
  AUTKRTBRequestParameters *params = [[AUTKRTBRequestParameters alloc] init];
  params.configuration = config;

  [adapter
      collectSignalsForRequestParameters:params
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(error);
                         XCTAssertEqualObjects(signals, @"token");
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];
}

- (void)testSignalCollectionsInterstitial {
  id unityAdsMock = OCMClassMock([UnityAds class]);
  OCMStub(ClassMethod([unityAdsMock getTokenWith:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(NSString *_Nullable token);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(@"token");
      });

  GADMediationAdapterUnity *adapter = [[GADMediationAdapterUnity alloc] init];
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Signal collection."];

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatInterstitial;
  AUTKRTBMediationSignalsConfiguration *config =
      [[AUTKRTBMediationSignalsConfiguration alloc] init];
  config.credentials = @[ credentials ];
  AUTKRTBRequestParameters *params = [[AUTKRTBRequestParameters alloc] init];
  params.configuration = config;

  [adapter
      collectSignalsForRequestParameters:params
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(error);
                         XCTAssertEqualObjects(signals, @"token");
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];
}

- (void)testSignalCollectionsRewarded {
  id unityAdsMock = OCMClassMock([UnityAds class]);
  OCMStub(ClassMethod([unityAdsMock getTokenWith:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(NSString *_Nullable token);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(@"token");
      });

  GADMediationAdapterUnity *adapter = [[GADMediationAdapterUnity alloc] init];
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Signal collection."];

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatRewarded;
  AUTKRTBMediationSignalsConfiguration *config =
      [[AUTKRTBMediationSignalsConfiguration alloc] init];
  config.credentials = @[ credentials ];
  AUTKRTBRequestParameters *params = [[AUTKRTBRequestParameters alloc] init];
  params.configuration = config;

  [adapter
      collectSignalsForRequestParameters:params
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(error);
                         XCTAssertEqualObjects(signals, @"token");
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];
}

- (void)testSignalCollectionsRewardedInterstitial {
  id unityAdsMock = OCMClassMock([UnityAds class]);
  OCMStub(ClassMethod([unityAdsMock getTokenWith:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(NSString *_Nullable token);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(@"token");
      });

  GADMediationAdapterUnity *adapter = [[GADMediationAdapterUnity alloc] init];
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Signal collection."];

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatRewardedInterstitial;
  AUTKRTBMediationSignalsConfiguration *config =
      [[AUTKRTBMediationSignalsConfiguration alloc] init];
  config.credentials = @[ credentials ];
  AUTKRTBRequestParameters *params = [[AUTKRTBRequestParameters alloc] init];
  params.configuration = config;

  [adapter
      collectSignalsForRequestParameters:params
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(error);
                         XCTAssertEqualObjects(signals, @"token");
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];
}

- (void)testSignalCollectionsFailureForUnsupportedAdFormat {
  id unityAdsMock = OCMClassMock([UnityAds class]);
  OCMStub(ClassMethod([unityAdsMock getTokenWith:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(NSString *_Nullable token);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(@"token");
      });

  GADMediationAdapterUnity *adapter = [[GADMediationAdapterUnity alloc] init];
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Signal collection."];

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatNative;
  AUTKRTBMediationSignalsConfiguration *config =
      [[AUTKRTBMediationSignalsConfiguration alloc] init];
  config.credentials = @[ credentials ];
  AUTKRTBRequestParameters *params = [[AUTKRTBRequestParameters alloc] init];
  params.configuration = config;

  [adapter
      collectSignalsForRequestParameters:params
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNotNil(error);
                         XCTAssertEqual(error.code, GADMAdapterUnityErrorAdUnsupportedAdFormat);
                         XCTAssertNil(signals);
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];
}

- (void)testNilSignalCollections {
  id unityAdsMock = OCMClassMock([UnityAds class]);
  OCMStub(ClassMethod([unityAdsMock getTokenWith:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(NSString *_Nullable token);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(nil);
      });

  GADMediationAdapterUnity *adapter = [[GADMediationAdapterUnity alloc] init];
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Nil signal collection."];

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatBanner;
  AUTKRTBMediationSignalsConfiguration *config =
      [[AUTKRTBMediationSignalsConfiguration alloc] init];
  config.credentials = @[ credentials ];
  AUTKRTBRequestParameters *params = [[AUTKRTBRequestParameters alloc] init];
  params.configuration = config;

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
