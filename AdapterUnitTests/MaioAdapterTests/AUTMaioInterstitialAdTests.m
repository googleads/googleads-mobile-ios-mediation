#import "GADMediationAdapterMaio.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationInterstitialAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <Maio/Maio-Swift.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMMaioConstants.h"

static const NSInteger kMaioLoadFailureErroCode = 10000;
static const NSInteger kMaioShowFailureErroCode = 20000;
static const NSInteger kMaioUnknownFailureErroCode = 99999;

@interface AUTMaioInterstitialAdTests : XCTestCase
@end

@implementation AUTMaioInterstitialAdTests {
  /// The adapte under test.
  GADMediationAdapterMaio *_adapter;

  /// Mock for MaioRequest.
  id _requestMock;

  /// Mock for MaioInterstitial.
  id _interstitialMock;
}

- (void)setUp {
  _adapter = [[GADMediationAdapterMaio alloc] init];
  _requestMock = OCMClassMock([MaioRequest class]);
  OCMStub([_requestMock alloc]).andReturn(_requestMock);
  _interstitialMock = OCMClassMock([MaioInterstitial class]);
}

- (void)tearDown {
  OCMVerifyAll(_requestMock);
  OCMVerifyAll(_interstitialMock);
}

- (AUTKMediationInterstitialAdEventDelegate *)loadAd {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMMaioAdapterZoneIdKey : @"zoneID"};
  AUTKMediationInterstitialAdConfiguration *config =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  config.credentials = credentials;
  config.isTestRequest = YES;

  OCMExpect([_requestMock initWithZoneId:@"zoneID" testMode:YES]).andReturn(_requestMock);
  OCMExpect(
      ClassMethod(([_interstitialMock
          loadAdWithRequest:_requestMock
                   callback:[OCMArg checkWithBlock:^BOOL(id obj) {
                     if ([obj conformsToProtocol:@protocol(MaioInterstitialLoadCallback)] &&
                         [obj conformsToProtocol:@protocol(MaioInterstitialShowCallback)]) {
                       id<MaioInterstitialLoadCallback, MaioInterstitialShowCallback> maioDelegate =
                           obj;
                       [maioDelegate didLoad:self->_interstitialMock];
                       return YES;
                     }
                     return NO;
                   }]])))
      .andReturn(_interstitialMock);

  return AUTKWaitAndAssertLoadInterstitialAd(_adapter, config);
}

- (void)loadAdFailureWithErrorCode:(NSInteger)errorCode {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMMaioAdapterZoneIdKey : @"zoneID"};
  AUTKMediationInterstitialAdConfiguration *config =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  config.credentials = credentials;
  config.isTestRequest = YES;

  OCMExpect([_requestMock initWithZoneId:@"zoneID" testMode:YES]).andReturn(_requestMock);
  OCMExpect(ClassMethod(([_interstitialMock
      loadAdWithRequest:_requestMock
               callback:[OCMArg checkWithBlock:^BOOL(id obj) {
                 if ([obj conformsToProtocol:@protocol(MaioInterstitialLoadCallback)] &&
                     [obj conformsToProtocol:@protocol(MaioInterstitialShowCallback)]) {
                   id<MaioInterstitialLoadCallback, MaioInterstitialShowCallback> maioDelegate =
                       obj;
                   [maioDelegate didFail:self->_interstitialMock errorCode:errorCode];
                   return YES;
                 }
                 return NO;
               }]])));

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMMaioSDKErrorDomain
                                                      code:errorCode
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, config, expectedError);
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
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];
  id<GADMediationInterstitialAd> adDelegate =
      (id<GADMediationInterstitialAd>)eventDelegate.interstitialAd;
  UIViewController *viewController = [[UIViewController alloc] init];
  OCMExpect([_interstitialMock showWithViewContext:viewController callback:OCMOCK_ANY]);

  [adDelegate presentFromViewController:viewController];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
}

- (void)testMaioFailedToPresentAd {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];
  id<GADMediationInterstitialAd, MaioInterstitialLoadCallback, MaioInterstitialShowCallback>
      adDelegate = (id<GADMediationInterstitialAd, MaioInterstitialLoadCallback,
                       MaioInterstitialShowCallback>)eventDelegate.interstitialAd;
  UIViewController *viewController = [[UIViewController alloc] init];
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Show error called."];
  OCMExpect([_interstitialMock showWithViewContext:viewController callback:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        [adDelegate didFail:self->_interstitialMock errorCode:kMaioShowFailureErroCode];
        [expectation fulfill];
      });

  XCTAssertNil(eventDelegate.didFailToPresentError);
  [adDelegate presentFromViewController:viewController];
  [self waitForExpectations:@[ expectation ]];
  XCTAssertEqual(eventDelegate.didFailToPresentError.code, kMaioShowFailureErroCode);
  XCTAssertEqualObjects(eventDelegate.didFailToPresentError.domain, GADMMaioSDKErrorDomain);
}

- (void)testAdDidOpen {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];
  id<MaioInterstitialLoadCallback, MaioInterstitialShowCallback> adDelegate =
      (id<MaioInterstitialLoadCallback, MaioInterstitialShowCallback>)eventDelegate.interstitialAd;

  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  [adDelegate didOpen:_interstitialMock];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testAdDidClose {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];
  id<MaioInterstitialLoadCallback, MaioInterstitialShowCallback> adDelegate =
      (id<MaioInterstitialLoadCallback, MaioInterstitialShowCallback>)eventDelegate.interstitialAd;

  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  [adDelegate didClose:_interstitialMock];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);
}

@end
