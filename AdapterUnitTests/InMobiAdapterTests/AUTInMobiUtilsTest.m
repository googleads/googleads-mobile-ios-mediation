#import "GADMAdapterInMobiUtils.h"

#import <CoreLocation/CoreLocation.h>
#import <XCTest/XCTest.h>

#import <InMobiSDK/InMobiSDK-Swift.h>

#import <OCMock/OCMock.h>

#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMediation+AdapterUnitTests.h"
#import "GADMediationAdapterInMobi.h"

@interface AUTInMobiUtilsTest : XCTestCase
@end

/// A test key value.
NSString *kTestKey = @"test_key";

/// A test object value.
NSString *kTestObject = @"test_object";

/// Returns a test configured InMobiExtras.
GADInMobiExtras *_Nonnull AUTGADInMobiExtras() {
  GADInMobiExtras *extras = [[GADInMobiExtras alloc] init];
  extras.location = [[CLLocation alloc] initWithLatitude:12 longitude:34];
  extras.postalCode = @"12345";
  extras.areaCode = @"1234";
  extras.interests = @"interests";
  extras.age = 1;
  extras.yearOfBirth = 1000;
  extras.language = @"EN";
  extras.educationType = IMSDKEducationCollageOrGraduate;
  extras.ageGroup = IMSDKAgeGroupAbove65;
  extras.logLevel = IMSDKLogLevelDebug;
  extras.additionalParameters = @{kTestKey : kTestObject};
  return extras;
}

@implementation AUTInMobiUtilsTest

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  [NSUserDefaults.standardUserDefaults removeObjectForKey:@"IABUSPrivacy_String"];
  [super tearDown];
}

- (void)testMutableArrayAddObject {
  NSMutableArray *array = [[NSMutableArray alloc] init];
  GADMAdapterInMobiMutableArrayAddObject(array, kTestObject);
  XCTAssertEqualObjects(array, @[ kTestObject ]);
}

- (void)testMutableArrayAddNilObject {
  NSMutableArray *array = [[NSMutableArray alloc] init];
  id nilObject = nil;
  GADMAdapterInMobiMutableArrayAddObject(array, nilObject);
  XCTAssertEqualObjects(array, @[]);
}

- (void)testMutableSetAddObject {
  NSMutableSet *set = [[NSMutableSet alloc] init];
  GADMAdapterInMobiMutableSetAddObject(set, kTestObject);
  XCTAssertEqualObjects(set, [NSSet setWithObject:kTestObject]);
}

- (void)testMutableSetAddNilObject {
  NSMutableSet *set = [[NSMutableSet alloc] init];
  id nilObject = nil;
  GADMAdapterInMobiMutableSetAddObject(set, nilObject);
  XCTAssertEqualObjects(set, [[NSMutableSet alloc] init]);
}

- (void)testMapTableSetObjectForKey {
  NSMapTable *table = [[NSMapTable alloc] init];
  GADMAdapterInMobiMapTableSetObjectForKey(table, kTestKey, kTestObject);

  NSMapTable *expectedTable = [[NSMapTable alloc] init];
  [expectedTable setObject:kTestObject forKey:kTestKey];
  XCTAssertEqualObjects(table, expectedTable);
}

- (void)testMapTableSetNilObjectForKey {
  NSMapTable *table = [[NSMapTable alloc] init];
  GADMAdapterInMobiMapTableSetObjectForKey(table, kTestKey, nil);
  XCTAssertEqualObjects(table, [[NSMapTable alloc] init]);
}

- (void)testMapTableSetObjectForNilKey {
  NSMapTable *table = [[NSMapTable alloc] init];
  GADMAdapterInMobiMapTableSetObjectForKey(table, nil, kTestObject);
  XCTAssertEqualObjects(table, [[NSMapTable alloc] init]);
}

- (void)testMapTableRemoveObjectForKey {
  NSMapTable *table = [[NSMapTable alloc] init];
  [table setObject:kTestObject forKey:kTestKey];
  GADMAdapterInMobiMapTableRemoveObjectForKey(table, kTestKey);

  NSMapTable *expectedTable = [[NSMapTable alloc] init];
  XCTAssertEqualObjects(table, expectedTable);
}

- (void)testMapTableRemoveObjectForNilKey {
  NSMapTable *table = [[NSMapTable alloc] init];
  [table setObject:kTestObject forKey:kTestKey];
  GADMAdapterInMobiMapTableRemoveObjectForKey(table, nil);

  NSMapTable *expectedTable = [[NSMapTable alloc] init];
  [expectedTable setObject:kTestObject forKey:kTestKey];
  XCTAssertEqualObjects(table, expectedTable);
}

- (void)testMutableDictionarySetObjectForKey {
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
  GADMAdapterInMobiMutableDictionarySetObjectForKey(dictionary, kTestKey, kTestObject);
  XCTAssertEqualObjects(dictionary, @{kTestKey : kTestObject});
}

- (void)testMutableDictionarySetNilObjectForKey {
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
  GADMAdapterInMobiMutableDictionarySetObjectForKey(dictionary, kTestKey, nil);
  XCTAssertEqualObjects(dictionary, @{});
}

- (void)testMutableDictionarySetObjectForNilKey {
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
  GADMAdapterInMobiMutableDictionarySetObjectForKey(dictionary, nil, kTestObject);
  XCTAssertEqualObjects(dictionary, @{});
}

- (void)testCacheSetObject {
  NSCache *cache = [[NSCache alloc] init];
  GADMAdapterInMobiCacheSetObjectForKey(cache, kTestKey, kTestObject);
  XCTAssertNotNil([cache objectForKey:kTestKey]);
}

- (void)testCacheSetNilObject {
  NSCache *cache = [[NSCache alloc] init];
  GADMAdapterInMobiCacheSetObjectForKey(cache, kTestKey, nil);
  XCTAssertNil([cache objectForKey:kTestKey]);
}

- (void)testErrorWithCodeAndDescription {
  NSString *expectedDescription = @"expectedDescription";
  NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(GADMAdapterInMobiErrorAdNotReady,
                                                                expectedDescription);
  XCTAssertEqual(error.code, GADMAdapterInMobiErrorAdNotReady);
  XCTAssertEqualObjects(error.localizedDescription, expectedDescription);
  XCTAssertEqualObjects(error.localizedFailureReason, expectedDescription);
  XCTAssertEqualObjects(error.domain, GADMAdapterInMobiErrorDomain);
}

- (void)testValidatePlacementIdentifier {
  NSError *error = GADMAdapterInMobiValidatePlacementIdentifier(@1);
  XCTAssertNil(error);
  error = GADMAdapterInMobiValidatePlacementIdentifier(@0);
  XCTAssertNotNil(error);
}

- (void)testTargetingFromAdConfiguration {
  GADInMobiExtras *extras = AUTGADInMobiExtras();
  GADMediationAdConfiguration *configuration =
      [[GADMediationAdConfiguration alloc] initWithAdConfiguration:nil
                                                         targeting:nil
                                                       credentials:OCMOCK_ANY
                                                            extras:extras];

  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMExpect([IMSDKMock setLocation:extras.location]);
  OCMExpect([IMSDKMock setPostalCode:extras.postalCode]);
  OCMExpect([IMSDKMock setAreaCode:extras.areaCode]);
  OCMExpect([IMSDKMock setInterests:extras.interests]);
  OCMExpect([IMSDKMock setAge:extras.age]);
  OCMExpect([IMSDKMock setYearOfBirth:extras.yearOfBirth]);
  OCMExpect([IMSDKMock setLanguage:extras.language]);
  OCMExpect([IMSDKMock setEducation:extras.educationType]);
  OCMExpect([IMSDKMock setAgeGroup:extras.ageGroup]);
  OCMReject([IMSDKMock setIsAgeRestricted:YES]);

  GADMAdapterInMobiSetTargetingFromAdConfiguration(configuration);

  OCMVerifyAll(IMSDKMock);
}

- (void)testTargetingFromAdConfiguration_WhenTagForChildIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;

  GADInMobiExtras *extras = AUTGADInMobiExtras();
  GADMediationAdConfiguration *configuration =
      [[GADMediationAdConfiguration alloc] initWithAdConfiguration:nil
                                                         targeting:nil
                                                       credentials:OCMOCK_ANY
                                                            extras:extras];

  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMExpect([IMSDKMock setLocation:extras.location]);
  OCMExpect([IMSDKMock setPostalCode:extras.postalCode]);
  OCMExpect([IMSDKMock setAreaCode:extras.areaCode]);
  OCMExpect([IMSDKMock setInterests:extras.interests]);
  OCMExpect([IMSDKMock setAge:extras.age]);
  OCMExpect([IMSDKMock setYearOfBirth:extras.yearOfBirth]);
  OCMExpect([IMSDKMock setLanguage:extras.language]);
  OCMExpect([IMSDKMock setEducation:extras.educationType]);
  OCMExpect([IMSDKMock setAgeGroup:extras.ageGroup]);
  OCMExpect([IMSDKMock setIsAgeRestricted:YES]);

  GADMAdapterInMobiSetTargetingFromAdConfiguration(configuration);

  OCMVerifyAll(IMSDKMock);
}

- (void)testTargetingFromAdConfiguration_WhenTagForChildIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;

  GADInMobiExtras *extras = AUTGADInMobiExtras();
  GADMediationAdConfiguration *configuration =
      [[GADMediationAdConfiguration alloc] initWithAdConfiguration:nil
                                                         targeting:nil
                                                       credentials:OCMOCK_ANY
                                                            extras:extras];

  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMExpect([IMSDKMock setLocation:extras.location]);
  OCMExpect([IMSDKMock setPostalCode:extras.postalCode]);
  OCMExpect([IMSDKMock setAreaCode:extras.areaCode]);
  OCMExpect([IMSDKMock setInterests:extras.interests]);
  OCMExpect([IMSDKMock setAge:extras.age]);
  OCMExpect([IMSDKMock setYearOfBirth:extras.yearOfBirth]);
  OCMExpect([IMSDKMock setLanguage:extras.language]);
  OCMExpect([IMSDKMock setEducation:extras.educationType]);
  OCMExpect([IMSDKMock setAgeGroup:extras.ageGroup]);
  OCMExpect([IMSDKMock setIsAgeRestricted:NO]);

  GADMAdapterInMobiSetTargetingFromAdConfiguration(configuration);

  OCMVerifyAll(IMSDKMock);
}

- (void)testTargetingFromAdConfiguration_WhenTagForUnderAgeIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  GADInMobiExtras *extras = AUTGADInMobiExtras();
  GADMediationAdConfiguration *configuration =
      [[GADMediationAdConfiguration alloc] initWithAdConfiguration:nil
                                                         targeting:nil
                                                       credentials:OCMOCK_ANY
                                                            extras:extras];

  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMExpect([IMSDKMock setLocation:extras.location]);
  OCMExpect([IMSDKMock setPostalCode:extras.postalCode]);
  OCMExpect([IMSDKMock setAreaCode:extras.areaCode]);
  OCMExpect([IMSDKMock setInterests:extras.interests]);
  OCMExpect([IMSDKMock setAge:extras.age]);
  OCMExpect([IMSDKMock setYearOfBirth:extras.yearOfBirth]);
  OCMExpect([IMSDKMock setLanguage:extras.language]);
  OCMExpect([IMSDKMock setEducation:extras.educationType]);
  OCMExpect([IMSDKMock setAgeGroup:extras.ageGroup]);
  OCMExpect([IMSDKMock setIsAgeRestricted:YES]);

  GADMAdapterInMobiSetTargetingFromAdConfiguration(configuration);

  OCMVerifyAll(IMSDKMock);
}

- (void)testTargetingFromAdConfiguration_WhenTagForUnderAgeIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  GADInMobiExtras *extras = AUTGADInMobiExtras();
  GADMediationAdConfiguration *configuration =
      [[GADMediationAdConfiguration alloc] initWithAdConfiguration:nil
                                                         targeting:nil
                                                       credentials:OCMOCK_ANY
                                                            extras:extras];

  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMExpect([IMSDKMock setLocation:extras.location]);
  OCMExpect([IMSDKMock setPostalCode:extras.postalCode]);
  OCMExpect([IMSDKMock setAreaCode:extras.areaCode]);
  OCMExpect([IMSDKMock setInterests:extras.interests]);
  OCMExpect([IMSDKMock setAge:extras.age]);
  OCMExpect([IMSDKMock setYearOfBirth:extras.yearOfBirth]);
  OCMExpect([IMSDKMock setLanguage:extras.language]);
  OCMExpect([IMSDKMock setEducation:extras.educationType]);
  OCMExpect([IMSDKMock setAgeGroup:extras.ageGroup]);
  OCMExpect([IMSDKMock setIsAgeRestricted:NO]);

  GADMAdapterInMobiSetTargetingFromAdConfiguration(configuration);

  OCMVerifyAll(IMSDKMock);
}

- (void)testTargetingFromAdConfiguration_WhenTagForChildIsTrueAndUnderAgeIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  GADInMobiExtras *extras = AUTGADInMobiExtras();
  GADMediationAdConfiguration *configuration =
      [[GADMediationAdConfiguration alloc] initWithAdConfiguration:nil
                                                         targeting:nil
                                                       credentials:OCMOCK_ANY
                                                            extras:extras];

  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMExpect([IMSDKMock setLocation:extras.location]);
  OCMExpect([IMSDKMock setPostalCode:extras.postalCode]);
  OCMExpect([IMSDKMock setAreaCode:extras.areaCode]);
  OCMExpect([IMSDKMock setInterests:extras.interests]);
  OCMExpect([IMSDKMock setAge:extras.age]);
  OCMExpect([IMSDKMock setYearOfBirth:extras.yearOfBirth]);
  OCMExpect([IMSDKMock setLanguage:extras.language]);
  OCMExpect([IMSDKMock setEducation:extras.educationType]);
  OCMExpect([IMSDKMock setAgeGroup:extras.ageGroup]);
  OCMExpect([IMSDKMock setIsAgeRestricted:YES]);

  GADMAdapterInMobiSetTargetingFromAdConfiguration(configuration);

  OCMVerifyAll(IMSDKMock);
}

- (void)testTargetingFromAdConfiguration_WhenTagForChildIsFalseAndUnderAgeIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  GADInMobiExtras *extras = AUTGADInMobiExtras();
  GADMediationAdConfiguration *configuration =
      [[GADMediationAdConfiguration alloc] initWithAdConfiguration:nil
                                                         targeting:nil
                                                       credentials:OCMOCK_ANY
                                                            extras:extras];

  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMExpect([IMSDKMock setLocation:extras.location]);
  OCMExpect([IMSDKMock setPostalCode:extras.postalCode]);
  OCMExpect([IMSDKMock setAreaCode:extras.areaCode]);
  OCMExpect([IMSDKMock setInterests:extras.interests]);
  OCMExpect([IMSDKMock setAge:extras.age]);
  OCMExpect([IMSDKMock setYearOfBirth:extras.yearOfBirth]);
  OCMExpect([IMSDKMock setLanguage:extras.language]);
  OCMExpect([IMSDKMock setEducation:extras.educationType]);
  OCMExpect([IMSDKMock setAgeGroup:extras.ageGroup]);
  OCMExpect([IMSDKMock setIsAgeRestricted:YES]);

  GADMAdapterInMobiSetTargetingFromAdConfiguration(configuration);

  OCMVerifyAll(IMSDKMock);
}

- (void)testTargetingFromAdConfiguration_WhenTagForChildIsTrueAndUnderAgeIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  GADInMobiExtras *extras = AUTGADInMobiExtras();
  GADMediationAdConfiguration *configuration =
      [[GADMediationAdConfiguration alloc] initWithAdConfiguration:nil
                                                         targeting:nil
                                                       credentials:OCMOCK_ANY
                                                            extras:extras];

  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMExpect([IMSDKMock setLocation:extras.location]);
  OCMExpect([IMSDKMock setPostalCode:extras.postalCode]);
  OCMExpect([IMSDKMock setAreaCode:extras.areaCode]);
  OCMExpect([IMSDKMock setInterests:extras.interests]);
  OCMExpect([IMSDKMock setAge:extras.age]);
  OCMExpect([IMSDKMock setYearOfBirth:extras.yearOfBirth]);
  OCMExpect([IMSDKMock setLanguage:extras.language]);
  OCMExpect([IMSDKMock setEducation:extras.educationType]);
  OCMExpect([IMSDKMock setAgeGroup:extras.ageGroup]);
  OCMExpect([IMSDKMock setIsAgeRestricted:YES]);

  GADMAdapterInMobiSetTargetingFromAdConfiguration(configuration);

  OCMVerifyAll(IMSDKMock);
}

- (void)testCreateRequestParametersForWaterfallMediation {
  GADInMobiExtras *extras = AUTGADInMobiExtras();
  GADMediationAdConfiguration *configuration =
      [[GADMediationAdConfiguration alloc] initWithAdConfiguration:nil
                                                         targeting:nil
                                                       credentials:OCMOCK_ANY
                                                            extras:extras];

  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment,
      GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent);
  NSString *versionString =
      [NSString stringWithFormat:@"afma-sdk-i-v%ld.%ld.%ld",
                                 GADMobileAds.sharedInstance.versionNumber.majorVersion,
                                 GADMobileAds.sharedInstance.versionNumber.minorVersion,
                                 GADMobileAds.sharedInstance.versionNumber.patchVersion];

  XCTAssertEqualObjects([requestParameters valueForKey:kTestKey], kTestObject);
  XCTAssertEqualObjects([requestParameters valueForKey:@"tp"], @"c_admob");
  XCTAssertEqualObjects([requestParameters valueForKey:@"tp-ver"], versionString);
  XCTAssertNil([requestParameters valueForKey:@"coppa"]);
}

- (void)testCreateRequestParametersForRTBMediation {
  GADInMobiExtras *extras = AUTGADInMobiExtras();
  GADMediationAdConfiguration *configuration =
      [[GADMediationAdConfiguration alloc] initWithAdConfiguration:nil
                                                         targeting:nil
                                                       credentials:OCMOCK_ANY
                                                            extras:extras];

  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeRTB,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment,
      GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent);
  NSString *versionString =
      [NSString stringWithFormat:@"afma-sdk-i-v%ld.%ld.%ld",
                                 GADMobileAds.sharedInstance.versionNumber.majorVersion,
                                 GADMobileAds.sharedInstance.versionNumber.minorVersion,
                                 GADMobileAds.sharedInstance.versionNumber.patchVersion];

  XCTAssertEqualObjects([requestParameters valueForKey:kTestKey], kTestObject);
  XCTAssertEqualObjects([requestParameters valueForKey:@"tp"], @"c_google");
  XCTAssertEqualObjects([requestParameters valueForKey:@"tp-ver"], versionString);
  XCTAssertNil([requestParameters valueForKey:@"coppa"]);
}

- (void)testRequestParameters_WhenTagForChildIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;

  GADInMobiExtras *extras = AUTGADInMobiExtras();
  GADMediationAdConfiguration *configuration =
      [[GADMediationAdConfiguration alloc] initWithAdConfiguration:nil
                                                         targeting:nil
                                                       credentials:OCMOCK_ANY
                                                            extras:extras];

  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeRTB,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment,
      GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent);

  XCTAssertEqualObjects([requestParameters valueForKey:@"coppa"], @"1");
}

- (void)testRequestParameters_WhenTagForChildIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;

  GADInMobiExtras *extras = AUTGADInMobiExtras();
  GADMediationAdConfiguration *configuration =
      [[GADMediationAdConfiguration alloc] initWithAdConfiguration:nil
                                                         targeting:nil
                                                       credentials:OCMOCK_ANY
                                                            extras:extras];

  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeRTB,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment,
      GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent);

  XCTAssertEqualObjects([requestParameters valueForKey:@"coppa"], @"0");
}

- (void)testRequestParameters_WhenTagForUnderageIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  GADInMobiExtras *extras = AUTGADInMobiExtras();
  GADMediationAdConfiguration *configuration =
      [[GADMediationAdConfiguration alloc] initWithAdConfiguration:nil
                                                         targeting:nil
                                                       credentials:OCMOCK_ANY
                                                            extras:extras];

  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeRTB,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment,
      GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent);

  XCTAssertEqualObjects([requestParameters valueForKey:@"coppa"], @"1");
}

- (void)testRequestParameters_WhenTagForUnderageIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  GADInMobiExtras *extras = AUTGADInMobiExtras();
  GADMediationAdConfiguration *configuration =
      [[GADMediationAdConfiguration alloc] initWithAdConfiguration:nil
                                                         targeting:nil
                                                       credentials:OCMOCK_ANY
                                                            extras:extras];

  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeRTB,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment,
      GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent);

  XCTAssertEqualObjects([requestParameters valueForKey:@"coppa"], @"0");
}

- (void)testRequestParameters_WhenTagForChildIsTrueAndTagForUnderAgeIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  GADInMobiExtras *extras = AUTGADInMobiExtras();
  GADMediationAdConfiguration *configuration =
      [[GADMediationAdConfiguration alloc] initWithAdConfiguration:nil
                                                         targeting:nil
                                                       credentials:OCMOCK_ANY
                                                            extras:extras];

  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeRTB,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment,
      GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent);

  XCTAssertEqualObjects([requestParameters valueForKey:@"coppa"], @"1");
}

- (void)testRequestParameters_WhenTagForChildIsFalseAndTagForUnderAgeIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  GADInMobiExtras *extras = AUTGADInMobiExtras();
  GADMediationAdConfiguration *configuration =
      [[GADMediationAdConfiguration alloc] initWithAdConfiguration:nil
                                                         targeting:nil
                                                       credentials:OCMOCK_ANY
                                                            extras:extras];

  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeRTB,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment,
      GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent);

  XCTAssertEqualObjects([requestParameters valueForKey:@"coppa"], @"1");
}

- (void)testRequestParameters_WhenTagForChildIsTrueAndTagForUnderAgeIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  GADInMobiExtras *extras = AUTGADInMobiExtras();
  GADMediationAdConfiguration *configuration =
      [[GADMediationAdConfiguration alloc] initWithAdConfiguration:nil
                                                         targeting:nil
                                                       credentials:OCMOCK_ANY
                                                            extras:extras];

  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeRTB,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment,
      GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent);

  XCTAssertEqualObjects([requestParameters valueForKey:@"coppa"], @"1");
}

- (void)testUSPrivacyCompliance {
  NSString *expectedComplianceValue = @"test";
  id IMPrivacyComplianceMock = OCMClassMock([IMPrivacyCompliance class]);
  OCMExpect(ClassMethod([IMPrivacyComplianceMock setUSPrivacyString:expectedComplianceValue]));
  [NSUserDefaults.standardUserDefaults setObject:expectedComplianceValue
                                          forKey:@"IABUSPrivacy_String"];

  GADMAdapterInMobiSetUSPrivacyCompliance();

  OCMVerifyAll(IMPrivacyComplianceMock);
}

@end
