#import "GADMediationAdapterIronSource.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationInterstitialAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/IronSource.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceInterstitialAd.h"
#import "GADMAdapterIronSourceRtbInterstitialAd.h"
#import "GADMAdapterIronSourceUtils.h"

static NSString *const kAppKey = @"AppKey";
static NSString *const kInstanceId = @"1234";
static NSString *const kBidResponse = @"bidResponse";

@interface GADMAdapterIronSourceRtbInterstitialAd (Testing)
@property(nonatomic, copy) NSString *instanceID;
@end

@interface AUTIronSourceRtbInterstitialAdTests : XCTestCase

@end

@implementation AUTIronSourceRtbInterstitialAdTests {
  /// An adapter instance that is used to test loading an interstitial ad.
  GADMediationAdapterIronSource *_adapter;

  /// Mock instance of ISAInterstitialAdLoader.
  id _isaInterstitialAdLoaderMock;

  /// Mock instance of ISAInterstitialAd.
  id _isaInterstitialAdMock;

  /// Captured loader delegate.
  __block id<ISAInterstitialAdLoaderDelegate> _loaderDelegate;

  /// Captured interstitial ad request.
  __block ISAInterstitialAdRequest *_capturedAdRequest;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterIronSource alloc] init];
  _isaInterstitialAdLoaderMock = OCMClassMock([ISAInterstitialAdLoader class]);
  _isaInterstitialAdMock = OCMClassMock([ISAInterstitialAd class]);
}

- (void)tearDown {
  [_isaInterstitialAdLoaderMock stopMocking];
  [_isaInterstitialAdMock stopMocking];
  [super tearDown];
}

- (AUTKMediationInterstitialAdEventDelegate *)
    loadInterstitialAdWithSettings:(nullable NSDictionary<NSString *, id> *)settings
                         watermark:(nullable NSData *)watermark {
  OCMStub(ClassMethod([_isaInterstitialAdLoaderMock loadAdWithAdRequest:[OCMArg any]
                                                               delegate:[OCMArg any]]))
      .andDo(^(NSInvocation *invocation) {
        ISAInterstitialAdRequest *request;
        id<ISAInterstitialAdLoaderDelegate> delegate;
        [invocation getArgument:&request atIndex:2];
        [invocation getArgument:&delegate atIndex:3];
        self->_capturedAdRequest = request;
        self->_loaderDelegate = delegate;
        [delegate interstitialAdDidLoad:self->_isaInterstitialAdMock];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = settings;
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  configuration.watermark = watermark;

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);
  XCTAssertNotNil(eventDelegate);
  return eventDelegate;
}

- (AUTKMediationInterstitialAdEventDelegate *)loadInterstitialAd {
  NSDictionary<NSString *, id> *settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  return [self loadInterstitialAdWithSettings:settings watermark:nil];
}

- (void)testLoadInterstitialAdWithCustomInstanceId {
  NSDictionary<NSString *, id> *settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  [self loadInterstitialAdWithSettings:settings watermark:nil];

  XCTAssertEqualObjects(_adapter.rtbInterstitialAd.instanceID, kInstanceId);
}

- (void)testLoadInterstitialAdWithDefaultInstanceId {
  NSDictionary<NSString *, id> *settings = @{GADMAdapterIronSourceAppKey : kAppKey};
  [self loadInterstitialAdWithSettings:settings watermark:nil];

  XCTAssertEqualObjects(_adapter.rtbInterstitialAd.instanceID, GADMIronSourceDefaultRtbInstanceId);
}

- (void)testLoadInterstitialAdWithWatermark {
  NSData *watermarkData = [@"watermark_data" dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary<NSString *, id> *settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};

  id requestBuilderMock = OCMClassMock([ISAInterstitialAdRequestBuilder class]);
  OCMStub([requestBuilderMock alloc]).andReturn(requestBuilderMock);
  OCMStub([requestBuilderMock initWithInstanceId:kInstanceId adm:kBidResponse])
      .andReturn(requestBuilderMock);
  OCMExpect([requestBuilderMock
                withExtraParams:[OCMArg checkWithBlock:^BOOL(id obj) {
                  NSDictionary *params = (NSDictionary *)obj;
                  NSString *expectedBase64 = [watermarkData base64EncodedStringWithOptions:0];
                  return [params[GADMAdapterIronSourceWatermark] isEqualToString:expectedBase64];
                }]])
      .andReturn(requestBuilderMock);
  OCMStub([requestBuilderMock build]).andReturn([OCMArg any]);

  [self loadInterstitialAdWithSettings:settings watermark:watermarkData];

  OCMVerifyAll(requestBuilderMock);
  [requestBuilderMock stopMocking];
}

- (void)testLoadInterstitialAdFailureWhenIronSourceFails {
  NSError *ironSourceLoadError = [NSError
      errorWithDomain:@"com.ironsource.error"
                 code:1
             userInfo:@{NSLocalizedDescriptionKey : @"IronSource interstitial load failed."}];
  OCMStub(ClassMethod([_isaInterstitialAdLoaderMock loadAdWithAdRequest:[OCMArg any]
                                                               delegate:[OCMArg any]]))
      .andDo(^(NSInvocation *invocation) {
        id<ISAInterstitialAdLoaderDelegate> delegate;
        [invocation getArgument:&delegate atIndex:3];
        [delegate interstitialAdDidFailToLoadWithError:ironSourceLoadError];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;

  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, ironSourceLoadError);
}

- (void)testPresentFromViewControllerWhenLoadedCallsShowAndInvokesWillPresentFullScreenView {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadInterstitialAd];
  UIViewController *viewController = [[UIViewController alloc] init];

  OCMExpect([_isaInterstitialAdMock setDelegate:_adapter.rtbInterstitialAd]);
  OCMExpect([_isaInterstitialAdMock showFromViewController:viewController]);

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  [eventDelegate.interstitialAd presentFromViewController:viewController];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);

  OCMVerifyAll(_isaInterstitialAdMock);
}

- (void)testPresentFromViewControllerWhenAdIsNilInvokesDidFailToPresentWithError {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadInterstitialAd];
  _adapter.rtbInterstitialAd.biddingISAInterstitialAd = nil;
  UIViewController *viewController = [[UIViewController alloc] init];

  [eventDelegate.interstitialAd presentFromViewController:viewController];

  NSError *presentationError = eventDelegate.didFailToPresentError;
  XCTAssertNotNil(presentationError);
  XCTAssertEqual(presentationError.code, GADMAdapterIronSourceErrorFailedToShow);
  XCTAssertEqualObjects(presentationError.domain, GADMAdapterIronSourceErrorDomain);
}

- (void)testPresentFromViewControllerWhenAdIsNilAndEventDelegateIsNilDoesNotCrash {
  GADMAdapterIronSourceRtbInterstitialAd *rtbInterstitialAd =
      [[GADMAdapterIronSourceRtbInterstitialAd alloc] init];
  rtbInterstitialAd.interstitialAdEventDelegate = nil;
  rtbInterstitialAd.biddingISAInterstitialAd = nil;
  UIViewController *viewController = [[UIViewController alloc] init];

  XCTAssertNoThrow([rtbInterstitialAd presentFromViewController:viewController]);
}

- (void)testInterstitialAdDidShowReportsImpression {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadInterstitialAd];
  id<ISAInterstitialAdDelegate> delegate =
      (id<ISAInterstitialAdDelegate>)_adapter.rtbInterstitialAd;

  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  [delegate interstitialAdDidShow:_isaInterstitialAdMock];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testInterstitialAdDidClickReportsClick {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadInterstitialAd];
  id<ISAInterstitialAdDelegate> delegate =
      (id<ISAInterstitialAdDelegate>)_adapter.rtbInterstitialAd;

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);
  [delegate interstitialAdDidClick:_isaInterstitialAdMock];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testInterstitialAdDidDismissInvokesDismissCallbacks {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadInterstitialAd];
  id<ISAInterstitialAdDelegate> delegate =
      (id<ISAInterstitialAdDelegate>)_adapter.rtbInterstitialAd;

  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);
  [delegate interstitialAdDidDismiss:_isaInterstitialAdMock];
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testInterstitialAdDidFailToShowWithErrorInvokesDidFailToPresentWithError {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadInterstitialAd];
  id<ISAInterstitialAdDelegate> delegate =
      (id<ISAInterstitialAdDelegate>)_adapter.rtbInterstitialAd;
  NSError *showError = [NSError errorWithDomain:@"com.ironsource.error"
                                           code:2
                                       userInfo:@{NSLocalizedDescriptionKey : @"Show failed."}];

  [delegate interstitialAd:_isaInterstitialAdMock didFailToShowWithError:showError];

  XCTAssertEqualObjects(eventDelegate.didFailToPresentError, showError);
}

- (void)testInterstitialAdEventsWithNilDelegateDoesNotCrash {
  GADMAdapterIronSourceRtbInterstitialAd *rtbInterstitialAd =
      [[GADMAdapterIronSourceRtbInterstitialAd alloc] init];
  rtbInterstitialAd.interstitialAdEventDelegate = nil;
  NSError *testError = [NSError errorWithDomain:@"test" code:1 userInfo:nil];

  XCTAssertNoThrow([rtbInterstitialAd interstitialAdDidShow:_isaInterstitialAdMock]);
  XCTAssertNoThrow([rtbInterstitialAd interstitialAdDidClick:_isaInterstitialAdMock]);
  XCTAssertNoThrow([rtbInterstitialAd interstitialAdDidDismiss:_isaInterstitialAdMock]);
  XCTAssertNoThrow([rtbInterstitialAd interstitialAd:_isaInterstitialAdMock
                              didFailToShowWithError:testError]);
}

- (void)testInterstitialAdDidLoadWithNilCompletionHandlerDoesNotCrash {
  GADMAdapterIronSourceRtbInterstitialAd *rtbInterstitialAd =
      [[GADMAdapterIronSourceRtbInterstitialAd alloc] init];
  rtbInterstitialAd.interstitalAdLoadCompletionHandler = nil;

  XCTAssertNoThrow([rtbInterstitialAd interstitialAdDidLoad:_isaInterstitialAdMock]);
}

- (void)testInterstitialAdDidFailToLoadWithNilCompletionHandlerDoesNotCrash {
  GADMAdapterIronSourceRtbInterstitialAd *rtbInterstitialAd =
      [[GADMAdapterIronSourceRtbInterstitialAd alloc] init];
  rtbInterstitialAd.interstitalAdLoadCompletionHandler = nil;
  NSError *testError = [NSError errorWithDomain:@"test" code:1 userInfo:nil];

  XCTAssertNoThrow([rtbInterstitialAd interstitialAdDidFailToLoadWithError:testError]);
}

- (void)testLoadInterstitialRoutesToRtbInterstitialWhenBidResponsePresent {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;

  id rtbInterstitialMock = OCMClassMock([GADMAdapterIronSourceRtbInterstitialAd class]);
  OCMStub([rtbInterstitialMock alloc]).andReturn(rtbInterstitialMock);
  OCMExpect([rtbInterstitialMock loadInterstitialForAdConfiguration:configuration
                                                  completionHandler:[OCMArg any]]);

  [_adapter loadInterstitialForAdConfiguration:configuration
                             completionHandler:^id<GADMediationInterstitialAdEventDelegate>(
                                 id<GADMediationInterstitialAd> ad, NSError *error) {
                               return nil;
                             }];

  OCMVerifyAll(rtbInterstitialMock);
  XCTAssertNotNil(_adapter.rtbInterstitialAd);
  [rtbInterstitialMock stopMocking];
}

- (void)testLoadInterstitialRoutesToWaterfallInterstitialWhenBidResponseNil {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = nil;

  id interstitialMock = OCMClassMock([GADMAdapterIronSourceInterstitialAd class]);
  OCMStub([interstitialMock alloc]).andReturn(interstitialMock);
  OCMExpect([interstitialMock loadInterstitialForAdConfiguration:configuration
                                               completionHandler:[OCMArg any]]);

  [_adapter loadInterstitialForAdConfiguration:configuration
                             completionHandler:^id<GADMediationInterstitialAdEventDelegate>(
                                 id<GADMediationInterstitialAd> ad, NSError *error) {
                               return nil;
                             }];

  OCMVerifyAll(interstitialMock);
  XCTAssertNil(_adapter.rtbInterstitialAd);
  [interstitialMock stopMocking];
}

@end
