#import "GADMAdapterChartboost.h"
#import "GADMediationAdapterChartboost.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <ChartboostSDK/ChartboostSDK.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "ChartboostAdapter-Swift.h"
#import "GADMAdapterChartboostUtils.h"

typedef void (^AUTChartboostSetUpCompletionBlock)(CHBStartError *);

@interface AUTChartboostAdapterTests : XCTestCase
@end

@implementation AUTChartboostAdapterTests {
  NSUserDefaults *_userDefaults;
  id _mockChartboost;
}

- (void)setUp {
  _userDefaults = NSUserDefaults.standardUserDefaults;
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  [_userDefaults removeObjectForKey:@"IABTCF_gdprApplies"];
  [_userDefaults removeObjectForKey:@"IABTCF_AddtlConsent"];
  [_userDefaults removeObjectForKey:@"IABUSPrivacy_String"];

  [_mockChartboost stopMocking];
  [super tearDown];
}

- (void)mockSuccessfulChartboostStart {
  _mockChartboost = OCMClassMock([Chartboost class]);
  OCMExpect(ClassMethod([_mockChartboost
      startWithAppID:@"app_id"
        appSignature:@"signature"
          completion:[OCMArg
                         checkWithBlock:^BOOL(AUTChartboostSetUpCompletionBlock completionBlock) {
                           completionBlock(nil);
                           return YES;
                         }]]));
}

- (void)setUpAdapterWithValidCredentials {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    [GADMAdapterChartboostConstants appID] : @"app_id",
    [GADMAdapterChartboostConstants appSignature] : @"signature"
  };
  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = @[ credentials ];

  XCTestExpectation *setUpExpectation = [[XCTestExpectation alloc] init];
  [GADMediationAdapterChartboost setUpWithConfiguration:configuration
                                      completionHandler:^(NSError *_Nullable error) {
                                        XCTAssertNil(error);
                                        [setUpExpectation fulfill];
                                      }];
  [self waitForExpectations:@[ setUpExpectation ]];
}

- (void)testMainAdapterClass {
  SEL mainAdapterClassSelector = NSSelectorFromString(@"mainAdapterClass");
  XCTAssertTrue([GADMAdapterChartboost respondsToSelector:mainAdapterClassSelector]);

  Class adapterClass = [GADMAdapterChartboost class];
  IMP imp = [adapterClass methodForSelector:mainAdapterClassSelector];
  Class (*func)(id, SEL) = (void *)imp;
  Class mainAdapterClass = func(adapterClass, mainAdapterClassSelector);
  XCTAssertEqualObjects(mainAdapterClass, [GADMediationAdapterChartboost class]);
}

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

- (GADVersionNumber)adSDKVersionForChartboostSDKVersion:(nonnull NSString *)sdkVersion {
  _mockChartboost = OCMClassMock([Chartboost class]);
  OCMStub(ClassMethod([_mockChartboost getSDKVersion])).andReturn(sdkVersion);
  return [GADMediationAdapterChartboost adSDKVersion];
}

- (void)testAdSDKVersionWithMoreThanThreeComponents {
  GADVersionNumber version = [self adSDKVersionForChartboostSDKVersion:@"9.14.2.1"];

  XCTAssertEqual(version.majorVersion, 9);
  XCTAssertEqual(version.minorVersion, 14);
  XCTAssertEqual(version.patchVersion, 2);
}

- (void)testAdSDKVersionWithFewerThanThreeComponents {
  GADVersionNumber version = [self adSDKVersionForChartboostSDKVersion:@"9.14"];

  XCTAssertEqual(version.majorVersion, 0);
  XCTAssertEqual(version.minorVersion, 0);
  XCTAssertEqual(version.patchVersion, 0);
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
             XCTAssertEqualObjects(error.domain, [GADMAdapterChartboostConstants errorDomain]);
             XCTAssertEqual(error.code, GADMAdapterChartboostErrorMinimumOSVersion);

             [setUpExpectation fulfill];
           }];

  [self waitForExpectations:@[ setUpExpectation ]];
  [mockDevice stopMocking];
}

- (void)testSetUpCredentialsSuccess {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  [self mockSuccessfulChartboostStart];

  OCMExpect(
      [_mockChartboost addDataUseConsent:[OCMArg checkWithBlock:^BOOL(CHBCOPPADataUseConsent *obj) {
                        return obj.isChildDirected == NO;
                      }]]);

  [self setUpAdapterWithValidCredentials];
  OCMVerifyAll(_mockChartboost);
}

- (void)testSetUpTrimsWhitespaceFromCredentials {
  _mockChartboost = OCMClassMock([Chartboost class]);
  // Match any credentials so the completion always runs, then verify the trimmed values below.
  OCMStub(ClassMethod([_mockChartboost
      startWithAppID:OCMOCK_ANY
        appSignature:OCMOCK_ANY
          completion:[OCMArg
                         checkWithBlock:^BOOL(AUTChartboostSetUpCompletionBlock completionBlock) {
                           completionBlock(nil);
                           return YES;
                         }]]));

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    [GADMAdapterChartboostConstants appID] : @"  app_id  ",
    [GADMAdapterChartboostConstants appSignature] : @"  signature  "
  };

  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = @[ credentials ];

  XCTestExpectation *setUpExpectation = [[XCTestExpectation alloc] init];
  [GADMediationAdapterChartboost setUpWithConfiguration:configuration
                                      completionHandler:^(NSError *_Nullable error) {
                                        XCTAssertNil(error);
                                        [setUpExpectation fulfill];
                                      }];

  [self waitForExpectations:@[ setUpExpectation ]];
  OCMVerify(ClassMethod([_mockChartboost startWithAppID:@"app_id"
                                           appSignature:@"signature"
                                             completion:OCMOCK_ANY]));
}

- (void)testSetUpWithMultipleCredentialsSuccess {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  _mockChartboost = OCMClassMock([Chartboost class]);
  OCMExpect(ClassMethod([_mockChartboost
      startWithAppID:@"app_id"
        appSignature:@"signature"
          completion:[OCMArg
                         checkWithBlock:^BOOL(AUTChartboostSetUpCompletionBlock completionBlock) {
                           completionBlock(nil);
                           return YES;
                         }]]));

  AUTKMediationCredentials *credentials1 = [[AUTKMediationCredentials alloc] init];
  credentials1.settings = @{[GADMAdapterChartboostConstants appID] : @"bad_app_id"};

  AUTKMediationCredentials *credentials2 = [[AUTKMediationCredentials alloc] init];
  credentials2.settings = @{[GADMAdapterChartboostConstants appSignature] : @"bad_signature"};

  AUTKMediationCredentials *credentials3 = [[AUTKMediationCredentials alloc] init];
  credentials3.settings = @{
    [GADMAdapterChartboostConstants appID] : @"app_id",
    [GADMAdapterChartboostConstants appSignature] : @"signature"
  };

  AUTKMediationCredentials *credentials4 = [[AUTKMediationCredentials alloc] init];
  credentials4.settings = @{
    [GADMAdapterChartboostConstants appID] : @"ignored_app_id",
    [GADMAdapterChartboostConstants appSignature] : @"ignored_signature"
  };

  // Expectation is that the first two credentials are ignored due to being invalid, third is used,
  // and 4th is ignored because 3 was already valid.
  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = @[ credentials1, credentials2, credentials3, credentials4 ];

  OCMExpect(
      [_mockChartboost addDataUseConsent:[OCMArg checkWithBlock:^BOOL(CHBCOPPADataUseConsent *obj) {
                        return obj.isChildDirected == YES;
                      }]]);

  XCTestExpectation *setUpExpectation = [[XCTestExpectation alloc] init];
  [GADMediationAdapterChartboost setUpWithConfiguration:configuration
                                      completionHandler:^(NSError *_Nullable error) {
                                        XCTAssertNil(error);
                                        [setUpExpectation fulfill];
                                      }];

  [self waitForExpectations:@[ setUpExpectation ]];
  OCMVerifyAll(_mockChartboost);
}

- (void)testSetUpCredentialsWithTagForUnderAgeOfConsentTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  [self mockSuccessfulChartboostStart];

  OCMExpect(
      [_mockChartboost addDataUseConsent:[OCMArg checkWithBlock:^BOOL(CHBCOPPADataUseConsent *obj) {
                        return obj.isChildDirected == YES;
                      }]]);

  [self setUpAdapterWithValidCredentials];
  OCMVerifyAll(_mockChartboost);
}

- (void)testSetUpCredentialsWithTagForUnderAgeOfConsentFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  [self mockSuccessfulChartboostStart];

  OCMExpect(
      [_mockChartboost addDataUseConsent:[OCMArg checkWithBlock:^BOOL(CHBCOPPADataUseConsent *obj) {
                        return obj.isChildDirected == NO;
                      }]]);

  [self setUpAdapterWithValidCredentials];
  OCMVerifyAll(_mockChartboost);
}

- (void)testSetUpCredentialsSuccessWithAgeRestrictedTreatment {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  [self mockSuccessfulChartboostStart];

  OCMExpect(
      [_mockChartboost addDataUseConsent:[OCMArg checkWithBlock:^BOOL(CHBCOPPADataUseConsent *obj) {
                        return obj.isChildDirected == YES;
                      }]]);

  [self setUpAdapterWithValidCredentials];
  OCMVerifyAll(_mockChartboost);
}

- (void)testSetUpCredentialsWithAgeRestrictedTreatmentNotChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  [self mockSuccessfulChartboostStart];

  OCMReject([_mockChartboost addDataUseConsent:[OCMArg checkWithBlock:^BOOL(id obj) {
    return [obj isKindOfClass:[CHBCOPPADataUseConsent class]];
  }]]);

  [self setUpAdapterWithValidCredentials];
  OCMVerifyAll(_mockChartboost);
}

- (void)testSetUpCredentialsChartboostFailure {
  _mockChartboost = OCMClassMock([Chartboost class]);
  CHBStartError *startError = [[CHBStartError alloc] initWithDomain:@"test_domain"
                                                               code:1
                                                           userInfo:nil];
  XCTAssertNotNil(startError);
  OCMExpect(ClassMethod([_mockChartboost
      startWithAppID:@"app_id"
        appSignature:@"signature"
          completion:[OCMArg
                         checkWithBlock:^BOOL(AUTChartboostSetUpCompletionBlock completionBlock) {
                           completionBlock(startError);
                           return YES;
                         }]]));

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    [GADMAdapterChartboostConstants appID] : @"app_id",
    [GADMAdapterChartboostConstants appSignature] : @"signature"
  };

  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = @[ credentials ];

  XCTestExpectation *setUpExpectation = [[XCTestExpectation alloc] init];
  [GADMediationAdapterChartboost
      setUpWithConfiguration:configuration
           completionHandler:^(NSError *_Nullable error) {
             XCTAssertEqualObjects(error.domain, [GADMAdapterChartboostConstants errorDomain]);
             XCTAssertEqual(error.code, GADMAdapterChartboostErrorInitializationFailure);
             [setUpExpectation fulfill];
           }];

  [self waitForExpectations:@[ setUpExpectation ]];
  OCMVerifyAll(_mockChartboost);
}

- (void)testSetUpEmptyCredentials {
  GADMediationServerConfiguration *configuration = [[GADMediationServerConfiguration alloc] init];

  XCTestExpectation *setUpExpectation = [[XCTestExpectation alloc] init];
  [GADMediationAdapterChartboost
      setUpWithConfiguration:configuration
           completionHandler:^(NSError *_Nullable error) {
             XCTAssertEqualObjects(error.domain, [GADMAdapterChartboostConstants errorDomain]);
             XCTAssertEqual(error.code, GADMAdapterChartboostErrorInvalidServerParameters);

             [setUpExpectation fulfill];
           }];

  [self waitForExpectations:@[ setUpExpectation ]];
}

- (void)testSetUpCredentialsMissingAppID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{[GADMAdapterChartboostConstants appSignature] : @"signature"};

  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = @[ credentials ];

  XCTestExpectation *setUpExpectation = [[XCTestExpectation alloc] init];
  [GADMediationAdapterChartboost
      setUpWithConfiguration:configuration
           completionHandler:^(NSError *_Nullable error) {
             XCTAssertEqualObjects(error.domain, [GADMAdapterChartboostConstants errorDomain]);
             XCTAssertEqual(error.code, GADMAdapterChartboostErrorInvalidServerParameters);

             [setUpExpectation fulfill];
           }];

  [self waitForExpectations:@[ setUpExpectation ]];
}

- (void)testSetUpCredentialsMissingSignature {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{[GADMAdapterChartboostConstants appID] : @"app_id"};

  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = @[ credentials ];

  XCTestExpectation *setUpExpectation = [[XCTestExpectation alloc] init];
  [GADMediationAdapterChartboost
      setUpWithConfiguration:configuration
           completionHandler:^(NSError *_Nullable error) {
             XCTAssertEqualObjects(error.domain, [GADMAdapterChartboostConstants errorDomain]);
             XCTAssertEqual(error.code, GADMAdapterChartboostErrorInvalidServerParameters);

             [setUpExpectation fulfill];
           }];

  [self waitForExpectations:@[ setUpExpectation ]];
}

#pragma mark - Additional Consent Initialization tests

- (void)testSetUpCredentialsUnknownACConsent {
  [self mockSuccessfulChartboostStart];

  OCMReject([_mockChartboost addDataUseConsent:[OCMArg any]]);

  [self setUpAdapterWithValidCredentials];
  OCMVerifyAll(_mockChartboost);
}

- (void)testSetUpCredentialsHasTrueACConsent {
  // Sets AC Consent to True
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.2898~dv" forKey:@"IABTCF_AddtlConsent"];

  [self mockSuccessfulChartboostStart];

  OCMExpect(
      [_mockChartboost addDataUseConsent:[OCMArg checkWithBlock:^BOOL(CHBGDPRDataUseConsent *obj) {
                        return obj.consent == CHBGDPRConsentBehavioral;
                      }]]);

  [self setUpAdapterWithValidCredentials];
  OCMVerifyAll(_mockChartboost);
}

- (void)testSetUpCredentialsHasFalseACConsent {
  // Sets AC Consent to False
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.2~dv.2898.3" forKey:@"IABTCF_AddtlConsent"];

  [self mockSuccessfulChartboostStart];

  OCMExpect(
      [_mockChartboost addDataUseConsent:[OCMArg checkWithBlock:^BOOL(CHBGDPRDataUseConsent *obj) {
                        return obj.consent == CHBGDPRConsentNonBehavioral;
                      }]]);

  [self setUpAdapterWithValidCredentials];
  OCMVerifyAll(_mockChartboost);
}


#pragma mark - US Privacy Initialization tests

- (void)testSetUpForwardsUSPrivacyOptOutOfSale {
  [_userDefaults setObject:@"1YYN" forKey:@"IABUSPrivacy_String"];
  [self mockSuccessfulChartboostStart];
  OCMExpect([_mockChartboost
      addDataUseConsent:[OCMArg checkWithBlock:^BOOL(CHBDataUseConsent *obj) {
        return [obj isKindOfClass:[CHBCCPADataUseConsent class]] &&
               ((CHBCCPADataUseConsent *)obj).consent == CHBCCPAConsentOptOutSale;
      }]]);

  [self setUpAdapterWithValidCredentials];
  OCMVerifyAll(_mockChartboost);
}

- (void)testSetUpForwardsUSPrivacyOptInSale {
  [_userDefaults setObject:@"1YNN" forKey:@"IABUSPrivacy_String"];
  [self mockSuccessfulChartboostStart];
  OCMExpect([_mockChartboost
      addDataUseConsent:[OCMArg checkWithBlock:^BOOL(CHBDataUseConsent *obj) {
        return [obj isKindOfClass:[CHBCCPADataUseConsent class]] &&
               ((CHBCCPADataUseConsent *)obj).consent == CHBCCPAConsentOptInSale;
      }]]);

  [self setUpAdapterWithValidCredentials];
  OCMVerifyAll(_mockChartboost);
}

- (void)testSetUpDoesNotForwardUSPrivacyWhenNotApplicable {
  [_userDefaults setObject:@"1---" forKey:@"IABUSPrivacy_String"];
  [self mockSuccessfulChartboostStart];
  OCMReject([_mockChartboost
      addDataUseConsent:[OCMArg checkWithBlock:^BOOL(CHBDataUseConsent *obj) {
        return [obj isKindOfClass:[CHBCCPADataUseConsent class]];
      }]]);

  [self setUpAdapterWithValidCredentials];
  OCMVerifyAll(_mockChartboost);
}

@end
