#import "GADMediationAdapterUnity.h"

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>

#import "AUTUnityTestCase.h"
#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnityUtils.h"

@interface AUTUnityAdapterUtilsTests : AUTUnityTestCase
@end

@implementation AUTUnityAdapterUtilsTests {
  id userDefaultsMock;
}

- (void)setUp {
  userDefaultsMock = OCMClassMock([NSUserDefaults class]);
  OCMStub([userDefaultsMock standardUserDefaults]).andReturn(userDefaultsMock);
}

- (void)tearDown {
  [userDefaultsMock stopMocking];
}

- (void)testACConsentResultNegativeGDPR {
  OCMStub([userDefaultsMock integerForKey:@"IABTCF_gdprApplies"]).andReturn(-1);

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultZeroGDPR {
  OCMStub([userDefaultsMock integerForKey:@"IABTCF_gdprApplies"]).andReturn(0);

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultMissingGDPR {
  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultMissingAdditionalConsent {
  OCMStub([userDefaultsMock integerForKey:@"IABTCF_gdprApplies"]).andReturn(1);

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultUnknownSpecVersion {
  OCMStub([userDefaultsMock integerForKey:@"IABTCF_gdprApplies"]).andReturn(1);
  OCMStub([userDefaultsMock stringForKey:@"IABTCF_AddtlConsent"]).andReturn(@"0~3234.1~dv.2.3");

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultInvalidSpecVersion {
  OCMStub([userDefaultsMock integerForKey:@"IABTCF_gdprApplies"]).andReturn(1);
  OCMStub([userDefaultsMock stringForKey:@"IABTCF_AddtlConsent"]).andReturn(@"a~3234.1~dv.2.3");

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultNoConsentedVendor {
  OCMStub([userDefaultsMock integerForKey:@"IABTCF_gdprApplies"]).andReturn(1);
  OCMStub([userDefaultsMock stringForKey:@"IABTCF_AddtlConsent"]).andReturn(@"1~");

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultUnityConsented {
  OCMStub([userDefaultsMock integerForKey:@"IABTCF_gdprApplies"]).andReturn(1);
  OCMStub([userDefaultsMock stringForKey:@"IABTCF_AddtlConsent"]).andReturn(@"1~1.3234");

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultTrue);
}

- (void)testACConsentResultUnityNotIncluded {
  OCMStub([userDefaultsMock integerForKey:@"IABTCF_gdprApplies"]).andReturn(1);
  OCMStub([userDefaultsMock stringForKey:@"IABTCF_AddtlConsent"]).andReturn(@"1~1.2");

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultVersionOneSpecWithUnexpectedParts {
  OCMStub([userDefaultsMock integerForKey:@"IABTCF_gdprApplies"]).andReturn(1);
  OCMStub([userDefaultsMock stringForKey:@"IABTCF_AddtlConsent"]).andReturn(@"1~3234.1~dv.2.3");

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithInvalidFormat {
  OCMStub([userDefaultsMock integerForKey:@"IABTCF_gdprApplies"]).andReturn(1);
  OCMStub([userDefaultsMock stringForKey:@"IABTCF_AddtlConsent"]).andReturn(@"2~3234.1~ax.2.3");

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithUnexpectedParts {
  OCMStub([userDefaultsMock integerForKey:@"IABTCF_gdprApplies"]).andReturn(1);
  OCMStub([userDefaultsMock stringForKey:@"IABTCF_AddtlConsent"]).andReturn(@"2~3234.1");

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

- (void)testACConsentResultVersionTwoSpecWithUnityConsented {
  OCMStub([userDefaultsMock integerForKey:@"IABTCF_gdprApplies"]).andReturn(1);
  OCMStub([userDefaultsMock stringForKey:@"IABTCF_AddtlConsent"]).andReturn(@"2~1.3234~dv.2.3");

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultTrue);
}

- (void)testACConsentResultVersionTwoSpecWithUnityDisclosed {
  OCMStub([userDefaultsMock integerForKey:@"IABTCF_gdprApplies"]).andReturn(1);
  OCMStub([userDefaultsMock stringForKey:@"IABTCF_AddtlConsent"]).andReturn(@"2~1.2~dv.3234.3");

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultFalse);
}

- (void)testACConsentResultVersionTwoSpecWithUnityMissing {
  OCMStub([userDefaultsMock integerForKey:@"IABTCF_gdprApplies"]).andReturn(1);
  OCMStub([userDefaultsMock stringForKey:@"IABTCF_AddtlConsent"]).andReturn(@"2~1.2~dv.3.4");

  GADMAdapterUnityConsentResult consentResult =
      GADMAdapterUnityHasACConsent(GADMAdapterUnityAdTechnologyProviderID);
  XCTAssertEqual(consentResult, GADMAdapterUnityConsentResultUnknown);
}

@end
