#import "GADMediationAdapterMyTarget.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationRewardedAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <MyTargetSDK/MyTargetSDK.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtras.h"
#import "GADMAdapterMyTargetRewardedAd.h"
#import "GADMAdapterMyTargetUtils.h"

static NSUInteger AUTSlotID = 12345;

@interface AUTMyTargetRewardedAdTests : XCTestCase
@end

@implementation AUTMyTargetRewardedAdTests {
  id _mockPrivacy;
  id _rewardedAdClassMock;
  MTRGRewardedAd *_rewardedAdMock;
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
  [(id)_rewardedAdMock stopMocking];
  [_rewardedAdClassMock stopMocking];
  [_mockPrivacy stopMocking];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  [super tearDown];
}

- (AUTKMediationRewardedAdEventDelegate *)loadRewardedAd:(MTRGRewardedAd *)rewardedAd
                                                  extras:
                                                      (nullable GADMAdapterMyTargetExtras *)extras {
  _rewardedAdMock = OCMPartialMock(rewardedAd);
  OCMStub([_rewardedAdMock load]).andDo(^(NSInvocation *invocation) {
    [self->_rewardedAdMock.delegate onLoadWithRewardedAd:self->_rewardedAdMock];
  });
  _rewardedAdClassMock = OCMClassMock([MTRGRewardedAd class]);
  OCMStub([_rewardedAdClassMock rewardedAdWithSlotId:AUTSlotID]).andReturn(_rewardedAdMock);
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationRewardedAdConfiguration *rewardedAdConfiguration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @(AUTSlotID),
  };
  rewardedAdConfiguration.credentials = credentials;
  rewardedAdConfiguration.extras = extras;
  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(adapter, rewardedAdConfiguration);
  XCTAssertNotNil(eventDelegate.rewardedAd);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertNil(eventDelegate.didFailToPresentError);
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 0);
  return eventDelegate;
}

- (void)failToLoadRewardedAd:(MTRGRewardedAd *)rewardedAd {
  _rewardedAdMock = OCMPartialMock(rewardedAd);
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                                      code:GADMAdapterMyTargetErrorNoFill
                                                  userInfo:@{
                                                    NSLocalizedDescriptionKey : @"foobar",
                                                    NSLocalizedFailureReasonErrorKey : @"foobar",
                                                  }];
  OCMStub([_rewardedAdMock load]).andDo(^(NSInvocation *invocation) {
    [self->_rewardedAdMock.delegate onLoadFailedWithError:expectedError
                                               rewardedAd:self->_rewardedAdMock];
  });
  _rewardedAdClassMock = OCMClassMock([MTRGRewardedAd class]);
  OCMStub([_rewardedAdClassMock rewardedAdWithSlotId:AUTSlotID]).andReturn(_rewardedAdMock);
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationRewardedAdConfiguration *rewardedAdConfiguration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @(AUTSlotID),
  };
  rewardedAdConfiguration.credentials = credentials;
  AUTKWaitAndAssertLoadRewardedAdFailure(adapter, rewardedAdConfiguration, expectedError);
}

- (void)testOnLoadWithRewardedAd {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  OCMReject(ClassMethod([_mockPrivacy setUserAgeRestricted:OCMOCK_ANY]));

  [self loadRewardedAd:rewardedAd extras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithRewardedAdWithTagForChildYes {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  [self loadRewardedAd:rewardedAd extras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithRewardedAdWithTagForChildNo {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:NO]));

  [self loadRewardedAd:rewardedAd extras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithRewardedAdWithTagForUnderAgeYes {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  [self loadRewardedAd:rewardedAd extras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithRewardedAdWithTagForUnderAgeNo {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:NO]));

  [self loadRewardedAd:rewardedAd extras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithRewardedAdWithAgeRestrictedTreatmentChild {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  [self loadRewardedAd:rewardedAd extras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithRewardedAdWithAgeRestrictedTreatmentTeen {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  [self loadRewardedAd:rewardedAd extras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithRewardedAdWithAgeRestrictedTreatmentUnspecified {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  OCMReject(ClassMethod([_mockPrivacy setUserAgeRestricted:OCMOCK_ANY]));

  [self loadRewardedAd:rewardedAd extras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnNoAdWithReason {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  [self failToLoadRewardedAd:rewardedAd];
}

- (void)testPresentFromViewController {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAd:rewardedAd extras:nil];
  UIViewController *viewController = [[UIViewController alloc] init];
  OCMExpect([_rewardedAdMock showWithController:viewController]);
  [eventDelegate.rewardedAd presentFromViewController:viewController];
  OCMVerifyAll((id)_rewardedAdMock);
  XCTAssertNil(eventDelegate.didFailToPresentError);

  [_rewardedAdMock.delegate onDisplayWithRewardedAd:_rewardedAdMock];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 1);

  MTRGReward *reward = [[MTRGReward alloc] init];
  [_rewardedAdMock.delegate onReward:reward rewardedAd:_rewardedAdMock];
  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 1);

  [_rewardedAdMock.delegate onCloseWithRewardedAd:_rewardedAdMock];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testPresentFromViewControllerWhenNotLoaded {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAd:rewardedAd extras:nil];
  [(id)eventDelegate.rewardedAd setValue:@NO forKey:@"_isRewardedAdLoaded"];
  UIViewController *viewController = [[UIViewController alloc] init];
  [eventDelegate.rewardedAd presentFromViewController:viewController];

  XCTAssertNotNil(eventDelegate.didFailToPresentError);
  XCTAssertEqualObjects(eventDelegate.didFailToPresentError.domain,
                        GADMAdapterMyTargetAdapterErrorDomain);
  XCTAssertEqual(eventDelegate.didFailToPresentError.code,
                 GADMAdapterMyTargetErrorAdNotLoaded);
}

- (void)testPresentFromViewControllerWhenRewardedAdIsNil {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAd:rewardedAd extras:nil];
  [(id)eventDelegate.rewardedAd setValue:nil forKey:@"_rewardedAd"];
  UIViewController *viewController = [[UIViewController alloc] init];
  [eventDelegate.rewardedAd presentFromViewController:viewController];

  XCTAssertNotNil(eventDelegate.didFailToPresentError);
  XCTAssertEqualObjects(eventDelegate.didFailToPresentError.domain,
                        GADMAdapterMyTargetAdapterErrorDomain);
  XCTAssertEqual(eventDelegate.didFailToPresentError.code,
                 GADMAdapterMyTargetErrorAdNotLoaded);
}

- (void)testCustomParametersExtras {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  _customParamsMock = OCMPartialMock(rewardedAd.customParams);
  OCMExpect([_customParamsMock setCustomParam:@"custom_value" forKey:@"custom_key"]);

  GADMAdapterMyTargetExtras *extras = [[GADMAdapterMyTargetExtras alloc] init];
  [extras setParameter:@"custom_value" forKey:@"custom_key"];
  [self loadRewardedAd:rewardedAd extras:extras];

  OCMVerifyAll(_customParamsMock);
}

- (void)testOnClickWithRewardedAd {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAd:rewardedAd extras:nil];
  [rewardedAd.delegate onClickWithRewardedAd:rewardedAd];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testOnCloseWithRewardedAd {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAd:rewardedAd extras:nil];
  [rewardedAd.delegate onCloseWithRewardedAd:rewardedAd];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testOnReward {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAd:rewardedAd extras:nil];
  MTRGReward *reward = [[MTRGReward alloc] init];
  [rewardedAd.delegate onReward:reward rewardedAd:rewardedAd];
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 1);
}

- (void)testOnDisplayWithRewardedAd {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAd:rewardedAd extras:nil];
  [rewardedAd.delegate onDisplayWithRewardedAd:rewardedAd];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 1);
}

- (void)testNilSlotIDFailure {
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  GADMediationRewardedAdConfiguration *rewardedAdConfiguration =
      [[GADMediationRewardedAdConfiguration alloc] init];
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                 code:GADMAdapterMyTargetErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(adapter, rewardedAdConfiguration, expectedError);
}

- (void)testEmptyStringSlotIDFailure {
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationRewardedAdConfiguration *rewardedAdConfiguration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @"",
  };
  rewardedAdConfiguration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                 code:GADMAdapterMyTargetErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(adapter, rewardedAdConfiguration, expectedError);
}

- (void)testNonNumericStringSlotIDFailure {
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationRewardedAdConfiguration *rewardedAdConfiguration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @"foobar",
  };
  rewardedAdConfiguration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                 code:GADMAdapterMyTargetErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(adapter, rewardedAdConfiguration, expectedError);
}

- (void)testZeroSlotIDFailure {
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationRewardedAdConfiguration *rewardedAdConfiguration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @0,
  };
  rewardedAdConfiguration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                 code:GADMAdapterMyTargetErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(adapter, rewardedAdConfiguration, expectedError);
}

@end
