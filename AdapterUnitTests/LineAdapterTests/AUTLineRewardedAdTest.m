// Copyright 2023 Google LLC
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

#import "GADMediationAdapterLine.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationRewardedAdLoadAssertions.h>
#import <FiveAd/FiveAd.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterLineConstants.h"
#import "GADMediationAdapterLineExtras.h"
#import "GADMediationAdapterLineUtils.h"

static NSString *const AUTLineTestSlotID = @"12345";
static NSString *const AUTLineTestApplicationID = @"123";

@interface AUTLineRewardedAdTest : XCTestCase
@end

@implementation AUTLineRewardedAdTest {
  /// An adapter instance that is used to test loading a rewarded ad.
  GADMediationAdapterLine *_adapter;

  /// A mock instance of FADVideoReward.
  id _rewardedMock;

  /// Partial mock of GADMobileAds.sharedInstance if used.
  id _adsMock;
}

- (void)setUp {
  [super setUp];
  GADMediationAdapterLineUnregisterFiveAd();

  _adapter = [[GADMediationAdapterLine alloc] init];

  _rewardedMock = OCMClassMock([FADVideoReward class]);
  OCMStub([_rewardedMock alloc]).andDo(^(NSInvocation *invocation) {
    id mock = self->_rewardedMock;
    CFRetain((__bridge CFTypeRef)mock);
    [invocation setReturnValue:&mock];
  });
  OCMStub([_rewardedMock initWithSlotId:AUTLineTestSlotID]).andReturn(_rewardedMock);
}

- (void)tearDown {
  GADMediationAdapterLineUnregisterFiveAd();
  [_rewardedMock stopMocking];
  _rewardedMock = nil;
  [_adsMock stopMocking];
  _adsMock = nil;
  GADMobileAds.sharedInstance.applicationMuted = NO;
  [super tearDown];
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
                                             XCTAssertTrue([config.appId
                                                 isEqualToString:AUTLineTestApplicationID]);
                                             return YES;
                                           }]
                                                    outError:[OCMArg anyObjectRef]]));

  // Test loading a rewarded ad.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID,
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
  [adLoaderClassMock stopMocking];

  return delegate;
}

- (void)testLoadRewardedAd {
  [self loadRewardedAdWithExtra:nil
             expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
}

- (void)testLoadBiddingRewardedAd {
  NSString *bidResponse = @"bidResponse";
  NSString *watermark = @"watermark";
  NSData *watermarkData = [watermark dataUsingEncoding:NSUTF8StringEncoding];
  id bidData = OCMClassMock([FADBidData class]);
  OCMStub([bidData alloc]).andReturn(bidData);
  OCMExpect([bidData initWithBidResponse:bidResponse withWatermark:watermark]).andReturn(bidData);

  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
                                             FADConfig *config = (FADConfig *)obj;
                                             XCTAssertTrue([config.appId
                                                 isEqualToString:AUTLineTestApplicationID]);
                                             return YES;
                                           }]
                                                    outError:[OCMArg anyObjectRef]]))
      .andReturn(adLoaderClassMock);

  OCMExpect([_rewardedMock setEventListener:OCMOCK_ANY]);
  OCMExpect([_rewardedMock enableSound:YES]);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID,
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };
  OCMExpect([adLoaderClassMock loadRewardAdWithBidData:bidData withLoadCallback:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(FADVideoReward *_Nullable customLayout,
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
  OCMVerifyAll(bidData);
  [bidData stopMocking];
  [adLoaderClassMock stopMocking];
}

- (void)testLoadBiddingRewardedAdFailureForFiveAdError {
  NSString *bidResponse = @"bidResponse";
  id bidData = OCMClassMock([FADBidData class]);
  OCMStub([bidData alloc]).andReturn(bidData);
  OCMStub([bidData initWithBidResponse:OCMOCK_ANY withWatermark:OCMOCK_ANY]).andReturn(bidData);

  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]))
      .andReturn(adLoaderClassMock);

  FADErrorCode code = kFADErrorCodeNoAd;
  NSError *fiveAdError = [NSError errorWithDomain:@"com.five_corp.ad.error" code:code userInfo:nil];
  OCMExpect([adLoaderClassMock loadRewardAdWithBidData:bidData withLoadCallback:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(FADVideoReward *_Nullable customLayout,
                                                      NSError *_Nullable adLoadError);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(nil, fiveAdError);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID,
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = bidResponse;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMediationAdapterFiveAdErrorDomain
                                                      code:code
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
  [bidData stopMocking];
  [adLoaderClassMock stopMocking];
}

- (void)testLoadRewardedAdAudioDefaultMuted {
  _adsMock = OCMPartialMock(GADMobileAds.sharedInstance);
  OCMStub([_adsMock isApplicationMuted]).andReturn(YES);
  [self loadRewardedAdWithExtra:nil expectSoundEnabled:NO];
  [_adsMock stopMocking];
  _adsMock = nil;
}

- (void)testLoadRewardedAdAudioDefaultUnmuted {
  _adsMock = OCMPartialMock(GADMobileAds.sharedInstance);
  OCMStub([_adsMock isApplicationMuted]).andReturn(NO);
  [self loadRewardedAdWithExtra:nil expectSoundEnabled:YES];
  [_adsMock stopMocking];
  _adsMock = nil;
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
  OCMReject([_rewardedMock loadAdAsync]);
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Test missing slot ID by omitting slot id from credential settings.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID,
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
  [adLoaderClassMock stopMocking];
}

- (void)testLoadRewardedAdFailureForFiveAdSDKFailedToReceiveAd {
  __block id<FADLoadDelegate> loadDelegate = nil;
  OCMStub([_rewardedMock setLoadDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  FADErrorCode code = kFADErrorCodeNoAd;
  OCMExpect([_rewardedMock loadAdAsync]).andDo(^(NSInvocation *invocation) {
    [loadDelegate fiveAd:self->_rewardedMock didFailedToReceiveAdWithError:code];
  });
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Test fail to receive an ad from FiveAd SDK.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID,
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
  [adLoaderClassMock stopMocking];
}

- (void)testRewardedAdPresent {
  AUTKMediationRewardedAdEventDelegate *delegate =
      [self loadRewardedAdWithExtra:nil
                 expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];

  FADVideoReward *rewardedAd = (FADVideoReward *)_rewardedMock;
  UIViewController *viewController = [[UIViewController alloc] init];
  OCMExpect([rewardedAd showWithViewController:viewController]);

  // Test ad present.
  id<GADMediationRewardedAd> mediationRewardedAd = delegate.rewardedAd;
  [mediationRewardedAd presentFromViewController:viewController];
  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 1);
  OCMVerifyAll(_rewardedMock);
}

- (void)testAdClick {
  AUTKMediationRewardedAdEventDelegate *delegate =
      [self loadRewardedAdWithExtra:nil
                 expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADVideoRewardEventListener> listener = (id<FADVideoRewardEventListener>)delegate.rewardedAd;
  [listener fiveVideoRewardAdDidClick:_rewardedMock];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);
}

- (void)testImpression {
  AUTKMediationRewardedAdEventDelegate *delegate =
      [self loadRewardedAdWithExtra:nil
                 expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADVideoRewardEventListener> listener = (id<FADVideoRewardEventListener>)delegate.rewardedAd;
  [listener fiveVideoRewardAdDidImpression:_rewardedMock];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);
}

- (void)testRewarded {
  FADVideoReward *rewardedAd = (FADVideoReward *)_rewardedMock;

  // Test that a reward is granted when the user closes the loaded ad after finishing watching it.
  AUTKMediationRewardedAdEventDelegate *delegate =
      [self loadRewardedAdWithExtra:nil
                 expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADVideoRewardEventListener> listener = (id<FADVideoRewardEventListener>)delegate.rewardedAd;
  [listener fiveVideoRewardAdDidReward:rewardedAd];

  XCTAssertEqual(delegate.didRewardUserInvokeCount, 1);
}

- (void)testVideoLifecycleEvents {
  FADVideoReward *rewardedAd = (FADVideoReward *)_rewardedMock;

  AUTKMediationRewardedAdEventDelegate *delegate =
      [self loadRewardedAdWithExtra:nil
                 expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADVideoRewardEventListener> listener = (id<FADVideoRewardEventListener>)delegate.rewardedAd;

  [listener fiveVideoRewardAdDidPlay:rewardedAd];
  XCTAssertEqual(delegate.didStartVideoInvokeCount, 1);

  [listener fiveVideoRewardAdDidViewThrough:rewardedAd];
  XCTAssertEqual(delegate.didEndVideoInvokeCount, 1);

  [listener fiveVideoRewardAdFullScreenDidClose:rewardedAd];
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

  [listener fiveVideoRewardAdFullScreenDidOpen:_rewardedMock];
  [listener fiveVideoRewardAdDidPause:_rewardedMock];
}

@end
