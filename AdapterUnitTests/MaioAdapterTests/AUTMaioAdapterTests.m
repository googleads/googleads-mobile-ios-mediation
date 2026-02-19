#import "GADMediationAdapterMaio.h"

#import "GADMMaioConstants.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <Maio/Maio-Swift.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

@interface AUTMaioAdapterTests : XCTestCase

@end

@implementation AUTMaioAdapterTests

- (void)setUp {
  [super setUp];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  [super tearDown];
}

- (void)testAdapterVersion {
  GADVersionNumber version = [GADMediationAdapterMaio adapterVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 9999);
}

- (void)testAdSDKVersion {
  GADVersionNumber version = [GADMediationAdapterMaio adSDKVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 99);
}

- (void)testSetUpSucceeds {
  AUTKMediationServerConfiguration *config = [[AUTKMediationServerConfiguration alloc] init];
  AUTKWaitAndAssertAdapterSetUpWithConfiguration([GADMediationAdapterMaio class], config);
}

- (void)testSetUpSucceedsWhenTagForChildDirectedTreatmentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;

  AUTKMediationServerConfiguration *config = [[AUTKMediationServerConfiguration alloc] init];
  AUTKWaitAndAssertAdapterSetUpWithConfiguration([GADMediationAdapterMaio class], config);
}

- (void)testSetUpSucceedsWhenTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  AUTKMediationServerConfiguration *config = [[AUTKMediationServerConfiguration alloc] init];
  AUTKWaitAndAssertAdapterSetUpWithConfiguration([GADMediationAdapterMaio class], config);
}

- (void)testSetUpFailsWhenTagForChildTreatmentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;

  NSString *errorDescription = @"The request had age-restricted treatment, but maio SDK "
                               @"cannot receive age-restricted signals.";
  NSDictionary *errorUserInfo = @{
    NSLocalizedDescriptionKey : errorDescription,
    NSLocalizedFailureReasonErrorKey : errorDescription
  };
  NSError *error = [[NSError alloc] initWithDomain:GADMMaioErrorDomain
                                              code:GADMAdapterMaioErrorChildUser
                                          userInfo:errorUserInfo];
  AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
      [GADMediationAdapterMaio class], [[AUTKMediationServerConfiguration alloc] init], error);
}
- (void)testSetUpFailsWhenTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  NSString *errorDescription = @"The request had age-restricted treatment, but maio SDK "
                               @"cannot receive age-restricted signals.";
  NSDictionary *errorUserInfo = @{
    NSLocalizedDescriptionKey : errorDescription,
    NSLocalizedFailureReasonErrorKey : errorDescription
  };
  NSError *error = [[NSError alloc] initWithDomain:GADMMaioErrorDomain
                                              code:GADMAdapterMaioErrorChildUser
                                          userInfo:errorUserInfo];
  AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
      [GADMediationAdapterMaio class], [[AUTKMediationServerConfiguration alloc] init], error);
}

- (void)testNetworkExtras {
  XCTAssertNil([GADMediationAdapterMaio networkExtrasClass]);
}

@end
