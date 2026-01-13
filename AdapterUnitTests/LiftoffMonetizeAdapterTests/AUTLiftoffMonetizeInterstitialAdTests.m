#import "GADMediationAdapterVungle.h"
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationInterstitialAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <VungleAdsSDK/VungleAdsSDK.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

static NSString *const kPlacementID = @"12345";
static NSString *const kAppID = @"AppId";
static NSString *const kBidResponse = @"bidResponse";

@interface AUTLiftoffMonetizeInterstitialAdTests : XCTestCase

@end

@implementation AUTLiftoffMonetizeInterstitialAdTests {
  /// An adapter instance that is used to test loading an interstitial ad.
  GADMediationAdapterVungle *_adapter;

  /// A mock instance of VungleInterstitial.
  id _interstitialMock;
}

- (void)setUp {
  [super setUp];

  _adapter = [[GADMediationAdapterVungle alloc] init];

  _interstitialMock = OCMClassMock([VungleInterstitial class]);
  OCMStub([_interstitialMock alloc]).andReturn(_interstitialMock);
}

- (void)testLoadInterstitialSetsCoppaYesWhenChildDirected {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment =
      [NSNumber numberWithInt:1];
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  GADMediationInterstitialLoadCompletionHandler completionHandler =
      ^(id<GADMediationInterstitialAd> _Nullable ad, NSError *_Nullable error) {
        return [[AUTKMediationInterstitialAdEventDelegate alloc] init];
      };
  id vunglePrivacySettingsMock = OCMClassMock([VunglePrivacySettings class]);

  [_adapter loadInterstitialForAdConfiguration:configuration completionHandler:completionHandler];

  OCMVerify([vunglePrivacySettingsMock setCOPPAStatus:YES]);
}

- (void)testLoadInterstitialSetsCoppaNoWhenNotChildDirected {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment =
      [NSNumber numberWithInt:0];
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  GADMediationInterstitialLoadCompletionHandler completionHandler =
      ^(id<GADMediationInterstitialAd> _Nullable ad, NSError *_Nullable error) {
        return [[AUTKMediationInterstitialAdEventDelegate alloc] init];
      };
  id vunglePrivacySettingsMock = OCMClassMock([VunglePrivacySettings class]);

  [_adapter loadInterstitialForAdConfiguration:configuration completionHandler:completionHandler];

  OCMVerify([vunglePrivacySettingsMock setCOPPAStatus:NO]);
}

- (AUTKMediationInterstitialAdEventDelegate *)
    loadInterstitialAndAssertLoadSuccessWithCredentials:(AUTKMediationCredentials *)credentials
                                              andExtras:(VungleAdNetworkExtras *)extras {
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = extras;
  configuration.bidResponse = kBidResponse;
  __block id<VungleInterstitialDelegate> loadDelegate = nil;
  OCMExpect([_interstitialMock initWithPlacementId:kPlacementID]).andReturn(_interstitialMock);
  OCMExpect([_interstitialMock setDelegate:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  OCMExpect([_interstitialMock load:kBidResponse]).andDo(^(NSInvocation *invocation) {
    [loadDelegate interstitialAdDidLoad:self->_interstitialMock];
  });
  NSData *const watermark = [@"watermark" dataUsingEncoding:NSUTF8StringEncoding];
  configuration.watermark = watermark;
  id vungleAdsExtrasMock = OCMClassMock([VungleAdsExtras class]);
  OCMStub([vungleAdsExtrasMock alloc]).andReturn(vungleAdsExtrasMock);
  OCMExpect([_interstitialMock setWithExtras:vungleAdsExtrasMock]);

  id<GADMediationInterstitialAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(_interstitialMock);
  OCMVerify([vungleAdsExtrasMock setWithWatermark:[watermark base64EncodedStringWithOptions:0]]);
  return delegate;
}

- (void)testLoadInterstitialSuccessWhenLiftoffSdkIsInitialized {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};

  [self loadInterstitialAndAssertLoadSuccessWithCredentials:credentials andExtras:nil];
}

- (void)testLoadInterstitialSuccessWhenLiftoffSdkIsNotYetInitialized {
  id vungleRouterMock = OCMClassMock([GADMAdapterVungleRouter class]);
  OCMStub([vungleRouterMock sharedInstance]).andReturn(vungleRouterMock);
  __block id<GADMAdapterVungleDelegate> initDelegate = nil;
  OCMExpect([vungleRouterMock initWithAppId:kAppID delegate:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&initDelegate atIndex:3];
        [initDelegate initialized:true error:nil];
      });
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterVunglePlacementID : kPlacementID, GADMAdapterVungleApplicationID : kAppID};

  [self loadInterstitialAndAssertLoadSuccessWithCredentials:credentials andExtras:nil];
  OCMVerifyAll(vungleRouterMock);
}

- (void)testLoadInterstitialFailureWhenLiftoffFailsToLoadAd {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  OCMStub([_interstitialMock initWithPlacementId:kPlacementID]).andReturn(_interstitialMock);
  __block id<VungleInterstitialDelegate> loadDelegate = nil;
  OCMStub([_interstitialMock setDelegate:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  NSError *liftoffError =
      [NSError errorWithDomain:@"liftoff.domain"
                          code:1
                      userInfo:@{NSLocalizedDescriptionKey : @"Interstitial ad load failed."}];
  OCMStub([_interstitialMock load:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [loadDelegate interstitialAdDidFailToLoad:self->_interstitialMock withError:liftoffError];
  });

  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, liftoffError);
}

/// Mocks a successful load of an interstitial ad, captures the instance of
/// AUTKMediationInterstitialAdEventDelegate and returns it.
- (AUTKMediationInterstitialAdEventDelegate *)loadInterstitialAndGetEventDelegate {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  return [self loadInterstitialAndAssertLoadSuccessWithCredentials:credentials andExtras:nil];
}

- (void)testInterstitialPresentCallsPresentOnLiftoffSdk {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadInterstitialAndGetEventDelegate];
  UIViewController *rootViewController = [[UIViewController alloc] init];

  [eventDelegate.interstitialAd presentFromViewController:rootViewController];

  OCMVerify([_interstitialMock presentWith:rootViewController]);
}

- (void)testInterstitialAdWillPresentInvokesWillPresentFullScreenViewOnDelegate {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadInterstitialAndGetEventDelegate];
  id<VungleInterstitialDelegate> vungleInterstitialDelegate =
      (id<VungleInterstitialDelegate>)eventDelegate.interstitialAd;
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);

  [vungleInterstitialDelegate interstitialAdWillPresent:_interstitialMock];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
}

- (void)testInterstitialAdDidPresentDoesNotCrash {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadInterstitialAndGetEventDelegate];
  id<VungleInterstitialDelegate> vungleInterstitialDelegate =
      (id<VungleInterstitialDelegate>)eventDelegate.interstitialAd;

  // The body of this function is empty. This test just tests that this function doesn't crash.
  [vungleInterstitialDelegate interstitialAdDidPresent:_interstitialMock];
}

- (void)testInterstitialAdDidFailToPresentInvokesPresentErrorOnDelegate {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadInterstitialAndGetEventDelegate];
  id<VungleInterstitialDelegate> vungleInterstitialDelegate =
      (id<VungleInterstitialDelegate>)eventDelegate.interstitialAd;
  NSError *liftoffError = [NSError
      errorWithDomain:@"liftoff.domain"
                 code:2
             userInfo:@{NSLocalizedDescriptionKey : @"Interstitial ad presentation failed."}];
  [vungleInterstitialDelegate interstitialAdDidFailToPresent:_interstitialMock
                                                   withError:liftoffError];

  NSError *presentationError = eventDelegate.didFailToPresentError;
  XCTAssertEqualObjects(presentationError, liftoffError);
}

- (void)testInterstitialAdWillCloseInvokesWillDismissFullScreenViewOnDelegate {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadInterstitialAndGetEventDelegate];
  id<VungleInterstitialDelegate> vungleInterstitialDelegate =
      (id<VungleInterstitialDelegate>)eventDelegate.interstitialAd;
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);

  [vungleInterstitialDelegate interstitialAdWillClose:_interstitialMock];

  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);
}

- (void)testInterstitialAdDidCloseInvokesDidDismissFullScreenViewOnDelegate {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadInterstitialAndGetEventDelegate];
  id<VungleInterstitialDelegate> vungleInterstitialDelegate =
      (id<VungleInterstitialDelegate>)eventDelegate.interstitialAd;
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);

  [vungleInterstitialDelegate interstitialAdDidClose:_interstitialMock];

  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testInterstitialAdDidTrackImpressionInvokesReportImpressionOnDelegate {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadInterstitialAndGetEventDelegate];
  id<VungleInterstitialDelegate> vungleInterstitialDelegate =
      (id<VungleInterstitialDelegate>)eventDelegate.interstitialAd;
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);

  [vungleInterstitialDelegate interstitialAdDidTrackImpression:_interstitialMock];

  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testInterstitialAdDidClickInvokesReportClickOnDelegate {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadInterstitialAndGetEventDelegate];
  id<VungleInterstitialDelegate> vungleInterstitialDelegate =
      (id<VungleInterstitialDelegate>)eventDelegate.interstitialAd;
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);

  [vungleInterstitialDelegate interstitialAdDidClick:_interstitialMock];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testInterstitialAdWillLeaveApplicationDoesNotCrash {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadInterstitialAndGetEventDelegate];
  id<VungleInterstitialDelegate> vungleInterstitialDelegate =
      (id<VungleInterstitialDelegate>)eventDelegate.interstitialAd;

  // The body of this function only calls the deprecated function willBackgroundApplication on the
  // delegate. Not testing for that function call since it is deprecated. Just testing that this
  // function doesn't crash.
  [vungleInterstitialDelegate interstitialAdWillLeaveApplication:_interstitialMock];
}

@end
