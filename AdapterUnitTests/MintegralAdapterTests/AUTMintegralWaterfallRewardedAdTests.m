#import "GADMediationAdapterMintegral.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationRewardedAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <MTGSDK/MTGSDK.h>
#import <MTGSDKReward/MTGRewardAd.h>
#import <MTGSDKReward/MTGRewardAdManager.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterMintegralConstants.h"

static NSString *const kPlacementID = @"12345";
static NSString *const kUnitID = @"67890";

@interface AUTMintegralWaterfallRewardedAdTests : XCTestCase
@end

@implementation AUTMintegralWaterfallRewardedAdTests {
  /// An adapter instance that is used to test loading an ad.
  GADMediationAdapterMintegral *_adapter;

  /// A mock instance of MTGRewardAdManager.
  id _rewardedAdMock;

  /// An ad loader.
  __block id<MTGRewardAdLoadDelegate, MTGRewardAdShowDelegate, GADMediationRewardedAd> _adLoader;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterMintegral alloc] init];
  _rewardedAdMock = OCMClassMock([MTGRewardAdManager class]);
  OCMStub([_rewardedAdMock sharedInstance]).andReturn(_rewardedAdMock);
}

- (void)stubLoadWithAndDoBlock:(void (^)(NSInvocation *))block {
  OCMStub([_rewardedAdMock
              loadVideoWithPlacementId:kPlacementID
                                unitId:kUnitID
                              delegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                                self->_adLoader = obj;
                                return
                                    [obj conformsToProtocol:@protocol(MTGRewardAdLoadDelegate)] &&
                                    [obj conformsToProtocol:@protocol(MTGRewardAdShowDelegate)];
                              }]])
      .andDo(block);
}

- (nonnull AUTKMediationRewardedAdEventDelegate *)loadAd {
  [self stubLoadWithAndDoBlock:^(NSInvocation *invocation) {
    [self->_adLoader onVideoAdLoadSuccess:kPlacementID unitId:kUnitID];
  }];

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);
  XCTAssertNotNil(_adLoader);

  return eventDelegate;
}

- (void)testloadAd {
  [self loadAd];
}

- (void)testloadAdFailureForMissingPlacementID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testloadAdFailureForMissingAdUnit {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralPlacementID : kPlacementID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadAdFailure {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorAdNotAvailable
                                                  userInfo:nil];
  [self stubLoadWithAndDoBlock:^(NSInvocation *invocation) {
    [self->_adLoader onVideoAdLoadFailed:kPlacementID unitId:kUnitID error:expectedError];
  }];

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;

  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testShowSuccessWithNoReward {
  UIViewController *controller = [[UIViewController alloc] init];
  OCMStub([_rewardedAdMock showVideoWithPlacementId:kPlacementID
                                             unitId:kUnitID
                                       withRewardId:nil
                                             userId:nil
                                           delegate:OCMOCK_ANY
                                     viewController:controller])
      .andDo(^(NSInvocation *invocation) {
        [self->_adLoader onVideoAdShowSuccess:kPlacementID unitId:kUnitID];
      });
  OCMStub([_rewardedAdMock isVideoReadyToPlayWithPlacementId:kPlacementID unitId:kUnitID])
      .andReturn(YES);
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadAd];
  // Assert the initial values of the counts before they are verified after the "Act" steps.
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);

  [_adLoader presentFromViewController:controller];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);

  [_adLoader onVideoAdDismissed:kPlacementID unitId:kUnitID withConverted:NO withRewardInfo:nil];
  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 0);
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);

  [_adLoader onVideoAdDidClosed:kPlacementID unitId:kUnitID];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testShowSuccessWithReward {
  UIViewController *controller = [[UIViewController alloc] init];
  OCMStub([_rewardedAdMock showVideoWithPlacementId:kPlacementID
                                             unitId:kUnitID
                                       withRewardId:nil
                                             userId:nil
                                           delegate:OCMOCK_ANY
                                     viewController:controller])
      .andDo(^(NSInvocation *invocation) {
        [self->_adLoader onVideoAdShowSuccess:kPlacementID unitId:kUnitID];
      });
  OCMStub([_rewardedAdMock isVideoReadyToPlayWithPlacementId:kPlacementID unitId:kUnitID])
      .andReturn(YES);
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadAd];
  // Assert the initial values of the counts before they are verified after the "Act" steps.
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);

  [_adLoader presentFromViewController:controller];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);

  [_adLoader onVideoAdDismissed:kPlacementID unitId:kUnitID withConverted:YES withRewardInfo:nil];
  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 1);
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);

  [_adLoader onVideoAdDidClosed:kPlacementID unitId:kUnitID];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testShowFailureForAdNotReadyToShow {
  OCMStub([_rewardedAdMock isVideoReadyToPlayWithPlacementId:kPlacementID unitId:kUnitID])
      .andReturn(NO);
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadAd];

  [_adLoader presentFromViewController:[[UIViewController alloc] init]];

  XCTAssertEqual(eventDelegate.didFailToPresentError.code, GADMintegralErrorAdFailedToShow);
}

- (void)testShowFailure {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorAdFailedToShow
                                                  userInfo:nil];
  UIViewController *controller = [[UIViewController alloc] init];
  OCMStub([_rewardedAdMock showVideoWithPlacementId:kPlacementID
                                             unitId:kUnitID
                                       withRewardId:nil
                                             userId:nil
                                           delegate:OCMOCK_ANY
                                     viewController:controller])
      .andDo(^(NSInvocation *invocation) {
        [self->_adLoader onVideoAdShowFailed:kPlacementID unitId:kUnitID withError:expectedError];
      });
  OCMStub([_rewardedAdMock isVideoReadyToPlayWithPlacementId:kPlacementID unitId:kUnitID])
      .andReturn(YES);
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadAd];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);

  [_adLoader presentFromViewController:controller];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqualObjects(eventDelegate.didFailToPresentError, expectedError);
}

- (void)testClick {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadAd];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);

  [_adLoader onVideoAdClicked:kPlacementID unitId:kUnitID];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

@end
