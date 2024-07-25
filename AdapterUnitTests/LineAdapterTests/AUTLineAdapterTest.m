#import "GADMediationAdapterLine.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <FiveAd/FiveAd.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterLineConstants.h"
#import "GADMediationAdapterLineExtras.h"

@interface AUTLineAdapterTest : XCTestCase

@end

@implementation AUTLineAdapterTest

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  [super tearDown];
}

- (void)testAdapterVersion {
  GADVersionNumber version = [GADMediationAdapterLine adapterVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  // Five SDK's patch version has a format of YYYYMMdd. The adapter version appends 2 more digits
  // for the adapter's patch version at the end.
  XCTAssertGreaterThanOrEqual(version.patchVersion, 2000000000);
  XCTAssertLessThanOrEqual(version.patchVersion, 3000000000);
}

- (void)testAdSDKVersion {
  GADVersionNumber version = [GADMediationAdapterLine adSDKVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  // Five SDK's patch version has a format of YYYYMMdd.
  XCTAssertGreaterThanOrEqual(version.patchVersion, 20000000);
  XCTAssertLessThanOrEqual(version.patchVersion, 30000000);
}

- (void)testSetUp {
  NSString *applicationID = @"12345";

  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(
      ClassMethod([adLoaderClassMock adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
                                       FADConfig *config = (FADConfig *)obj;
                                       XCTAssertEqual(config.needChildDirectedTreatment,
                                                      kFADNeedChildDirectedTreatmentUnspecified);
                                       XCTAssertTrue([config.appId isEqualToString:applicationID]);
                                       return YES;
                                     }]
                                              outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMediationAdapterLineCredentialKeyApplicationID : applicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
}

- (void)testSetUpWithChildTreatmentTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;

  NSString *applicationID = @"12345";

  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock
      adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FADConfig *config = (FADConfig *)obj;
        XCTAssertEqual(config.needChildDirectedTreatment, kFADNeedChildDirectedTreatmentTrue);
        XCTAssertTrue([config.appId isEqualToString:applicationID]);
        return YES;
      }]
               outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMediationAdapterLineCredentialKeyApplicationID : applicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);

  OCMVerifyAll(adLoaderClassMock);
}

- (void)testSetUpWithChildTreatmentFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;

  NSString *applicationID = @"12345";

  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock
      adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FADConfig *config = (FADConfig *)obj;
        XCTAssertEqual(config.needChildDirectedTreatment, kFADNeedChildDirectedTreatmentFalse);
        XCTAssertTrue([config.appId isEqualToString:applicationID]);
        return YES;
      }]
               outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMediationAdapterLineCredentialKeyApplicationID : applicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);

  OCMVerifyAll(adLoaderClassMock);
}

- (void)testFiveAdAlreadyRegistered {
  NSString *applicationID = @"12345";

  // Mock FiveAd SDK.
  id settingsClassMock = OCMClassMock([FADSettings class]);
  OCMStub([settingsClassMock isConfigRegistered]).andReturn(YES);
  OCMReject([settingsClassMock registerConfig:OCMOCK_ANY]);

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMediationAdapterLineCredentialKeyApplicationID : applicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(settingsClassMock);
}

- (void)testTestModeEnabled {
  // Mock GoogleMobileAds SDK.
  id requestConfigurationMock = OCMPartialMock(GADMobileAds.sharedInstance.requestConfiguration);
  OCMStub([requestConfigurationMock testDeviceIdentifiers]).andReturn(@[ @"abc" ]);

  // Mock FiveAd SDK.
  NSString *applicationID = @"12345";
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
                                             FADConfig *config = (FADConfig *)obj;
                                             XCTAssertTrue(config.isTest);
                                             return YES;
                                           }]
                                                    outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMediationAdapterLineCredentialKeyApplicationID : applicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
}

- (void)testTestModeDisabled {
  // Mock GoogleMobileAds SDK.
  id requestConfigurationMock = OCMPartialMock(GADMobileAds.sharedInstance.requestConfiguration);
  OCMStub([requestConfigurationMock testDeviceIdentifiers]).andReturn(@[]);

  // Mock FiveAd SDK.
  NSString *applicationID = @"12345";
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
                                             FADConfig *config = (FADConfig *)obj;
                                             XCTAssertFalse(config.isTest);
                                             return YES;
                                           }]
                                                    outError:[OCMArg anyObjectRef]]));

  // Test.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMediationAdapterLineCredentialKeyApplicationID : applicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(adLoaderClassMock);
}

- (void)testMuted {
  // Mock GoogleMobileAds SDK.
  id adsMock = OCMPartialMock(GADMobileAds.sharedInstance);
  OCMStub([adsMock applicationMuted]).andReturn(YES);

  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  id configMock = OCMClassMock([FADConfig class]);
  OCMStub([configMock alloc]).andReturn(configMock);
  OCMStub([configMock initWithAppId:OCMOCK_ANY]).andReturn(configMock);
  OCMExpect([configMock enableSoundByDefault:NO]);

  // Test.
  NSString *applicationID = @"12345";
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMediationAdapterLineCredentialKeyApplicationID : applicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(configMock);
}

- (void)testNotMuted {
  // Mock GoogleMobileAds SDK.
  id adsMock = OCMPartialMock(GADMobileAds.sharedInstance);
  OCMStub([adsMock applicationMuted]).andReturn(NO);

  // Mock FiveAd SDK.
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  id configMock = OCMClassMock([FADConfig class]);
  OCMStub([configMock alloc]).andReturn(configMock);
  OCMStub([configMock initWithAppId:OCMOCK_ANY]).andReturn(configMock);
  OCMExpect([configMock enableSoundByDefault:YES]);

  // Test.
  NSString *applicationID = @"12345";
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMediationAdapterLineCredentialKeyApplicationID : applicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterLine class], credentials);
  OCMVerifyAll(configMock);
}

- (void)testSetUpWithMultipleApplicationIDs {
  // Mock FiveAd SDK.
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

  // Test
  AUTKMediationCredentials *credentials1 = [[AUTKMediationCredentials alloc] init];
  credentials1.settings = @{GADMediationAdapterLineCredentialKeyApplicationID : applicationID1};
  AUTKMediationCredentials *credentials2 = [[AUTKMediationCredentials alloc] init];
  credentials2.settings = @{GADMediationAdapterLineCredentialKeyApplicationID : applicationID2};
  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray([GADMediationAdapterLine class],
                                                    @[ credentials1, credentials2 ]);
  OCMVerifyAll(adLoaderClassMock);
}

- (void)testSetUpFailureByMissingApplicationID {
  NSError *error =
      [[NSError alloc] initWithDomain:GADMediationAdapterLineErrorDomain
                                 code:GADMediationAdapterLineErrorInvalidServerParameters
                             userInfo:nil];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  AUTKWaitAndAssertAdapterSetUpFailureWithCredentials([GADMediationAdapterLine class], credentials,
                                                      error);
}

- (void)testSetUpFailureByMissingCredentials {
  NSError *error =
      [[NSError alloc] initWithDomain:GADMediationAdapterLineErrorDomain
                                 code:GADMediationAdapterLineErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertAdapterSetUpFailureWithCredentialsArray([GADMediationAdapterLine class], @[],
                                                           error);
}

- (void)testNetworkExtras {
  XCTAssertEqual([GADMediationAdapterLine networkExtrasClass],
                 [GADMediationAdapterLineExtras class]);
}

@end
