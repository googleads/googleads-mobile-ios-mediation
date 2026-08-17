#import "GADMediationAdapterMyTarget.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationInterstitialAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <MyTargetSDK/MyTargetSDK.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtras.h"
#import "GADMAdapterMyTargetUtils.h"

static NSUInteger AUTSlotID = 12345;

@interface AUTMyTargetInterstitialAdTests : XCTestCase
@end

@implementation AUTMyTargetInterstitialAdTests {
  id _mockPrivacy;
  id _interstitialAdClassMock;
  MTRGInterstitialAd *_interstitialAdMock;
  id _customParamsMock;
}

- (void)setUp {
  [super setUp];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  _mockPrivacy = OCMClassMock([MTRGPrivacy class]);
}

- (void)tearDown {
  [_customParamsMock stopMocking];
  [(id)_interstitialAdMock stopMocking];
  [_interstitialAdClassMock stopMocking];
  [_mockPrivacy stopMocking];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  [super tearDown];
}

- (AUTKMediationInterstitialAdEventDelegate *)loadInterstitialAdWithExtras:
    (nullable GADMAdapterMyTargetExtras *)extras {
  MTRGInterstitialAd *interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:AUTSlotID];
  _interstitialAdMock = OCMPartialMock(interstitialAd);
  OCMStub([_interstitialAdMock load]).andDo(^(NSInvocation *invocation) {
    [self->_interstitialAdMock.delegate onLoadWithInterstitialAd:self->_interstitialAdMock];
  });
  _interstitialAdClassMock = OCMClassMock([MTRGInterstitialAd class]);
  OCMStub([_interstitialAdClassMock interstitialAdWithSlotId:AUTSlotID])
      .andReturn(_interstitialAdMock);
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationInterstitialAdConfiguration *interstitialAdConfiguration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @(AUTSlotID),
  };
  interstitialAdConfiguration.credentials = credentials;
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

- (void)failToLoadInterstitialAd:(MTRGInterstitialAd *)interstitialAd {
  _interstitialAdMock = OCMPartialMock(interstitialAd);
  NSError *loadError =
      [NSError errorWithDomain:GADMAdapterMyTargetSDKErrorDomain
                          code:12345
                      userInfo:@{
                        NSLocalizedDescriptionKey : @"foobar",
                        NSLocalizedFailureReasonErrorKey : @"foobar",
                      }];
  OCMStub([_interstitialAdMock load]).andDo(^(NSInvocation *invocation) {
    [self->_interstitialAdMock.delegate onLoadFailedWithError:loadError
                                               interstitialAd:self->_interstitialAdMock];
  });
  _interstitialAdClassMock = OCMClassMock([MTRGInterstitialAd class]);
  OCMStub([_interstitialAdClassMock interstitialAdWithSlotId:AUTSlotID])
      .andReturn(_interstitialAdMock);
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

- (void)testOnLoadWithInterstitialAd {
  OCMReject(ClassMethod([_mockPrivacy setUserAgeRestricted:OCMOCK_ANY]));

  [self loadInterstitialAdWithExtras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithInterstitialAdWithTagForChildYes {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  [self loadInterstitialAdWithExtras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithInterstitialAdWithTagForChildNo {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:NO]));

  [self loadInterstitialAdWithExtras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithInterstitialAdWithTagForUnderAgeYes {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  [self loadInterstitialAdWithExtras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithInterstitialAdWithTagForUnderAgeNo {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:NO]));

  [self loadInterstitialAdWithExtras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithInterstitialAdWithAgeRestrictedTreatmentChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  [self loadInterstitialAdWithExtras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithInterstitialAdWithAgeRestrictedTreatmentTeen {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  [self loadInterstitialAdWithExtras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithInterstitialAdWithAgeRestrictedTreatmentUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  OCMReject(ClassMethod([_mockPrivacy setUserAgeRestricted:OCMOCK_ANY]));

  [self loadInterstitialAdWithExtras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testLoadFailure {
  MTRGInterstitialAd *interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:AUTSlotID];
  [self failToLoadInterstitialAd:interstitialAd];
}

- (void)testPresentInterstitialAd {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadInterstitialAdWithExtras:nil];
  UIViewController *viewController = [[UIViewController alloc] init];
  OCMExpect([_interstitialAdMock showWithController:viewController]);
  [eventDelegate.interstitialAd presentFromViewController:viewController];
  OCMVerifyAll((id)_interstitialAdMock);
  XCTAssertNil(eventDelegate.didFailToPresentError);
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
}

- (void)testCustomParametersExtras {
  MTRGInterstitialAd *interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:AUTSlotID];
  _interstitialAdMock = OCMPartialMock(interstitialAd);
  OCMStub([_interstitialAdMock load]).andDo(^(NSInvocation *invocation) {
    [self->_interstitialAdMock.delegate onLoadWithInterstitialAd:self->_interstitialAdMock];
  });
  _interstitialAdClassMock = OCMClassMock([MTRGInterstitialAd class]);
  OCMStub([_interstitialAdClassMock interstitialAdWithSlotId:AUTSlotID])
      .andReturn(_interstitialAdMock);

  _customParamsMock = OCMPartialMock(_interstitialAdMock.customParams);
  OCMExpect([_customParamsMock setCustomParam:@"custom_value" forKey:@"custom_key"]);

  GADMAdapterMyTargetExtras *extras = [[GADMAdapterMyTargetExtras alloc] init];
  [extras setParameter:@"custom_value" forKey:@"custom_key"];

  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationInterstitialAdConfiguration *interstitialAdConfiguration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @(AUTSlotID),
  };
  interstitialAdConfiguration.credentials = credentials;
  interstitialAdConfiguration.extras = extras;
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(adapter, interstitialAdConfiguration);
  XCTAssertNotNil(eventDelegate.interstitialAd);

  OCMVerifyAll(_customParamsMock);
}

- (void)testOnClickWithInterstitialAd {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadInterstitialAdWithExtras:nil];
  [_interstitialAdMock.delegate onClickWithInterstitialAd:_interstitialAdMock];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testOnCloseWithInterstitialAd {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadInterstitialAdWithExtras:nil];
  [_interstitialAdMock.delegate onCloseWithInterstitialAd:_interstitialAdMock];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testOnDisplayWithInterstitialAd {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadInterstitialAdWithExtras:nil];
  [_interstitialAdMock.delegate onDisplayWithInterstitialAd:_interstitialAdMock];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testLeaveApplication {
  // Leave application is no op. Invoking to make sure it doesn't crash the app.
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadInterstitialAdWithExtras:nil];
  [_interstitialAdMock.delegate onLeaveApplicationWithInterstitialAd:_interstitialAdMock];
  XCTAssertNotNil(eventDelegate);
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
