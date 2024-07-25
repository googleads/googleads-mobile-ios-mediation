#import "GADMediationAdapterLine.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationInterstitialAdLoadAssertions.h>
#import <FiveAd/FiveAd.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterLineConstants.h"
#import "GADMediationAdapterLineExtras.h"

static NSString *const kTestSlotID = @"12345";

@interface AUTLineInterstitialAdTest : XCTestCase
@end

@implementation AUTLineInterstitialAdTest {
  /// An adapter instance that is used to test loading an interstitial ad.
  GADMediationAdapterLine *_adapter;

  /// A mock instance of FADInterstitial.
  id _interstitialMock;
}

- (void)setUp {
  [super setUp];

  _adapter = [[GADMediationAdapterLine alloc] init];

  _interstitialMock = OCMClassMock([FADInterstitial class]);
  OCMStub([_interstitialMock alloc]).andReturn(_interstitialMock);
  OCMStub([_interstitialMock initWithSlotId:kTestSlotID]).andReturn(_interstitialMock);

  id configClassMock = OCMClassMock([FADSettings class]);
  OCMStub([configClassMock registerConfig:OCMOCK_ANY]);
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
                                             XCTAssertTrue([config.appId isEqualToString:@"123"]);
                                             return YES;
                                           }]
                                                    outError:[OCMArg anyObjectRef]]));

  // Test loading an interstitial ad.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : @"123",
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

  return delegate;
}

- (void)testLoadInterstitialAd {
  [self loadInterstitialAdWithExtra:nil
                 expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
}

- (void)testLoadBiddingInterstitialAd {
  // Mock FiveAd SDK.
  __block id<FADLoadDelegate> loadDelegate = nil;
  OCMStub([_interstitialMock setLoadDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
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

  // Test loading an interstitial ad.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : @"123",
    GADMediationAdapterLineCredentialKeyAdUnit : kTestSlotID
  };
  OCMExpect([adLoaderClassMock loadInterstitialAdWithBidData:bidData withLoadCallback:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(FADAdViewCustomLayout *_Nullable customLayout,
                                                      NSError *_Nullable adLoadError);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(self->_interstitialMock, nil);
      });

  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.watermark = watermarkData;
  configuration.bidResponse = bidResponse;
  id<GADMediationInterstitialAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(_interstitialMock);
  OCMVerifyAll(adLoaderClassMock);
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
  // Mock FiveAd SDK.
  id _interstitialMock = OCMClassMock([FADInterstitial class]);
  OCMStub([_interstitialMock alloc]).andReturn(_interstitialMock);
  OCMReject([_interstitialMock loadAdAsync]);
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Test missing slot ID by omitting slot id from credential settings.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : @"123",
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
}

- (void)testLoadInterstitialAdFailureForFiveAdSDKFailedToReceiveAd {
  // Mock FiveAd SDK.
  id _interstitialMock = OCMClassMock([FADInterstitial class]);
  OCMStub([_interstitialMock alloc]).andReturn(_interstitialMock);
  OCMStub([_interstitialMock initWithSlotId:kTestSlotID]).andReturn(_interstitialMock);
  __block id<FADLoadDelegate> loadDelegate = nil;
  OCMStub([_interstitialMock setLoadDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  FADErrorCode code = kFADErrorCodeNoAd;
  OCMExpect([_interstitialMock loadAdAsync]).andDo(^(NSInvocation *invocation) {
    [loadDelegate fiveAd:_interstitialMock didFailedToReceiveAdWithError:code];
  });
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Test fail to receive ad from FiveAd SDK.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : @"123",
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
}

- (void)testInterstitialAdPresent {
  AUTKMediationInterstitialAdEventDelegate *delegate =
      [self loadInterstitialAdWithExtra:nil
                     expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Mock FiveAd SDK.
  FADInterstitial *interstitialAd = (FADInterstitial *)_interstitialMock;
  OCMExpect([interstitialAd show]);

  // Test ad present.
  id<GADMediationInterstitialAd> mediationInterstitialAd = delegate.interstitialAd;
  [mediationInterstitialAd presentFromViewController:[[UIViewController alloc] init]];
  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 1);
  OCMVerifyAll(_interstitialMock);
}

- (void)testAdClick {
  AUTKMediationInterstitialAdEventDelegate *delegate =
      [self loadInterstitialAdWithExtra:nil
                     expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADInterstitialEventListener> listener =
      (id<FADInterstitialEventListener>)delegate.interstitialAd;
  [listener fiveInterstitialAdDidClick:OCMOCK_ANY];
  XCTAssertTrue(delegate.reportClickInvokeCount == 1);
}

- (void)testImpression {
  AUTKMediationInterstitialAdEventDelegate *delegate =
      [self loadInterstitialAdWithExtra:nil
                     expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADInterstitialEventListener> listener =
      (id<FADInterstitialEventListener>)delegate.interstitialAd;
  [listener fiveInterstitialAdDidImpression:OCMOCK_ANY];
  XCTAssertTrue(delegate.reportImpressionInvokeCount == 1);
}

- (void)testAdClose {
  AUTKMediationInterstitialAdEventDelegate *delegate =
      [self loadInterstitialAdWithExtra:nil
                     expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADInterstitialEventListener> listener =
      (id<FADInterstitialEventListener>)delegate.interstitialAd;
  [listener fiveInterstitialAdFullScreenDidClose:OCMOCK_ANY];
  XCTAssertTrue(delegate.didDismissFullScreenViewInvokeCount == 1);
}

- (void)testFailToShowAd {
  AUTKMediationInterstitialAdEventDelegate *delegate =
      [self loadInterstitialAdWithExtra:nil
                     expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
  id<FADInterstitialEventListener> listener =
      (id<FADInterstitialEventListener>)delegate.interstitialAd;
  FADErrorCode expectedErrorCode = kFADErrorCodePlayerError;
  [listener fiveInterstitialAd:OCMOCK_ANY didFailedToShowAdWithError:expectedErrorCode];
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
  [listener fiveInterstitialAdFullScreenDidOpen:OCMOCK_ANY];
  [listener fiveInterstitialAdDidPlay:OCMOCK_ANY];
  [listener fiveInterstitialAdDidPause:OCMOCK_ANY];
  [listener fiveInterstitialAdDidViewThrough:OCMOCK_ANY];
}

@end
