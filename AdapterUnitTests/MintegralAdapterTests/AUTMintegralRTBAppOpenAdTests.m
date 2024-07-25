#import "GADMediationAdapterMintegral.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationAppOpenAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <MTGSDK/MTGSDK.h>
#import <MTGSDKSplash/MTGSplashAD.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterMintegralConstants.h"

static NSString *const kPlacementID = @"12345";
static NSString *const kUnitID = @"67890";
static NSString *const kBidResponse = @"bidResponse";

@interface AUTMintegralRTBAppOpenAdTests : XCTestCase
@end

@implementation AUTMintegralRTBAppOpenAdTests {
  /// An adapter instance that is used to test loading an app open ad.
  GADMediationAdapterMintegral *_adapter;

  /// A mock instance of MTGSplashAD.
  id _splashAdMock;

  /// An app open ad loader.
  __block id<MTGSplashADDelegate, GADMediationAppOpenAd> _adLoader;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterMintegral alloc] init];
  _splashAdMock = OCMClassMock([MTGSplashAD class]);
  OCMStub([_splashAdMock alloc]).andReturn(_splashAdMock);
  OCMStub([_splashAdMock initWithPlacementID:kPlacementID
                                      unitID:kUnitID
                                   countdown:GADMAdapterMintegralAppOpenSkipCountDownInSeconds
                                   allowSkip:YES])
      .andReturn(_splashAdMock);
}

- (void)tearDown {
  // Reset _adLoader after each test.
  _adLoader = nil;
}

- (nonnull AUTKMediationAppOpenAdEventDelegate *)loadRTBAppOpenAd {
  OCMStub([_splashAdMock setDelegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                           self->_adLoader = obj;
                           return [obj conformsToProtocol:@protocol(MTGSplashADDelegate)] &&
                                  [obj conformsToProtocol:@protocol(GADMediationAppOpenAd)];
                         }]]);
  OCMStub([_splashAdMock preloadWithBidToken:kBidResponse]).andDo(^(NSInvocation *invocation) {
    [self->_adLoader splashADPreloadSuccess:self->_splashAdMock];
  });
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  NSData *watermarkData = [[NSData alloc] init];
  configuration.watermark = watermarkData;
  OCMExpect([_splashAdMock setExtraInfo:watermarkData forKey:@"admob_watermark"]);

  AUTKMediationAppOpenAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadAppOpenAd(_adapter, configuration);
  XCTAssertNotNil(_adLoader);
  OCMVerifyAll(_splashAdMock);
  return eventDelegate;
}

- (void)testLoadRTBAppOpenAd {
  [self loadRTBAppOpenAd];
}

- (void)testLoadRTBAppOpenAdFailureForMissingPlacementID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadRTBAppOpenAdFailureForMissingAdUnit {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralPlacementID : kPlacementID};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadRTBAppOpenAdFailureForSplashAdLoadFail {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorAdNotAvailable
                                                  userInfo:nil];
  __block id<MTGSplashADDelegate> delegate = nil;
  OCMStub([_splashAdMock setDelegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                           delegate = obj;
                           return [obj conformsToProtocol:@protocol(MTGSplashADDelegate)];
                         }]]);
  OCMStub([_splashAdMock preloadWithBidToken:kBidResponse]).andDo(^(NSInvocation *invocation) {
    [delegate splashADPreloadFail:self->_splashAdMock error:expectedError];
  });
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;

  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, expectedError);
  XCTAssertNotNil(delegate);
}

- (void)testShowSuccess {
  UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
  OCMStub([_splashAdMock showBiddingADInKeyWindow:keyWindow customView:nil])
      .andDo(^(NSInvocation *invocation) {
        [self->_adLoader splashADShowSuccess:self->_splashAdMock];
      });
  OCMStub([_splashAdMock isBiddingADReadyToShow]).andReturn(YES);
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadRTBAppOpenAd];
  // Assert the initial values of the counts before they are verified after the "Act" steps.
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);

  [_adLoader presentFromViewController:[[UIViewController alloc] init]];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);

  [_adLoader splashADWillClose:_splashAdMock];

  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);

  [_adLoader splashADDidClose:_splashAdMock];

  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testShowFailureForAdNotReadyToShow {
  OCMStub([_splashAdMock isBiddingADReadyToShow]).andReturn(NO);
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadRTBAppOpenAd];

  [_adLoader presentFromViewController:[[UIViewController alloc] init]];

  XCTAssertEqual(eventDelegate.didFailToPresentError.code, GADMintegralErrorAdFailedToShow);
}

- (void)testShowFailureForAdShowFail {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorAdFailedToShow
                                                  userInfo:nil];
  UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
  OCMStub([_splashAdMock showBiddingADInKeyWindow:keyWindow customView:nil])
      .andDo(^(NSInvocation *invocation) {
        [self->_adLoader splashADShowFail:self->_splashAdMock error:expectedError];
      });
  OCMStub([_splashAdMock isBiddingADReadyToShow]).andReturn(YES);
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadRTBAppOpenAd];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);

  [_adLoader presentFromViewController:[[UIViewController alloc] init]];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqualObjects(eventDelegate.didFailToPresentError, expectedError);
}

- (void)testClick {
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadRTBAppOpenAd];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);

  [_adLoader splashADDidClick:_splashAdMock];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testUnusedDelegateMethodsNotCrashing {
  [self loadRTBAppOpenAd];

  [_adLoader splashADLoadSuccess:_splashAdMock];
  [_adLoader splashADLoadFail:_splashAdMock error:_splashAdMock];
  [_adLoader splashAD:_splashAdMock timeLeft:2];
  [_adLoader pointForSplashZoomOutADViewToAddOn:_splashAdMock];
  [_adLoader splashADDidLeaveApplication:_splashAdMock];
  [_adLoader splashZoomOutADViewClosed:_splashAdMock];
  [_adLoader splashZoomOutADViewDidShow:_splashAdMock];
  [_adLoader superViewForSplashZoomOutADViewToAddOn:_splashAdMock];
}

@end
