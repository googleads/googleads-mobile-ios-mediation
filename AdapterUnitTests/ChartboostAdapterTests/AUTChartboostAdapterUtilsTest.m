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

#import "ChartboostAdapter.h"

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterChartboostConstants.h"
#import "GADMAdapterChartboostUtils.h"

@interface AUTChartboostAdapterUtilsTests : XCTestCase
@end

@implementation AUTChartboostAdapterUtilsTests {
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

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent(GADMAdapterChartboostAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultZeroGDPRApplies {
  [_userDefaults setObject:@0 forKey:@"IABTCF_gdprApplies"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent(GADMAdapterChartboostAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultMissingGDPRApplies {
  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent(GADMAdapterChartboostAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultMissingAdditionalConsent {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent(GADMAdapterChartboostAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultUnknownSpecVersion {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"0~2898.1~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent(GADMAdapterChartboostAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultInvalidSpecVersion {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"a~2898.1~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent(GADMAdapterChartboostAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultNoConsentedVendor {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent(GADMAdapterChartboostAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultChartboostConsented {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~1.2898" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent(GADMAdapterChartboostAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultTrue);
}

- (void)testACConsentResultChartboostNotIncluded {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~1.2" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent(GADMAdapterChartboostAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultVersionOneSpecWithUnexpectedParts {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~2898.1~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent(GADMAdapterChartboostAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithInvalidFormat {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~2898.1~ax.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent(GADMAdapterChartboostAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithUnexpectedParts {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~2898.1" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent(GADMAdapterChartboostAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithChartboostConsented {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.2898~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent(GADMAdapterChartboostAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultTrue);
}

- (void)testACConsentResultVersionTwoSpecWithChartboostConsentedWithNoneDisclosed {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.2898~dv" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent(GADMAdapterChartboostAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultTrue);
}

- (void)testACConsentResultVersionTwoSpecWithChartboostDisclosed {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.2~dv.2898.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent(GADMAdapterChartboostAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultFalse);
}

- (void)testACConsentResultVersionTwoSpecWithChartboostMissing {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.2~dv.3.4" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent(GADMAdapterChartboostAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

@end
