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
#import "GADMediationAdapterChartboost.h"

#import <ChartboostSDK/ChartboostSDK.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <XCTest/XCTest.h>

#import "ChartboostAdapter-Swift.h"
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
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultZeroGDPRApplies {
  [_userDefaults setObject:@0 forKey:@"IABTCF_gdprApplies"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultMissingGDPRApplies {
  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultMissingAdditionalConsent {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultEmptyAdditionalConsent {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultUnknownSpecVersion {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"0~2898.1~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultInvalidSpecVersion {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"a~2898.1~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultNoConsentedVendor {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultChartboostConsented {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~1.2898" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultTrue);
}

- (void)testACConsentResultChartboostNotIncluded {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~1.2" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultVersionOneSpecWithUnexpectedParts {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"1~2898.1~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithInvalidFormat {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~2898.1~ax.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithUnexpectedParts {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~2898.1" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithChartboostConsented {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.2898~dv.2.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultTrue);
}

- (void)testACConsentResultVersionTwoSpecWithChartboostConsentedWithNoneDisclosed {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.2898~dv" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultTrue);
}

- (void)testACConsentResultVersionTwoSpecWithChartboostDisclosed {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.2~dv.2898.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultFalse);
}

- (void)testACConsentResultVersionTwoSpecWithChartboostMissing {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.2~dv.3.4" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithEmptyDisclosed {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~~dv.3.4" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithEmptyDisclosedWithChartboostDisclosed {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~~dv.2898.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterChartboostConsentResult consentResult =
      GADMAdapterChartboostHasACConsent([GADMAdapterChartboostConstants adTechnologyProviderID]);
  XCTAssertEqual(consentResult, GADMAdapterChartboostConsentResultFalse);
}

#pragma mark - Trimmed Credential Tests

- (void)testTrimmedCredentialTrimsSurroundingWhitespace {
  NSDictionary *settings = @{[GADMAdapterChartboostConstants appSignature] : @"  signature  "};
  NSString *value = GADMAdapterChartboostTrimmedCredential(
      settings, [GADMAdapterChartboostConstants appSignature]);
  XCTAssertEqualObjects(value, @"signature");
}

- (void)testTrimmedCredentialLeavesCleanValueUnchanged {
  NSDictionary *settings = @{[GADMAdapterChartboostConstants appID] : @"app-id"};
  NSString *value =
      GADMAdapterChartboostTrimmedCredential(settings, [GADMAdapterChartboostConstants appID]);
  XCTAssertEqualObjects(value, @"app-id");
}

- (void)testTrimmedCredentialMissingKeyReturnsNil {
  NSString *value =
      GADMAdapterChartboostTrimmedCredential(@{}, [GADMAdapterChartboostConstants appID]);
  XCTAssertNil(value);
}

- (void)testTrimmedCredentialWhitespaceOnlyTrimsToEmpty {
  NSDictionary *settings = @{[GADMAdapterChartboostConstants appID] : @"   "};
  NSString *value =
      GADMAdapterChartboostTrimmedCredential(settings, [GADMAdapterChartboostConstants appID]);
  XCTAssertEqualObjects(value, @"");
}

#pragma mark - Banner Size Tests

- (void)testBannerSizeFromAdSizeBanner {
  NSError *error = nil;
  CHBBannerSize size = GADMAdapterChartboostBannerSizeFromAdSize(GADAdSizeBanner, &error);
  XCTAssertNil(error);
  XCTAssertEqual(size.width, CHBBannerSizeStandard.width);
  XCTAssertEqual(size.height, CHBBannerSizeStandard.height);
}

- (void)testBannerSizeFromAdSizeMediumRectangle {
  NSError *error = nil;
  CHBBannerSize size = GADMAdapterChartboostBannerSizeFromAdSize(GADAdSizeMediumRectangle, &error);
  XCTAssertNil(error);
  XCTAssertEqual(size.width, CHBBannerSizeMedium.width);
  XCTAssertEqual(size.height, CHBBannerSizeMedium.height);
}

- (void)testBannerSizeFromAdSizeLeaderboard {
  NSError *error = nil;
  CHBBannerSize size = GADMAdapterChartboostBannerSizeFromAdSize(GADAdSizeLeaderboard, &error);
  XCTAssertNil(error);
  XCTAssertEqual(size.width, CHBBannerSizeLeaderboard.width);
  XCTAssertEqual(size.height, CHBBannerSizeLeaderboard.height);
}

- (void)testBannerSizeFromAdSizeInvalid {
  NSError *error = nil;
  CHBBannerSize size = GADMAdapterChartboostBannerSizeFromAdSize(
      GADAdSizeFromCGSize(CGSizeMake(100, 100)), &error);
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.domain, [GADMAdapterChartboostConstants errorDomain]);
  XCTAssertEqual(error.code, GADMAdapterChartboostErrorBannerSizeMismatch);
  XCTAssertEqual(size.width, 0);
  XCTAssertEqual(size.height, 0);
}

- (void)testBannerSizeFromAdSizeInvalidWithoutErrorPointer {
  CHBBannerSize size = GADMAdapterChartboostBannerSizeFromAdSize(
      GADAdSizeFromCGSize(CGSizeMake(100, 100)), NULL);
  XCTAssertEqual(size.width, 0);
  XCTAssertEqual(size.height, 0);
}

#pragma mark - Error Mapping Tests

- (void)testErrorForCacheError {
  NSDictionary<NSNumber *, NSString *> *expectedMappings = @{
    @0 : @"CHBCacheErrorCodeInternalError",
    @1 : @"CHBCacheErrorCodeInternetUnavailable",
    @2 : @"CHBCacheErrorCodeNetworkFailure",
    @3 : @"CHBCacheErrorCodeNoAdFound",
    @4 : @"CHBCacheErrorCodeSessionNotStarted",
    @5 : @"CHBCacheErrorCodeAssetDownloadFailure",
    @6 : @"CHBCacheErrorCodePublisherDisabled",
    @7 : @"CHBCacheErrorCodeServerError",
    @999 : @"code 999",
  };

  [expectedMappings enumerateKeysAndObjectsUsingBlock:^(NSNumber *codeKey, NSString *suffix,
                                                        BOOL *stop) {
    NSInteger code = codeKey.integerValue;
    CHBCacheError *cbError = [[CHBCacheError alloc] initWithDomain:@"test_domain"
                                                              code:code
                                                          userInfo:nil];
    NSError *error = [GADMChartboostError errorForCacheError:cbError];
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, [GADMAdapterChartboostConstants errorDomain]);
    XCTAssertEqual(error.code, 200 + code);
    NSString *expectedDescription =
        [NSString stringWithFormat:@"Chartboost SDK returned a cache error: %@", suffix];
    XCTAssertEqualObjects(error.localizedDescription, expectedDescription);
    XCTAssertEqualObjects(error.localizedFailureReason, expectedDescription);
  }];
}

- (void)testErrorForShowError {
  NSDictionary<NSNumber *, NSString *> *expectedMappings = @{
    @0 : @"CHBShowErrorCodeInternalError",
    @1 : @"CHBShowErrorCodeSessionNotStarted",
    @2 : @"CHBShowErrorCodeInternetUnavailable",
    @3 : @"CHBShowErrorCodePresentationFailure",
    @4 : @"CHBShowErrorCodeNoCachedAd",
    @5 : @"CHBShowErrorCodeNoViewController",
    @999 : @"code 999",
  };

  [expectedMappings enumerateKeysAndObjectsUsingBlock:^(NSNumber *codeKey, NSString *suffix,
                                                        BOOL *stop) {
    NSInteger code = codeKey.integerValue;
    CHBShowError *cbError = [[CHBShowError alloc] initWithDomain:@"test_domain"
                                                            code:code
                                                        userInfo:nil];
    NSError *error = [GADMChartboostError errorForShowError:cbError];
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, [GADMAdapterChartboostConstants errorDomain]);
    XCTAssertEqual(error.code, 300 + code);
    NSString *expectedDescription =
        [NSString stringWithFormat:@"Chartboost SDK returned a show error: %@", suffix];
    XCTAssertEqualObjects(error.localizedDescription, expectedDescription);
    XCTAssertEqualObjects(error.localizedFailureReason, expectedDescription);
  }];
}

- (void)testErrorForClickError {
  NSDictionary<NSNumber *, NSString *> *expectedMappings = @{
    @0 : @"CHBClickErrorCodeUriInvalid",
    @1 : @"CHBClickErrorCodeUriUnrecognized",
    @2 : @"CHBClickErrorCodeInternalError",
    @999 : @"code 999",
  };

  [expectedMappings enumerateKeysAndObjectsUsingBlock:^(NSNumber *codeKey, NSString *suffix,
                                                        BOOL *stop) {
    NSInteger code = codeKey.integerValue;
    CHBClickError *cbError = [[CHBClickError alloc] initWithDomain:@"test_domain"
                                                              code:code
                                                          userInfo:nil];
    NSError *error = [GADMChartboostError errorForClickError:cbError];
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, [GADMAdapterChartboostConstants errorDomain]);
    XCTAssertEqual(error.code, 400 + code);
    NSString *expectedDescription =
        [NSString stringWithFormat:@"Chartboost SDK returned a click error: %@", suffix];
    XCTAssertEqualObjects(error.localizedDescription, expectedDescription);
    XCTAssertEqualObjects(error.localizedFailureReason, expectedDescription);
  }];
}

@end
