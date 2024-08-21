#import "GADMediationAdapterLine.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationRewardedAdLoadAssertions.h>
#import <FiveAd/FiveAd.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterLineConstants.h"
#import "GADMediationAdapterLineExtras.h"

@interface AUTLineRewardedAdTest : XCTestCase

@end

static NSString *const AUTLineTestSlotID = @"12345";

@implementation AUTLineRewardedAdTest {
  /// An adapter instance that is used to test loading a rewarded ad.
  GADMediationAdapterLine *_adapter;

  /// A mock instance of FADVideoReward.
  id _rewardedMock;
}

- (void)setUp {
  [super setUp];

  _adapter = [[GADMediationAdapterLine alloc] init];

  _rewardedMock = OCMClassMock([FADVideoReward class]);
  OCMStub([_rewardedMock alloc]).andReturn(_rewardedMock);
  OCMStub([_rewardedMock initWithSlotId:AUTLineTestSlotID]).andReturn(_rewardedMock);

  id configClassMock = OCMClassMock([FADSettings class]);
  OCMStub([configClassMock registerConfig:OCMOCK_ANY]);
}

- (nonnull id<GADMediationRewardedAdEventDelegate>)
    loadRewardedAdWithExtra:(nullable GADMediationAdapterLineExtras *)extras
         expectSoundEnabled:(BOOL)soundEnabled {
  // Mock FiveAd SDK.
  __block id<FADLoadDelegate> loadDelegate = nil;
  OCMStub([_rewardedMock setLoadDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  OCMStub([_rewardedMock setEventListener:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    id<FADVideoRewardEventListener> eventListener = nil;
    [invocation getArgument:&eventListener atIndex:2];
    XCTAssertTrue([eventListener conformsToProtocol:@protocol(FADVideoRewardEventListener)]);
  });
  OCMExpect([_rewardedMock loadAdAsync]).andDo(^(NSInvocation *invocation) {
    [loadDelegate fiveAdDidLoad:self->_rewardedMock];
  });
  OCMExpect([_rewardedMock enableSound:soundEnabled]);

  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
                                             FADConfig *config = (FADConfig *)obj;
                                             XCTAssertTrue([config.appId isEqualToString:@"123"]);
                                             return YES;
                                           }]
                                                    outError:[OCMArg anyObjectRef]]));

  // Test loading a rewarded ad.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : @"123",
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = extras;
  id<GADMediationRewardedAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(_rewardedMock);
  OCMVerifyAll(adLoaderClassMock);

  return delegate;
}

- (void)testLoadRewardedAd {
  [self loadRewardedAdWithExtra:nil
             expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
}

- (void)testLoadBiddingRewardedAd {
  // Mock FiveAd SDK.
  __block id<FADLoadDelegate> loadDelegate = nil;
  OCMStub([_rewardedMock setLoadDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  OCMStub([_rewardedMock setEventListener:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    id<FADVideoRewardEventListener> eventListener = nil;
    [invocation getArgument:&eventListener atIndex:2];
    XCTAssertTrue([eventListener conformsToProtocol:@protocol(FADVideoRewardEventListener)]);
  });

  NSString *bidResponse = @"bidResponse";
  NSString *watermark = @"watermark";
  NSData *watermarkData = [watermark dataUsingEncoding:NSUTF8StringEncoding];
  id bidData = OCMClassMock([FADBidData class]);
  OCMStub([bidData alloc]).andReturn(bidData);
  OCMExpect([bidData initWithBidResponse:bidResponse withWatermark:watermark]).andReturn(bidData);

  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
                                             FADConfig *config = (FADConfig *)obj;
                                             XCTAssertTrue([config.appId isEqualToString:@"123"]);
                                             return YES;
                                           }]
                                                    outError:[OCMArg anyObjectRef]]))
      .andReturn(adLoaderClassMock);

  // Test loading a rewarded ad.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : @"123",
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };
  OCMExpect([adLoaderClassMock loadRewardAdWithBidData:bidData withLoadCallback:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(FADAdViewCustomLayout *_Nullable customLayout,
                                                      NSError *_Nullable adLoadError);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(self->_rewardedMock, nil);
      });

  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.watermark = watermarkData;
  configuration.bidResponse = bidResponse;
  id<GADMediationRewardedAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(_rewardedMock);
  OCMVerifyAll(adLoaderClassMock);
}

- (void)testLoadRewardedAdAudioUnset {
  GADMediationAdapterLineExtras *extras = [[GADMediationAdapterLineExtras alloc] init];
  extras.adAudio = GADMediationAdapterLineAdAudioUnset;
  [self loadRewardedAdWithExtra:extras
             expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
}

- (void)testLoadRewardedAdAudioUnmuted {
  GADMediationAdapterLineExtras *extras = [[GADMediationAdapterLineExtras alloc] init];
  extras.adAudio = GADMediationAdapterLineAdAudioUnmuted;
  [self loadRewardedAdWithExtra:extras expectSoundEnabled:YES];
}

- (void)testLoadRewardedAdAudioMuted {
  GADMediationAdapterLineExtras *extras = [[GADMediationAdapterLineExtras alloc] init];
  extras.adAudio = GADMediationAdapterLineAdAudioMuted;
  [self loadRewardedAdWithExtra:extras expectSoundEnabled:NO];
}

- (void)testLoadRewardedAdFailureForMissingSlotID {
  // Mock FiveAd SDK.
  id _rewardedMock = OCMClassMock([FADVideoReward class]);
  OCMStub([_rewardedMock alloc]).andReturn(_rewardedMock);
  OCMReject([_rewardedMock loadAdAsync]);
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Test missing slot ID by omitting slot id from credential settings.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : @"123",
  };
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMediationAdapterLineErrorDomain
                                 code:GADMediationAdapterLineErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
  OCMVerifyAll(_rewardedMock);
}

- (void)testLoadRewardedAdFailureForFiveAdSDKFailedToReceiveAd {
  // Mock FiveAd SDK.
  id _rewardedMock = OCMClassMock([FADVideoReward class]);
  OCMStub([_rewardedMock alloc]).andReturn(_rewardedMock);
  OCMStub([_rewardedMock initWithSlotId:AUTLineTestSlotID]).andReturn(_rewardedMock);
  __block id<FADLoadDelegate> loadDelegate = nil;
  OCMStub([_rewardedMock setLoadDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  FADErrorCode code = kFADErrorCodeNoAd;
  OCMExpect([_rewardedMock loadAdAsync]).andDo(^(NSInvocation *invocation) {
    [loadDelegate fiveAd:_rewardedMock didFailedToReceiveAdWithError:code];
  });
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Test fail to receive an ad from FiveAd SDK.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : @"123",
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMediationAdapterFiveAdErrorDomain
                                                      code:code
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
  OCMVerifyAll(_rewardedMock);
}

- (void)testRewardedAdPresent {
  AUTKMediationRewardedAdEventDelegate *delegate =
      [self loadRewardedAdWithExtra:nil
                 expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];

  // Mock FiveAd SDK.
  FADVideoReward *rewardedAd = (FADVideoReward *)_rewardedMock;
  OCMExpect([rewardedAd show]);

  // Test ad present.
  id<GADMediationRewardedAd> mediationRewardedAd = delegate.rewardedAd;
  [mediationRewardedAd presentFromViewController:[[UIViewController alloc] init]];
  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 1);
  OCMVerifyAll(_rewardedMock);
}

- (void)testAdClick {
  AUTKMediationRewardedAdEventDelegate *delegate =
      [self loadRewardedAdWithExtra:nil
                 expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADVideoRewardEventListener> listener = (id<FADVideoRewardEventListener>)delegate.rewardedAd;
  [listener fiveVideoRewardAdDidClick:_rewardedMock];
  XCTAssertTrue(delegate.reportClickInvokeCount == 1);
}

- (void)testImpression {
  AUTKMediationRewardedAdEventDelegate *delegate =
      [self loadRewardedAdWithExtra:nil
                 expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADVideoRewardEventListener> listener = (id<FADVideoRewardEventListener>)delegate.rewardedAd;
  [listener fiveVideoRewardAdDidImpression:_rewardedMock];
  XCTAssertTrue(delegate.reportImpressionInvokeCount == 1);
}

- (void)testRewarded {
  // Mock FiveAd SDK.
  FADVideoReward *rewardedAd = (FADVideoReward *)_rewardedMock;
  OCMStub([rewardedAd state]).andReturn(kFADStateClosed);

  // Test that a reward is granted when the user closes the loaded ad after finishing watching it.
  AUTKMediationRewardedAdEventDelegate *delegate =
      [self loadRewardedAdWithExtra:nil
                 expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADVideoRewardEventListener> listener = (id<FADVideoRewardEventListener>)delegate.rewardedAd;
  [listener fiveVideoRewardAdDidReward:rewardedAd];

  XCTAssertEqual(delegate.didRewardUserInvokeCount, 1);
}

- (void)testAdClose {
  // Mock FiveAd SDK.
  FADVideoReward *rewardedAd = (FADVideoReward *)_rewardedMock;
  OCMStub([rewardedAd state]).andReturn(kFADStateClosed);

  // Test that a reward is granted when the user closes the loaded ad after finishing watching it.
  AUTKMediationRewardedAdEventDelegate *delegate =
      [self loadRewardedAdWithExtra:nil
                 expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADVideoRewardEventListener> listener = (id<FADVideoRewardEventListener>)delegate.rewardedAd;
  [listener fiveVideoRewardAdDidPlay:rewardedAd];
  [listener fiveVideoRewardAdFullScreenDidClose:rewardedAd];
  XCTAssertEqual(delegate.didStartVideoInvokeCount, 1);
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testFailToShowAd {
  AUTKMediationRewardedAdEventDelegate *delegate =
      [self loadRewardedAdWithExtra:nil
                 expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADVideoRewardEventListener> listener = (id<FADVideoRewardEventListener>)delegate.rewardedAd;
  FADErrorCode expectedErrorCode = kFADErrorCodePlayerError;
  [listener fiveVideoRewardAd:_rewardedMock didFailedToShowAdWithError:expectedErrorCode];
  NSError *presentError = delegate.didFailToPresentError;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMediationAdapterFiveAdErrorDomain
                                                      code:expectedErrorCode
                                                  userInfo:nil];
  XCTAssertEqual(presentError.code, expectedError.code);
  XCTAssertEqualObjects(presentError.domain, expectedError.domain);
}

- (void)testUnhandledEvents {
  // Following events are not handled by the GoogleMobileAds's rewarded event delegate, but
  // checking invoking them does not crash the running app.
  AUTKMediationRewardedAdEventDelegate *delegate =
      [self loadRewardedAdWithExtra:nil
                 expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADVideoRewardEventListener> listener = (id<FADVideoRewardEventListener>)delegate.rewardedAd;

  [listener fiveVideoRewardAdFullScreenDidOpen:OCMOCK_ANY];
  [listener fiveVideoRewardAdDidPause:OCMOCK_ANY];
}

@end
