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
#import <AdapterUnitTestKit/AUTKMediationBannerAdLoadAssertions.h>
#import <FiveAd/FiveAd.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterLineConstants.h"
#import "GADMediationAdapterLineExtras.h"
#import "GADMediationAdapterLineUtils.h"

static NSString *const AUTLineTestSlotID = @"12345";
static NSString *const AUTLineTestApplicationID = @"123";

@interface AUTLineBannerAdTest : XCTestCase
@end

@implementation AUTLineBannerAdTest {
  /// An adapter instance that is used to test loading a banner ad.
  GADMediationAdapterLine *_adapter;

  /// A mock instance of FADAdViewCustomLayout (banner ad).
  id _bannerMock;

  /// Partial mock of GADMobileAds.sharedInstance if used.
  id _adsMock;
}

- (void)setUp {
  [super setUp];
  GADMediationAdapterLineUnregisterFiveAd();

  _adapter = [[GADMediationAdapterLine alloc] init];

  _bannerMock = OCMClassMock([FADAdViewCustomLayout class]);
  OCMStub([_bannerMock alloc]).andDo(^(NSInvocation *invocation) {
    id mock = self->_bannerMock;
    CFRetain((__bridge CFTypeRef)mock);
    [invocation setReturnValue:&mock];
  });
}

- (void)tearDown {
  GADMediationAdapterLineUnregisterFiveAd();
  [_bannerMock stopMocking];
  _bannerMock = nil;
  [_adsMock stopMocking];
  _adsMock = nil;
  GADMobileAds.sharedInstance.applicationMuted = NO;
  [super tearDown];
}

- (nonnull id<GADMediationBannerAdEventDelegate>)
    loadBannerAdWithSize:(GADAdSize)adSize
                   extra:(nullable GADMediationAdapterLineExtras *)extras
      expectSoundEnabled:(BOOL)soundEnabled {
  OCMStub([_bannerMock initWithSlotId:AUTLineTestSlotID width:adSize.size.width])
      .andReturn(_bannerMock);
  __block id<FADLoadDelegate> loadDelegate = nil;
  OCMStub([_bannerMock setLoadDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
    XCTAssertTrue([loadDelegate conformsToProtocol:@protocol(FADLoadDelegate)]);
  });
  OCMExpect([_bannerMock loadAdAsync]).andDo(^(NSInvocation *invocation) {
    [loadDelegate fiveAdDidLoad:self->_bannerMock];
  });
  OCMStub([_bannerMock frame]).andReturn(CGRectMake(0, 0, adSize.size.width, adSize.size.height));
  OCMExpect([_bannerMock enableSound:soundEnabled]);

  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
                                             FADConfig *config = (FADConfig *)obj;
                                             XCTAssertTrue([config.appId
                                                 isEqualToString:AUTLineTestApplicationID]);
                                             return YES;
                                           }]
                                                    outError:[OCMArg anyObjectRef]]));

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID,
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = adSize;
  configuration.extras = extras;
  id<GADMediationBannerAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(_bannerMock);
  OCMVerifyAll(adLoaderClassMock);
  [adLoaderClassMock stopMocking];

  return delegate;
}

- (nonnull id<GADMediationBannerAdEventDelegate>)
    loadBannerAdWithExtra:(nullable GADMediationAdapterLineExtras *)extras
       expectSoundEnabled:(BOOL)soundEnabled {
  return [self loadBannerAdWithSize:GADAdSizeBanner extra:extras expectSoundEnabled:soundEnabled];
}

- (void)testLoadBannerAd {
  [self loadBannerAdWithExtra:nil expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
}

- (void)testLoadBannerAdSizeBanner {
  [self loadBannerAdWithSize:GADAdSizeBanner
                       extra:nil
          expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
}

- (void)testLoadBannerAdSizeMediumRectangle {
  [self loadBannerAdWithSize:GADAdSizeMediumRectangle
                       extra:nil
          expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
}

- (void)testLoadBannerAdSizeLargeBanner {
  [self loadBannerAdWithSize:GADAdSizeLargeBanner
                       extra:nil
          expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
}

- (void)testLoadBannerAdSizeLeaderboard {
  [self loadBannerAdWithSize:GADAdSizeLeaderboard
                       extra:nil
          expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
}

- (void)testBiddingBannerAd {
  NSString *bidResponse = @"bidResponse";
  NSString *watermark = @"watermark";
  NSData *watermarkData = [watermark dataUsingEncoding:NSUTF8StringEncoding];
  id bidData = OCMClassMock([FADBidData class]);
  OCMStub([bidData alloc]).andReturn(bidData);
  OCMExpect([bidData initWithBidResponse:bidResponse withWatermark:watermark]).andReturn(bidData);

  GADAdSize requestedAdSize = GADAdSizeBanner;
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
                                             FADConfig *config = (FADConfig *)obj;
                                             XCTAssertTrue([config.appId
                                                 isEqualToString:AUTLineTestApplicationID]);
                                             return YES;
                                           }]
                                                    outError:[OCMArg anyObjectRef]]))
      .andReturn(adLoaderClassMock);

  id biddingBannerAdMock = OCMClassMock([FADAdViewCustomLayout class]);
  OCMStub([biddingBannerAdMock frame])
      .andReturn(CGRectMake(0, 0, requestedAdSize.size.width, requestedAdSize.size.height));
  OCMExpect([biddingBannerAdMock setEventListener:OCMOCK_ANY]);
  OCMExpect([biddingBannerAdMock enableSound:YES]);

  OCMExpect([adLoaderClassMock loadBannerAdWithBidData:bidData
                                      withInitialWidth:requestedAdSize.size.width
                                      withLoadCallback:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(FADAdViewCustomLayout *_Nullable customLayout,
                                                      NSError *_Nullable adLoadError);
        [invocation getArgument:&completionHandler atIndex:4];
        completionHandler(biddingBannerAdMock, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID,
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = requestedAdSize;
  configuration.bidResponse = bidResponse;
  configuration.watermark = watermarkData;
  id<GADMediationBannerAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(adLoaderClassMock);
  OCMVerifyAll(bidData);
  OCMVerifyAll(biddingBannerAdMock);
  [biddingBannerAdMock stopMocking];
  [bidData stopMocking];
  [adLoaderClassMock stopMocking];
}

- (void)testBiddingBannerAdFailureForFiveAdError {
  NSString *bidResponse = @"bidResponse";
  id bidData = OCMClassMock([FADBidData class]);
  OCMStub([bidData alloc]).andReturn(bidData);
  OCMStub([bidData initWithBidResponse:OCMOCK_ANY withWatermark:OCMOCK_ANY]).andReturn(bidData);

  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]))
      .andReturn(adLoaderClassMock);

  NSError *fiveAdError = [NSError errorWithDomain:@"com.five_corp.ad.error"
                                             code:kFADErrorCodeNoAd
                                         userInfo:nil];
  OCMExpect([adLoaderClassMock loadBannerAdWithBidData:bidData
                                      withInitialWidth:GADAdSizeBanner.size.width
                                      withLoadCallback:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(FADAdViewCustomLayout *_Nullable customLayout,
                                                      NSError *_Nullable adLoadError);
        [invocation getArgument:&completionHandler atIndex:4];
        completionHandler(nil, fiveAdError);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID,
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;
  configuration.bidResponse = bidResponse;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMediationAdapterFiveAdErrorDomain
                                                      code:kFADErrorCodeNoAd
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
  [bidData stopMocking];
  [adLoaderClassMock stopMocking];
}

- (void)testLoadBannerAdAudioDefaultMuted {
  _adsMock = OCMPartialMock(GADMobileAds.sharedInstance);
  OCMStub([_adsMock isApplicationMuted]).andReturn(YES);
  [self loadBannerAdWithExtra:nil expectSoundEnabled:NO];
  [_adsMock stopMocking];
  _adsMock = nil;
}

- (void)testLoadBannerAdAudioDefaultUnmuted {
  _adsMock = OCMPartialMock(GADMobileAds.sharedInstance);
  OCMStub([_adsMock isApplicationMuted]).andReturn(NO);
  [self loadBannerAdWithExtra:nil expectSoundEnabled:YES];
  [_adsMock stopMocking];
  _adsMock = nil;
}

- (void)testLoadBannerAdAudioUnset {
  GADMediationAdapterLineExtras *extras = [[GADMediationAdapterLineExtras alloc] init];
  extras.adAudio = GADMediationAdapterLineAdAudioUnset;
  [self loadBannerAdWithExtra:extras
           expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
}

- (void)testLoadBannerAdAudioUnmuted {
  GADMediationAdapterLineExtras *extras = [[GADMediationAdapterLineExtras alloc] init];
  extras.adAudio = GADMediationAdapterLineAdAudioUnmuted;
  [self loadBannerAdWithExtra:extras expectSoundEnabled:YES];
}

- (void)testLoadBannerAdAudioMuted {
  GADMediationAdapterLineExtras *extras = [[GADMediationAdapterLineExtras alloc] init];
  extras.adAudio = GADMediationAdapterLineAdAudioMuted;
  [self loadBannerAdWithExtra:extras expectSoundEnabled:NO];
}

- (void)testLoadBannerAdFailureForMissingSlotID {
  OCMReject([_bannerMock loadAdAsync]);
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Test banner ad load failure by omitting slot id from credential settings.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMediationAdapterLineErrorDomain
                                 code:GADMediationAdapterLineErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
  OCMVerifyAll(_bannerMock);
  [adLoaderClassMock stopMocking];
}

- (void)testLoadWaterfallBannerAdFailureForLoadedBannerSizeMismatch {
  // Mock FiveAd SDK.
  OCMStub([_bannerMock initWithSlotId:AUTLineTestSlotID width:GADAdSizeBanner.size.width])
      .andReturn(_bannerMock);
  __block id<FADLoadDelegate> loadDelegate = nil;
  OCMStub([_bannerMock setLoadDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  OCMExpect([_bannerMock loadAdAsync]).andDo(^(NSInvocation *invocation) {
    id loadedBannerAd = OCMClassMock([FADAdViewCustomLayout class]);
    OCMStub([loadedBannerAd frame]).andReturn(CGRectMake(0, 0, 123, 123));
    [loadDelegate fiveAdDidLoad:loadedBannerAd];
  });
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Test banner ad load failure by returning a mocked banner ad with a size that does not match the
  // requested ad size.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID,
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMediationAdapterLineErrorDomain
                                 code:GADMediationAdapterLineErrorLoadedBannerSizeMismatch
                             userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
  OCMVerifyAll(_bannerMock);
  [adLoaderClassMock stopMocking];
}

- (void)testLoadBannerAdFailureForFiveAdSDKFailedToReceiveAd {
  // Mock FiveAd SDK.
  OCMStub([_bannerMock initWithSlotId:AUTLineTestSlotID width:GADAdSizeBanner.size.width])
      .andReturn(_bannerMock);
  __block id<FADLoadDelegate> loadDelegate = nil;
  OCMStub([_bannerMock setLoadDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  FADErrorCode code = kFADErrorCodeNoAd;
  OCMExpect([_bannerMock loadAdAsync]).andDo(^(NSInvocation *invocation) {
    [loadDelegate fiveAd:self->_bannerMock didFailedToReceiveAdWithError:code];
  });
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Test ad load failure by mocking FiveAd SDK to call the ad load failure delegate method.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID,
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMediationAdapterFiveAdErrorDomain
                                                      code:code
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
  OCMVerifyAll(_bannerMock);
  [adLoaderClassMock stopMocking];
}

- (void)testMediationBannerAdView {
  // Mock FiveAd SDK.
  OCMStub([_bannerMock initWithSlotId:AUTLineTestSlotID width:GADAdSizeBanner.size.width])
      .andReturn(_bannerMock);
  __block id<FADLoadDelegate> loadDelegate = nil;
  OCMStub([_bannerMock setLoadDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  GADAdSize requestedAdSize = GADAdSizeBanner;
  OCMStub([_bannerMock loadAdAsync]).andDo(^(NSInvocation *invocation) {
    [loadDelegate fiveAdDidLoad:self->_bannerMock];
  });
  OCMStub([_bannerMock frame])
      .andReturn(CGRectMake(0, 0, requestedAdSize.size.width, requestedAdSize.size.height));
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Test that GADMediationBannerAd view property is actually the loaded banner ad view.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : AUTLineTestApplicationID,
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = requestedAdSize;
  AUTKMediationBannerAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);
  XCTAssertNotNil(delegate);

  id<GADMediationBannerAd> mediationBannerAd = delegate.bannerAd;
  XCTAssertEqualObjects(mediationBannerAd.view, _bannerMock);
  [adLoaderClassMock stopMocking];
}

- (void)testAdClick {
  AUTKMediationBannerAdEventDelegate *delegate = [self loadBannerAdWithExtra:nil
                                                          expectSoundEnabled:YES];
  id<FADCustomLayoutEventListener> listener = (id<FADCustomLayoutEventListener>)delegate.bannerAd;
  [listener fiveCustomLayoutAdDidClick:_bannerMock];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);
}

- (void)testImpression {
  AUTKMediationBannerAdEventDelegate *delegate = [self loadBannerAdWithExtra:nil
                                                          expectSoundEnabled:YES];
  id<FADCustomLayoutEventListener> listener = (id<FADCustomLayoutEventListener>)delegate.bannerAd;
  [listener fiveCustomLayoutAdDidImpression:_bannerMock];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);
}

- (void)testFailToShowAd {
  AUTKMediationBannerAdEventDelegate *delegate = [self loadBannerAdWithExtra:nil
                                                          expectSoundEnabled:YES];
  id<FADCustomLayoutEventListener> listener = (id<FADCustomLayoutEventListener>)delegate.bannerAd;
  FADErrorCode expectedErrorCode = kFADErrorCodePlayerError;
  [listener fiveCustomLayoutAd:_bannerMock didFailedToShowAdWithError:expectedErrorCode];
  NSError *presentError = delegate.didFailToPresentError;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMediationAdapterFiveAdErrorDomain
                                                      code:expectedErrorCode
                                                  userInfo:nil];
  XCTAssertEqual(presentError.code, expectedError.code);
  XCTAssertEqualObjects(presentError.domain, expectedError.domain);
}

- (void)testUnhandledEvents {
  // Following events are not handled by the GoogleMobileAds's banner event delegate, but
  // checking invoking them does not crash the running app.
  AUTKMediationBannerAdEventDelegate *delegate = [self loadBannerAdWithExtra:nil
                                                          expectSoundEnabled:YES];
  id<FADCustomLayoutEventListener> listener = (id<FADCustomLayoutEventListener>)delegate.bannerAd;
  [listener fiveCustomLayoutAdViewDidRemove:_bannerMock];
  [listener fiveCustomLayoutAdDidPlay:_bannerMock];
  [listener fiveCustomLayoutAdDidPause:_bannerMock];
  [listener fiveCustomLayoutAdDidViewThrough:_bannerMock];
}

@end
