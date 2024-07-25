#import "GADMediationAdapterLine.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationBannerAdLoadAssertions.h>
#import <FiveAd/FiveAd.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterLineConstants.h"
#import "GADMediationAdapterLineExtras.h"

@interface AUTLineBannerAdTest : XCTestCase
@end

static NSString *const AUTLineTestSlotID = @"12345";

@interface FakeFADAdViewCustomLayout : UIView <FADAdInterface>
- (void)setEventListener:(nullable id<FADCustomLayoutEventListener>)listener;
@end

@implementation FakeFADAdViewCustomLayout
- (void)enableSound:(BOOL)enabled {
}
- (void)setEventListener:(id<FADCustomLayoutEventListener>)listener {
}
@end

@implementation AUTLineBannerAdTest {
  /// An adapter instance that is used to test loading a banner ad.
  GADMediationAdapterLine *_adapter;

  /// A mock instance of FADAdViewCustomLayout (banner ad).
  id _bannerMock;
}

- (void)setUp {
  [super setUp];

  _adapter = [[GADMediationAdapterLine alloc] init];

  _bannerMock = OCMClassMock([FADAdViewCustomLayout class]);
  OCMStub([_bannerMock alloc]).andReturn(_bannerMock);

  id configClassMock = OCMClassMock([FADSettings class]);
  OCMStub([configClassMock registerConfig:OCMOCK_ANY]);
}

- (nonnull id<GADMediationBannerAdEventDelegate>)
    loadBannerAdWithExtra:(nullable GADMediationAdapterLineExtras *)extras
       expectSoundEnabled:(BOOL)soundEnabled {
  // Mock FiveAd SDK.
  OCMStub([_bannerMock initWithSlotId:AUTLineTestSlotID width:GADAdSizeBanner.size.width])
      .andReturn(_bannerMock);
  __block id<FADLoadDelegate> loadDelegate = nil;
  OCMStub([_bannerMock setLoadDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
    XCTAssertTrue([loadDelegate conformsToProtocol:@protocol(FADLoadDelegate)]);
  });
  OCMStub([_bannerMock setAdViewEventListener:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    id<FADAdViewEventListener> eventListener = nil;
    [invocation getArgument:&eventListener atIndex:2];
    XCTAssertTrue([eventListener conformsToProtocol:@protocol(FADAdViewEventListener)]);
  });
  GADAdSize requestedAdSize = GADAdSizeBanner;
  OCMExpect([_bannerMock loadAdAsync]).andDo(^(NSInvocation *invocation) {
    id loadedBannerAd = [[UIView alloc]
        initWithFrame:CGRectMake(0, 0, requestedAdSize.size.width, requestedAdSize.size.height)];
    [loadDelegate fiveAdDidLoad:loadedBannerAd];
  });
  OCMExpect([_bannerMock enableSound:soundEnabled]);

  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
                                             FADConfig *config = (FADConfig *)obj;
                                             XCTAssertTrue([config.appId isEqualToString:@"123"]);
                                             return YES;
                                           }]
                                                    outError:[OCMArg anyObjectRef]]));

  // Test loading a banner ad.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : @"123",
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = requestedAdSize;
  configuration.extras = extras;
  id<GADMediationBannerAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(_bannerMock);
  OCMVerifyAll(adLoaderClassMock);

  return delegate;
}

- (void)testLoadBannerAd {
  [self loadBannerAdWithExtra:nil expectSoundEnabled:!GADMobileAds.sharedInstance.applicationMuted];
}

- (void)testBiddingBannerAd {
  // Mock FiveAd SDK.
  OCMStub([_bannerMock initWithSlotId:AUTLineTestSlotID width:GADAdSizeBanner.size.width])
      .andReturn(_bannerMock);
  __block id<FADLoadDelegate> loadDelegate = nil;
  OCMStub([_bannerMock setLoadDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
    XCTAssertTrue([loadDelegate conformsToProtocol:@protocol(FADLoadDelegate)]);
  });
  OCMStub([_bannerMock setAdViewEventListener:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    id<FADAdViewEventListener> eventListener = nil;
    [invocation getArgument:&eventListener atIndex:2];
    XCTAssertTrue([eventListener conformsToProtocol:@protocol(FADAdViewEventListener)]);
  });

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
                                             XCTAssertTrue([config.appId isEqualToString:@"123"]);
                                             return YES;
                                           }]
                                                    outError:[OCMArg anyObjectRef]]))
      .andReturn(adLoaderClassMock);
  OCMExpect([adLoaderClassMock loadBannerAdWithBidData:bidData withLoadCallback:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(FADAdViewCustomLayout *_Nullable customLayout,
                                                      NSError *_Nullable adLoadError);
        [invocation getArgument:&completionHandler atIndex:3];
        id bannerView = [[FakeFADAdViewCustomLayout alloc]
            initWithFrame:CGRectMake(0, 0, requestedAdSize.size.width,
                                     requestedAdSize.size.height)];
        completionHandler(bannerView, nil);
      });

  // Test loading a banner ad.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : @"123",
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
  OCMVerifyAll(_bannerMock);
  OCMVerifyAll(adLoaderClassMock);
  OCMVerifyAll(bidData);
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
  // Mock FiveAd SDK.
  OCMReject([_bannerMock loadAdAsync]);
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Test banner ad load failure by omitting slot id from credential settings.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMediationAdapterLineCredentialKeyApplicationID : @"123"};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMediationAdapterLineErrorDomain
                                 code:GADMediationAdapterLineErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
  OCMVerifyAll(_bannerMock);
}

- (void)testLoadBannerAdFailureForLoadedBannerSizeMismatch {
  // Mock FiveAd SDK.
  OCMStub([_bannerMock initWithSlotId:AUTLineTestSlotID width:GADAdSizeBanner.size.width])
      .andReturn(_bannerMock);
  __block id<FADLoadDelegate> loadDelegate = nil;
  OCMStub([_bannerMock setLoadDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  OCMExpect([_bannerMock loadAdAsync]).andDo(^(NSInvocation *invocation) {
    FADAdViewCustomLayout *loadedBannerAd = [[FADAdViewCustomLayout alloc] initWithSlotId:@"123123"
                                                                                    width:123];
    loadedBannerAd.frame = CGRectMake(0, 0, 123, 123);
    [loadDelegate fiveAdDidLoad:loadedBannerAd];
  });
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Test banner ad load failure by returning a mocked banner ad with a size that does not match the
  // requested ad size.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : @"123",
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
    GADMediationAdapterLineCredentialKeyApplicationID : @"123",
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
  id loadedBannerAd = [[UIView alloc]
      initWithFrame:CGRectMake(0, 0, requestedAdSize.size.width, requestedAdSize.size.height)];
  OCMStub([_bannerMock loadAdAsync]).andDo(^(NSInvocation *invocation) {
    [loadDelegate fiveAdDidLoad:loadedBannerAd];
  });
  OCMStub([_bannerMock frame]).andReturn(((UIView *)loadedBannerAd).frame);
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Test that GADMediationBannerAd view property is actually the loaded banner ad view.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : @"123",
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
