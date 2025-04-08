#import "GADMAdapterIronSourceRewardedAd.h"
#import "GADMediationAdapterIronSource.h"
#import "GADMAdapterIronSourceConstants.h"

#import <IronSource/IronSource.h>
#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationRewardedAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

static NSString *const kAppKey = @"AppKey";
static NSString *const kInstanceId = @"1234";

/// An instance of GADMAdapterIronSourceRewardedAdDelegate.
static id<ISDemandOnlyRewardedVideoDelegate> _ironSourceRewardedAdDelegate;

@interface AUTIronSourceRewardedAdTests : XCTestCase

@end

@implementation AUTIronSourceRewardedAdTests {
  /// An adapter instance that is used to test loading an rewarded ad.
  GADMediationAdapterIronSource *_adapter;

  /// A  mock of the adapter to verify init method call on the adapter.
  id _adapterMock;

  /// A mock instance of IronSource.
  id _ironSourceMock;

  id _ironSourceAdsMock;

  id _request;

  /// A partial mock instance of GADMAdapterIronSourceRewardedAd.
  id _adapterRewardedAd;

  /// Instance ID.
  __block NSString *_instanceId;
}

- (void)setUp {
  [super setUp];
  _ironSourceMock = OCMClassMock([IronSource class]);
  _ironSourceAdsMock = OCMClassMock([IronSourceAds class]);
  OCMStub([_ironSourceMock setISDemandOnlyRewardedVideoDelegate:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&_ironSourceRewardedAdDelegate atIndex:2];
      });

  [GADMAdapterIronSourceRewardedAd initialize];
  _adapterRewardedAd = OCMPartialMock([GADMAdapterIronSourceRewardedAd alloc]);
  OCMStub([_adapterRewardedAd alloc]).andReturn(_adapterRewardedAd);

  _adapter = [[GADMediationAdapterIronSource alloc] init];

  _request = [OCMArg any];  // Mock request argument

  // Define the mock's behavior for initWithRequest:completion:
  OCMStub([_ironSourceAdsMock
      initWithRequest:[OCMArg any]
           completion:([OCMArg invokeBlockWithArgs:@YES, [NSNull null], nil])]);
}

- (void)tearDown {
  [_adapterMock stopMocking];
  [_adapterRewardedAd stopMocking];
}

- (AUTKMediationRewardedAdEventDelegate *)
    checkLoadRewardedAdSuccessForSettings:(NSDictionary<NSString *, id> *)settings
                   withExpectedInstanceId:(NSString *)expectedInstanceId {
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = settings;
  configuration.credentials = credentials;
  OCMExpect([_ironSourceMock loadISDemandOnlyRewardedVideo:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&self->_instanceId atIndex:2];
        XCTAssertEqualObjects(self->_instanceId, expectedInstanceId);
        [_ironSourceRewardedAdDelegate rewardedVideoDidLoad:self->_instanceId];
      });

  id<GADMediationRewardedAdEventDelegate> eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);
  [OCMArg invokeBlockWithArgs:[NSNull null], nil];

  OCMVerifyAll(_ironSourceMock);
  OCMVerify([(GADMAdapterIronSourceRewardedAd *)_adapterRewardedAd
      setState:GADMAdapterIronSourceInstanceStateLocked]);
  XCTAssertEqualObjects([_adapterRewardedAd getState], GADMAdapterIronSourceInstanceStateLocked);
  return eventDelegate;
}

- (void)testLoadRewardedAdSuccess {
  NSDictionary<NSString *, id> *settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  [self checkLoadRewardedAdSuccessForSettings:settings withExpectedInstanceId:kInstanceId];
}

- (void)testLoadRewardedAdUsesDefaultInstanceIdWhenNoInstanceIdInAdConfig {
  NSDictionary<NSString *, id> *settings = @{GADMAdapterIronSourceAppKey : kAppKey};
  [self checkLoadRewardedAdSuccessForSettings:settings
                       withExpectedInstanceId:GADMIronSourceDefaultNonRtbInstanceId];
}

- (void)testLoadFailureWithEmptyAppKey {
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterIronSourceAppKey : @""};
  configuration.credentials = credentials;

  NSError *expectedError =
      [NSError errorWithDomain:GADMAdapterIronSourceErrorDomain
                          code:GADMAdapterIronSourceErrorInvalidServerParameters
                      userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureWithNoAppKey {
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError =
      [NSError errorWithDomain:GADMAdapterIronSourceErrorDomain
                          code:GADMAdapterIronSourceErrorInvalidServerParameters
                      userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureWhenIronSourceAdLoadFails {
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  configuration.credentials = credentials;
  __block NSString *instanceId;
  NSError *ironSourceAdLoadError =
      [NSError errorWithDomain:@"ironsource.domain"
                          code:1
                      userInfo:@{NSLocalizedDescriptionKey : @"Rewarded ad load failed."}];
  OCMExpect([_ironSourceMock loadISDemandOnlyRewardedVideo:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&instanceId atIndex:2];
        [_ironSourceRewardedAdDelegate rewardedVideoDidFailToLoadWithError:ironSourceAdLoadError
                                                                instanceId:instanceId];
      });

  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, ironSourceAdLoadError);
  [OCMArg invokeBlockWithArgs:[NSNull null], nil];

  OCMVerifyAll(_ironSourceMock);
  OCMVerify([(GADMAdapterIronSourceRewardedAd *)_adapterRewardedAd
      setState:GADMAdapterIronSourceInstanceStateLocked]);
  OCMVerify([(GADMAdapterIronSourceRewardedAd *)_adapterRewardedAd
      setState:GADMAdapterIronSourceInstanceStateCanLoad]);
  XCTAssertEqualObjects([_adapterRewardedAd getState], GADMAdapterIronSourceInstanceStateCanLoad);
}

- (AUTKMediationRewardedAdEventDelegate *)loadRewardedAdAndGetEventDelegate {
  NSDictionary<NSString *, id> *settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  return [self checkLoadRewardedAdSuccessForSettings:settings withExpectedInstanceId:kInstanceId];
}

- (void)testRewardedAdPresentInvokesShowOnIronSourceSdk {
  // Load IronSource rewarded ad first.
  [self loadRewardedAdAndGetEventDelegate];
  UIViewController *rootViewController = [[UIViewController alloc] init];

  [_adapterRewardedAd presentFromViewController:rootViewController];

  OCMVerify([_ironSourceMock showISDemandOnlyRewardedVideo:rootViewController
                                                instanceId:_instanceId]);
}

- (void)
    testRewardedVideoDidOpenInvokesWillPresentFullScreenViewAndDidStartVideoAndReportImpression {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAdAndGetEventDelegate];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);

  [_ironSourceRewardedAdDelegate rewardedVideoDidOpen:_instanceId];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 1);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testRewardedVideoDidClickInvokesReportClick {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAdAndGetEventDelegate];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);

  [_ironSourceRewardedAdDelegate rewardedVideoDidClick:_instanceId];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testRewardedVideoDidCloseInvokesWillDismissFullScreenViewAndDidDismissFullScreenView {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAdAndGetEventDelegate];
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);

  [_ironSourceRewardedAdDelegate rewardedVideoDidClose:_instanceId];

  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testRewardedVideoDidFailToShowInvokesDidFailToPresent {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAdAndGetEventDelegate];
  NSError *showError =
      [NSError errorWithDomain:@"ironsource.domain"
                          code:2
                      userInfo:@{
                        NSLocalizedDescriptionKey : @"IronSource rewarded ad presentation failed."
                      }];

  [_ironSourceRewardedAdDelegate rewardedVideoDidFailToShowWithError:showError
                                                          instanceId:_instanceId];

  NSError *presentationError = eventDelegate.didFailToPresentError;
  XCTAssertEqual(presentationError.domain, @"ironsource.domain");
  XCTAssertEqual(presentationError.code, 2);
  XCTAssertEqualObjects(presentationError.userInfo[NSLocalizedDescriptionKey],
                        @"IronSource rewarded ad presentation failed.");
}

- (void)testRewardedVideoAdRewardedInvokesDidEndVideoAndDidRewardUser {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAdAndGetEventDelegate];
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 0);

  [_ironSourceRewardedAdDelegate rewardedVideoAdRewarded:_instanceId];

  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 1);
}

@end
