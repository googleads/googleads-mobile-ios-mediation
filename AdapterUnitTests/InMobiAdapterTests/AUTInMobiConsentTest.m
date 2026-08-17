#import "GADMInMobiConsent.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <InMobiSDK/InMobiSDK-Swift.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AUTInMobiUtils.h"
#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiInitializer.h"
#import "GADMAdapterInMobiUtils.h"

@interface AUTInMobiConsentTest : XCTestCase
@end

@implementation AUTInMobiConsentTest {
  id _imsdkMock;
  id _initializerMock;
  id _privacyComplianceMock;
}

- (void)setUp {
  [super setUp];
  _imsdkMock = OCMClassMock([IMSdk class]);
  _privacyComplianceMock = OCMClassMock([IMPrivacyCompliance class]);
}

- (void)tearDown {
  // Reset the static global consent dictionary.
  [GADMInMobiConsent updateGDPRConsent:nil];

  // Reset COPPA and child-directed settings.
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  [NSUserDefaults.standardUserDefaults removeObjectForKey:GADMAdapterInMobiIABUSPrivacyString];

  [_imsdkMock stopMocking];
  _imsdkMock = nil;
  [_initializerMock stopMocking];
  _initializerMock = nil;
  [_privacyComplianceMock stopMocking];
  _privacyComplianceMock = nil;

  [super tearDown];
}

- (void)testUpdateGDPRConsentWhenInitialized {
  OCMStub(ClassMethod([_imsdkMock initWithAccountID:OCMOCK_ANY
                                  consentDictionary:OCMOCK_ANY
                               andCompletionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionBlock)(NSError *_Nullable);
        [invocation getArgument:&completionBlock atIndex:4];
        completionBlock(nil);
      });

  GADMAdapterInMobiInitializer *initializer = [[GADMAdapterInMobiInitializer alloc] init];
  [initializer initializeWithAccountID:AUTInMobiAccountID
                     completionHandler:^(NSError *_Nullable error){
                     }];
  _initializerMock = OCMClassMock([GADMAdapterInMobiInitializer class]);
  OCMStub([_initializerMock sharedInstance]).andReturn(initializer);

  NSDictionary<NSString *, NSString *> *expectedConsent = @{
    @"gdpr" : @"1",
    @"gdpr_consent" : @"CP12345ABCDE",
  };

  OCMExpect([_imsdkMock updateGDPRConsent:expectedConsent]);
  [GADMInMobiConsent updateGDPRConsent:expectedConsent];

  XCTAssertEqualObjects(GADMInMobiConsent.consent, expectedConsent);
  OCMVerifyAll(_imsdkMock);
}

- (void)testUpdateGDPRConsentWhenUninitialized {
  GADMAdapterInMobiInitializer *initializer = [[GADMAdapterInMobiInitializer alloc] init];
  _initializerMock = OCMClassMock([GADMAdapterInMobiInitializer class]);
  OCMStub([_initializerMock sharedInstance]).andReturn(initializer);

  OCMReject([_imsdkMock updateGDPRConsent:OCMOCK_ANY]);

  NSDictionary<NSString *, NSString *> *expectedConsent = @{
    @"gdpr" : @"1",
    @"gdpr_consent" : @"CP12345ABCDE",
  };

  [GADMInMobiConsent updateGDPRConsent:expectedConsent];
  XCTAssertEqualObjects(GADMInMobiConsent.consent, expectedConsent);
}

- (void)testGDPRTCFConsentDictionaryFormatting {
  NSDictionary<NSString *, NSString *> *tcfConsent = @{
    @"gdpr" : @"1",
    @"gdpr_consent" : @"CP12345ABCDE",
    @"gdpr_consent_available" : @"true",
  };

  [GADMInMobiConsent updateGDPRConsent:tcfConsent];

  XCTAssertEqualObjects(GADMInMobiConsent.consent[@"gdpr"], @"1");
  XCTAssertEqualObjects(GADMInMobiConsent.consent[@"gdpr_consent"], @"CP12345ABCDE");
  XCTAssertEqualObjects(GADMInMobiConsent.consent[@"gdpr_consent_available"], @"true");
}

- (void)testCCPADoNotSellComplianceWithValidString {
  NSString *expectedUSPrivacyString = @"1YNN";
  [NSUserDefaults.standardUserDefaults setObject:expectedUSPrivacyString
                                          forKey:GADMAdapterInMobiIABUSPrivacyString];

  OCMExpect(ClassMethod([_privacyComplianceMock setUSPrivacyString:expectedUSPrivacyString]));

  GADMAdapterInMobiSetUSPrivacyCompliance();

  OCMVerifyAll(_privacyComplianceMock);
}

- (void)testCCPADoNotSellComplianceWithEmptyOrMissingString {
  [NSUserDefaults.standardUserDefaults removeObjectForKey:GADMAdapterInMobiIABUSPrivacyString];
  OCMExpect(ClassMethod([_privacyComplianceMock setUSPrivacyString:nil]));

  GADMAdapterInMobiSetUSPrivacyCompliance();

  OCMVerifyAll(_privacyComplianceMock);
}

- (void)testCOPPAAgeRestrictionChildDirectedTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];

  OCMExpect([_imsdkMock setIsAgeRestricted:YES]);
  GADMAdapterInMobiSetTargetingFromAdConfiguration(configuration);
  OCMVerifyAll(_imsdkMock);

  NSDictionary<NSString *, id> *params = GADMAdapterInMobiRequestParameters(
      nil, GADMAdapterInMobiRequestParametersMediationTypeWaterfall);
  XCTAssertEqualObjects(params[GADMAdapterInMobiRequestParametersCOPPAKey], @"1");
}

- (void)testCOPPAAgeRestrictionUnderAgeOfConsentTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];

  OCMExpect([_imsdkMock setIsAgeRestricted:YES]);
  GADMAdapterInMobiSetTargetingFromAdConfiguration(configuration);
  OCMVerifyAll(_imsdkMock);

  NSDictionary<NSString *, id> *params = GADMAdapterInMobiRequestParameters(
      nil, GADMAdapterInMobiRequestParametersMediationTypeWaterfall);
  XCTAssertEqualObjects(params[GADMAdapterInMobiRequestParametersCOPPAKey], @"1");
}

- (void)testCOPPAAgeRestrictionTreatmentChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];

  OCMExpect([_imsdkMock setIsAgeRestricted:YES]);
  GADMAdapterInMobiSetTargetingFromAdConfiguration(configuration);
  OCMVerifyAll(_imsdkMock);

  NSDictionary<NSString *, id> *params = GADMAdapterInMobiRequestParameters(
      nil, GADMAdapterInMobiRequestParametersMediationTypeWaterfall);
  XCTAssertEqualObjects(params[GADMAdapterInMobiRequestParametersCOPPAKey], @"1");
}

- (void)testCOPPAAgeRestrictionExplicitlyFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];

  OCMExpect([_imsdkMock setIsAgeRestricted:NO]);
  GADMAdapterInMobiSetTargetingFromAdConfiguration(configuration);
  OCMVerifyAll(_imsdkMock);

  NSDictionary<NSString *, id> *params = GADMAdapterInMobiRequestParameters(
      nil, GADMAdapterInMobiRequestParametersMediationTypeWaterfall);
  XCTAssertEqualObjects(params[GADMAdapterInMobiRequestParametersCOPPAKey], @"0");
}

- (void)testCOPPAAgeRestrictionUnspecified {
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];

  OCMExpect([_imsdkMock setIsAgeRestricted:NO]);
  GADMAdapterInMobiSetTargetingFromAdConfiguration(configuration);
  OCMVerifyAll(_imsdkMock);

  NSDictionary<NSString *, id> *params = GADMAdapterInMobiRequestParameters(
      nil, GADMAdapterInMobiRequestParametersMediationTypeWaterfall);
  XCTAssertNil(params[GADMAdapterInMobiRequestParametersCOPPAKey]);
}

@end
