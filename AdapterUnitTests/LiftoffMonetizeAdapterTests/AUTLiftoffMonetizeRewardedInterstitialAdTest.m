// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleRewardBasedVideoAd.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"
#import "GADMediationAdapterVungle.h"
#import "GADMediationVungleRewardedAd.h"
#import "VungleAdNetworkExtras.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationRewardedAdLoadAssertions.h>
#import <AdapterUnitTestKit/AUTKMediationRewardedInterstitialAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <VungleAdsSDK/VungleAdsSDK.h>
#import <XCTest/XCTest.h>

static NSString *const kPlacementID = @"12345";
static NSString *const kAppID = @"AppId";
static NSString *const kBidResponse = @"bidResponse";
static NSString *const kUserId = @"UserId";
static NSString *const kWatermark = @"watermark";

@interface AUTLiftoffMonetizeRewardedInterstitialAdTest : XCTestCase

@end

@implementation AUTLiftoffMonetizeRewardedInterstitialAdTest {
  /// An adapter instance that is used to test loading a rewarded interstitial ad.
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

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  [super tearDown];
}

#pragma mark - COPPA Synchronization Tests

- (void)testLoadRewardedInterstitialSetsCoppaYesWhenChildDirected {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @1;
  id vunglePrivacySettingsMock = OCMClassMock([VunglePrivacySettings class]);
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  GADMediationRewardedLoadCompletionHandler completionHandler =
      ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
        return [[AUTKMediationRewardedAdEventDelegate alloc] init];
      };
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(NO);

  [_adapter loadRewardedInterstitialAdForAdConfiguration:configuration
                                       completionHandler:completionHandler];

  OCMVerify([vunglePrivacySettingsMock setCOPPAStatus:YES]);
}

- (void)testLoadRewardedInterstitialSetsCoppaNoWhenNotChildDirected {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @0;
  id vunglePrivacySettingsMock = OCMClassMock([VunglePrivacySettings class]);
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  GADMediationRewardedLoadCompletionHandler completionHandler =
      ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
        return [[AUTKMediationRewardedAdEventDelegate alloc] init];
      };
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(NO);

  [_adapter loadRewardedInterstitialAdForAdConfiguration:configuration
                                       completionHandler:completionHandler];

  OCMVerify([vunglePrivacySettingsMock setCOPPAStatus:NO]);
}

- (void)testLoadRewardedInterstitialSetsCoppaYesWhenTagForUnderAgeIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @1;
  id vunglePrivacySettingsMock = OCMClassMock([VunglePrivacySettings class]);
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  GADMediationRewardedLoadCompletionHandler completionHandler =
      ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
        return [[AUTKMediationRewardedAdEventDelegate alloc] init];
      };
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(NO);

  [_adapter loadRewardedInterstitialAdForAdConfiguration:configuration
                                       completionHandler:completionHandler];

  OCMVerify([vunglePrivacySettingsMock setCOPPAStatus:YES]);
}

- (void)testLoadRewardedInterstitialSetsCoppaNoWhenTagForUnderAgeIsNo {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @0;
  id vunglePrivacySettingsMock = OCMClassMock([VunglePrivacySettings class]);
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  GADMediationRewardedLoadCompletionHandler completionHandler =
      ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
        return [[AUTKMediationRewardedAdEventDelegate alloc] init];
      };
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(NO);

  [_adapter loadRewardedInterstitialAdForAdConfiguration:configuration
                                       completionHandler:completionHandler];

  OCMVerify([vunglePrivacySettingsMock setCOPPAStatus:NO]);
}

- (void)testLoadRewardedInterstitialSetsCoppaYesWhenAgeRestrictedTreatmentIsChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  id vunglePrivacySettingsMock = OCMClassMock([VunglePrivacySettings class]);
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  GADMediationRewardedLoadCompletionHandler completionHandler =
      ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
        return [[AUTKMediationRewardedAdEventDelegate alloc] init];
      };
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(NO);

  [_adapter loadRewardedInterstitialAdForAdConfiguration:configuration
                                       completionHandler:completionHandler];

  OCMVerify([vunglePrivacySettingsMock setCOPPAStatus:YES]);
}

#pragma mark - Waterfall Flow Tests

- (AUTKMediationRewardedAdEventDelegate *)
    loadWaterfallRewardedInterstitialAndAssertSuccessWithCredentials:
        (AUTKMediationCredentials *)credentials
                                                           andExtras:
                                                               (VungleAdNetworkExtras *)extras {
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = extras;
  configuration.bidResponse = nil;

  __block id<VungleRewardedDelegate> loadDelegate = nil;
  OCMExpect([_rewardedMock initWithPlacementId:kPlacementID]).andReturn(_rewardedMock);
  OCMExpect([_rewardedMock setDelegate:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  OCMExpect([_rewardedMock setAdapterAdFormat:@"GADMAdapterVungleRewardBasedVideoAd"]);
  if (extras && extras.userId) {
    OCMExpect([_rewardedMock setUserIdWithUserId:extras.userId]);
  }
  OCMExpect([_rewardedMock load:nil]).andDo(^(NSInvocation *invocation) {
    [loadDelegate rewardedAdDidLoad:self->_rewardedMock];
  });

  id<GADMediationRewardedAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadRewardedInterstitialAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(_rewardedMock);
  return delegate;
}

- (void)testLoadWaterfallRewardedInterstitialSuccessWhenLiftoffSdkIsInitialized {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  VungleAdNetworkExtras *extras = [[VungleAdNetworkExtras alloc] init];
  extras.userId = kUserId;

  [self loadWaterfallRewardedInterstitialAndAssertSuccessWithCredentials:credentials
                                                               andExtras:extras];
}

- (void)testLoadWaterfallRewardedInterstitialSuccessWhenLiftoffSdkIsNotYetInitialized {
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
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(NO);

  [self loadWaterfallRewardedInterstitialAndAssertSuccessWithCredentials:credentials
                                                               andExtras:extras];

  OCMVerifyAll(vungleRouterMock);
}

- (void)testLoadWaterfallRewardedInterstitialFailureWhenLiftoffFailsToLoadAd {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = nil;

  OCMStub([_rewardedMock initWithPlacementId:kPlacementID]).andReturn(_rewardedMock);
  __block id<VungleRewardedDelegate> loadDelegate = nil;
  OCMStub([_rewardedMock setDelegate:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  NSError *liftoffError =
      [NSError errorWithDomain:@"liftoff.domain"
                          code:1
                      userInfo:@{NSLocalizedDescriptionKey : @"Rewarded ad load failed."}];
  OCMStub([_rewardedMock load:nil]).andDo(^(NSInvocation *invocation) {
    [loadDelegate rewardedAdDidFailToLoad:self->_rewardedMock withError:liftoffError];
  });

  AUTKWaitAndAssertLoadRewardedInterstitialAdFailure(_adapter, configuration, liftoffError);
}

- (void)testLoadWaterfallRewardedInterstitialFailureWhenLiftoffInitializationFails {
  id vungleRouterMock = OCMClassMock([GADMAdapterVungleRouter class]);
  OCMStub([vungleRouterMock sharedInstance]).andReturn(vungleRouterMock);
  NSError *initError = [NSError errorWithDomain:@"liftoff.domain"
                                           code:100
                                       userInfo:@{NSLocalizedDescriptionKey : @"Init failed."}];
  __block id<GADMAdapterVungleDelegate> initDelegate = nil;
  OCMExpect([vungleRouterMock initWithAppId:kAppID delegate:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&initDelegate atIndex:3];
        [initDelegate initialized:false error:initError];
      });
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterVunglePlacementID : kPlacementID, GADMAdapterVungleApplicationID : kAppID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = nil;
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(NO);

  AUTKWaitAndAssertLoadRewardedInterstitialAdFailure(_adapter, configuration, initError);
  OCMVerifyAll(vungleRouterMock);
}

#pragma mark - Bidding Flow Tests

- (AUTKMediationRewardedAdEventDelegate *)
    loadBiddingRewardedInterstitialAndAssertSuccessWithCredentials:
        (AUTKMediationCredentials *)credentials
                                                         andExtras:(VungleAdNetworkExtras *)extras {
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = extras;
  configuration.bidResponse = kBidResponse;

  NSData *const watermarkData = [kWatermark dataUsingEncoding:NSUTF8StringEncoding];
  configuration.watermark = watermarkData;
  id vungleAdsExtrasMock = OCMClassMock([VungleAdsExtras class]);
  OCMStub([vungleAdsExtrasMock alloc]).andReturn(vungleAdsExtrasMock);
  OCMExpect([_rewardedMock setWithExtras:vungleAdsExtrasMock]);

  __block id<VungleRewardedDelegate> loadDelegate = nil;
  OCMExpect([_rewardedMock initWithPlacementId:kPlacementID]).andReturn(_rewardedMock);
  OCMExpect([_rewardedMock setDelegate:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  OCMExpect([_rewardedMock setAdapterAdFormat:@"GADMediationVungleRewardedAd"]);
  if (extras && extras.userId) {
    OCMExpect([_rewardedMock setUserIdWithUserId:extras.userId]);
  }
  OCMExpect([_rewardedMock load:kBidResponse]).andDo(^(NSInvocation *invocation) {
    [loadDelegate rewardedAdDidLoad:self->_rewardedMock];
  });

  id<GADMediationRewardedAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadRewardedInterstitialAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(_rewardedMock);
  OCMVerify(
      [vungleAdsExtrasMock setWithWatermark:[watermarkData base64EncodedStringWithOptions:0]]);
  return delegate;
}

- (void)testLoadBiddingRewardedInterstitialSuccessWhenLiftoffSdkIsInitialized {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};

  [self loadBiddingRewardedInterstitialAndAssertSuccessWithCredentials:credentials andExtras:nil];
}

- (void)testLoadBiddingRewardedInterstitialSuccessWhenLiftoffSdkIsNotYetInitialized {
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
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(NO);

  [self loadBiddingRewardedInterstitialAndAssertSuccessWithCredentials:credentials andExtras:nil];
  OCMVerifyAll(vungleRouterMock);
}

- (void)testLoadBiddingRewardedInterstitialFailureWhenLiftoffFailsToLoadAd {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;

  OCMStub([_rewardedMock initWithPlacementId:kPlacementID]).andReturn(_rewardedMock);
  __block id<VungleRewardedDelegate> loadDelegate = nil;
  OCMStub([_rewardedMock setDelegate:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  NSError *liftoffError =
      [NSError errorWithDomain:@"liftoff.domain"
                          code:1
                      userInfo:@{NSLocalizedDescriptionKey : @"Rewarded ad load failed."}];
  OCMStub([_rewardedMock load:kBidResponse]).andDo(^(NSInvocation *invocation) {
    [loadDelegate rewardedAdDidFailToLoad:self->_rewardedMock withError:liftoffError];
  });

  AUTKWaitAndAssertLoadRewardedInterstitialAdFailure(_adapter, configuration, liftoffError);
}

- (void)testLoadBiddingRewardedInterstitialFailureWhenLiftoffInitializationFails {
  id vungleRouterMock = OCMClassMock([GADMAdapterVungleRouter class]);
  OCMStub([vungleRouterMock sharedInstance]).andReturn(vungleRouterMock);
  NSError *initError = [NSError errorWithDomain:@"liftoff.domain"
                                           code:100
                                       userInfo:@{NSLocalizedDescriptionKey : @"Init failed."}];
  __block id<GADMAdapterVungleDelegate> initDelegate = nil;
  OCMExpect([vungleRouterMock initWithAppId:kAppID delegate:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&initDelegate atIndex:3];
        [initDelegate initialized:false error:initError];
      });
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterVunglePlacementID : kPlacementID, GADMAdapterVungleApplicationID : kAppID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(NO);

  AUTKWaitAndAssertLoadRewardedInterstitialAdFailure(_adapter, configuration, initError);
  OCMVerifyAll(vungleRouterMock);
}

- (void)testLoadBiddingRewardedInterstitialWithExtrasSetsUserId {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  VungleAdNetworkExtras *extras = [[VungleAdNetworkExtras alloc] init];
  extras.userId = kUserId;

  [self loadBiddingRewardedInterstitialAndAssertSuccessWithCredentials:credentials
                                                             andExtras:extras];
}

#pragma mark - Presentation Flow Tests

- (AUTKMediationRewardedAdEventDelegate *)loadRewardedInterstitialAndGetEventDelegate {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  return [self loadWaterfallRewardedInterstitialAndAssertSuccessWithCredentials:credentials
                                                                      andExtras:nil];
}

- (void)testRewardedInterstitialPresentCallsPresentOnLiftoffSdk {
  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      [self loadRewardedInterstitialAndGetEventDelegate];
  UIViewController *rootViewController = [[UIViewController alloc] init];

  [eventDelegate.rewardedAd presentFromViewController:rootViewController];

  OCMVerify([_rewardedMock presentWith:rootViewController]);
}

- (void)testRewardedInterstitialWillPresentInvokesWillPresentFullScreenViewOnDelegate {
  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      [self loadRewardedInterstitialAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);

  [vungleRewardedDelegate rewardedAdWillPresent:_rewardedMock];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
}

- (void)testRewardedInterstitialDidPresentInvokesDidStartVideoOnDelegate {
  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      [self loadRewardedInterstitialAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 0);

  [vungleRewardedDelegate rewardedAdDidPresent:_rewardedMock];

  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 1);
}

- (void)testRewardedInterstitialDidFailToPresentInvokesPresentErrorOnDelegate {
  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      [self loadRewardedInterstitialAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;
  NSError *liftoffError =
      [NSError errorWithDomain:@"liftoff.domain"
                          code:2
                      userInfo:@{NSLocalizedDescriptionKey : @"Presentation failed."}];

  [vungleRewardedDelegate rewardedAdDidFailToPresent:_rewardedMock withError:liftoffError];

  XCTAssertEqualObjects(eventDelegate.didFailToPresentError, liftoffError);
}

- (void)testRewardedInterstitialWillCloseInvokesWillDismissFullScreenViewOnDelegate {
  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      [self loadRewardedInterstitialAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);

  [vungleRewardedDelegate rewardedAdWillClose:_rewardedMock];

  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);
}

- (void)testRewardedInterstitialDidCloseInvokesDidEndVideoAndDidDismissFullScreenViewOnDelegate {
  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      [self loadRewardedInterstitialAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);

  [vungleRewardedDelegate rewardedAdDidClose:_rewardedMock];

  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testRewardedInterstitialDidTrackImpressionInvokesReportImpressionOnDelegate {
  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      [self loadRewardedInterstitialAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);

  [vungleRewardedDelegate rewardedAdDidTrackImpression:_rewardedMock];

  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testRewardedInterstitialDidClickInvokesReportClickOnDelegate {
  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      [self loadRewardedInterstitialAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);

  [vungleRewardedDelegate rewardedAdDidClick:_rewardedMock];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testRewardedInterstitialDidRewardUserInvokesDidRewardUserOnDelegate {
  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      [self loadRewardedInterstitialAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;
  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 0);

  [vungleRewardedDelegate rewardedAdDidRewardUser:_rewardedMock];

  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 1);
}

- (void)testRewardedInterstitialWillLeaveApplicationDoesNotCrash {
  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      [self loadRewardedInterstitialAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;

  [vungleRewardedDelegate rewardedAdWillLeaveApplication:_rewardedMock];
}

- (void)testRewardedInterstitialFullPresentationLifecycle {
  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      [self loadRewardedInterstitialAndGetEventDelegate];
  id<VungleRewardedDelegate> vungleRewardedDelegate =
      (id<VungleRewardedDelegate>)eventDelegate.rewardedAd;
  UIViewController *rootViewController = [[UIViewController alloc] init];

  [eventDelegate.rewardedAd presentFromViewController:rootViewController];
  OCMVerify([_rewardedMock presentWith:rootViewController]);

  [vungleRewardedDelegate rewardedAdWillPresent:_rewardedMock];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);

  [vungleRewardedDelegate rewardedAdDidPresent:_rewardedMock];
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 1);

  [vungleRewardedDelegate rewardedAdDidTrackImpression:_rewardedMock];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);

  [vungleRewardedDelegate rewardedAdDidClick:_rewardedMock];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);

  [vungleRewardedDelegate rewardedAdDidRewardUser:_rewardedMock];
  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 1);

  [vungleRewardedDelegate rewardedAdWillClose:_rewardedMock];
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);

  [vungleRewardedDelegate rewardedAdDidClose:_rewardedMock];
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testLoadRewardedInterstitialAdLoadsRewardedAd {
  GADMediationRewardedLoadCompletionHandler completionHandler =
      ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
        return [[AUTKMediationRewardedAdEventDelegate alloc] init];
      };
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  id adapterMock = OCMPartialMock(_adapter);
  OCMStub([adapterMock loadRewardedAdForAdConfiguration:configuration
                                      completionHandler:completionHandler])
      .andDo(nil);

  [_adapter loadRewardedInterstitialAdForAdConfiguration:configuration
                                       completionHandler:completionHandler];

  OCMVerify([adapterMock loadRewardedAdForAdConfiguration:configuration
                                        completionHandler:completionHandler]);
  [adapterMock stopMocking];
}

@end
