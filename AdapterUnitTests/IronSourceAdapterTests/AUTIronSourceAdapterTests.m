#import "GADMediationAdapterIronSource.h"
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceUtils.h"

#import <IronSource/IronSource.h>
#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

static NSString *const kAppKey1 = @"AppKey_1";
static NSString *const kAppKey2 = @"AppKey_2";

@interface AUTIronSourceAdapterTests : XCTestCase

@end

@implementation AUTIronSourceAdapterTests {
  /// An adapter instance.
  GADMediationAdapterIronSource *_adapter;

  /// A mock instance of IronSource.
  id _ironSourceMock;
}

- (void)setUp {
  _adapter = OCMPartialMock([[GADMediationAdapterIronSource alloc] init]);

  id adapterClassMock = OCMClassMock([GADMediationAdapterIronSource class]);
  OCMStub([adapterClassMock alloc]).andReturn(_adapter);

  _ironSourceMock = OCMClassMock([IronSource class]);
}

- (void)testCollectSignals {
  NSString *expectedIronSourceSignal = @"ironSourceSignal";

  OCMExpect(ClassMethod([_ironSourceMock getISDemandOnlyBiddingData]))
      .andReturn(expectedIronSourceSignal);

  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Signal collection."];
  [_adapter
      collectSignalsForRequestParameters:OCMOCK_ANY
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(error);
                         XCTAssertEqualObjects(signals, expectedIronSourceSignal);
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];
  OCMVerifyAll(_ironSourceMock);
}

- (void)testAdapterVersion {
  GADVersionNumber version = [GADMediationAdapterIronSource adapterVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 9999);
}

- (void)testAdSDKVersion {
  GADVersionNumber version = [GADMediationAdapterIronSource adSDKVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 99);
}

- (void)testAdSDKVersionWhenIronSouceVersionHasOnlyTwoComponents {
  id ironSourceMock = OCMClassMock([IronSource class]);
  OCMStub([ironSourceMock sdkVersion]).andReturn(@"6.3");

  GADVersionNumber version = [GADMediationAdapterIronSource adSDKVersion];

  XCTAssertEqual(version.majorVersion, 6);
  XCTAssertEqual(version.minorVersion, 3);
  XCTAssertEqual(version.patchVersion, 0);
}

- (void)testAdSDKVersionWhenIronSourceVersionHasOnlyOneComponent {
  id ironSourceMock = OCMClassMock([IronSource class]);
  OCMStub([ironSourceMock sdkVersion]).andReturn(@"6");

  GADVersionNumber version = [GADMediationAdapterIronSource adSDKVersion];

  XCTAssertEqual(version.majorVersion, 6);
  XCTAssertEqual(version.minorVersion, 0);
  XCTAssertEqual(version.patchVersion, 0);
}

- (void)testSetUpInitializesIronSourceSdk {
  AUTKMediationCredentials *interstitialCredentials = [[AUTKMediationCredentials alloc] init];
  // At least one of the credentials needs to contain an app key.
  interstitialCredentials.settings = @{GADMAdapterIronSourceAppKey : kAppKey1};
  interstitialCredentials.format = GADAdFormatInterstitial;
  AUTKMediationCredentials *rewardedCredentials = [[AUTKMediationCredentials alloc] init];
  rewardedCredentials.format = GADAdFormatRewarded;
  AUTKMediationCredentials *bannerCredentials = [[AUTKMediationCredentials alloc] init];
  bannerCredentials.format = GADAdFormatBanner;
  OCMExpect([_adapter initIronSourceSDKWithAppKey:kAppKey1
                                       forAdUnits:[OCMArg checkWithBlock:^(id value) {
                                         NSSet *set = (NSSet *)value;
                                         return (BOOL)([set count] == 3 &&
                                                       [set containsObject:IS_INTERSTITIAL] &&
                                                       [set containsObject:IS_REWARDED_VIDEO] &&
                                                       [set containsObject:IS_BANNER]);
                                       }]])
      .andDo(nil);

  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray(
      [GADMediationAdapterIronSource class],
      @[ interstitialCredentials, rewardedCredentials, bannerCredentials ]);
  OCMVerifyAll(_adapter);
  OCMVerify([_ironSourceMock setMediationType:[OCMArg any]]);
}

- (void)testSetUpInitializesWithAnyOneAppKeyWhenThereAreMultipleAppKeys {
  AUTKMediationCredentials *interstitialCredentials = [[AUTKMediationCredentials alloc] init];
  interstitialCredentials.settings = @{GADMAdapterIronSourceAppKey : kAppKey1};
  interstitialCredentials.format = GADAdFormatInterstitial;
  AUTKMediationCredentials *rewardedCredentials = [[AUTKMediationCredentials alloc] init];
  rewardedCredentials.settings = @{GADMAdapterIronSourceAppKey : kAppKey2};
  rewardedCredentials.format = GADAdFormatRewarded;
  AUTKMediationCredentials *bannerCredentials = [[AUTKMediationCredentials alloc] init];
  bannerCredentials.format = GADAdFormatBanner;
  OCMExpect([_adapter initIronSourceSDKWithAppKey:[OCMArg checkWithBlock:^(id value) {
                        return ([@[ kAppKey1, kAppKey2 ] containsObject:value]);
                      }]
                                       forAdUnits:[OCMArg any]])
      .andDo(nil);

  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray(
      [GADMediationAdapterIronSource class],
      @[ interstitialCredentials, rewardedCredentials, bannerCredentials ]);
  OCMVerifyAll(_adapter);
}

- (void)testSetUpFailsWithNoAppKey {
  AUTKMediationCredentials *interstitialCredentials = [[AUTKMediationCredentials alloc] init];
  interstitialCredentials.format = GADAdFormatInterstitial;
  AUTKMediationCredentials *rewardedCredentials = [[AUTKMediationCredentials alloc] init];
  rewardedCredentials.format = GADAdFormatRewarded;
  AUTKMediationCredentials *bannerCredentials = [[AUTKMediationCredentials alloc] init];
  bannerCredentials.format = GADAdFormatBanner;
  NSError *expectedError =
      [NSError errorWithDomain:GADMAdapterIronSourceErrorDomain
                          code:GADMAdapterIronSourceErrorInvalidServerParameters
                      userInfo:nil];

  AUTKWaitAndAssertAdapterSetUpFailureWithCredentialsArray(
      [GADMediationAdapterIronSource class],
      @[ interstitialCredentials, rewardedCredentials, bannerCredentials ], expectedError);
}

@end
