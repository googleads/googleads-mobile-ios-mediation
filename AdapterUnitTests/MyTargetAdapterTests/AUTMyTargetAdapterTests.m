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
}

- (void)setUp {
  [super setUp];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  _mockPrivacy = OCMClassMock([MTRGPrivacy class]);
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
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

- (void)testNetworkExtrasClass {
  XCTAssertEqual([GADMediationAdapterMyTarget networkExtrasClass],
                 [GADMAdapterMyTargetExtras class]);
}

@end
