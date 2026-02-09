#import "GADMediationAdapterMyTarget.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationRewardedAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <MyTargetSDK/MyTargetSDK.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterMyTargetConstants.h"

static NSUInteger AUTSlotID = 12345;

AUTKMediationRewardedAdEventDelegate *_Nonnull AUTLoadRewardedAd(
    MTRGRewardedAd *_Nonnull rewardedAd) {
  MTRGRewardedAd *rewardedAdMock = OCMPartialMock(rewardedAd);
  OCMStub([rewardedAdMock load]).andDo(^(NSInvocation *invocation) {
    [rewardedAdMock.delegate onLoadWithRewardedAd:rewardedAdMock];
  });
  id rewardedAdClassMock = OCMClassMock([MTRGRewardedAd class]);
  OCMStub([rewardedAdClassMock rewardedAdWithSlotId:AUTSlotID]).andReturn(rewardedAdMock);
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationRewardedAdConfiguration *rewardedAdConfiguration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @(AUTSlotID),
  };
  rewardedAdConfiguration.credentials = credentials;
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

void AUTFailToLoadRewardedAd(MTRGRewardedAd *_Nonnull rewardedAd) {
  MTRGRewardedAd *rewardedAdMock = OCMPartialMock(rewardedAd);
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                                      code:GADMAdapterMyTargetErrorNoFill
                                                  userInfo:@{
                                                    NSLocalizedDescriptionKey : @"foobar",
                                                    NSLocalizedFailureReasonErrorKey : @"foobar",
                                                  }];
  OCMStub([rewardedAdMock load]).andDo(^(NSInvocation *invocation) {
    [rewardedAdMock.delegate onLoadFailedWithError:expectedError rewardedAd:rewardedAdMock];
  });
  id rewardedAdClassMock = OCMClassMock([MTRGRewardedAd class]);
  OCMStub([rewardedAdClassMock rewardedAdWithSlotId:AUTSlotID]).andReturn(rewardedAdMock);
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

@interface AUTMyTargetRewardedAdTests : XCTestCase

@end

@implementation AUTMyTargetRewardedAdTests {
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

- (void)testOnLoadWithRewardedAd {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  OCMReject(ClassMethod([_mockPrivacy setUserAgeRestricted:OCMOCK_ANY]));

  AUTLoadRewardedAd(rewardedAd);
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithRewardedAdWithTagForChildYes {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  AUTLoadRewardedAd(rewardedAd);
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithRewardedAdWithTagForChildNo {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:NO]));

  AUTLoadRewardedAd(rewardedAd);
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithRewardedAdWithTagForUnderAgeYes {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  AUTLoadRewardedAd(rewardedAd);
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithRewardedAdWithTagForUnderAgeNo {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:NO]));

  AUTLoadRewardedAd(rewardedAd);
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnNoAdWithReason {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  AUTFailToLoadRewardedAd(rewardedAd);
}

- (void)testOnClickWithRewardedAd {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  AUTKMediationRewardedAdEventDelegate *eventDelegate = AUTLoadRewardedAd(rewardedAd);
  [rewardedAd.delegate onClickWithRewardedAd:rewardedAd];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testOnCloseWithRewardedAd {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  AUTKMediationRewardedAdEventDelegate *eventDelegate = AUTLoadRewardedAd(rewardedAd);
  [rewardedAd.delegate onCloseWithRewardedAd:rewardedAd];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testOnReward {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  AUTKMediationRewardedAdEventDelegate *eventDelegate = AUTLoadRewardedAd(rewardedAd);
  MTRGReward *reward = [[MTRGReward alloc] init];
  [rewardedAd.delegate onReward:reward rewardedAd:rewardedAd];
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 1);
}

- (void)testOnDisplayWithRewardedAd {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  AUTKMediationRewardedAdEventDelegate *eventDelegate = AUTLoadRewardedAd(rewardedAd);
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
