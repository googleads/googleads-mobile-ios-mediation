#import "GADMediationAdapterUnity.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <UnityAds/UnityAds.h>

#import "AUTUnityTestCase.h"
#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnityUtils.h"
#import "GADUnityRouter.h"

@interface GADMediationAdapterUnity (Testing)
+ (void)updatePrivacyPreferences;
@end

@interface AUTUnityAdapterTests : AUTUnityTestCase
@end

@implementation AUTUnityAdapterTests {
  NSUserDefaults *_userDefaults;
}

- (void)setUp {
  [super setUp];

  _userDefaults = NSUserDefaults.standardUserDefaults;
}

- (void)tearDown {
  [_userDefaults removeObjectForKey:@"IABTCF_gdprApplies"];
  [_userDefaults removeObjectForKey:@"IABTCF_AddtlConsent"];

  [super tearDown];
}

- (void)testAdapterSetUp {
  id unityAdClassMock = OCMClassMock([UnityAds class]);
  OCMStub(ClassMethod([unityAdClassMock initialize:AUTUnityGameID
                                          testMode:NO
                            initializationDelegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained NSObject *initDelegate;
        [invocation getArgument:&initDelegate atIndex:4];
        if ([initDelegate respondsToSelector:@selector(initializationComplete)]) {
          [initDelegate performSelector:@selector(initializationComplete)];
        }
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterUnityGameID : AUTUnityGameID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterUnity class], credentials);
  [unityAdClassMock stopMocking];
}

- (void)testAdapterSetUpMissingGameID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{};
  NSError *expectedError =
      [NSError errorWithDomain:GADMAdapterUnityErrorDomain
                          code:GADMAdapterUnityErrorInvalidServerParameters
                      userInfo:@{
                        NSLocalizedDescriptionKey :
                            @"UnityAds mediation configurations did not contain a valid game ID."
                      }];
  AUTKWaitAndAssertAdapterSetUpFailureWithCredentials([GADMediationAdapterUnity class], credentials,
                                                      expectedError);
}

- (void)testAdapterSetUpEmptyCredentials {
  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = @[];
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Adapter setup fails with missing game ID."];
  [GADMediationAdapterUnity
      setUpWithConfiguration:configuration
           completionHandler:^(NSError *_Nullable error) {
             XCTAssertNotNil(error);
             XCTAssertEqualObjects(error.domain, GADMAdapterUnityErrorDomain);
             XCTAssertEqual(error.code, GADMAdapterUnityErrorInvalidServerParameters);
             [expectation fulfill];
           }];
  [self waitForExpectations:@[ expectation ]];
}

- (void)testAdapterSetUpInitializationFailure {
  id routerMock = OCMPartialMock([GADUnityRouter sharedRouter]);
  NSError *expectedError = GADMAdapterUnityErrorWithCodeAndDescription(
      GADMAdapterUnityErrorAdInitializationFailure, @"Unity Ads initialization failed.");
  OCMStub([routerMock sdkInitializeWithGameId:AUTUnityGameID withCompletionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(NSError *_Nullable);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(expectedError);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterUnityGameID : AUTUnityGameID};
  AUTKWaitAndAssertAdapterSetUpFailureWithCredentials([GADMediationAdapterUnity class], credentials,
                                                      expectedError);
  [routerMock stopMocking];
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
  [unityAdClassMock stopMocking];
}

- (void)testExtractVersionFromString {
  GADVersionNumber fourPartVersion = extractVersionFromString(@"4.19.0.1");
  XCTAssertEqual(fourPartVersion.majorVersion, 4);
  XCTAssertEqual(fourPartVersion.minorVersion, 19);
  XCTAssertEqual(fourPartVersion.patchVersion, 1);

  GADVersionNumber fourPartNonzeroPatch = extractVersionFromString(@"4.19.1.2");
  XCTAssertEqual(fourPartNonzeroPatch.majorVersion, 4);
  XCTAssertEqual(fourPartNonzeroPatch.minorVersion, 19);
  XCTAssertEqual(fourPartNonzeroPatch.patchVersion, 102);

  GADVersionNumber threePartVersion = extractVersionFromString(@"4.19.0");
  XCTAssertEqual(threePartVersion.majorVersion, 4);
  XCTAssertEqual(threePartVersion.minorVersion, 19);
  XCTAssertEqual(threePartVersion.patchVersion, 0);

  GADVersionNumber twoPartVersion = extractVersionFromString(@"4.19");
  XCTAssertEqual(twoPartVersion.majorVersion, 0);
  XCTAssertEqual(twoPartVersion.minorVersion, 0);
  XCTAssertEqual(twoPartVersion.patchVersion, 0);

  GADVersionNumber emptyVersion = extractVersionFromString(@"");
  XCTAssertEqual(emptyVersion.majorVersion, 0);
  XCTAssertEqual(emptyVersion.minorVersion, 0);
  XCTAssertEqual(emptyVersion.patchVersion, 0);
}

- (void)testNetworkExtrasClass {
  XCTAssertNil([GADMediationAdapterUnity networkExtrasClass]);
}

- (void)testTestMode {
  [GADMediationAdapterUnity setTestMode:YES];
  XCTAssertTrue([GADMediationAdapterUnity testMode]);

  [GADMediationAdapterUnity setTestMode:NO];
  XCTAssertFalse([GADMediationAdapterUnity testMode]);
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
                         XCTAssertNil(signals);
                         XCTAssertEqual(error.code, GADMAdapterUnityErrorEmptyBiddingToken);
                         XCTAssertEqualObjects(error.domain, GADMAdapterUnityErrorDomain);
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];
}

- (void)testEmptySignalCollections {
  id unityAdsMock = OCMClassMock([UnityAds class]);
  OCMStub(ClassMethod([unityAdsMock getTokenWith:OCMOCK_ANY completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(NSString *_Nullable token);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(@"");
      });

  GADMediationAdapterUnity *adapter = [[GADMediationAdapterUnity alloc] init];
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Empty signal collection."];

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
                         XCTAssertNil(signals);
                         XCTAssertEqual(error.code, GADMAdapterUnityErrorEmptyBiddingToken);
                         XCTAssertEqualObjects(error.domain, GADMAdapterUnityErrorDomain);
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];
  [unityAdsMock stopMocking];
}

#pragma mark - Privacy Consent Tests

- (void)testSetUpCredentialsUnknownACConsent {
  id metaDataMock = OCMClassMock([UADSMetaData class]);
  [metaDataMock setExpectationOrderMatters:YES];

  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMReject([metaDataMock set:@"gdpr.consent" value:OCMOCK_ANY]);
  OCMReject([metaDataMock commit]);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterUnityGameID : AUTUnityGameID};
  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = @[ credentials ];

  [GADMediationAdapterUnity setUpWithConfiguration:configuration
                                 completionHandler:^(NSError *_Nullable error) {
                                   XCTAssertNil(error);
                                 }];
  OCMVerifyAll(metaDataMock);
  [metaDataMock stopMocking];
}

- (void)testSetUpCredentialsHasTrueACConsent {
  // Sets AC Consent to True
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.3234~dv" forKey:@"IABTCF_AddtlConsent"];

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  [metaDataMock setExpectationOrderMatters:YES];

  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"gdpr.consent" value:@YES]);
  OCMExpect([metaDataMock commit]);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterUnityGameID : AUTUnityGameID};
  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = @[ credentials ];

  [GADMediationAdapterUnity setUpWithConfiguration:configuration
                                 completionHandler:^(NSError *_Nullable error) {
                                   XCTAssertNil(error);
                                 }];
  OCMVerifyAll(metaDataMock);
  [metaDataMock stopMocking];
}

- (void)testSetUpCredentialsHasFalseACConsent {
  // Sets AC Consent to False
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.2~dv.3.3234" forKey:@"IABTCF_AddtlConsent"];

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  [metaDataMock setExpectationOrderMatters:YES];

  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"gdpr.consent" value:@NO]);
  OCMExpect([metaDataMock commit]);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterUnityGameID : AUTUnityGameID};
  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = @[ credentials ];

  [GADMediationAdapterUnity setUpWithConfiguration:configuration
                                 completionHandler:^(NSError *_Nullable error) {
                                   XCTAssertNil(error);
                                 }];
  OCMVerifyAll(metaDataMock);
  [metaDataMock stopMocking];
}

- (void)testCCPAPrivacyConsent {
  id metaDataMock = OCMClassMock([UADSMetaData class]);
  [metaDataMock setExpectationOrderMatters:YES];

  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"privacy.consent" value:@YES]);
  OCMExpect([metaDataMock commit]);

  UADSMetaData *ccpaMetaData = [[UADSMetaData alloc] init];
  [ccpaMetaData set:@"privacy.consent" value:@YES];
  [ccpaMetaData commit];

  OCMVerifyAll(metaDataMock);
  [metaDataMock stopMocking];
}

- (void)testUpdatePrivacyPreferencesChildDirectedAndUnderAgeOfConsent {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@YES]);
  OCMExpect([metaDataMock commit]);

  [GADMediationAdapterUnity updatePrivacyPreferences];

  OCMVerifyAll(metaDataMock);
  [metaDataMock stopMocking];
}

- (void)testUpdatePrivacyPreferencesChildDirectedOnly {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@YES]);
  OCMExpect([metaDataMock commit]);

  [GADMediationAdapterUnity updatePrivacyPreferences];

  OCMVerifyAll(metaDataMock);
  [metaDataMock stopMocking];
}

- (void)testUpdatePrivacyPreferencesUnderAgeOfConsentOnly {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@YES]);
  OCMExpect([metaDataMock commit]);

  [GADMediationAdapterUnity updatePrivacyPreferences];

  OCMVerifyAll(metaDataMock);
  [metaDataMock stopMocking];
}

- (void)testUpdatePrivacyPreferencesNeitherChildDirectedNorUnderAge {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@NO]);
  OCMExpect([metaDataMock commit]);

  [GADMediationAdapterUnity updatePrivacyPreferences];

  OCMVerifyAll(metaDataMock);
  [metaDataMock stopMocking];
}

- (void)testUpdatePrivacyPreferencesUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@YES]);
  OCMExpect([metaDataMock commit]);

  [GADMediationAdapterUnity updatePrivacyPreferences];

  OCMVerifyAll(metaDataMock);
  [metaDataMock stopMocking];
}

@end
