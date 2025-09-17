#import "GADMediationAdapterUnity.h"

#import <GoogleMobileAds/GoogleMobileAds.h>

#import "AUTUnityTestCase.h"
#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnityUtils.h"

@interface AUTUnityAdapterUtilsTests : AUTUnityTestCase
@end

@implementation AUTUnityAdapterUtilsTests {
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

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultZeroGDPRApplies {
  [_userDefaults setObject:@0 forKey:@"IABTCF_gdprApplies"];

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultMissingGDPRApplies {
  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultMissingAdditionalConsent {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultUnknownSpecVersion {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"0~3234.1~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultInvalidSpecVersion {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"a~3234.1~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultNoConsentedVendor {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultUnityConsented {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~1.3234" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultTrue);
}

- (void)testACConsentResultUnityNotIncluded {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~1.2" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultVersionOneSpecWithUnexpectedParts {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~3234.1~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithInvalidFormat {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~3234.1~ax.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithUnexpectedParts {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~3234.1" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithUnityConsented {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.3234~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultTrue);
}

- (void)testACConsentResultVersionTwoSpecWithUnityDisclosed {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.2~dv.3234.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultFalse);
}

- (void)testACConsentResultVersionTwoSpecWithUnityMissing {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.2~dv.3.4" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

@end
