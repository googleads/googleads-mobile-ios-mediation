#import "GADMediationAdapterPangle.h"

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterPangleUtils.h"
#import "GADMediationAdapterPangleConstants.h"

@interface AUTPangleAdapterUtilsTests : XCTestCase
@end

@implementation AUTPangleAdapterUtilsTests {
  NSUserDefaults *_userDefaults;
}

- (void)setUp {
  _userDefaults = NSUserDefaults.standardUserDefaults;
}

- (void)tearDown {
  [_userDefaults removeObjectForKey:@"IABTCF_gdprApplies"];
  [_userDefaults removeObjectForKey:@"IABTCF_AddtlConsent"];
}

- (void)testACConsentResultNegativeGDPRApplies {
  [_userDefaults setObject:@-1 forKey:@"IABTCF_gdprApplies"];

  GADMAdapterPangleConsentResult consentResult =
      GADMAdapterPangleHasACConsent(GADMAdapterPangleAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterPangleConsentResultUnknown);
}

- (void)testACConsentResultZeroGDPRApplies {
  [_userDefaults setObject:@0 forKey:@"IABTCF_gdprApplies"];

  GADMAdapterPangleConsentResult consentResult =
      GADMAdapterPangleHasACConsent(GADMAdapterPangleAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterPangleConsentResultUnknown);
}

- (void)testACConsentResultMissingGDPRApplies {
  GADMAdapterPangleConsentResult consentResult =
      GADMAdapterPangleHasACConsent(GADMAdapterPangleAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterPangleConsentResultUnknown);
}

- (void)testACConsentResultMissingAdditionalConsent {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];

  GADMAdapterPangleConsentResult consentResult =
      GADMAdapterPangleHasACConsent(GADMAdapterPangleAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterPangleConsentResultUnknown);
}

- (void)testACConsentResultUnknownSpecVersion {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"0~3100.1~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterPangleConsentResult consentResult =
      GADMAdapterPangleHasACConsent(GADMAdapterPangleAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterPangleConsentResultUnknown);
}

- (void)testACConsentResultInvalidSpecVersion {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"a~3100.1~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterPangleConsentResult consentResult =
      GADMAdapterPangleHasACConsent(GADMAdapterPangleAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterPangleConsentResultUnknown);
}

- (void)testACConsentResultNoConsentedVendor {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterPangleConsentResult consentResult =
      GADMAdapterPangleHasACConsent(GADMAdapterPangleAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterPangleConsentResultUnknown);
}

- (void)testACConsentResultPangleConsented {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~1.3100" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterPangleConsentResult consentResult =
      GADMAdapterPangleHasACConsent(GADMAdapterPangleAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterPangleConsentResultTrue);
}

- (void)testACConsentResultPangleNotIncluded {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~1.2" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterPangleConsentResult consentResult =
      GADMAdapterPangleHasACConsent(GADMAdapterPangleAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterPangleConsentResultUnknown);
}

- (void)testACConsentResultVersionOneSpecWithUnexpectedParts {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~3100.1~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterPangleConsentResult consentResult =
      GADMAdapterPangleHasACConsent(GADMAdapterPangleAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterPangleConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithInvalidFormat {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~3100.1~ax.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterPangleConsentResult consentResult =
      GADMAdapterPangleHasACConsent(GADMAdapterPangleAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterPangleConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithUnexpectedParts {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~3100.1" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterPangleConsentResult consentResult =
      GADMAdapterPangleHasACConsent(GADMAdapterPangleAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterPangleConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithPangleConsented {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.3100~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterPangleConsentResult consentResult =
      GADMAdapterPangleHasACConsent(GADMAdapterPangleAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterPangleConsentResultTrue);
}

- (void)testACConsentResultVersionTwoSpecWithPangleDisclosed {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.2~dv.3100.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterPangleConsentResult consentResult =
      GADMAdapterPangleHasACConsent(GADMAdapterPangleAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterPangleConsentResultFalse);
}

- (void)testACConsentResultVersionTwoSpecWithPangleMissing {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.2~dv.3.4" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterPangleConsentResult consentResult =
      GADMAdapterPangleHasACConsent(GADMAdapterPangleAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterPangleConsentResultUnknown);
}

@end
