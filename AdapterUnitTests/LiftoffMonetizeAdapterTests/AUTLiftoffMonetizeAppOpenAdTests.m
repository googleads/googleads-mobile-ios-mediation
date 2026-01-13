#import "GADMediationAdapterVungle.h"
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationAppOpenAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <VungleAdsSDK/VungleAdsSDK.h>
#import <XCTest/XCTest.h>

static NSString *const kPlacementID = @"12345";
static NSString *const kAppID = @"AppId";
static NSString *const kBidResponse = @"bidResponse";

@interface AUTLiftoffMonetizeAppOpenAdTests : XCTestCase
@end

@implementation AUTLiftoffMonetizeAppOpenAdTests {
  /// An adapter instance that is used to test loading an app open ad.
  GADMediationAdapterVungle *_adapter;

  /// A mock instance of VungleInterstitial. Note: Liftoff uses VungleInterstitial for displaying
  /// app open ads.
  id _appOpenMock;
}

- (void)setUp {
  [super setUp];

  _adapter = [[GADMediationAdapterVungle alloc] init];

  _appOpenMock = OCMClassMock([VungleInterstitial class]);
  OCMStub([_appOpenMock alloc]).andReturn(_appOpenMock);
}

- (void)testLoadAppOpenAdSetsCoppaYesWhenChildDirected {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @(YES);
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  GADMediationAppOpenLoadCompletionHandler completionHandler =
      ^(id<GADMediationAppOpenAd> _Nullable ad, NSError *_Nullable error) {
        return [[AUTKMediationAppOpenAdEventDelegate alloc] init];
      };
  id vunglePrivacySettingsMock = OCMClassMock([VunglePrivacySettings class]);

  [_adapter loadAppOpenAdForAdConfiguration:configuration completionHandler:completionHandler];

  OCMVerify([vunglePrivacySettingsMock setCOPPAStatus:YES]);
}

- (void)testLoadAppOpenAdSetsCoppaNoWhenNotChildDirected {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @(NO);
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  GADMediationAppOpenLoadCompletionHandler completionHandler =
      ^(id<GADMediationAppOpenAd> _Nullable ad, NSError *_Nullable error) {
        return [[AUTKMediationAppOpenAdEventDelegate alloc] init];
      };
  id vunglePrivacySettingsMock = OCMClassMock([VunglePrivacySettings class]);

  [_adapter loadAppOpenAdForAdConfiguration:configuration completionHandler:completionHandler];

  OCMVerify([vunglePrivacySettingsMock setCOPPAStatus:NO]);
}

- (AUTKMediationAppOpenAdEventDelegate *)loadAppOpenAdAndAssertLoadSuccess {
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterVungleApplicationID : kAppID, GADMAdapterVunglePlacementID : kPlacementID};
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  NSData *const watermark = [@"watermark" dataUsingEncoding:NSUTF8StringEncoding];
  configuration.watermark = watermark;
  __block id<VungleInterstitialDelegate> loadDelegate = nil;
  OCMExpect([_appOpenMock initWithPlacementId:kPlacementID]).andReturn(_appOpenMock);
  OCMExpect([_appOpenMock setDelegate:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  OCMExpect([_appOpenMock load:kBidResponse]).andDo(^(NSInvocation *invocation) {
    [loadDelegate interstitialAdDidLoad:self->_appOpenMock];
  });
  id vungleAdsExtrasMock = OCMClassMock([VungleAdsExtras class]);
  OCMStub([vungleAdsExtrasMock alloc]).andReturn(vungleAdsExtrasMock);
  OCMExpect([_appOpenMock setWithExtras:vungleAdsExtrasMock]);

  id<GADMediationAppOpenAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadAppOpenAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(_appOpenMock);
  OCMVerify([vungleAdsExtrasMock setWithWatermark:[watermark base64EncodedStringWithOptions:0]]);
  return delegate;
}

- (void)testLoadAppOpenAdSuccessWhenLiftoffSdkIsInitialized {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);

  [self loadAppOpenAdAndAssertLoadSuccess];
}

- (void)testLoadAppOpenAdSuccessWhenLiftoffSdkIsNotYetInitialized {
  id vungleRouterMock = OCMClassMock([GADMAdapterVungleRouter class]);
  OCMStub([vungleRouterMock sharedInstance]).andReturn(vungleRouterMock);
  __block id<GADMAdapterVungleDelegate> initDelegate = nil;
  OCMExpect([vungleRouterMock initWithAppId:kAppID delegate:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&initDelegate atIndex:3];
        [initDelegate initialized:YES error:nil];
      });

  [self loadAppOpenAdAndAssertLoadSuccess];
  OCMVerifyAll(vungleRouterMock);
}

/// Test app open ad load success for waterfall scenario (i.e. when there is no bid response in ad
/// configuration).
- (void)testLoadAppOpenAdSuccessWithNoBidResponse {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterVungleApplicationID : kAppID, GADMAdapterVunglePlacementID : kPlacementID};
  configuration.credentials = credentials;
  __block id<VungleInterstitialDelegate> loadDelegate = nil;
  OCMExpect([_appOpenMock initWithPlacementId:kPlacementID]).andReturn(_appOpenMock);
  OCMExpect([_appOpenMock setDelegate:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  OCMExpect([_appOpenMock load:nil]).andDo(^(NSInvocation *invocation) {
    [loadDelegate interstitialAdDidLoad:self->_appOpenMock];
  });

  id<GADMediationAppOpenAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadAppOpenAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(_appOpenMock);
}

- (void)testLoadAppOpenAdFailureWithNoAppId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *invalidServerParamsError =
      [NSError errorWithDomain:GADMAdapterVungleErrorDomain
                          code:GADMAdapterVungleErrorInvalidServerParameters
                      userInfo:nil];
  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, invalidServerParamsError);
}

- (void)testLoadAppOpenAdFailureWithEmptyAppId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterVungleApplicationID : @"", GADMAdapterVunglePlacementID : kPlacementID};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *invalidServerParamsError =
      [NSError errorWithDomain:GADMAdapterVungleErrorDomain
                          code:GADMAdapterVungleErrorInvalidServerParameters
                      userInfo:nil];
  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, invalidServerParamsError);
}

- (void)testLoadAppOpenAdFailureWithNoPlacementId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVungleApplicationID : kAppID};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *invalidServerParamsError =
      [NSError errorWithDomain:GADMAdapterVungleErrorDomain
                          code:GADMAdapterVungleErrorInvalidServerParameters
                      userInfo:nil];
  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, invalidServerParamsError);
}

- (void)testLoadAppOpenAdFailureWithEmptyPlacementId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterVungleApplicationID : kAppID, GADMAdapterVunglePlacementID : @""};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *invalidServerParamsError =
      [NSError errorWithDomain:GADMAdapterVungleErrorDomain
                          code:GADMAdapterVungleErrorInvalidServerParameters
                      userInfo:nil];
  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, invalidServerParamsError);
}

- (void)testLoadAppOpenAdFailureIfLiftoffFailsToLoadAd {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterVungleApplicationID : kAppID, GADMAdapterVunglePlacementID : kPlacementID};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;
  OCMStub([_appOpenMock initWithPlacementId:kPlacementID]).andReturn(_appOpenMock);
  __block id<VungleInterstitialDelegate> loadDelegate = nil;
  OCMStub([_appOpenMock setDelegate:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  NSError *liftoffLoadError =
      [NSError errorWithDomain:@"liftoff.domain"
                          code:1
                      userInfo:@{NSLocalizedDescriptionKey : @"Interstitial ad load failed."}];
  OCMStub([_appOpenMock load:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [loadDelegate interstitialAdDidFailToLoad:self->_appOpenMock withError:liftoffLoadError];
  });

  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, liftoffLoadError);
}

- (void)testLoadAppOpenAdFailureIfLiftoffInitializationFails {
  id vungleRouterMock = OCMClassMock([GADMAdapterVungleRouter class]);
  OCMStub([vungleRouterMock sharedInstance]).andReturn(vungleRouterMock);
  __block id<GADMAdapterVungleDelegate> initDelegate = nil;
  NSError *liftoffInitError =
      [NSError errorWithDomain:@"liftoff.domain"
                          code:10
                      userInfo:@{NSLocalizedDescriptionKey : @"Liftoff SDK failed to initialize"}];
  OCMStub([vungleRouterMock initWithAppId:kAppID delegate:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&initDelegate atIndex:3];
        [initDelegate initialized:NO error:liftoffInitError];
      });
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterVungleApplicationID : kAppID, GADMAdapterVunglePlacementID : kPlacementID};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;

  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, liftoffInitError);
}

/// Mocks a successful load of an app open ad, captures the instance of
/// AUTKMediationAppOpenAdEventDelegate and returns it.
- (AUTKMediationAppOpenAdEventDelegate *)loadAppOpenAdAndGetEventDelegate {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  return [self loadAppOpenAdAndAssertLoadSuccess];
}

- (void)testAppOpenAdPresentCallsPresentOnLiftoffSdkIfLiftoffCanPlayAd {
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAppOpenAdAndGetEventDelegate];
  OCMStub([_appOpenMock canPlayAd]).andReturn(YES);
  UIViewController *rootViewController = [[UIViewController alloc] init];

  [eventDelegate.appOpenAd presentFromViewController:rootViewController];

  OCMVerify([_appOpenMock presentWith:rootViewController]);
}

- (void)testAppOpenAdPresentInvokesPresentErrorIfLiftoffCannotPlayAd {
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAppOpenAdAndGetEventDelegate];
  OCMStub([_appOpenMock canPlayAd]).andReturn(NO);
  UIViewController *rootViewController = [[UIViewController alloc] init];

  [eventDelegate.appOpenAd presentFromViewController:rootViewController];

  NSError *expectedError = [NSError
      errorWithDomain:GADMAdapterVungleErrorDomain
                 code:GADMAdapterVungleErrorCannotPlayAd
             userInfo:@{
               NSLocalizedDescriptionKey : @"Failed to show app open ad from Liftoff Monetize.",
               NSLocalizedFailureReasonErrorKey :
                   @"Failed to show app open ad from Liftoff Monetize."
             }];
  XCTAssertEqualObjects(eventDelegate.didFailToPresentError, expectedError);
}

- (void)testAdWillPresentInvokesWillPresentFullScreenViewOnDelegate {
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAppOpenAdAndGetEventDelegate];
  id<VungleInterstitialDelegate> vungleDelegate =
      (id<VungleInterstitialDelegate>)eventDelegate.appOpenAd;
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);

  [vungleDelegate interstitialAdWillPresent:_appOpenMock];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
}

- (void)testAdDidPresentDoesNotCrash {
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAppOpenAdAndGetEventDelegate];
  id<VungleInterstitialDelegate> vungleDelegate =
      (id<VungleInterstitialDelegate>)eventDelegate.appOpenAd;

  // The body of this function is empty. This test just tests that this function doesn't crash.
  [vungleDelegate interstitialAdDidPresent:_appOpenMock];
}

- (void)testAdDidFailToPresentInvokesPresentErrorOnDelegate {
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAppOpenAdAndGetEventDelegate];
  id<VungleInterstitialDelegate> vungleDelegate =
      (id<VungleInterstitialDelegate>)eventDelegate.appOpenAd;
  NSError *liftoffError = [NSError
      errorWithDomain:@"liftoff.domain"
                 code:2
             userInfo:@{NSLocalizedDescriptionKey : @"Interstitial ad presentation failed."}];

  [vungleDelegate interstitialAdDidFailToPresent:_appOpenMock withError:liftoffError];

  NSError *presentationError = eventDelegate.didFailToPresentError;
  XCTAssertEqualObjects(presentationError, liftoffError);
}

- (void)testAdWillCloseInvokesWillDismissFullScreenViewOnDelegate {
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAppOpenAdAndGetEventDelegate];
  id<VungleInterstitialDelegate> vungleDelegate =
      (id<VungleInterstitialDelegate>)eventDelegate.appOpenAd;
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);

  [vungleDelegate interstitialAdWillClose:_appOpenMock];

  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);
}

- (void)testAdDidCloseInvokesDidDismissFullScreenViewOnDelegate {
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAppOpenAdAndGetEventDelegate];
  id<VungleInterstitialDelegate> vungleDelegate =
      (id<VungleInterstitialDelegate>)eventDelegate.appOpenAd;
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);

  [vungleDelegate interstitialAdDidClose:_appOpenMock];

  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testAdDidTrackImpressionInvokesReportImpressionOnDelegate {
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAppOpenAdAndGetEventDelegate];
  id<VungleInterstitialDelegate> vungleDelegate =
      (id<VungleInterstitialDelegate>)eventDelegate.appOpenAd;
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);

  [vungleDelegate interstitialAdDidTrackImpression:_appOpenMock];

  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testAdDidClickInvokesReportClickOnDelegate {
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAppOpenAdAndGetEventDelegate];
  id<VungleInterstitialDelegate> vungleDelegate =
      (id<VungleInterstitialDelegate>)eventDelegate.appOpenAd;
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);

  [vungleDelegate interstitialAdDidClick:_appOpenMock];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testAdWillLeaveApplicationDoesNotCrash {
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAppOpenAdAndGetEventDelegate];
  id<VungleInterstitialDelegate> vungleDelegate =
      (id<VungleInterstitialDelegate>)eventDelegate.appOpenAd;

  // The body of this function is empty. This test just tests that this function doesn't crash.
  [vungleDelegate interstitialAdWillLeaveApplication:_appOpenMock];
}

@end
