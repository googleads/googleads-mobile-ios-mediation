#import "GADMediationAdapterVungle.h"
#import "GADMAdapterVungleRewardBasedVideoAd.h"
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationRewardedAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <VungleAdsSDK/VungleAdsSDK.h>
#import <XCTest/XCTest.h>

static NSString *const kPlacementID = @"12345";
static NSString *const kAppID = @"AppId";
static NSString *const kUserId = @"UserId";

@interface AUTLiftoffMonetizeWaterfallRewardedAdTests : XCTestCase

@end

@implementation AUTLiftoffMonetizeWaterfallRewardedAdTests {
  /// An adapter instance that is used to test loading an rewarded ad.
  GADMediationAdapterVungle *_adapter;

  /// A mock instance of VungleRewarded.
  id _rewardedMock;
}

- (void)setUp {
  [super setUp];

  _adapter = [[GADMediationAdapterVungle alloc] init];

  _rewardedMock = OCMClassMock([VungleRewarded class]);
  OCMStub([_rewardedMock alloc]).andReturn(_rewardedMock);
}

- (void)testLoadRewardedSetsCoppaYesWhenChildDirected {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment =
      [NSNumber numberWithInt:1];
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  GADMediationRewardedLoadCompletionHandler completionHandler =
      ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
        return [[AUTKMediationRewardedAdEventDelegate alloc] init];
      };
  id vunglePrivacySettingsMock = OCMClassMock([VunglePrivacySettings class]);

  [_adapter loadRewardedAdForAdConfiguration:configuration completionHandler:completionHandler];

  OCMVerify([vunglePrivacySettingsMock setCOPPAStatus:YES]);
}

- (void)testLoadRewardedSetsCoppaNoWhenNotChildDirected {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment =
      [NSNumber numberWithInt:0];
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  GADMediationRewardedLoadCompletionHandler completionHandler =
      ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
        return [[AUTKMediationRewardedAdEventDelegate alloc] init];
      };
  id vunglePrivacySettingsMock = OCMClassMock([VunglePrivacySettings class]);

  [_adapter loadRewardedAdForAdConfiguration:configuration completionHandler:completionHandler];

  OCMVerify([vunglePrivacySettingsMock setCOPPAStatus:NO]);
}

- (AUTKMediationRewardedAdEventDelegate *)
    loadRewardedAndAssertLoadSuccessWithCredentials:(AUTKMediationCredentials *)credentials
                                          andExtras:(VungleAdNetworkExtras *)extras {
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = extras;
  __block id<VungleRewardedDelegate> loadDelegate = nil;
  OCMExpect([_rewardedMock initWithPlacementId:kPlacementID]).andReturn(_rewardedMock);
  OCMExpect([_rewardedMock setDelegate:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  OCMExpect([_rewardedMock setUserIdWithUserId:kUserId]);
  OCMExpect([_rewardedMock load:nil]).andDo(^(NSInvocation *invocation) {
    [loadDelegate rewardedAdDidLoad:self->_rewardedMock];
  });

  id<GADMediationRewardedAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(_rewardedMock);
  return delegate;
}

- (void)testLoadRewardedSuccessWhenLiftoffSdkIsInitialized {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  VungleAdNetworkExtras *extras = [[VungleAdNetworkExtras alloc] init];
  extras.userId = kUserId;

  [self loadRewardedAndAssertLoadSuccessWithCredentials:credentials andExtras:extras];
}

- (void)testLoadRewardedSuccessWhenLiftoffSdkIsNotYetInitialized {
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
  VungleAdNetworkExtras *extras = [[VungleAdNetworkExtras alloc] init];
  extras.userId = kUserId;

  [self loadRewardedAndAssertLoadSuccessWithCredentials:credentials andExtras:extras];
  OCMVerifyAll(vungleRouterMock);
}

- (void)testLoadRewardedFailureWhenLiftoffFailsToLoadAd {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  OCMStub([_rewardedMock initWithPlacementId:kPlacementID]).andReturn(_rewardedMock);
  __block id<VungleRewardedDelegate> loadDelegate = nil;
  OCMStub([_rewardedMock setDelegate:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  NSError *liftoffError =
      [NSError errorWithDomain:@"liftoff.domain"
                          code:1
                      userInfo:@{NSLocalizedDescriptionKey : @"Rewarded ad load failed."}];
  OCMStub([_rewardedMock load:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [loadDelegate rewardedAdDidFailToLoad:self->_rewardedMock withError:liftoffError];
  });

  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, liftoffError);
}

/// Mocks a successful load of an rewarded ad, captures the instance of
/// AUTKMediationRewardedAdEventDelegate and returns it.
- (AUTKMediationRewardedAdEventDelegate *)loadRewardedAndGetEventDelegate {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  VungleAdNetworkExtras *extras = [[VungleAdNetworkExtras alloc] init];
  extras.userId = kUserId;
  return [self loadRewardedAndAssertLoadSuccessWithCredentials:credentials andExtras:extras];
}

- (void)testRewardedAdPresentCallsPresentOnLiftoffSdk {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAndGetEventDelegate];
  UIViewController *rootViewController = [[UIViewController alloc] init];

  [eventDelegate.rewardedAd presentFromViewController:rootViewController];

  OCMVerify([_rewardedMock presentWith:rootViewController]);
}

- (void)testRewardedAdWillPresentInvokesWillPresentFullScreenViewOnDelegate {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);

  [vungleRewardedDelegate rewardedAdWillPresent:_rewardedMock];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
}

- (void)testRewardedAdDidPresentInvokesDidStartVideoOnDelegate {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 0);

  [vungleRewardedDelegate rewardedAdDidPresent:_rewardedMock];

  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 1);
}

- (void)testRewardedAdDidFailToPresentInvokesPresentErrorOnDelegate {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;
  NSError *liftoffError =
      [NSError errorWithDomain:@"liftoff.domain"
                          code:2
                      userInfo:@{NSLocalizedDescriptionKey : @"Rewarded ad presentation failed."}];
  [vungleRewardedDelegate rewardedAdDidFailToPresent:_rewardedMock withError:liftoffError];

  NSError *presentationError = eventDelegate.didFailToPresentError;
  XCTAssertEqualObjects(presentationError, liftoffError);
}

- (void)testRewardedAdWillCloseInvokesWillDismissFullScreenViewOnDelegate {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);

  [vungleRewardedDelegate rewardedAdWillClose:_rewardedMock];

  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);
}

- (void)testRewardedAdDidCloseInvokesDidEndVideoAndDidDismissFullScreenViewOnDelegate {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);

  [vungleRewardedDelegate rewardedAdDidClose:_rewardedMock];

  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testRewardedAdDidTrackImpressionInvokesReportImpressionOnDelegate {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);

  [vungleRewardedDelegate rewardedAdDidTrackImpression:_rewardedMock];

  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testRewardedAdDidClickInvokesReportClickOnDelegate {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);

  [vungleRewardedDelegate rewardedAdDidClick:_rewardedMock];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testRewardedAdWillLeaveApplicationDoesNotCrash {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;

  // The body of this function is empty. This test just tests that this function doesn't crash.
  [vungleRewardedDelegate rewardedAdWillLeaveApplication:_rewardedMock];
}

- (void)testRewardedAdDidRewardUserInvokesDidRewardUserOnDelegate {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;
  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 0);

  [vungleRewardedDelegate rewardedAdDidRewardUser:_rewardedMock];

  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 1);
}

- (void)testMainAdapterClassReturnsClassConformingToGADRTBAdapter {
  SEL mainAdapterClassSelector = NSSelectorFromString(@"mainAdapterClass");
  XCTAssertTrue([GADMAdapterVungleRewardBasedVideoAd respondsToSelector:mainAdapterClassSelector]);
  Class adapterClass = [GADMAdapterVungleRewardBasedVideoAd class];
  IMP imp = [adapterClass methodForSelector:mainAdapterClassSelector];
  Class (*func)(id, SEL) = (void *)imp;
  Class mainAdapterClass = func(adapterClass, mainAdapterClassSelector);

  id mainAdapter = [[mainAdapterClass alloc] init];

  XCTAssertTrue([mainAdapter conformsToProtocol:@protocol(GADRTBAdapter)]);
}

@end
