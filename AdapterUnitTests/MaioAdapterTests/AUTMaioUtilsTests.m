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

#import "GADMAdapterMaioUtils.h"

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <Maio/Maio-Swift.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMMaioConstants.h"
#import "GADMediationAdapterMaio.h"

@interface AUTMaioUtilsTests : XCTestCase
@end

@implementation AUTMaioUtilsTests

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

#pragma mark - Collection Helpers Tests

- (void)testMutableSetAddObjectWithValidObject {
  NSMutableSet *set = [[NSMutableSet alloc] init];
  GADMAdapterMaioMutableSetAddObject(set, @"testObject");
  XCTAssertEqual(set.count, 1);
  XCTAssertTrue([set containsObject:@"testObject"]);
}

- (void)testMutableSetAddObjectWithNilObject {
  NSMutableSet *set = [[NSMutableSet alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  GADMAdapterMaioMutableSetAddObject(set, nil);
#pragma clang diagnostic pop
  XCTAssertEqual(set.count, 0);
}

- (void)testMutableSetAddObjectWithNilSet {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  GADMAdapterMaioMutableSetAddObject(nil, @"testObject");
  GADMAdapterMaioMutableSetAddObject(nil, nil);
#pragma clang diagnostic pop
}

- (void)testMutableArrayAddObjectWithValidObject {
  NSMutableArray *array = [[NSMutableArray alloc] init];
  GADMAdapterMaioMutableArrayAddObject(array, @"testObject");
  XCTAssertEqual(array.count, 1);
  XCTAssertEqualObjects(array[0], @"testObject");
}

- (void)testMutableArrayAddObjectWithNilObject {
  NSMutableArray *array = [[NSMutableArray alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  GADMAdapterMaioMutableArrayAddObject(array, nil);
#pragma clang diagnostic pop
  XCTAssertEqual(array.count, 0);
}

- (void)testMutableArrayAddObjectWithNilArray {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  GADMAdapterMaioMutableArrayAddObject(nil, @"testObject");
  GADMAdapterMaioMutableArrayAddObject(nil, nil);
#pragma clang diagnostic pop
}

- (void)testMapTableSetObjectForKeyWithValidKeyAndValue {
  NSMapTable *mapTable = [NSMapTable strongToStrongObjectsMapTable];
  GADMAdapterMaioMapTableSetObjectForKey(mapTable, @"key", @"value");
  XCTAssertEqualObjects([mapTable objectForKey:@"key"], @"value");
}

- (void)testMapTableSetObjectForKeyWithNilValue {
  NSMapTable *mapTable = [NSMapTable strongToStrongObjectsMapTable];
  GADMAdapterMaioMapTableSetObjectForKey(mapTable, @"key", nil);
  XCTAssertNil([mapTable objectForKey:@"key"]);
}

- (void)testMapTableSetObjectForKeyWithNilKey {
  NSMapTable *mapTable = [NSMapTable strongToStrongObjectsMapTable];
  GADMAdapterMaioMapTableSetObjectForKey(mapTable, nil, @"value");
  XCTAssertEqual(mapTable.count, 0);
}

- (void)testMapTableSetObjectForKeyWithNilKeyAndValue {
  NSMapTable *mapTable = [NSMapTable strongToStrongObjectsMapTable];
  GADMAdapterMaioMapTableSetObjectForKey(mapTable, nil, nil);
  XCTAssertEqual(mapTable.count, 0);
}

- (void)testMapTableRemoveObjectForKeyWithValidKey {
  NSMapTable *mapTable = [NSMapTable strongToStrongObjectsMapTable];
  [mapTable setObject:@"value" forKey:@"key"];
  GADMAdapterMaioMapTableRemoveObjectForKey(mapTable, @"key");
  XCTAssertNil([mapTable objectForKey:@"key"]);
}

- (void)testMapTableRemoveObjectForKeyWithNilKey {
  NSMapTable *mapTable = [NSMapTable strongToStrongObjectsMapTable];
  [mapTable setObject:@"value" forKey:@"key"];
  GADMAdapterMaioMapTableRemoveObjectForKey(mapTable, nil);
  XCTAssertEqualObjects([mapTable objectForKey:@"key"], @"value");
}

- (void)testMapTableRemoveObjectForKeyWithNilMapTable {
  GADMAdapterMaioMapTableRemoveObjectForKey(nil, @"key");
  GADMAdapterMaioMapTableRemoveObjectForKey(nil, nil);
}

#pragma mark - Error Helper Tests

- (void)testErrorWithCodeAndDescription {
  NSString *description = @"Test error description";
  NSError *error = GADMAdapterMaioErrorWithCodeAndDescription(
      GADMAdapterMaioErrorInvalidServerParameters, description);
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.domain, GADMMaioErrorDomain);
  XCTAssertEqual(error.code, GADMAdapterMaioErrorInvalidServerParameters);
  XCTAssertEqualObjects(error.localizedDescription, description);
  XCTAssertEqualObjects(error.userInfo[NSLocalizedFailureReasonErrorKey], description);
}

#pragma mark - Child User Tests

- (void)testIsChildUserDefaultReturnsFalse {
  XCTAssertFalse(GADMAdapterMaioIsChildUser());
}

- (void)testIsChildUserWhenTagForChildDirectedTreatmentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  XCTAssertTrue(GADMAdapterMaioIsChildUser());
}

- (void)testIsChildUserWhenTagForChildDirectedTreatmentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  XCTAssertFalse(GADMAdapterMaioIsChildUser());
}

- (void)testIsChildUserWhenTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  XCTAssertTrue(GADMAdapterMaioIsChildUser());
}

- (void)testIsChildUserWhenTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  XCTAssertFalse(GADMAdapterMaioIsChildUser());
}

- (void)testIsChildUserWhenAgeRestrictedTreatmentIsChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  XCTAssertTrue(GADMAdapterMaioIsChildUser());
}

- (void)testIsChildUserWhenAgeRestrictedTreatmentIsTeen {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;
  XCTAssertFalse(GADMAdapterMaioIsChildUser());
}

- (void)testIsChildUserWhenAgeRestrictedTreatmentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  XCTAssertFalse(GADMAdapterMaioIsChildUser());
}

#pragma mark - Size Conversion Tests

- (void)testMaioAdSizeFromRequestedSizeBanner {
  MaioBannerSize *maioSize =
      [GADMAdapterMaioUtils maioAdSizeFromRequestedSize:GADAdSizeBanner];
  XCTAssertNotNil(maioSize);
  XCTAssertNotNil([MaioBannerSize banner]);
}

- (void)testMaioAdSizeFromRequestedSizeLargeBanner {
  MaioBannerSize *maioSize =
      [GADMAdapterMaioUtils maioAdSizeFromRequestedSize:GADAdSizeLargeBanner];
  XCTAssertNotNil(maioSize);
  XCTAssertNotNil([MaioBannerSize bigBanner]);
}

- (void)testMaioAdSizeFromRequestedSizeMediumRectangle {
  MaioBannerSize *maioSize =
      [GADMAdapterMaioUtils maioAdSizeFromRequestedSize:GADAdSizeMediumRectangle];
  XCTAssertNotNil(maioSize);
  XCTAssertNotNil([MaioBannerSize mediumRectangle]);
}

- (void)testMaioAdSizeFromRequestedSizeUnsupportedSizes {
  XCTAssertNil([GADMAdapterMaioUtils maioAdSizeFromRequestedSize:GADAdSizeInvalid]);
  XCTAssertNil(
      [GADMAdapterMaioUtils maioAdSizeFromRequestedSize:GADAdSizeFromCGSize(CGSizeMake(10, 10))]);
  XCTAssertNil(
      [GADMAdapterMaioUtils maioAdSizeFromRequestedSize:GADAdSizeFromCGSize(CGSizeMake(100, 100))]);
  XCTAssertNil(
      [GADMAdapterMaioUtils maioAdSizeFromRequestedSize:GADAdSizeFromCGSize(CGSizeMake(200, 40))]);
}

@end
