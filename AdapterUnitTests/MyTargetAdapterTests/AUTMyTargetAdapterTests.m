#import "GADMediationAdapterMyTarget.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <MyTargetSDK/MyTargetSDK.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterMyTargetExtras.h"

@interface AUTMyTargetAdapterTests : XCTestCase

@end

@implementation AUTMyTargetAdapterTests {
  id _mockPrivacy;
  NSUserDefaults *_userDefaults;
}

- (void)setUp {
  [super setUp];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  _mockPrivacy = OCMClassMock([MTRGPrivacy class]);

  _userDefaults = NSUserDefaults.standardUserDefaults;
}

- (void)tearDown {
  [_mockPrivacy stopMocking];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  [_userDefaults removeObjectForKey:@"IABTCF_gdprApplies"];
  [_userDefaults removeObjectForKey:@"IABTCF_AddtlConsent"];
  [super tearDown];
}

- (void)testAdapterVersion {
  GADVersionNumber version = [GADMediationAdapterMyTarget adapterVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 9999);
}

- (void)testAdSDKVersion {
  GADVersionNumber version = [GADMediationAdapterMyTarget adSDKVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 99);
}

- (void)testSetUp {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  OCMReject(ClassMethod([_mockPrivacy setUserAgeRestricted:OCMOCK_ANY]));

  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterMyTarget class], credentials);
  OCMVerifyAll(_mockPrivacy);
}

- (void)testSetUpWithChildDirectedSetToYes {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterMyTarget class], credentials);
  OCMVerifyAll(_mockPrivacy);
}

- (void)testSetUpWithChildDirectedSetToNo {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:NO]));

  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterMyTarget class], credentials);
  OCMVerifyAll(_mockPrivacy);
}

- (void)testSetUpWithTagForUnderAgeYES {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterMyTarget class], credentials);
  OCMVerifyAll(_mockPrivacy);
}

- (void)testSetUpWithTagForUnderAgeNo {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:NO]));

  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterMyTarget class], credentials);
  OCMVerifyAll(_mockPrivacy);
}

- (void)testSetUpWithAgeRestrictedTreatmentChild {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterMyTarget class], credentials);
  OCMVerifyAll(_mockPrivacy);
}

- (void)testSetUpWithAgeRestrictedTreatmentTeen {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterMyTarget class], credentials);
  OCMVerifyAll(_mockPrivacy);
}

- (void)testNetworkExtrasClass {
  XCTAssertEqual([GADMediationAdapterMyTarget networkExtrasClass],
                 [GADMAdapterMyTargetExtras class]);
}

#pragma mark - Additional Consent Initialization tests

- (void)testSetUpCredentialsUnknownACConsent {
  OCMReject(ClassMethod([_mockPrivacy setUserConsent:OCMOCK_ANY]));

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterMyTarget class], credentials);
  OCMVerifyAll(_mockPrivacy);
}

- (void)testSetUpCredentialsHasTrueACConsent {
  // Sets AC Consent to True
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.1067~dv" forKey:@"IABTCF_AddtlConsent"];

  OCMExpect(ClassMethod([_mockPrivacy setUserConsent:YES]));

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterMyTarget class], credentials);
  OCMVerifyAll(_mockPrivacy);
}

- (void)testSetUpCredentialsHasFalseACConsent {
  // Sets AC Consent to False
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.2~dv.1067.3" forKey:@"IABTCF_AddtlConsent"];

  OCMExpect(ClassMethod([_mockPrivacy setUserConsent:NO]));

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterMyTarget class], credentials);
  OCMVerifyAll(_mockPrivacy);
}

@end
