#import "GADMediationAdapterFyber.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationInterstitialAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IASDKCore/IASDKCore.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterFyberConstants.h"
#import "GADMAdapterFyberExtras.h"

@interface AUTDTExchangeInterstitialAdTests : XCTestCase
@end

static NSString *const kDTExchangeAppID = @"12345";
static NSString *const kDTExchangeSpotID = @"67890";

@implementation AUTDTExchangeInterstitialAdTests {
  /// An adapter instance that is used to test loading an interstitial ad.
  GADMediationAdapterFyber *_adapter;

  /// IASDKCore mock.
  id _IASDKCoreMock;

  /// IAAdSpot mock.
  id _IAAdSpotMock;

  /// IAAdRequest mock.
  id _IAAdRequestMock;

  /// IAAdRequestBuilder mock.
  id _IAAdRequestBuilderMock;

  /// IAAdSpotBuilder mock.
  id _IAAdSpotBuilderMock;

  /// IAMRAIDContentController mock.
  id _IAMRAIDContentControllerMock;

  /// IAMRAIDContentController mock.
  id _IAMRAIDContentControllerBuilderMock;

  /// IAVideoContentController mock.
  id _IAVideoContentControllerMock;

  /// IAVideoContentControllerBuilder mock.
  id _IAVideoContentControllerBuilderMock;

  /// IAFullscreenUnitController mock.
  id _IAFullscreenUnitControllerMock;

  /// IAFullscreenUnitControllerBuilder mock.
  id _IAFullscreenUnitControllerBuilderMock;
}

- (void)setUp {
  [super setUp];

  _adapter = [[GADMediationAdapterFyber alloc] init];

  _IASDKCoreMock = OCMClassMock([IASDKCore class]);
  OCMStub(ClassMethod([_IASDKCoreMock sharedInstance])).andReturn(_IASDKCoreMock);
  OCMStub([_IASDKCoreMock setMediationType:[OCMArg isKindOfClass:[IAMediationAdMob class]]]);

  _IAMRAIDContentControllerBuilderMock =
      OCMProtocolMock(@protocol(IAMRAIDContentControllerBuilder));
  _IAMRAIDContentControllerMock = OCMClassMock([IAMRAIDContentController class]);
  OCMStub(ClassMethod([_IAMRAIDContentControllerMock build:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(id<IAMRAIDContentControllerBuilder>);
        [invocation getArgument:&completionHandler atIndex:2];
        completionHandler(self->_IAAdRequestBuilderMock);
      })
      .andReturn(_IAMRAIDContentControllerMock);

  _IAVideoContentControllerBuilderMock =
      OCMProtocolMock(@protocol(IAVideoContentControllerBuilder));
  _IAVideoContentControllerMock = OCMClassMock([IAVideoContentController class]);
  OCMStub(ClassMethod([_IAVideoContentControllerMock build:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(id<IAVideoContentControllerBuilder>);
        [invocation getArgument:&completionHandler atIndex:2];
        completionHandler(self->_IAVideoContentControllerBuilderMock);
      })
      .andReturn(_IAVideoContentControllerMock);

  _IAFullscreenUnitControllerBuilderMock =
      OCMProtocolMock(@protocol(IAFullscreenUnitControllerBuilder));
  OCMStub([_IAFullscreenUnitControllerBuilderMock setUnitDelegate:OCMOCK_ANY]);
  OCMStub([_IAFullscreenUnitControllerBuilderMock addSupportedContentController:OCMOCK_ANY]);
  _IAFullscreenUnitControllerMock = OCMClassMock([IAFullscreenUnitController class]);
  OCMStub(ClassMethod([_IAFullscreenUnitControllerMock build:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(id<IAFullscreenUnitControllerBuilder>);
        [invocation getArgument:&completionHandler atIndex:2];
        completionHandler(self->_IAFullscreenUnitControllerBuilderMock);
      })
      .andReturn(_IAFullscreenUnitControllerMock);

  _IAAdRequestBuilderMock = OCMProtocolMock(@protocol(IAAdRequestBuilder));
  OCMStub([_IAAdRequestBuilderMock setUseSecureConnections:NO]);
  OCMStub([_IAAdRequestBuilderMock setTimeout:10]);
  _IAAdRequestMock = OCMClassMock([IAAdRequest class]);
  OCMStub(ClassMethod([_IAAdRequestMock build:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(id<IAAdRequestBuilder>);
        [invocation getArgument:&completionHandler atIndex:2];
        completionHandler(self->_IAAdRequestBuilderMock);
      })
      .andReturn(_IAAdRequestMock);

  _IAAdSpotBuilderMock = OCMProtocolMock(@protocol(IAAdSpotBuilder));
  OCMStub([_IAAdSpotBuilderMock setAdRequest:_IAAdRequestMock]);
  OCMStub([_IAAdSpotBuilderMock addSupportedUnitController:_IAFullscreenUnitControllerMock]);
  _IAAdSpotMock = OCMClassMock([IAAdSpot class]);
  OCMStub(ClassMethod([_IAAdSpotMock build:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(id<IAAdSpotBuilder>);
        [invocation getArgument:&completionHandler atIndex:2];
        completionHandler(self->_IAAdSpotBuilderMock);
      })
      .andReturn(_IAAdSpotMock);
}

- (void)tearDown {
  OCMVerifyAll(_IASDKCoreMock);
  OCMVerifyAll(_IAAdSpotMock);
  OCMVerifyAll(_IAAdRequestMock);
  OCMVerifyAll(_IAAdRequestBuilderMock);
  OCMVerifyAll(_IAAdSpotBuilderMock);
  OCMVerifyAll(_IAMRAIDContentControllerMock);
  OCMVerifyAll(_IAMRAIDContentControllerBuilderMock);
  OCMVerifyAll(_IAVideoContentControllerMock);
  OCMVerifyAll(_IAVideoContentControllerBuilderMock);
  OCMVerifyAll(_IAFullscreenUnitControllerMock);
  OCMVerifyAll(_IAFullscreenUnitControllerBuilderMock);
}

- (AUTKMediationInterstitialAdEventDelegate *)loadAd {
  OCMStub([_IASDKCoreMock initWithAppID:kDTExchangeAppID
                        completionBlock:OCMOCK_ANY
                        completionQueue:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(YES, nil);
      });
  OCMExpect([_IASDKCoreMock setKeywords:@"1234"]);
  OCMExpect([_IAAdRequestBuilderMock setSpotID:kDTExchangeSpotID]);
  OCMStub([_IAAdSpotMock fetchAdWithCompletion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained void (^completionHandler)(
        IAAdSpot *_Nullable adSpot, IAAdModel *_Nullable adModel, NSError *_Nullable error);
    [invocation getArgument:&completionHandler atIndex:2];
    completionHandler(nil, nil, nil);
  });

  GADMAdapterFyberExtras *extras = [[GADMAdapterFyberExtras alloc] init];
  extras.keywords = @"1234";
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterFyberApplicationID : kDTExchangeAppID,
    GADMAdapterFyberSpotID : kDTExchangeSpotID
  };
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = extras;
  configuration.topViewController = [[UIViewController alloc] init];
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);
  XCTAssertNotNil(eventDelegate);
  return eventDelegate;
}

- (void)testLoad {
  [self loadAd];
}

- (void)testLoadFailureForInitFailure {
  NSError *expectedError = [[NSError alloc] initWithDomain:@"com.Fyber.domain"
                                                      code:123456
                                                  userInfo:nil];
  OCMStub([_IASDKCoreMock initWithAppID:kDTExchangeAppID
                        completionBlock:OCMOCK_ANY
                        completionQueue:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(NO, expectedError);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterFyberApplicationID : kDTExchangeAppID,
    GADMAdapterFyberSpotID : kDTExchangeSpotID
  };
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureForMissingAppID {
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterFyberErrorDomain
                                 code:GADMAdapterFyberErrorInvalidServerParameters
                             userInfo:nil];

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterFyberSpotID : kDTExchangeSpotID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureForMissingSpotID {
  OCMStub([_IASDKCoreMock initWithAppID:kDTExchangeAppID
                        completionBlock:OCMOCK_ANY
                        completionQueue:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(NO, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterFyberApplicationID : kDTExchangeAppID,
  };
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterFyberErrorDomain
                                 code:GADMAdapterFyberErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureForFyberFailedToLoadAd {
  OCMStub([_IASDKCoreMock initWithAppID:kDTExchangeAppID
                        completionBlock:OCMOCK_ANY
                        completionQueue:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(YES, nil);
      });
  OCMExpect([_IAAdRequestBuilderMock setSpotID:kDTExchangeSpotID]);
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterFyberErrorDomain
                                 code:GADMAdapterFyberErrorInvalidServerParameters
                             userInfo:nil];
  OCMStub([_IAAdSpotMock fetchAdWithCompletion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained void (^completionHandler)(
        IAAdSpot *_Nullable adSpot, IAAdModel *_Nullable adModel, NSError *_Nullable error);
    [invocation getArgument:&completionHandler atIndex:2];
    completionHandler(nil, nil, expectedError);
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterFyberApplicationID : kDTExchangeAppID,
    GADMAdapterFyberSpotID : kDTExchangeSpotID
  };
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
}

- (void)testPresentFromViewController {
  OCMStub([_IAFullscreenUnitControllerMock isPresented]).andReturn(NO);
  OCMStub([_IAFullscreenUnitControllerMock isReady]).andReturn(YES);
  OCMExpect([_IAFullscreenUnitControllerMock showAdAnimated:YES completion:nil]);

  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];
  [eventDelegate.interstitialAd presentFromViewController:[[UIViewController alloc] init]];
}

- (void)testPresentFromViewControllerFailureForAlreadyPresented {
  OCMStub([_IAFullscreenUnitControllerMock isPresented]).andReturn(YES);

  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];
  [eventDelegate.interstitialAd presentFromViewController:[[UIViewController alloc] init]];

  XCTAssertEqual(eventDelegate.didFailToPresentError.code, GADMAdapterFyberErrorAdAlreadyUsed);
  XCTAssertEqualObjects(eventDelegate.didFailToPresentError.domain, GADMAdapterFyberErrorDomain);
}

- (void)testPresentFromViewControllerFailureForAdNotReady {
  OCMStub([_IAFullscreenUnitControllerMock isPresented]).andReturn(NO);
  OCMStub([_IAFullscreenUnitControllerMock isReady]).andReturn(NO);

  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];
  [eventDelegate.interstitialAd presentFromViewController:[[UIViewController alloc] init]];

  XCTAssertEqual(eventDelegate.didFailToPresentError.code, GADMAdapterFyberErrorAdNotReady);
  XCTAssertEqualObjects(eventDelegate.didFailToPresentError.domain, GADMAdapterFyberErrorDomain);
}

- (void)testPresentFromViewControllerFailureForAdExpired {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];

  id<IAUnitDelegate> unitDelegate = (id<IAUnitDelegate>)eventDelegate.interstitialAd;
  [unitDelegate IAAdDidExpire:nil];

  XCTAssertEqual(eventDelegate.didFailToPresentError.code,
                 GADMAdapterFyberErrorPresentationFailureForAdExpiration);
}

- (void)testParentViewController {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];

  id<IAUnitDelegate> unitDelegate = (id<IAUnitDelegate>)eventDelegate.interstitialAd;

  id parentController = [unitDelegate IAParentViewControllerForUnitController:nil];
  XCTAssertTrue([parentController isKindOfClass:[UIViewController class]]);
}

- (void)testClick {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];

  id<IAUnitDelegate> unitDelegate = (id<IAUnitDelegate>)eventDelegate.interstitialAd;
  [unitDelegate IAAdDidReceiveClick:nil];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testImpression {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];

  id<IAUnitDelegate> unitDelegate = (id<IAUnitDelegate>)eventDelegate.interstitialAd;
  [unitDelegate IAAdWillLogImpression:nil];

  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testWillPresent {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];

  id<IAUnitDelegate> unitDelegate = (id<IAUnitDelegate>)eventDelegate.interstitialAd;
  [unitDelegate IAUnitControllerWillPresentFullscreen:nil];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
}

- (void)testWillDismiss {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];

  id<IAUnitDelegate> unitDelegate = (id<IAUnitDelegate>)eventDelegate.interstitialAd;
  [unitDelegate IAUnitControllerWillDismissFullscreen:nil];

  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);
}

- (void)testDidDismiss {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];

  id<IAUnitDelegate> unitDelegate = (id<IAUnitDelegate>)eventDelegate.interstitialAd;
  [unitDelegate IAUnitControllerDidDismissFullscreen:nil];

  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testUnusedCallbacks {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];

  id<IAUnitDelegate> unitDelegate = (id<IAUnitDelegate>)eventDelegate.interstitialAd;
  [unitDelegate IAUnitControllerWillOpenExternalApp:nil];
}

@end
