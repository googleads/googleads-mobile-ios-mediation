#import "GADMediationAdapterMyTarget.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationInterstitialAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <MyTargetSDK/MyTargetSDK.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtras.h"

static NSUInteger AUTSlotID = 12345;

AUTKMediationInterstitialAdEventDelegate *_Nonnull AUTLoadInterstitialAd(
    MTRGInterstitialAd *_Nonnull interstitialAd) {
  MTRGInterstitialAd *interstitialAdMock = OCMPartialMock(interstitialAd);
  OCMStub([interstitialAdMock load]).andDo(^(NSInvocation *invocation) {
    [interstitialAdMock.delegate onLoadWithInterstitialAd:interstitialAdMock];
  });
  id interstitialAdClassMock = OCMClassMock([MTRGInterstitialAd class]);
  OCMStub([interstitialAdClassMock interstitialAdWithSlotId:AUTSlotID])
      .andReturn(interstitialAdMock);
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationInterstitialAdConfiguration *interstitialAdConfiguration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @(AUTSlotID),
  };
  interstitialAdConfiguration.credentials = credentials;
  GADMAdapterMyTargetExtras *extras = [[GADMAdapterMyTargetExtras alloc] init];
  extras.isDebugMode = YES;
  interstitialAdConfiguration.extras = extras;
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(adapter, interstitialAdConfiguration);
  XCTAssertNotNil(eventDelegate.interstitialAd);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertNil(eventDelegate.didFailToPresentError);
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);
  return eventDelegate;
}

void AUTFailToLoadInterstitialAd(MTRGInterstitialAd *_Nonnull interstitialAd) {
  MTRGInterstitialAd *interstitialAdMock = OCMPartialMock(interstitialAd);
  NSError *loadError = [[NSError alloc] initWithDomain:@"MyFyberDomain" code:12345 userInfo:nil];
  OCMStub([interstitialAdMock load]).andDo(^(NSInvocation *invocation) {
    [interstitialAdMock.delegate onLoadFailedWithError:loadError interstitialAd:interstitialAdMock];
  });
  id interstitialAdClassMock = OCMClassMock([MTRGInterstitialAd class]);
  OCMStub([interstitialAdClassMock interstitialAdWithSlotId:AUTSlotID])
      .andReturn(interstitialAdMock);
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationInterstitialAdConfiguration *interstitialAdConfiguration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @(AUTSlotID),
  };
  GADMAdapterMyTargetExtras *extras = [[GADMAdapterMyTargetExtras alloc] init];
  extras.isDebugMode = YES;
  interstitialAdConfiguration.extras = extras;
  interstitialAdConfiguration.credentials = credentials;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                                      code:GADMAdapterMyTargetErrorNoFill
                                                  userInfo:@{
                                                    NSLocalizedDescriptionKey : @"foobar",
                                                    NSLocalizedFailureReasonErrorKey : @"foobar",
                                                  }];
  AUTKWaitAndAssertLoadInterstitialAdFailure(adapter, interstitialAdConfiguration, expectedError);
}

@interface AUTMyTargetInterstitialAdTests : XCTestCase
@end

@implementation AUTMyTargetInterstitialAdTests {
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

- (void)testOnLoadWithInterstitialAd {
  MTRGInterstitialAd *interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:AUTSlotID];
  OCMReject(ClassMethod([_mockPrivacy setUserAgeRestricted:OCMOCK_ANY]));

  AUTLoadInterstitialAd(interstitialAd);
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithInterstitialAdWithTagForChildYes {
  MTRGInterstitialAd *interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:AUTSlotID];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  AUTLoadInterstitialAd(interstitialAd);
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithInterstitialAdWithTagForChildNo {
  MTRGInterstitialAd *interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:AUTSlotID];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:NO]));

  AUTLoadInterstitialAd(interstitialAd);
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithInterstitialAdWithTagForUnderAgeYes {
  MTRGInterstitialAd *interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:AUTSlotID];
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  AUTLoadInterstitialAd(interstitialAd);
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithInterstitialAdWithTagForUnderAgeNo {
  MTRGInterstitialAd *interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:AUTSlotID];
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:NO]));

  AUTLoadInterstitialAd(interstitialAd);
  OCMVerifyAll(_mockPrivacy);
}
- (void)testMyFyberLoadFailure {
  MTRGInterstitialAd *interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:AUTSlotID];
  AUTFailToLoadInterstitialAd(interstitialAd);
}

- (void)testPresentInterstitialAd {
  MTRGInterstitialAd *interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:AUTSlotID];
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = AUTLoadInterstitialAd(interstitialAd);
  [eventDelegate.interstitialAd presentFromViewController:[[UIViewController alloc] init]];
  XCTAssertNil(eventDelegate.didFailToPresentError);
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
}

- (void)testOnClickWithInterstitialAd {
  MTRGInterstitialAd *interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:AUTSlotID];
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = AUTLoadInterstitialAd(interstitialAd);
  [interstitialAd.delegate onClickWithInterstitialAd:interstitialAd];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testOnCloseWithInterstitialAd {
  MTRGInterstitialAd *interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:AUTSlotID];
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = AUTLoadInterstitialAd(interstitialAd);
  [interstitialAd.delegate onCloseWithInterstitialAd:interstitialAd];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testOnDisplayWithInterstitialAd {
  MTRGInterstitialAd *interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:AUTSlotID];
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = AUTLoadInterstitialAd(interstitialAd);
  [interstitialAd.delegate onDisplayWithInterstitialAd:interstitialAd];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testLeaveApplication {
  // Leave application is no op. Invoking to make sure it doesn't crash the app.
  MTRGInterstitialAd *interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:AUTSlotID];
  AUTLoadInterstitialAd(interstitialAd);
  [interstitialAd.delegate onLeaveApplicationWithInterstitialAd:interstitialAd];
}

- (void)testNilSlotIDFailure {
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  GADMediationInterstitialAdConfiguration *interstitialAdConfiguration =
      [[GADMediationInterstitialAdConfiguration alloc] init];
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                 code:GADMAdapterMyTargetErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(adapter, interstitialAdConfiguration, expectedError);
}

- (void)testEmptyStringSlotIDFailure {
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationInterstitialAdConfiguration *interstitialAdConfiguration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @"",
  };
  interstitialAdConfiguration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                 code:GADMAdapterMyTargetErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(adapter, interstitialAdConfiguration, expectedError);
}

- (void)testNonNumericStringSlotIDFailure {
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationInterstitialAdConfiguration *interstitialAdConfiguration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @"foobar",
  };
  interstitialAdConfiguration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                 code:GADMAdapterMyTargetErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(adapter, interstitialAdConfiguration, expectedError);
}

- (void)testZeroSlotIDFailure {
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationInterstitialAdConfiguration *interstitialAdConfiguration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @0,
  };
  interstitialAdConfiguration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                 code:GADMAdapterMyTargetErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(adapter, interstitialAdConfiguration, expectedError);
}

@end
