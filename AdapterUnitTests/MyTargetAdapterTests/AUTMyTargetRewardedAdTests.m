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
  OCMStub([rewardedAdMock load]).andDo(^(NSInvocation *invocation) {
    [rewardedAdMock.delegate onNoAdWithReason:@"foobar" rewardedAd:rewardedAdMock];
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
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                                      code:GADMAdapterMyTargetErrorNoFill
                                                  userInfo:@{
                                                    NSLocalizedDescriptionKey : @"foobar",
                                                    NSLocalizedFailureReasonErrorKey : @"foobar",
                                                  }];
  AUTKWaitAndAssertLoadRewardedAdFailure(adapter, rewardedAdConfiguration, expectedError);
}

@interface AUTMyTargetRewardedAdTests : XCTestCase

@end

@implementation AUTMyTargetRewardedAdTests

- (void)testOnLoadWithRewardedAd {
  MTRGRewardedAd *rewardedAd = [[MTRGRewardedAd alloc] initWithSlotId:AUTSlotID];
  AUTLoadRewardedAd(rewardedAd);
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
