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

@interface AUTMintegralWaterfallAppOpenAdTests : XCTestCase
@end

@implementation AUTMintegralWaterfallAppOpenAdTests {
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

- (nonnull AUTKMediationAppOpenAdEventDelegate *)loadWaterfallAppOpenAd {
  OCMStub([_splashAdMock setDelegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                           self->_adLoader = obj;
                           return [obj conformsToProtocol:@protocol(MTGSplashADDelegate)] &&
                                  [obj conformsToProtocol:@protocol(GADMediationAppOpenAd)];
                         }]]);
  OCMStub([_splashAdMock preload]).andDo(^(NSInvocation *invocation) {
    [self->_adLoader splashADPreloadSuccess:OCMOCK_ANY];
  });
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : @"12345", GADMAdapterMintegralAdUnitID : @"67890"};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;

  return AUTKWaitAndAssertLoadAppOpenAd(_adapter, configuration);
}

- (void)testLoadWaterfallAppOpenAd {
  [self loadWaterfallAppOpenAd];
}

- (void)testLoadWaterfallAppOpenAdFailureForMissingPlacementID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralAdUnitID : @"67890"};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadWaterfallAppOpenAdFailureForMissingAdUnit {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  // Only placement ID is present in the credentials. Ad unit ID is missing.
  credentials.settings = @{GADMAdapterMintegralPlacementID : @"12345"};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadWaterfallAppOpenAdFailureForSplashAdLoadFail {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorAdNotAvailable
                                                  userInfo:nil];
  __block id<MTGSplashADDelegate> delegate = nil;
  OCMStub([_splashAdMock setDelegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                           delegate = obj;
                           return [obj conformsToProtocol:@protocol(MTGSplashADDelegate)];
                         }]]);
  OCMStub([_splashAdMock preload]).andDo(^(NSInvocation *invocation) {
    [delegate splashADPreloadFail:OCMOCK_ANY error:expectedError];
  });
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : @"12345", GADMAdapterMintegralAdUnitID : @"67890"};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;

  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, expectedError);
}

- (void)testShowSuccess {
  UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
  OCMStub([_splashAdMock showInKeyWindow:keyWindow customView:nil])
      .andDo(^(NSInvocation *invocation) {
        [self->_adLoader splashADShowSuccess:OCMOCK_ANY];
      });
  OCMStub([_splashAdMock isADReadyToShow]).andReturn(YES);
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadWaterfallAppOpenAd];

  [self->_adLoader presentFromViewController:[[UIViewController alloc] init]];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);

  [_adLoader splashADWillClose:OCMOCK_ANY];

  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);

  [_adLoader splashADDidClose:OCMOCK_ANY];

  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testShowFailureForAdNotReadyToShow {
  OCMStub([_splashAdMock isADReadyToShow]).andReturn(NO);
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadWaterfallAppOpenAd];

  [_adLoader presentFromViewController:[[UIViewController alloc] init]];

  XCTAssertEqual(eventDelegate.didFailToPresentError.code, GADMintegralErrorAdFailedToShow);
}

- (void)testShowFailureForAdShowFail {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorAdFailedToShow
                                                  userInfo:nil];
  UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
  OCMStub([_splashAdMock showInKeyWindow:keyWindow customView:nil])
      .andDo(^(NSInvocation *invocation) {
        [self->_adLoader splashADShowFail:OCMOCK_ANY error:expectedError];
      });
  OCMStub([_splashAdMock isADReadyToShow]).andReturn(YES);
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadWaterfallAppOpenAd];

  [_adLoader presentFromViewController:[[UIViewController alloc] init]];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqualObjects(eventDelegate.didFailToPresentError, expectedError);
}

- (void)testClick {
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadWaterfallAppOpenAd];

  [_adLoader splashADDidClick:OCMOCK_ANY];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testUnusedDelegateMethodsNotCrashing {
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadWaterfallAppOpenAd];

  [_adLoader splashADLoadSuccess:OCMOCK_ANY];
  [_adLoader splashADLoadFail:OCMOCK_ANY error:OCMOCK_ANY];
  [_adLoader splashAD:OCMOCK_ANY timeLeft:2];
  [_adLoader pointForSplashZoomOutADViewToAddOn:OCMOCK_ANY];
  [_adLoader splashADDidLeaveApplication:OCMOCK_ANY];
  [_adLoader splashZoomOutADViewClosed:OCMOCK_ANY];
  [_adLoader splashZoomOutADViewDidShow:OCMOCK_ANY];
  [_adLoader superViewForSplashZoomOutADViewToAddOn:OCMOCK_ANY];
}

@end
