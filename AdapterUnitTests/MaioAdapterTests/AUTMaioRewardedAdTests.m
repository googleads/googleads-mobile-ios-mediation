#import "GADMediationAdapterMaio.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationRewardedAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <Maio/Maio-Swift.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMMaioConstants.h"

static const NSInteger kMaioLoadFailureErroCode = 10000;
static const NSInteger kMaioShowFailureErroCode = 20000;
static const NSInteger kMaioUnknownFailureErroCode = 99999;

@interface AUTMaioRewardedAdTests : XCTestCase
@end

@implementation AUTMaioRewardedAdTests {
  /// The adapte under test.
  GADMediationAdapterMaio *_adapter;

  /// Mock for MaioRequest.
  id _requestMock;

  /// Mock for MaioRewarded.
  id _rewardedMock;
}

- (void)setUp {
  _adapter = [[GADMediationAdapterMaio alloc] init];
  _requestMock = OCMClassMock([MaioRequest class]);
  OCMStub([_requestMock alloc]).andReturn(_requestMock);
  _rewardedMock = OCMClassMock([MaioRewarded class]);
}

- (void)tearDown {
  OCMVerifyAll(_requestMock);
  OCMVerifyAll(_rewardedMock);
}

- (AUTKMediationRewardedAdEventDelegate *)loadAd {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMMaioAdapterZoneIdKey : @"zoneID"};
  AUTKMediationRewardedAdConfiguration *config =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  config.credentials = credentials;
  config.isTestRequest = YES;

  OCMExpect([_requestMock initWithZoneId:@"zoneID" testMode:YES]).andReturn(_requestMock);
  OCMExpect(ClassMethod(([_rewardedMock
                loadAdWithRequest:_requestMock
                         callback:[OCMArg checkWithBlock:^BOOL(id obj) {
                           if ([obj conformsToProtocol:@protocol(MaioRewardedLoadCallback)] &&
                               [obj conformsToProtocol:@protocol(MaioRewardedShowCallback)]) {
                             id<MaioRewardedLoadCallback, MaioRewardedShowCallback> maioDelegate =
                                 obj;
                             [maioDelegate didLoad:self->_rewardedMock];
                             return YES;
                           }
                           return NO;
                         }]])))
      .andReturn(_rewardedMock);

  return AUTKWaitAndAssertLoadRewardedAd(_adapter, config);
}

- (void)loadAdFailureWithErrorCode:(NSInteger)errorCode {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMMaioAdapterZoneIdKey : @"zoneID"};
  AUTKMediationRewardedAdConfiguration *config =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  config.credentials = credentials;
  config.isTestRequest = YES;

  OCMExpect([_requestMock initWithZoneId:@"zoneID" testMode:YES]).andReturn(_requestMock);
  OCMExpect(ClassMethod(([_rewardedMock
      loadAdWithRequest:_requestMock
               callback:[OCMArg checkWithBlock:^BOOL(id obj) {
                 if ([obj conformsToProtocol:@protocol(MaioRewardedLoadCallback)] &&
                     [obj conformsToProtocol:@protocol(MaioRewardedShowCallback)]) {
                   id<MaioRewardedLoadCallback, MaioRewardedShowCallback> maioDelegate = obj;
                   [maioDelegate didFail:self->_rewardedMock errorCode:errorCode];
                   return YES;
                 }
                 return NO;
               }]])));

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMMaioSDKErrorDomain
                                                      code:errorCode
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, config, expectedError);
}

- (void)testLoadAd {
  [self loadAd];
}

- (void)testMaioAdLoadFailure {
  [self loadAdFailureWithErrorCode:kMaioLoadFailureErroCode];
}

- (void)testMaioUnknownFailure {
  [self loadAdFailureWithErrorCode:kMaioUnknownFailureErroCode];
}

- (void)testAdPresent {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadAd];
  id<GADMediationRewardedAd> adDelegate = (id<GADMediationRewardedAd>)eventDelegate.rewardedAd;
  UIViewController *viewController = [[UIViewController alloc] init];
  OCMExpect([_rewardedMock showWithViewContext:viewController callback:OCMOCK_ANY]);

  [adDelegate presentFromViewController:viewController];
}

- (void)testMaioFailedToPresentAd {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadAd];
  id<GADMediationRewardedAd, MaioRewardedLoadCallback, MaioRewardedShowCallback> adDelegate =
      (id<GADMediationRewardedAd, MaioRewardedLoadCallback, MaioRewardedShowCallback>)
          eventDelegate.rewardedAd;
  UIViewController *viewController = [[UIViewController alloc] init];
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Show error called."];
  OCMExpect([_rewardedMock showWithViewContext:viewController callback:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        [adDelegate didFail:self->_rewardedMock errorCode:kMaioShowFailureErroCode];
        [expectation fulfill];
      });

  XCTAssertNil(eventDelegate.didFailToPresentError);
  [adDelegate presentFromViewController:viewController];
  [self waitForExpectations:@[ expectation ]];
  XCTAssertEqual(eventDelegate.didFailToPresentError.code, kMaioShowFailureErroCode);
  XCTAssertEqualObjects(eventDelegate.didFailToPresentError.domain, GADMMaioSDKErrorDomain);
}

- (void)testAdDidOpen {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadAd];
  id<MaioRewardedLoadCallback, MaioRewardedShowCallback> adDelegate =
      (id<MaioRewardedLoadCallback, MaioRewardedShowCallback>)eventDelegate.rewardedAd;

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 0);
  [adDelegate didOpen:_rewardedMock];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 1);
}

- (void)testAdDidClose {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadAd];
  id<MaioRewardedLoadCallback, MaioRewardedShowCallback> adDelegate =
      (id<MaioRewardedLoadCallback, MaioRewardedShowCallback>)eventDelegate.rewardedAd;

  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 0);
  [adDelegate didClose:_rewardedMock];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 1);
}

- (void)testDidReward {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadAd];
  id<MaioRewardedLoadCallback, MaioRewardedShowCallback> adDelegate =
      (id<MaioRewardedLoadCallback, MaioRewardedShowCallback>)eventDelegate.rewardedAd;

  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 0);
  [adDelegate didReward:_rewardedMock reward:OCMOCK_ANY];
  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 1);
}

@end

