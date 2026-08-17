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
#import <AdapterUnitTestKit/AUTKMediationInterstitialAdLoadAssertions.h>
#import <FiveAd/FiveAd.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterLineConstants.h"
#import "GADMediationAdapterLineExtras.h"
#import "GADMediationAdapterLineUtils.h"

static NSString *const kTestSlotID = @"12345";
static NSString *const kTestApplicationID = @"123";

@interface AUTLineWaterfallInterstitialAdTest : XCTestCase
@end

@implementation AUTLineWaterfallInterstitialAdTest {
  /// An adapter instance that is used to test loading an interstitial ad.
  GADMediationAdapterLine *_adapter;

  /// A mock instance of FADInterstitial.
  id _interstitialMock;

  /// Partial mock of GADMobileAds.sharedInstance if used.
  id _adsMock;
}

- (void)setUp {
  [super setUp];
  GADMediationAdapterLineUnregisterFiveAd();

  _adapter = [[GADMediationAdapterLine alloc] init];

  _interstitialMock = OCMClassMock([FADInterstitial class]);
  OCMStub([_interstitialMock alloc]).andDo(^(NSInvocation *invocation) {
    id mock = self->_interstitialMock;
    CFRetain((__bridge CFTypeRef)mock);
    [invocation setReturnValue:&mock];
  });
  OCMStub([_interstitialMock initWithSlotId:kTestSlotID]).andReturn(_interstitialMock);
}

- (void)tearDown {
  GADMediationAdapterLineUnregisterFiveAd();
  [_interstitialMock stopMocking];
  _interstitialMock = nil;
  [_adsMock stopMocking];
  _adsMock = nil;
  GADMobileAds.sharedInstance.applicationMuted = NO;
  [super tearDown];
}

- (nonnull id<GADMediationInterstitialAdEventDelegate>)
    loadInterstitialAdWithExtra:(nullable GADMediationAdapterLineExtras *)extras
             expectSoundEnabled:(BOOL)soundEnabled {
  // Mock FiveAd SDK.
  __block id<FADLoadDelegate> loadDelegate = nil;
  OCMStub([_interstitialMock setLoadDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  OCMExpect([_interstitialMock loadAdAsync]).andDo(^(NSInvocation *invocation) {
    [loadDelegate fiveAdDidLoad:self->_interstitialMock];
  });
  OCMExpect([_interstitialMock enableSound:soundEnabled]);

  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
                                             FADConfig *config = (FADConfig *)obj;
                                             XCTAssertTrue(
                                                 [config.appId isEqualToString:kTestApplicationID]);
                                             return YES;
                                           }]
                                                    outError:[OCMArg anyObjectRef]]));

  // Test loading an interstitial ad.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : kTestApplicationID,
    GADMediationAdapterLineCredentialKeyAdUnit : kTestSlotID
  };
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = extras;
  id<GADMediationInterstitialAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(_interstitialMock);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];

  return delegate;
}

- (void)testLoadInterstitialAd {
  [self loadInterstitialAdWithExtra:nil
                 expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
}

- (void)testLoadInterstitialAdAudioDefaultMuted {
  _adsMock = OCMPartialMock(GADMobileAds.sharedInstance);
  OCMStub([_adsMock isApplicationMuted]).andReturn(YES);
  [self loadInterstitialAdWithExtra:nil expectSoundEnabled:NO];
  [_adsMock stopMocking];
  _adsMock = nil;
}

- (void)testLoadInterstitialAdAudioDefaultUnmuted {
  _adsMock = OCMPartialMock(GADMobileAds.sharedInstance);
  OCMStub([_adsMock isApplicationMuted]).andReturn(NO);
  [self loadInterstitialAdWithExtra:nil expectSoundEnabled:YES];
  [_adsMock stopMocking];
  _adsMock = nil;
}

- (void)testLoadInterstitialAdAudioUnset {
  GADMediationAdapterLineExtras *extras = [[GADMediationAdapterLineExtras alloc] init];
  extras.adAudio = GADMediationAdapterLineAdAudioUnset;
  [self loadInterstitialAdWithExtra:extras
                 expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
}

- (void)testLoadInterstitialAdAudioUnmuted {
  GADMediationAdapterLineExtras *extras = [[GADMediationAdapterLineExtras alloc] init];
  extras.adAudio = GADMediationAdapterLineAdAudioUnmuted;
  [self loadInterstitialAdWithExtra:extras expectSoundEnabled:YES];
}

- (void)testLoadInterstitialAdAudioMuted {
  GADMediationAdapterLineExtras *extras = [[GADMediationAdapterLineExtras alloc] init];
  extras.adAudio = GADMediationAdapterLineAdAudioMuted;
  [self loadInterstitialAdWithExtra:extras expectSoundEnabled:NO];
}

- (void)testLoadInterstitialAdFailureForMissingSlotID {
  OCMReject([_interstitialMock loadAdAsync]);
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Test missing slot ID by omitting slot id from credential settings.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : kTestApplicationID,
  };
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMediationAdapterLineErrorDomain
                                 code:GADMediationAdapterLineErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
  OCMVerifyAll(_interstitialMock);
  [adLoaderClassMock stopMocking];
}

- (void)testLoadInterstitialAdFailureForFiveAdSDKFailedToReceiveAd {
  __block id<FADLoadDelegate> loadDelegate = nil;
  OCMStub([_interstitialMock setLoadDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  FADErrorCode code = kFADErrorCodeNoAd;
  OCMExpect([_interstitialMock loadAdAsync]).andDo(^(NSInvocation *invocation) {
    [loadDelegate fiveAd:self->_interstitialMock didFailedToReceiveAdWithError:code];
  });
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Test fail to receive ad from FiveAd SDK.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : kTestApplicationID,
    GADMediationAdapterLineCredentialKeyAdUnit : kTestSlotID
  };
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMediationAdapterFiveAdErrorDomain
                                                      code:code
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
  OCMVerifyAll(_interstitialMock);
  [adLoaderClassMock stopMocking];
}

- (void)testInterstitialAdPresent {
  AUTKMediationInterstitialAdEventDelegate *delegate =
      [self loadInterstitialAdWithExtra:nil
                     expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];

  FADInterstitial *interstitialAd = (FADInterstitial *)_interstitialMock;
  UIViewController *viewController = [[UIViewController alloc] init];
  OCMExpect([interstitialAd showWithViewController:viewController]);

  // Test ad present.
  id<GADMediationInterstitialAd> mediationInterstitialAd = delegate.interstitialAd;
  [mediationInterstitialAd presentFromViewController:viewController];
  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 1);
  OCMVerifyAll(_interstitialMock);
}

- (void)testAdClick {
  AUTKMediationInterstitialAdEventDelegate *delegate =
      [self loadInterstitialAdWithExtra:nil
                     expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADInterstitialEventListener> listener =
      (id<FADInterstitialEventListener>)delegate.interstitialAd;
  [listener fiveInterstitialAdDidClick:_interstitialMock];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);
}

- (void)testImpression {
  AUTKMediationInterstitialAdEventDelegate *delegate =
      [self loadInterstitialAdWithExtra:nil
                     expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADInterstitialEventListener> listener =
      (id<FADInterstitialEventListener>)delegate.interstitialAd;
  [listener fiveInterstitialAdDidImpression:_interstitialMock];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);
}

- (void)testAdClose {
  AUTKMediationInterstitialAdEventDelegate *delegate =
      [self loadInterstitialAdWithExtra:nil
                     expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADInterstitialEventListener> listener =
      (id<FADInterstitialEventListener>)delegate.interstitialAd;
  [listener fiveInterstitialAdFullScreenDidClose:_interstitialMock];
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testFailToShowAd {
  AUTKMediationInterstitialAdEventDelegate *delegate =
      [self loadInterstitialAdWithExtra:nil
                     expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADInterstitialEventListener> listener =
      (id<FADInterstitialEventListener>)delegate.interstitialAd;
  FADErrorCode expectedErrorCode = kFADErrorCodePlayerError;
  [listener fiveInterstitialAd:_interstitialMock didFailedToShowAdWithError:expectedErrorCode];
  NSError *presentError = delegate.didFailToPresentError;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMediationAdapterFiveAdErrorDomain
                                                      code:expectedErrorCode
                                                  userInfo:nil];
  XCTAssertEqual(presentError.code, expectedError.code);
  XCTAssertEqualObjects(presentError.domain, expectedError.domain);
}

- (void)testUnhandledEvents {
  // Following events are not handled by the GoogleMobileAds's interstitial event delegate, but
  // checking invoking them does not crash the running app.
  AUTKMediationInterstitialAdEventDelegate *delegate =
      [self loadInterstitialAdWithExtra:nil
                     expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADInterstitialEventListener> listener =
      (id<FADInterstitialEventListener>)delegate.interstitialAd;
  [listener fiveInterstitialAdFullScreenDidOpen:_interstitialMock];
  [listener fiveInterstitialAdDidPlay:_interstitialMock];
  [listener fiveInterstitialAdDidPause:_interstitialMock];
  [listener fiveInterstitialAdDidViewThrough:_interstitialMock];
}

@end
