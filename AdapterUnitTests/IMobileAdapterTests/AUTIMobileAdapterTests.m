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

#import "GADMediationAdapterIMobile.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <ImobileSdkAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterIMobile.h"
#import "GADMAdapterIMobileConstants.h"
#import "GADMAdapterIMobileUtils.h"

@interface AUTIMobileAdapterTests : XCTestCase
@end

@implementation AUTIMobileAdapterTests {
  /// Class mock for ImobileSdkAds.
  id _sdkMock;
}

- (void)setUp {
  [super setUp];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  _sdkMock = OCMClassMock([ImobileSdkAds class]);
}

- (void)tearDown {
  [_sdkMock stopMocking];
  _sdkMock = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  [super tearDown];
}

#pragma mark - Version Tests

- (void)testAdapterVersion {
  GADVersionNumber version = [GADMediationAdapterIMobile adapterVersion];

  GADVersionNumber expectedVersion = {2, 3, 408};
  AUTKAssertEqualVersion(version, expectedVersion);
}

- (void)testAdSDKVersion {
  OCMStub(ClassMethod([_sdkMock getSdkVersion])).andReturn(@"2.3.4");

  GADVersionNumber version = [GADMediationAdapterIMobile adSDKVersion];

  GADVersionNumber expectedVersion = {2, 3, 4};
  AUTKAssertEqualVersion(version, expectedVersion);
}

- (void)testAdSDKVersionWhenVersionHasLessThanThreeComponents {
  OCMStub(ClassMethod([_sdkMock getSdkVersion])).andReturn(@"2.3");

  GADVersionNumber version = [GADMediationAdapterIMobile adSDKVersion];

  GADVersionNumber expectedVersion = {0, 0, 0};
  AUTKAssertEqualVersion(version, expectedVersion);
}

- (void)testAdSDKVersionWhenVersionHasExtraComponents {
  OCMStub(ClassMethod([_sdkMock getSdkVersion])).andReturn(@"2.3.4.1");

  GADVersionNumber version = [GADMediationAdapterIMobile adSDKVersion];

  GADVersionNumber expectedVersion = {2, 3, 4};
  AUTKAssertEqualVersion(version, expectedVersion);
}

- (void)testAdSDKVersionWhenVersionIsEmpty {
  OCMStub(ClassMethod([_sdkMock getSdkVersion])).andReturn(@"");

  GADVersionNumber version = [GADMediationAdapterIMobile adSDKVersion];

  GADVersionNumber expectedVersion = {0, 0, 0};
  AUTKAssertEqualVersion(version, expectedVersion);
}

- (void)testNetworkExtrasClass {
  XCTAssertNil([GADMediationAdapterIMobile networkExtrasClass]);
}

- (void)testLegacyIMobileAdapterSubclass {
  IMobileAdapter *legacyAdapter = [[IMobileAdapter alloc] init];
  XCTAssertTrue([legacyAdapter isKindOfClass:[GADMediationAdapterIMobile class]]);

  AUTKMediationServerConfiguration *config = [[AUTKMediationServerConfiguration alloc] init];
  AUTKWaitAndAssertAdapterSetUpWithConfiguration([IMobileAdapter class], config);
}

#pragma mark - SetUp Tests

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

#pragma mark - Utility Tests

- (void)testAdSizeConversionForBanner {
  GADAdSize convertedSize = GADMAdapterIMobileAdSizeFromGADAdSize(GADAdSizeBanner);
  XCTAssertTrue(GADAdSizeEqualToSize(convertedSize, GADAdSizeBanner));
}

- (void)testAdSizeConversionForLargeBanner {
  GADAdSize convertedSize = GADMAdapterIMobileAdSizeFromGADAdSize(GADAdSizeLargeBanner);
  XCTAssertTrue(GADAdSizeEqualToSize(convertedSize, GADAdSizeLargeBanner));
}

- (void)testAdSizeConversionForMediumRectangle {
  GADAdSize convertedSize = GADMAdapterIMobileAdSizeFromGADAdSize(GADAdSizeMediumRectangle);
  XCTAssertTrue(GADAdSizeEqualToSize(convertedSize, GADAdSizeMediumRectangle));
}

- (void)testAdSizeConversionForUnsupportedSize {
  GADAdSize unsupportedSize = GADAdSizeSkyscraper;
  GADAdSize convertedSize = GADMAdapterIMobileAdSizeFromGADAdSize(unsupportedSize);
  XCTAssertFalse(IsGADAdSizeValid(convertedSize));
}

- (void)testErrorWithCodeAndDescription {
  NSError *error = GADMAdapterIMobileErrorWithCodeAndDescription(
      GADMAdapterIMobileErrorInvalidServerParameters, @"Test error description.");

  XCTAssertEqualObjects(error.domain, GADMAdapterIMobileErrorDomain);
  XCTAssertEqual(error.code, GADMAdapterIMobileErrorInvalidServerParameters);
  XCTAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey], @"Test error description.");
  XCTAssertEqualObjects(error.userInfo[NSLocalizedFailureReasonErrorKey],
                        @"Test error description.");
}

- (void)testErrorWithFailResultAndDescription {
  NSError *error =
      GADMAdapterIMobileErrorWithFailResultAndDescription(100, @"Test fail result description.");

  XCTAssertEqualObjects(error.domain, GADMAdapterIMobileErrorDomain);
  XCTAssertEqual(error.code, 100);
  XCTAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey],
                        @"Test fail result description.");
  XCTAssertEqualObjects(error.userInfo[NSLocalizedFailureReasonErrorKey],
                        @"Test fail result description.");
}

- (void)testMapTableSetObjectWhenKeyAndValueAreValidSetsObject {
  NSMapTable<NSString *, NSString *> *mapTable =
      [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                            valueOptions:NSPointerFunctionsStrongMemory];

  GADMAdapterIMobileMapTableSetObjectForKey(mapTable, @"testKey", @"testValue");
  XCTAssertEqualObjects([mapTable objectForKey:@"testKey"], @"testValue");
}

- (void)testMapTableSetObjectWhenKeyOrValueIsNilDoesNotSetObject {
  NSMapTable<NSString *, NSString *> *mapTable =
      [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                            valueOptions:NSPointerFunctionsStrongMemory];

  GADMAdapterIMobileMapTableSetObjectForKey(mapTable, nil, @"anotherValue");
  GADMAdapterIMobileMapTableSetObjectForKey(mapTable, @"anotherKey", nil);
  XCTAssertNil([mapTable objectForKey:@"anotherKey"]);
}

- (void)testMapTableRemoveObjectWhenKeyIsValidRemovesObject {
  NSMapTable<NSString *, NSString *> *mapTable =
      [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                            valueOptions:NSPointerFunctionsStrongMemory];

  GADMAdapterIMobileMapTableSetObjectForKey(mapTable, @"testKey", @"testValue");
  GADMAdapterIMobileMapTableRemoveObjectForKey(mapTable, @"testKey");
  XCTAssertNil([mapTable objectForKey:@"testKey"]);
}

- (void)testMapTableRemoveObjectWhenKeyOrMapTableIsNilDoesNotCrash {
  NSMapTable<NSString *, NSString *> *mapTable =
      [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                            valueOptions:NSPointerFunctionsStrongMemory];

  GADMAdapterIMobileMapTableRemoveObjectForKey(mapTable, nil);
  GADMAdapterIMobileMapTableRemoveObjectForKey(nil, @"testKey");
}

- (void)testIsChildUserWhenDefaultConfigurationReturnsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  XCTAssertFalse(GADMAdapterIMobileIsChildUser());
}

- (void)testIsChildUserWhenAgeRestrictedTreatmentIsTeenReturnsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;
  XCTAssertFalse(GADMAdapterIMobileIsChildUser());
}

- (void)testIsChildUserWhenTagForChildDirectedTreatmentIsTrueReturnsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  XCTAssertTrue(GADMAdapterIMobileIsChildUser());
}

- (void)testIsChildUserWhenTagForUnderAgeOfConsentIsTrueReturnsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  XCTAssertTrue(GADMAdapterIMobileIsChildUser());
}

- (void)testIsChildUserWhenAgeRestrictedTreatmentIsChildReturnsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  XCTAssertTrue(GADMAdapterIMobileIsChildUser());
}

@end
