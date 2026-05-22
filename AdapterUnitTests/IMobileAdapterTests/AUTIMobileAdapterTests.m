
#import "GADMediationAdapterIMobile.h"

#import "GADMAdapterIMobileConstants.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

@interface AUTIMobileAdapterTests : XCTestCase

@end

@implementation AUTIMobileAdapterTests

- (void)setUp {
  [super setUp];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  [super tearDown];
}

- (void)testAdapterVersion {
  GADVersionNumber version = [GADMediationAdapterIMobile adapterVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 9999);
}

- (void)testAdSDKVersion {
  GADVersionNumber version = [GADMediationAdapterIMobile adSDKVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 99);
}

- (void)testSetUpSucceeds {
  AUTKMediationServerConfiguration *config = [[AUTKMediationServerConfiguration alloc] init];
  AUTKWaitAndAssertAdapterSetUpWithConfiguration([GADMediationAdapterIMobile class], config);
}

- (void)testSetUpSucceedsWhenTagForChildDirectedTreatmentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;

  AUTKMediationServerConfiguration *config = [[AUTKMediationServerConfiguration alloc] init];
  AUTKWaitAndAssertAdapterSetUpWithConfiguration([GADMediationAdapterIMobile class], config);
}

- (void)testSetUpSucceedsWhenTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  AUTKMediationServerConfiguration *config = [[AUTKMediationServerConfiguration alloc] init];
  AUTKWaitAndAssertAdapterSetUpWithConfiguration([GADMediationAdapterIMobile class], config);
}

- (void)testSetUpSucceedsWhenAgeRestrictedTreatmentIsTeen {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;

  AUTKMediationServerConfiguration *config = [[AUTKMediationServerConfiguration alloc] init];
  AUTKWaitAndAssertAdapterSetUpWithConfiguration([GADMediationAdapterIMobile class], config);
}

- (void)testSetUpFailsWhenTagForChildTreatmentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;

  NSString *errorDescription = @"The request had age-restricted treatment, but i-mobile "
                               @"SDK cannot receive age-restricted signals.";
  NSDictionary<NSString *, NSString *> *errorUserInfo = @{
    NSLocalizedDescriptionKey : errorDescription,
    NSLocalizedFailureReasonErrorKey : errorDescription
  };
  NSError *error = [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                              code:GADMAdapterIMobileErrorChildUser
                                          userInfo:errorUserInfo];
  AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
      [GADMediationAdapterIMobile class], [[AUTKMediationServerConfiguration alloc] init], error);
}
- (void)testSetUpFailsWhenTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  NSString *errorDescription = @"The request had age-restricted treatment, but i-mobile "
                               @"SDK cannot receive age-restricted signals.";
  NSDictionary<NSString *, NSString *> *errorUserInfo = @{
    NSLocalizedDescriptionKey : errorDescription,
    NSLocalizedFailureReasonErrorKey : errorDescription
  };
  NSError *error = [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                              code:GADMAdapterIMobileErrorChildUser
                                          userInfo:errorUserInfo];
  AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
      [GADMediationAdapterIMobile class], [[AUTKMediationServerConfiguration alloc] init], error);
}

- (void)testSetUpFailsWhenAgeRestrictedTreatmentIsChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;

  NSString *errorDescription = @"The request had age-restricted treatment, but i-mobile "
                               @"SDK cannot receive age-restricted signals.";
  NSDictionary<NSString *, NSString *> *errorUserInfo = @{
    NSLocalizedDescriptionKey : errorDescription,
    NSLocalizedFailureReasonErrorKey : errorDescription
  };
  NSError *error = [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                              code:GADMAdapterIMobileErrorChildUser
                                          userInfo:errorUserInfo];
  AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
      [GADMediationAdapterIMobile class], [[AUTKMediationServerConfiguration alloc] init], error);
}
@end
