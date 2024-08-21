#import "GADMediationAdapterVungle.h"
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"
#import "VungleAdNetworkExtras.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationBannerAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <VungleAdsSDK/VungleAdsSDK.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

static NSString *const kPlacementID = @"12345";
static NSString *const kAppID = @"AppId";
static NSString *const kBidResponse = @"bidResponse";

@interface AUTLiftoffMonetizeBannerAdTests : XCTestCase

@end

@implementation AUTLiftoffMonetizeBannerAdTests {
  /// An adapter instance that is used to test loading of a banner ad.
  GADMediationAdapterVungle *_adapter;

  /// A mock instance of VungleBannerView.
  id _bannerMock;
}

- (void)setUp {
  [super setUp];

  _adapter = [[GADMediationAdapterVungle alloc] init];

  _bannerMock = OCMClassMock([VungleBannerView class]);
  OCMStub([_bannerMock alloc]).andReturn(_bannerMock);
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
}

- (void)testLoadBannerSetsCoppaYesWhenChildDirected {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment =
      [NSNumber numberWithInt:1];
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  GADMediationBannerLoadCompletionHandler completionHandler =
      ^(id<GADMediationBannerAd> _Nullable ad, NSError *_Nullable error) {
        return [[AUTKMediationBannerAdEventDelegate alloc] init];
      };
  id vunglePrivacySettingsMock = OCMClassMock([VunglePrivacySettings class]);

  [_adapter loadBannerForAdConfiguration:configuration completionHandler:completionHandler];

  OCMVerify([vunglePrivacySettingsMock setCOPPAStatus:YES]);
}

- (void)testLoadBannerSetsCoppaNoWhenNotChildDirected {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment =
      [NSNumber numberWithInt:0];
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  GADMediationBannerLoadCompletionHandler completionHandler =
      ^(id<GADMediationBannerAd> _Nullable ad, NSError *_Nullable error) {
        return [[AUTKMediationBannerAdEventDelegate alloc] init];
      };
  id vunglePrivacySettingsMock = OCMClassMock([VunglePrivacySettings class]);

  [_adapter loadBannerForAdConfiguration:configuration completionHandler:completionHandler];

  OCMVerify([vunglePrivacySettingsMock setCOPPAStatus:NO]);
}

- (AUTKMediationBannerAdEventDelegate *)
    loadBannerAndAssertLoadSuccessWithCredentials:(AUTKMediationCredentials *)credentials
                                        andExtras:(VungleAdNetworkExtras *)extras {
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = extras;
  configuration.bidResponse = kBidResponse;
  configuration.adSize = GADAdSizeBanner;
  __block id<VungleBannerViewDelegate> loadDelegate = nil;
  OCMExpect([_bannerMock initWithPlacementId:kPlacementID
                                vungleAdSize:VungleAdSize.VungleAdSizeBannerRegular])
      .andReturn(_bannerMock);
  OCMExpect([_bannerMock setDelegate:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  OCMExpect([_bannerMock load:kBidResponse]).andDo(^(NSInvocation *invocation) {
    [loadDelegate bannerAdDidLoad:self->_bannerMock];
  });
  NSData *const watermark = [@"watermark" dataUsingEncoding:NSUTF8StringEncoding];
  configuration.watermark = watermark;
  id vungleAdsExtrasMock = OCMClassMock([VungleAdsExtras class]);
  OCMStub([vungleAdsExtrasMock alloc]).andReturn(vungleAdsExtrasMock);
  OCMExpect([_bannerMock setWithExtras:vungleAdsExtrasMock]);

  id<GADMediationBannerAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(_bannerMock);
  OCMVerify([vungleAdsExtrasMock setWithWatermark:[watermark base64EncodedStringWithOptions:0]]);
  return delegate;
}

- (void)testLoadBannerSuccessWhenLiftoffSdkIsInitialized {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};

  [self loadBannerAndAssertLoadSuccessWithCredentials:credentials andExtras:nil];
}

- (void)testLoadBannerSuccessWhenLiftoffSdkIsNotYetInitialized {
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

  [self loadBannerAndAssertLoadSuccessWithCredentials:credentials andExtras:nil];
  OCMVerifyAll(vungleRouterMock);
}

- (void)testLoadBannerFailureWhenLiftoffFailsToLoadAd {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;
  OCMStub([_bannerMock initWithPlacementId:kPlacementID
                              vungleAdSize:VungleAdSize.VungleAdSizeBannerRegular])
      .andReturn(_bannerMock);
  __block id<VungleBannerViewDelegate> loadDelegate = nil;
  OCMStub([_bannerMock setDelegate:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  NSError *liftoffError =
      [NSError errorWithDomain:@"liftoff.domain"
                          code:1
                      userInfo:@{NSLocalizedDescriptionKey : @"Banner ad load failed."}];
  OCMStub([_bannerMock load:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [loadDelegate bannerAdDidFail:self->_bannerMock withError:liftoffError];
  });

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, liftoffError);
}

/// Mocks a successful load of a banner ad, captures the instance of
/// AUTKMediationBannerAdEventDelegate and returns it.
- (AUTKMediationBannerAdEventDelegate *)loadBannerAndGetEventDelegate {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  return [self loadBannerAndAssertLoadSuccessWithCredentials:credentials andExtras:nil];
}

- (void)testBannerAdWillPresentDoesNotCrash {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAndGetEventDelegate];
  id<VungleBannerViewDelegate> vungleBannerDelegate =
      (id<VungleBannerViewDelegate>)eventDelegate.bannerAd;

  // The body of this function is empty. This test just tests that this function doesn't crash.
  [vungleBannerDelegate bannerAdWillPresent:_bannerMock];
}

- (void)testBannerAdDidPresentDoesNotCrash {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAndGetEventDelegate];
  id<VungleBannerViewDelegate> vungleBannerDelegate =
      (id<VungleBannerViewDelegate>)eventDelegate.bannerAd;

  // The body of this function is empty. This test just tests that this function doesn't crash.
  [vungleBannerDelegate bannerAdDidPresent:_bannerMock];
}

- (void)testBannerAdDidFailToPresentInvokesPresentErrorOnDelegate {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAndGetEventDelegate];
  id<VungleBannerViewDelegate> vungleBannerDelegate =
      (id<VungleBannerViewDelegate>)eventDelegate.bannerAd;

  NSError *liftoffError =
      [NSError errorWithDomain:@"liftoff.domain"
                          code:2
                      userInfo:@{NSLocalizedDescriptionKey : @"Banner ad presentation failed."}];
  [vungleBannerDelegate bannerAdDidFail:_bannerMock
                              withError:[NSError errorWithDomain:@"liftoff.domain"
                                                            code:2
                                                        userInfo:@{
                                                          NSLocalizedDescriptionKey :
                                                              @"Banner ad presentation failed."
                                                        }]];

  NSError *presentationError = eventDelegate.didFailToPresentError;
  XCTAssertEqualObjects(presentationError, liftoffError);
}

- (void)testBannerAdWillCloseDoesNotCrash {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAndGetEventDelegate];
  id<VungleBannerViewDelegate> vungleBannerDelegate =
      (id<VungleBannerViewDelegate>)eventDelegate.bannerAd;

  // The body of this function is empty. This test just tests that this function doesn't crash.
  [vungleBannerDelegate bannerAdWillClose:_bannerMock];
}

- (void)testBannerAdDidCloseDoesNotCrash {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAndGetEventDelegate];
  id<VungleBannerViewDelegate> vungleBannerDelegate =
      (id<VungleBannerViewDelegate>)eventDelegate.bannerAd;

  // The body of this function is empty. This test just tests that this function doesn't crash.
  [vungleBannerDelegate bannerAdDidClose:_bannerMock];
}

- (void)testBannerAdDidTrackImpressionInvokesReportImpressionOnDelegate {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAndGetEventDelegate];
  id<VungleBannerViewDelegate> vungleBannerDelegate =
      (id<VungleBannerViewDelegate>)eventDelegate.bannerAd;
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);

  [vungleBannerDelegate bannerAdDidTrackImpression:_bannerMock];

  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testBannerAdDidClickInvokesReportClickOnDelegate {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAndGetEventDelegate];
  id<VungleBannerViewDelegate> vungleBannerDelegate =
      (id<VungleBannerViewDelegate>)eventDelegate.bannerAd;
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);

  [vungleBannerDelegate bannerAdDidClick:_bannerMock];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testBannerAdWillLeaveApplicationDoesNotCrash {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAndGetEventDelegate];
  id<VungleBannerViewDelegate> vungleBannerDelegate =
      (id<VungleBannerViewDelegate>)eventDelegate.bannerAd;

  // The body of this function only calls the deprecated function willBackgroundApplication on the
  // delegate. Not testing for that function call since it is deprecated. Just testing that this
  // function doesn't crash.
  [vungleBannerDelegate bannerAdWillLeaveApplication:_bannerMock];
}

- (void)testViewReturnsBannerView {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAndGetEventDelegate];
  id<GADMediationBannerAd> mediationBannerAd = eventDelegate.bannerAd;

  XCTAssertEqual(mediationBannerAd.view, self->_bannerMock);
}

@end
