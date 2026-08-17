// Copyright 2023 Google LLC
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

#import "GADMediationAdapterLine.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <FiveAd/FiveAd.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterLineConstants.h"
#import "GADMediationAdapterLineExtras.h"
#import "GADMediationAdapterLineUtils.h"

static NSString *const AUTLineTestApplicationID = @"12345";
static NSString *const AUTLineTestSlotID = @"67890";

@interface AUTLineAdapterTest : XCTestCase
@end

@implementation AUTLineAdapterTest {
  id _adsMock;
}

- (void)setUp {
  [super setUp];
  GADMediationAdapterLineUnregisterFiveAd();
}

- (void)tearDown {
  [_adsMock stopMocking];
  _adsMock = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  [GADMediationAdapterLine setTestMode:NO];
  GADMediationAdapterLineUnregisterFiveAd();
  [super tearDown];
}

- (void)testAdapterVersion {
  GADVersionNumber version = [GADMediationAdapterLine adapterVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  // Adapter's version string has 4 parts. So patch version can be up to 9999.
  XCTAssertLessThanOrEqual(version.patchVersion, 9999);
}

- (void)testAdSDKVersion {
  GADVersionNumber version = [GADMediationAdapterLine adSDKVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 99);
}

- (void)testAdSDKVersionWithInvalidVersion {
  id settingsClassMock = OCMClassMock([FADSettings class]);
  OCMStub(ClassMethod([settingsClassMock semanticVersion])).andReturn(@"1.0");

  GADVersionNumber version = [GADMediationAdapterLine adSDKVersion];
  XCTAssertEqual(version.majorVersion, 0);
  XCTAssertEqual(version.minorVersion, 0);
  XCTAssertEqual(version.patchVersion, 0);
  [settingsClassMock stopMocking];
}

- (void)testSetUp {
  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock
      adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FADConfig *config = (FADConfig *)obj;
        XCTAssertEqual(config.needChildDirectedTreatment,
                       kFADNeedChildDirectedTreatmentUnspecified);
        XCTAssertTrue([config.appId isEqualToString:AUTLineTestApplicationID]);
        return YES;
      }]
               outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testSetUpWithChildTreatmentTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;

  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock
      adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FADConfig *config = (FADConfig *)obj;
        XCTAssertEqual(config.needChildDirectedTreatment, kFADNeedChildDirectedTreatmentTrue);
        XCTAssertTrue([config.appId isEqualToString:AUTLineTestApplicationID]);
        return YES;
      }]
               outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testSetUpWithChildTreatmentFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;

  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock
      adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FADConfig *config = (FADConfig *)obj;
        XCTAssertEqual(config.needChildDirectedTreatment, kFADNeedChildDirectedTreatmentFalse);
        XCTAssertTrue([config.appId isEqualToString:AUTLineTestApplicationID]);
        return YES;
      }]
               outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testSetUpWithChildTreatmentNil {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;

  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock
      adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FADConfig *config = (FADConfig *)obj;
        XCTAssertEqual(config.needChildDirectedTreatment,
                       kFADNeedChildDirectedTreatmentUnspecified);
        XCTAssertTrue([config.appId isEqualToString:AUTLineTestApplicationID]);
        return YES;
      }]
               outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testSetUpWithUnderAgeOfConsentTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock
      adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FADConfig *config = (FADConfig *)obj;
        XCTAssertEqual(config.needChildDirectedTreatment, kFADNeedChildDirectedTreatmentTrue);
        XCTAssertTrue([config.appId isEqualToString:AUTLineTestApplicationID]);
        return YES;
      }]
               outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testSetUpWithUnderAgeOfConsentFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock
      adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FADConfig *config = (FADConfig *)obj;
        XCTAssertEqual(config.needChildDirectedTreatment, kFADNeedChildDirectedTreatmentFalse);
        XCTAssertTrue([config.appId isEqualToString:AUTLineTestApplicationID]);
        return YES;
      }]
               outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testSetUpWithUnderAgeOfConsentNil {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock
      adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FADConfig *config = (FADConfig *)obj;
        XCTAssertEqual(config.needChildDirectedTreatment,
                       kFADNeedChildDirectedTreatmentUnspecified);
        XCTAssertTrue([config.appId isEqualToString:AUTLineTestApplicationID]);
        return YES;
      }]
               outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testSetUpWithChildDirectedTrueAndUnderAgeTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock
      adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FADConfig *config = (FADConfig *)obj;
        XCTAssertEqual(config.needChildDirectedTreatment, kFADNeedChildDirectedTreatmentTrue);
        XCTAssertTrue([config.appId isEqualToString:AUTLineTestApplicationID]);
        return YES;
      }]
               outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testSetUpWithChildDirectedTrueAndUnderAgeFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock
      adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FADConfig *config = (FADConfig *)obj;
        XCTAssertEqual(config.needChildDirectedTreatment, kFADNeedChildDirectedTreatmentTrue);
        XCTAssertTrue([config.appId isEqualToString:AUTLineTestApplicationID]);
        return YES;
      }]
               outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testSetUpWithChildDirectedFalseAndUnderAgeTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock
      adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FADConfig *config = (FADConfig *)obj;
        XCTAssertEqual(config.needChildDirectedTreatment, kFADNeedChildDirectedTreatmentTrue);
        XCTAssertTrue([config.appId isEqualToString:AUTLineTestApplicationID]);
        return YES;
      }]
               outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testSetUpWithChildDirectedFalseAndUnderAgeFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock
      adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FADConfig *config = (FADConfig *)obj;
        XCTAssertEqual(config.needChildDirectedTreatment, kFADNeedChildDirectedTreatmentFalse);
        XCTAssertTrue([config.appId isEqualToString:AUTLineTestApplicationID]);
        return YES;
      }]
               outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testSetUpWithAgeRestrictedTreatmentChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;

  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock
      adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FADConfig *config = (FADConfig *)obj;
        XCTAssertEqual(config.needChildDirectedTreatment, kFADNeedChildDirectedTreatmentTrue);
        XCTAssertTrue([config.appId isEqualToString:AUTLineTestApplicationID]);
        return YES;
      }]
               outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testSetUpWithAgeRestrictedTreatmentTeen {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;

  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock
      adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FADConfig *config = (FADConfig *)obj;
        XCTAssertEqual(config.needChildDirectedTreatment,
                       kFADNeedChildDirectedTreatmentUnspecified);
        XCTAssertTrue([config.appId isEqualToString:AUTLineTestApplicationID]);
        return YES;
      }]
               outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testSetUpWithAgeRestrictedTreatmentUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock
      adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FADConfig *config = (FADConfig *)obj;
        XCTAssertEqual(config.needChildDirectedTreatment,
                       kFADNeedChildDirectedTreatmentUnspecified);
        XCTAssertTrue([config.appId isEqualToString:AUTLineTestApplicationID]);
        return YES;
      }]
               outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testFiveAdAlreadyRegistered {
  // First register FiveAd.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]))
      .andReturn(adLoaderClassMock);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);

  // Calling setup again when already registered should succeed without re-initializing.
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  [adLoaderClassMock stopMocking];
}

- (void)testFiveAdUnregistrationLifecycle {
  NSError *error = nil;

  // Before registration, FADAdLoader should return nil with error.
  FADAdLoader *adLoader = GADMediationAdapterLineFADAdLoaderForRegisteredConfig(&error);
  XCTAssertNil(adLoader);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, GADMediationAdapterLineErrorFailedToInitializeAdLoader);
  XCTAssertEqualObjects(error.domain, GADMediationAdapterLineErrorDomain);

  // Register FiveAd.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]))
      .andReturn(adLoaderClassMock);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  NSError *registerError = GADMediationAdapterLineRegisterFiveAd(@[ credentials ]);
  XCTAssertNil(registerError);

  // After registration, FADAdLoader should be available.
  error = nil;
  adLoader = GADMediationAdapterLineFADAdLoaderForRegisteredConfig(&error);
  XCTAssertNotNil(adLoader);
  XCTAssertNil(error);

  // Unregister FiveAd.
  GADMediationAdapterLineUnregisterFiveAd();

  // After unregistration, FADAdLoader should return nil with error again.
  error = nil;
  adLoader = GADMediationAdapterLineFADAdLoaderForRegisteredConfig(&error);
  XCTAssertNil(adLoader);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, GADMediationAdapterLineErrorFailedToInitializeAdLoader);
  XCTAssertEqualObjects(error.domain, GADMediationAdapterLineErrorDomain);

  [adLoaderClassMock stopMocking];
}

- (void)testTestModeEnabled {
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
                                             FADConfig *config = (FADConfig *)obj;
                                             XCTAssertTrue(config.isTest);
                                             return YES;
                                           }]
                                                    outError:[OCMArg anyObjectRef]]));

  [GADMediationAdapterLine setTestMode:YES];

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testTestModeDisabled {
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
                                             FADConfig *config = (FADConfig *)obj;
                                             XCTAssertFalse(config.isTest);
                                             return YES;
                                           }]
                                                    outError:[OCMArg anyObjectRef]]));

  [GADMediationAdapterLine setTestMode:NO];

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testMuted {
  _adsMock = OCMPartialMock(GADMobileAds.sharedInstance);
  OCMStub([_adsMock isApplicationMuted]).andReturn(YES);

  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  id configMock = OCMClassMock([FADConfig class]);
  OCMStub([configMock alloc]).andReturn(configMock);
  OCMStub([configMock initWithAppId:OCMOCK_ANY]).andReturn(configMock);
  OCMExpect([configMock enableSoundByDefault:NO]);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(configMock);
  [configMock stopMocking];
  [adLoaderClassMock stopMocking];
  [_adsMock stopMocking];
  _adsMock = nil;
}

- (void)testNotMuted {
  _adsMock = OCMPartialMock(GADMobileAds.sharedInstance);
  OCMStub([_adsMock isApplicationMuted]).andReturn(NO);

  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  id configMock = OCMClassMock([FADConfig class]);
  OCMStub([configMock alloc]).andReturn(configMock);
  OCMStub([configMock initWithAppId:OCMOCK_ANY]).andReturn(configMock);
  OCMExpect([configMock enableSoundByDefault:YES]);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(configMock);
  [configMock stopMocking];
  [adLoaderClassMock stopMocking];
  [_adsMock stopMocking];
  _adsMock = nil;
}

- (void)testSetUpWithMultipleApplicationIDs {
  NSString *applicationID1 = @"12345";
  NSString *applicationID2 = @"67890";
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
                                             FADConfig *config = (FADConfig *)obj;
                                             XCTAssertTrue(
                                                 [config.appId isEqualToString:applicationID1] ||
                                                 [config.appId isEqualToString:applicationID2]);
                                             return YES;
                                           }]
                                                    outError:[OCMArg anyObjectRef]]));

  AUTKMediationCredentials *credentials1 = [[AUTKMediationCredentials alloc] init];
  credentials1.settings = @{GADMediationAdapterLineCredentialKeyApplicationID : applicationID1};
  AUTKMediationCredentials *credentials2 = [[AUTKMediationCredentials alloc] init];
  credentials2.settings = @{GADMediationAdapterLineCredentialKeyApplicationID : applicationID2};
  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray([GADMediationAdapterLine class],
                                                    @[ credentials1, credentials2 ]);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testSetUpFailureByMissingApplicationID {
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMediationAdapterLineErrorDomain
                                 code:GADMediationAdapterLineErrorInvalidServerParameters
                             userInfo:nil];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  AUTKWaitAndAssertAdapterSetUpFailureWithCredentials([GADMediationAdapterLine class], credentials,
                                                      expectedError);
}

- (void)testSetUpFailureByMissingCredentials {
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMediationAdapterLineErrorDomain
                                 code:GADMediationAdapterLineErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertAdapterSetUpFailureWithCredentialsArray([GADMediationAdapterLine class], @[],
                                                           expectedError);
}

- (void)testSetUpFailureByAdLoaderCreationError {
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  NSError *fiveAdError = [NSError errorWithDomain:@"com.five_corp.ad.error"
                                             code:kFADErrorCodeInternalError
                                         userInfo:nil];
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg setTo:fiveAdError]]))
      .andReturn(nil);

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMediationAdapterFiveAdErrorDomain
                                                      code:kFADErrorCodeInternalError
                                                  userInfo:nil];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKWaitAndAssertAdapterSetUpFailureWithCredentials([GADMediationAdapterLine class], credentials,
                                                      expectedError);
  [adLoaderClassMock stopMocking];
}

- (void)testNetworkExtras {
  XCTAssertEqual([GADMediationAdapterLine networkExtrasClass],
                 [GADMediationAdapterLineExtras class]);
}

- (void)testCollectSignalsSuccess {
  // Register FiveAd first.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]))
      .andReturn(adLoaderClassMock);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID,
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };
  GADMediationAdapterLineRegisterFiveAd(@[ credentials ]);

  NSString *expectedSignal = @"test_signal_data";
  OCMExpect([adLoaderClassMock collectSignalWithSlotId:AUTLineTestSlotID
                                    withSignalCallback:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        void (^callback)(NSString *_Nullable signal, NSError *_Nullable error);
        [invocation getArgument:&callback atIndex:3];
        callback(expectedSignal, nil);
      });

  AUTKRTBMediationSignalsConfiguration *signalsConfig =
      [[AUTKRTBMediationSignalsConfiguration alloc] init];
  signalsConfig.credentials = @[ credentials ];
  AUTKRTBRequestParameters *params = [[AUTKRTBRequestParameters alloc] init];
  params.configuration = signalsConfig;

  GADMediationAdapterLine *adapter = [[GADMediationAdapterLine alloc] init];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Signals collected successfully."];
  [adapter
      collectSignalsForRequestParameters:params
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertEqualObjects(signals, expectedSignal);
                         XCTAssertNil(error);
                         [expectation fulfill];
                       }];

  [self waitForExpectations:@[ expectation ] timeout:5.0];
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testCollectSignalsFailureForNoCredentials {
  AUTKRTBMediationSignalsConfiguration *signalsConfig =
      [[AUTKRTBMediationSignalsConfiguration alloc] init];
  signalsConfig.credentials = @[];
  AUTKRTBRequestParameters *params = [[AUTKRTBRequestParameters alloc] init];
  params.configuration = signalsConfig;

  GADMediationAdapterLine *adapter = [[GADMediationAdapterLine alloc] init];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Signals collection failed for no credentials."];
  [adapter
      collectSignalsForRequestParameters:params
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(signals);
                         XCTAssertNotNil(error);
                         XCTAssertEqual(error.code,
                                        GADMediationAdapterLineErrorFailedToCollectSignals);
                         XCTAssertEqualObjects(error.domain, GADMediationAdapterLineErrorDomain);
                         [expectation fulfill];
                       }];

  [self waitForExpectations:@[ expectation ] timeout:5.0];
}

- (void)testCollectSignalsFailureForUnregisteredFiveAd {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID,
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };

  AUTKRTBMediationSignalsConfiguration *signalsConfig =
      [[AUTKRTBMediationSignalsConfiguration alloc] init];
  signalsConfig.credentials = @[ credentials ];
  AUTKRTBRequestParameters *params = [[AUTKRTBRequestParameters alloc] init];
  params.configuration = signalsConfig;

  GADMediationAdapterLine *adapter = [[GADMediationAdapterLine alloc] init];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Signals collection failed for unregistered FiveAd."];
  [adapter
      collectSignalsForRequestParameters:params
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(signals);
                         XCTAssertNotNil(error);
                         XCTAssertEqual(error.code,
                                        GADMediationAdapterLineErrorFailedToInitializeAdLoader);
                         XCTAssertEqualObjects(error.domain, GADMediationAdapterLineErrorDomain);
                         [expectation fulfill];
                       }];

  [self waitForExpectations:@[ expectation ] timeout:5.0];
}

- (void)testCollectSignalsFailureForFiveAdError {
  // Register FiveAd first.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]))
      .andReturn(adLoaderClassMock);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID,
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };
  GADMediationAdapterLineRegisterFiveAd(@[ credentials ]);

  NSError *fiveAdError = [NSError errorWithDomain:@"com.five_corp.ad.error"
                                             code:kFADErrorCodeNetworkError
                                         userInfo:nil];
  OCMExpect([adLoaderClassMock collectSignalWithSlotId:AUTLineTestSlotID
                                    withSignalCallback:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        void (^callback)(NSString *_Nullable signal, NSError *_Nullable error);
        [invocation getArgument:&callback atIndex:3];
        callback(nil, fiveAdError);
      });

  AUTKRTBMediationSignalsConfiguration *signalsConfig =
      [[AUTKRTBMediationSignalsConfiguration alloc] init];
  signalsConfig.credentials = @[ credentials ];
  AUTKRTBRequestParameters *params = [[AUTKRTBRequestParameters alloc] init];
  params.configuration = signalsConfig;

  GADMediationAdapterLine *adapter = [[GADMediationAdapterLine alloc] init];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Signals collection failed with FiveAd error."];
  [adapter
      collectSignalsForRequestParameters:params
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(signals);
                         XCTAssertNotNil(error);
                         XCTAssertEqual(error.code, kFADErrorCodeNetworkError);
                         XCTAssertEqualObjects(error.domain, GADMediationAdapterFiveAdErrorDomain);
                         [expectation fulfill];
                       }];

  [self waitForExpectations:@[ expectation ] timeout:5.0];
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

- (void)testCollectSignalsFailureForNilSignal {
  // Register FiveAd first.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]))
      .andReturn(adLoaderClassMock);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID,
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };
  GADMediationAdapterLineRegisterFiveAd(@[ credentials ]);

  OCMExpect([adLoaderClassMock collectSignalWithSlotId:AUTLineTestSlotID
                                    withSignalCallback:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        void (^callback)(NSString *_Nullable signal, NSError *_Nullable error);
        [invocation getArgument:&callback atIndex:3];
        callback(nil, nil);
      });

  AUTKRTBMediationSignalsConfiguration *signalsConfig =
      [[AUTKRTBMediationSignalsConfiguration alloc] init];
  signalsConfig.credentials = @[ credentials ];
  AUTKRTBRequestParameters *params = [[AUTKRTBRequestParameters alloc] init];
  params.configuration = signalsConfig;

  GADMediationAdapterLine *adapter = [[GADMediationAdapterLine alloc] init];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Signals collection failed for nil signal."];
  [adapter
      collectSignalsForRequestParameters:params
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(signals);
                         XCTAssertNotNil(error);
                         XCTAssertEqual(error.code,
                                        GADMediationAdapterLineErrorFailedToCollectSignals);
                         XCTAssertEqualObjects(error.domain, GADMediationAdapterLineErrorDomain);
                         [expectation fulfill];
                       }];

  [self waitForExpectations:@[ expectation ] timeout:5.0];
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];
}

@end
