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

#import "GADMediationAdapterUnity.h"

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <UnityAds/UnityAds.h>

#import "AUTUnityTestCase.h"
#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnityUtils.h"
#import "GADUnityRouter.h"

@interface AUTUnityAdapterUtilsTests : AUTUnityTestCase
@end

@implementation AUTUnityAdapterUtilsTests {
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

- (void)testACConsentResultEmptyAdditionalConsent {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"" forKey:@"IABTCF_AddtlConsent"];

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

- (void)testACConsentResultVersionTwoSpecWithUnityConsentedWithNoneDisclosed {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~1.3234~dv" forKey:@"IABTCF_AddtlConsent"];

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

- (void)testACConsentResultVersionTwoSpecWithEmptyConsentedPartners {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~~dv.3.4" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithEmptyConsentedPartnersWithUnityDisclosed {
  [_userDefaults setObject:@1 forKey:@"IABTCF_gdprApplies"];
  [_userDefaults setObject:@"2~~dv.3234.3" forKey:@"IABTCF_AddtlConsent"];

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultFalse);
}

- (void)testConfigureMediationService {
  id unityAdsMock = OCMClassMock([UnityAds class]);
  OCMStub(ClassMethod([unityAdsMock getVersion])).andReturn(@"4.19.0");

  id metaDataMock = OCMClassMock([UADSMediationMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock setName:GADMAdapterUnityMediationNetworkName]);
  OCMExpect([metaDataMock setVersion:GADMAdapterUnityVersion]);
  OCMExpect([metaDataMock set:@"adapter_version" value:@"4.19.0"]);
  OCMExpect([metaDataMock commit]);

  GADMAdapterUnityConfigureMediationService();

  OCMVerifyAll(metaDataMock);
  [metaDataMock stopMocking];
  [unityAdsMock stopMocking];
}

- (void)testMutableArrayAddObject {
  NSMutableArray *array = [[NSMutableArray alloc] init];
  GADMAdapterUnityMutableArrayAddObject(array, @"object1");
  XCTAssertEqual(array.count, 1);
  XCTAssertEqualObjects(array[0], @"object1");

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  GADMAdapterUnityMutableArrayAddObject(array, nil);
#pragma clang diagnostic pop
  XCTAssertEqual(array.count, 1);
}

- (void)testMutableSetAddObject {
  NSMutableSet *set = [[NSMutableSet alloc] init];
  GADMAdapterUnityMutableSetAddObject(set, @"object1");
  XCTAssertEqual(set.count, 1);
  XCTAssertTrue([set containsObject:@"object1"]);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  GADMAdapterUnityMutableSetAddObject(set, nil);
#pragma clang diagnostic pop
  XCTAssertEqual(set.count, 1);
}

- (void)testErrorWithCodeAndDescription {
  NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(
      GADMAdapterUnityErrorInvalidServerParameters, @"Invalid parameters");
  XCTAssertEqualObjects(error.domain, GADMAdapterUnityErrorDomain);
  XCTAssertEqual(error.code, GADMAdapterUnityErrorInvalidServerParameters);
  XCTAssertEqualObjects(error.localizedDescription, @"Invalid parameters");
}

- (void)testSDKErrorWithUnityAdsShowErrorAndMessage {
  NSError *error = GADMAdapterUnitySDKErrorWithUnityAdsShowErrorAndMessage(
      kUnityShowErrorInternalError, @"Show failed");
  XCTAssertEqualObjects(error.domain, GADMAdapterUnitySDKErrorDomain);
  XCTAssertEqual(error.code, kUnityShowErrorInternalError);
  XCTAssertEqualObjects(error.localizedDescription, @"Show failed");
}

- (void)testSDKErrorWithUnityAdsLoadErrorAndMessage {
  NSError *error =
      GADMAdapterUnitySDKErrorWithUnityAdsLoadErrorAndMessage(kUnityAdsLoadErrorNoFill, @"No fill");
  XCTAssertEqualObjects(error.domain, GADMAdapterUnitySDKErrorDomain);
  XCTAssertEqual(error.code, kUnityAdsLoadErrorNoFill);
  XCTAssertEqualObjects(error.localizedDescription, @"No fill");
}

- (void)testRouterSharedRouter {
  GADUnityRouter *router1 = [GADUnityRouter sharedRouter];
  GADUnityRouter *router2 = [GADUnityRouter sharedRouter];
  XCTAssertNotNil(router1);
  XCTAssertEqual(router1, router2);
}

- (void)testRouterSdkInitializeWhenAlreadyInitialized {
  id unityAdsMock = OCMClassMock([UnityAds class]);
  OCMStub(ClassMethod([unityAdsMock isInitialized])).andReturn(YES);

  GADUnityRouter *router = [GADUnityRouter sharedRouter];
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Init completion"];
  [router sdkInitializeWithGameId:AUTUnityGameID
            withCompletionHandler:^(NSError *_Nullable error) {
              XCTAssertNil(error);
              [expectation fulfill];
            }];
  [self waitForExpectations:@[ expectation ]];
  [unityAdsMock stopMocking];
}

@end
