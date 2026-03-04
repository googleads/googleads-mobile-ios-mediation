// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMediationAdapterMyTarget.h"

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetUtils.h"

@interface AUTMyTargetAdapterUtilsTests : XCTestCase
@end

@implementation AUTMyTargetAdapterUtilsTests {
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

  GADMAdapterMyTargetConsentResult consentResult =
      GADMAdapterMyTargetHasACConsent(GADMAdapterMyTargetAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterMyTargetConsentResultUnknown);
}

- (void)testACConsentResultZeroGDPRApplies {
  [_userDefaults setObject:@0 forKey:@"IABTCF_gdprApplies"];

  GADMAdapterMyTargetConsentResult consentResult =
      GADMAdapterMyTargetHasACConsent(GADMAdapterMyTargetAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterMyTargetConsentResultUnknown);
}

- (void)testACConsentResultMissingGDPRApplies {
  GADMAdapterMyTargetConsentResult consentResult =
      GADMAdapterMyTargetHasACConsent(GADMAdapterMyTargetAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterMyTargetConsentResultUnknown);
}

- (void)testACConsentResultMissingAdditionalConsent {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];

  GADMAdapterMyTargetConsentResult consentResult =
      GADMAdapterMyTargetHasACConsent(GADMAdapterMyTargetAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterMyTargetConsentResultUnknown);
}

- (void)testACConsentResultUnknownSpecVersion {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"0~1067.1~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterMyTargetConsentResult consentResult =
      GADMAdapterMyTargetHasACConsent(GADMAdapterMyTargetAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterMyTargetConsentResultUnknown);
}

- (void)testACConsentResultInvalidSpecVersion {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"a~1067.1~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterMyTargetConsentResult consentResult =
      GADMAdapterMyTargetHasACConsent(GADMAdapterMyTargetAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterMyTargetConsentResultUnknown);
}

- (void)testACConsentResultNoConsentedVendor {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterMyTargetConsentResult consentResult =
      GADMAdapterMyTargetHasACConsent(GADMAdapterMyTargetAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterMyTargetConsentResultUnknown);
}

- (void)testACConsentResultMyTargetConsented {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~1.1067" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterMyTargetConsentResult consentResult =
      GADMAdapterMyTargetHasACConsent(GADMAdapterMyTargetAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterMyTargetConsentResultTrue);
}

- (void)testACConsentResultMyTargetNotIncluded {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~1.2" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterMyTargetConsentResult consentResult =
      GADMAdapterMyTargetHasACConsent(GADMAdapterMyTargetAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterMyTargetConsentResultUnknown);
}

- (void)testACConsentResultVersionOneSpecWithUnexpectedParts {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~1067.1~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterMyTargetConsentResult consentResult =
      GADMAdapterMyTargetHasACConsent(GADMAdapterMyTargetAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterMyTargetConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithInvalidFormat {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1067.1~ax.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterMyTargetConsentResult consentResult =
      GADMAdapterMyTargetHasACConsent(GADMAdapterMyTargetAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterMyTargetConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithUnexpectedParts {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1067.1" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterMyTargetConsentResult consentResult =
      GADMAdapterMyTargetHasACConsent(GADMAdapterMyTargetAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterMyTargetConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithMyTargetConsented {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.1067~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterMyTargetConsentResult consentResult =
      GADMAdapterMyTargetHasACConsent(GADMAdapterMyTargetAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterMyTargetConsentResultTrue);
}

- (void)testACConsentResultVersionTwoSpecWithMyTargetDisclosed {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.2~dv.1067.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterMyTargetConsentResult consentResult =
      GADMAdapterMyTargetHasACConsent(GADMAdapterMyTargetAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterMyTargetConsentResultFalse);
}

- (void)testACConsentResultVersionTwoSpecWithMyTargetMissing {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.2~dv.3.4" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterMyTargetConsentResult consentResult =
      GADMAdapterMyTargetHasACConsent(GADMAdapterMyTargetAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterMyTargetConsentResultUnknown);
}

@end
