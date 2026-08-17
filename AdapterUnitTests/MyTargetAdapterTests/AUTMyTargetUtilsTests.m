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
#import <MyTargetSDK/MyTargetSDK.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtras.h"
#import "GADMAdapterMyTargetUtils.h"

@interface AUTMyTargetAdapterUtilsTests : XCTestCase
@end

@implementation AUTMyTargetAdapterUtilsTests {
  NSUserDefaults *_userDefaults;
}

- (void)setUp {
  [super setUp];
  _userDefaults = NSUserDefaults.standardUserDefaults;
}

- (void)tearDown {
  [_userDefaults removeObjectForKey:@"IABTCF_gdprApplies"];
  [_userDefaults removeObjectForKey:@"IABTCF_AddtlConsent"];
  GADMAdapterMyTargetUtils.logEnabled = YES;
  [super tearDown];
}

#pragma mark - Size Conversion Tests

- (void)testSizeFromRequestedSizeStandardBanner {
  NSError *error = nil;
  MTRGAdSize *size = GADMAdapterMyTargetSizeFromRequestedSize(GADAdSizeBanner, &error);
  XCTAssertNil(error);
  XCTAssertNotNil(size);
  XCTAssertEqual(size.size.width, 320);
  XCTAssertEqual(size.size.height, 50);
}

- (void)testSizeFromRequestedSizeMediumRectangle {
  NSError *error = nil;
  MTRGAdSize *size = GADMAdapterMyTargetSizeFromRequestedSize(GADAdSizeMediumRectangle, &error);
  XCTAssertNil(error);
  XCTAssertNotNil(size);
  XCTAssertEqual(size.size.width, 300);
  XCTAssertEqual(size.size.height, 250);
}

- (void)testSizeFromRequestedSizeLeaderboard {
  NSError *error = nil;
  MTRGAdSize *size = GADMAdapterMyTargetSizeFromRequestedSize(GADAdSizeLeaderboard, &error);
  XCTAssertNil(error);
  XCTAssertNotNil(size);
  XCTAssertEqual(size.size.width, 728);
  XCTAssertEqual(size.size.height, 90);
}

- (void)testSizeFromRequestedSizeAdaptive {
  NSError *error = nil;
  GADAdSize adaptiveSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(320);
  MTRGAdSize *size = GADMAdapterMyTargetSizeFromRequestedSize(adaptiveSize, &error);
  XCTAssertNil(error);
  XCTAssertNotNil(size);
  MTRGAdSize *expectedSize = [MTRGAdSize adSizeForCurrentOrientationForWidth:320];
  XCTAssertEqual(size.size.width, expectedSize.size.width);
  XCTAssertEqual(size.size.height, expectedSize.size.height);
}

- (void)testSizeFromRequestedSizeInvalid {
  NSError *error = nil;
  MTRGAdSize *size = GADMAdapterMyTargetSizeFromRequestedSize(GADAdSizeInvalid, &error);
  XCTAssertNil(size);
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.domain, GADMAdapterMyTargetAdapterErrorDomain);
  XCTAssertEqual(error.code, GADMAdapterMyTargetErrorBannerSizeMismatch);
}

- (void)testSizeFromRequestedSizeUnsupportedSize {
  NSError *error = nil;
  GADAdSize unsupportedSize = GADAdSizeFromCGSize(CGSizeMake(10, 10));
  MTRGAdSize *size = GADMAdapterMyTargetSizeFromRequestedSize(unsupportedSize, &error);
  XCTAssertNil(size);
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.domain, GADMAdapterMyTargetAdapterErrorDomain);
  XCTAssertEqual(error.code, GADMAdapterMyTargetErrorBannerSizeMismatch);
}

- (void)testSizeFromRequestedSizeWithoutErrorPointer {
  MTRGAdSize *size = GADMAdapterMyTargetSizeFromRequestedSize(GADAdSizeInvalid, NULL);
  XCTAssertNil(size);
}

#pragma mark - Custom Params Tests

- (void)testFillCustomParamsWithValidExtras {
  GADMAdapterMyTargetExtras *extras = [[GADMAdapterMyTargetExtras alloc] init];
  [extras setParameter:@"value1" forKey:@"key1"];
  [extras setParameter:@"value2" forKey:@"key2"];

  MTRGCustomParams *customParams = [[MTRGCustomParams alloc] init];
  id customParamsMock = OCMPartialMock(customParams);
  OCMExpect([customParamsMock setCustomParam:@"value1" forKey:@"key1"]);
  OCMExpect([customParamsMock setCustomParam:@"value2" forKey:@"key2"]);

  GADMAdapterMyTargetFillCustomParams(customParamsMock, extras);

  OCMVerifyAll(customParamsMock);
  [customParamsMock stopMocking];
}

- (void)testFillCustomParamsWithNilExtras {
  MTRGCustomParams *customParams = [[MTRGCustomParams alloc] init];
  id customParamsMock = OCMPartialMock(customParams);
  OCMReject([customParamsMock setCustomParam:OCMOCK_ANY forKey:OCMOCK_ANY]);

  GADMAdapterMyTargetFillCustomParams(customParamsMock, nil);

  OCMVerifyAll(customParamsMock);
  [customParamsMock stopMocking];
}

- (void)testFillCustomParamsWithNonMyTargetExtras {
  MTRGCustomParams *customParams = [[MTRGCustomParams alloc] init];
  id customParamsMock = OCMPartialMock(customParams);
  OCMReject([customParamsMock setCustomParam:OCMOCK_ANY forKey:OCMOCK_ANY]);

  id dummyExtras = OCMProtocolMock(@protocol(GADAdNetworkExtras));
  GADMAdapterMyTargetFillCustomParams(customParamsMock, dummyExtras);

  OCMVerifyAll(customParamsMock);
  [dummyExtras stopMocking];
  [customParamsMock stopMocking];
}

- (void)testFillCustomParamsWithEmptyParameters {
  GADMAdapterMyTargetExtras *extras = [[GADMAdapterMyTargetExtras alloc] init];
  MTRGCustomParams *customParams = [[MTRGCustomParams alloc] init];
  id customParamsMock = OCMPartialMock(customParams);
  OCMReject([customParamsMock setCustomParam:OCMOCK_ANY forKey:OCMOCK_ANY]);

  GADMAdapterMyTargetFillCustomParams(customParamsMock, extras);

  OCMVerifyAll(customParamsMock);
  [customParamsMock stopMocking];
}

#pragma mark - Slot ID Extraction Tests

- (void)testSlotIdFromNumericString {
  NSDictionary<NSString *, id> *credentials = @{
    GADMAdapterMyTargetSlotIdKey : @"12345",
  };
  NSUInteger slotId = GADMAdapterMyTargetSlotIdFromCredentials(credentials);
  XCTAssertEqual(slotId, 12345);
}

- (void)testSlotIdFromNSNumber {
  NSDictionary<NSString *, id> *credentials = @{
    GADMAdapterMyTargetSlotIdKey : @(12345),
  };
  NSUInteger slotId = GADMAdapterMyTargetSlotIdFromCredentials(credentials);
  XCTAssertEqual(slotId, 12345);
}

- (void)testSlotIdFromEmptyString {
  NSDictionary<NSString *, id> *credentials = @{
    GADMAdapterMyTargetSlotIdKey : @"",
  };
  NSUInteger slotId = GADMAdapterMyTargetSlotIdFromCredentials(credentials);
  XCTAssertEqual(slotId, 0);
}

- (void)testSlotIdFromNonNumericString {
  NSDictionary<NSString *, id> *credentials = @{
    GADMAdapterMyTargetSlotIdKey : @"foobar",
  };
  NSUInteger slotId = GADMAdapterMyTargetSlotIdFromCredentials(credentials);
  XCTAssertEqual(slotId, 0);
}

- (void)testSlotIdFromNilCredentials {
  NSUInteger slotId = GADMAdapterMyTargetSlotIdFromCredentials(nil);
  XCTAssertEqual(slotId, 0);
}

- (void)testSlotIdFromEmptyCredentials {
  NSUInteger slotId = GADMAdapterMyTargetSlotIdFromCredentials(@{});
  XCTAssertEqual(slotId, 0);
}

- (void)testSlotIdFromZeroNumber {
  NSDictionary<NSString *, id> *credentials = @{
    GADMAdapterMyTargetSlotIdKey : @0,
  };
  NSUInteger slotId = GADMAdapterMyTargetSlotIdFromCredentials(credentials);
  XCTAssertEqual(slotId, 0);
}

- (void)testSlotIdFromUnsupportedType {
  NSDictionary<NSString *, id> *credentials = @{
    GADMAdapterMyTargetSlotIdKey : [NSNull null],
  };
  NSUInteger slotId = GADMAdapterMyTargetSlotIdFromCredentials(credentials);
  XCTAssertEqual(slotId, 0);
}

#pragma mark - Error Helper Tests

- (void)testErrorWithCodeAndDescription {
  NSError *error = GADMAdapterMyTargetErrorWithCodeAndDescription(
      GADMAdapterMyTargetErrorNoFill, @"No fill description");
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.domain, GADMAdapterMyTargetAdapterErrorDomain);
  XCTAssertEqual(error.code, GADMAdapterMyTargetErrorNoFill);
  XCTAssertEqualObjects(error.localizedDescription, @"No fill description");
  XCTAssertEqualObjects(error.userInfo[NSLocalizedFailureReasonErrorKey], @"No fill description");
}

- (void)testSDKErrorWithDescription {
  NSError *error = GADMAdapterMyTargetSDKErrorWithDescription(@"SDK error description");
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.domain, GADMAdapterMyTargetSDKErrorDomain);
  XCTAssertEqual(error.code, 0);
  XCTAssertEqualObjects(error.localizedDescription, @"SDK error description");
  XCTAssertEqualObjects(error.userInfo[NSLocalizedFailureReasonErrorKey], @"SDK error description");
}

- (void)testAdapterErrorWithDescription {
  NSError *error = GADMAdapterMyTargetAdapterErrorWithDescription(@"Adapter error description");
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.domain, GADMAdapterMyTargetAdapterErrorDomain);
  XCTAssertEqual(error.code, 1000);
  XCTAssertEqualObjects(error.localizedDescription, @"Adapter error description");
  XCTAssertEqualObjects(error.userInfo[NSLocalizedFailureReasonErrorKey],
                        @"Adapter error description");
}

#pragma mark - Mutable Dictionary Helper Tests

- (void)testMutableDictionarySetObjectForKey {
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
  GADMAdapterMyTargetMutableDictionarySetObjectForKey(dictionary, @"key1", @"value1");
  XCTAssertEqualObjects(dictionary[@"key1"], @"value1");

  // Setting nil key or nil value should not crash or modify dictionary.
  GADMAdapterMyTargetMutableDictionarySetObjectForKey(dictionary, nil, @"value2");
  XCTAssertNil(dictionary[@"value2"]);
  GADMAdapterMyTargetMutableDictionarySetObjectForKey(dictionary, @"key2", nil);
  XCTAssertNil(dictionary[@"key2"]);
}

- (void)testMutableDictionaryRemoveObjectForKey {
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:@{@"key1" : @"value1"}];
  GADMAdapterMyTargetMutableDictionaryRemoveObjectForKey(dictionary, @"key1");
  XCTAssertNil(dictionary[@"key1"]);

  // Removing nil key should not crash.
  GADMAdapterMyTargetMutableDictionaryRemoveObjectForKey(dictionary, nil);
}

#pragma mark - Native Ad Image Helper Tests

- (void)testNativeAdImageWithNilImageData {
  GADNativeAdImage *image = GADMAdapterMyTargetNativeAdImageWithImageData(nil);
  XCTAssertNil(image);
}

- (void)testNativeAdImageWithUIImage {
  MTRGImageData *imageData = [[MTRGImageData alloc] init];
  id imageDataMock = OCMPartialMock(imageData);
  UIImage *uiImage = [[UIImage alloc] init];
  OCMStub([imageDataMock image]).andReturn(uiImage);

  GADNativeAdImage *image = GADMAdapterMyTargetNativeAdImageWithImageData(imageDataMock);
  XCTAssertNotNil(image);
  XCTAssertEqualObjects(image.image, uiImage);

  [imageDataMock stopMocking];
}

- (void)testNativeAdImageWithURL {
  MTRGImageData *imageData = [[MTRGImageData alloc] init];
  id imageDataMock = OCMPartialMock(imageData);
  OCMStub([imageDataMock image]).andReturn(nil);
  OCMStub([imageDataMock url]).andReturn(@"https://google.com/icon.png");

  GADNativeAdImage *image = GADMAdapterMyTargetNativeAdImageWithImageData(imageDataMock);
  XCTAssertNotNil(image);
  XCTAssertEqualObjects(image.imageURL, [NSURL URLWithString:@"https://google.com/icon.png"]);

  [imageDataMock stopMocking];
}

#pragma mark - Log Enabled Property Tests

- (void)testLogEnabledProperty {
  GADMAdapterMyTargetUtils.logEnabled = YES;
  XCTAssertTrue(GADMAdapterMyTargetUtils.logEnabled);

  GADMAdapterMyTargetUtils.logEnabled = NO;
  XCTAssertFalse(GADMAdapterMyTargetUtils.logEnabled);

  GADMAdapterMyTargetUtils.logEnabled = YES;
}

#pragma mark - AC Consent Tests

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

- (void)testACConsentResultEmptyAdditionalConsent {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"" forKey:@"IABTCF_AddtlConsent"];

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

- (void)testACConsentResultVersionTwoSpecWithMyTargetConsentedWithNoneDisclosed {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.1067~dv" forKey:@"IABTCF_AddtlConsent"];

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

- (void)testACConsentResultVersionTwoSpecWithEmptyConsentedPartners {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~~dv.3.4" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterMyTargetConsentResult consentResult =
      GADMAdapterMyTargetHasACConsent(GADMAdapterMyTargetAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterMyTargetConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithEmptyConsentedPartnersWithMyTargetDisclosed {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~~dv.1067.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterMyTargetConsentResult consentResult =
      GADMAdapterMyTargetHasACConsent(GADMAdapterMyTargetAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterMyTargetConsentResultFalse);
}

@end
