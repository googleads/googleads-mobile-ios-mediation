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

@interface AUTLineRTBInterstitialAdTest : XCTestCase
@end

@implementation AUTLineRTBInterstitialAdTest {
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

  id configClassMock = OCMClassMock([FADSettings class]);
  OCMStub([configClassMock registerConfig:OCMOCK_ANY]);
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
  NSString *bidResponse = @"bidResponse";
  NSString *watermark = @"watermark";
  NSData *watermarkData = [watermark dataUsingEncoding:NSUTF8StringEncoding];
  id bidData = OCMClassMock([FADBidData class]);
  OCMStub([bidData alloc]).andReturn(bidData);
  OCMExpect([bidData initWithBidResponse:bidResponse withWatermark:watermark]).andReturn(bidData);

  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
                                             FADConfig *config = (FADConfig *)obj;
                                             XCTAssertTrue(
                                                 [config.appId isEqualToString:kTestApplicationID]);
                                             return YES;
                                           }]
                                                    outError:[OCMArg anyObjectRef]]))
      .andReturn(adLoaderClassMock);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : kTestApplicationID,
    GADMediationAdapterLineCredentialKeyAdUnit : kTestSlotID
  };
  OCMExpect([adLoaderClassMock loadInterstitialAdWithBidData:bidData withLoadCallback:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(FADInterstitial *_Nullable interstitialAd,
                                                      NSError *_Nullable adLoadError);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(self->_interstitialMock, nil);
      });

  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.watermark = watermarkData;
  configuration.bidResponse = bidResponse;
  configuration.extras = extras;
  OCMExpect([_interstitialMock setEventListener:OCMOCK_ANY]);
  OCMExpect([_interstitialMock enableSound:soundEnabled]);
  id<GADMediationInterstitialAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(_interstitialMock);
  OCMVerifyAll(adLoaderClassMock);
  OCMVerifyAll(bidData);
  [bidData stopMocking];
  [adLoaderClassMock stopMocking];
  return delegate;
}

- (void)testLoadInterstitialAd {
  [self loadInterstitialAdWithExtra:nil
                 expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
}

- (void)testLoadInterstitialAdWatermarkDataForwarding {
  NSString *bidResponse = @"test_bid_response";
  NSString *watermark = @"test_watermark_string";
  NSData *watermarkData = [watermark dataUsingEncoding:NSUTF8StringEncoding];

  id bidData = OCMClassMock([FADBidData class]);
  OCMStub([bidData alloc]).andReturn(bidData);
  OCMExpect([bidData initWithBidResponse:bidResponse withWatermark:watermark]).andReturn(bidData);

  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]))
      .andReturn(adLoaderClassMock);

  OCMExpect([adLoaderClassMock loadInterstitialAdWithBidData:bidData withLoadCallback:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(FADInterstitial *_Nullable interstitialAd,
                                                      NSError *_Nullable adLoadError);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(self->_interstitialMock, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : kTestApplicationID,
    GADMediationAdapterLineCredentialKeyAdUnit : kTestSlotID
  };
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.watermark = watermarkData;
  configuration.bidResponse = bidResponse;

  id<GADMediationInterstitialAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(bidData);
  [bidData stopMocking];
  [adLoaderClassMock stopMocking];
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

- (void)testLoadInterstitialAdFailureForMissingApplicationID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = @"bidResponse";
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMediationAdapterLineErrorDomain
                                 code:GADMediationAdapterLineErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadInterstitialAdFailureForFiveAdSDKFailedToLoad {
  id bidData = OCMClassMock([FADBidData class]);
  OCMStub([bidData alloc]).andReturn(bidData);
  OCMStub([bidData initWithBidResponse:OCMOCK_ANY withWatermark:OCMOCK_ANY]).andReturn(bidData);

  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]))
      .andReturn(adLoaderClassMock);

  FADErrorCode code = kFADErrorCodeNoAd;
  NSError *fiveAdError = [NSError errorWithDomain:@"com.five_corp.ad.error" code:code userInfo:nil];
  OCMExpect([adLoaderClassMock loadInterstitialAdWithBidData:bidData withLoadCallback:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(FADInterstitial *_Nullable interstitialAd,
                                                      NSError *_Nullable adLoadError);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(nil, fiveAdError);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : kTestApplicationID,
    GADMediationAdapterLineCredentialKeyAdUnit : kTestSlotID
  };
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = @"bidResponse";
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMediationAdapterFiveAdErrorDomain
                                                      code:code
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
  [bidData stopMocking];
  [adLoaderClassMock stopMocking];
}

- (void)testInterstitialAdPresent {
  AUTKMediationInterstitialAdEventDelegate *delegate =
      [self loadInterstitialAdWithExtra:nil
                     expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];

  FADInterstitial *interstitialAd = (FADInterstitial *)_interstitialMock;
  UIViewController *viewController = [[UIViewController alloc] init];
  OCMExpect([interstitialAd showWithViewController:viewController]);

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
