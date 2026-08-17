#import "GADMediationAdapterIronSource.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationBannerAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/IronSource.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterIronSourceBannerAd.h"
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceRtbBannerAd.h"
#import "GADMAdapterIronSourceUtils.h"

static NSString *const kAppKey = @"AppKey";
static NSString *const kInstanceId = @"1234";
static NSString *const kBidResponse = @"bidResponse";

@interface AUTIronSourceRtbBannerAdTests : XCTestCase

@end

@implementation AUTIronSourceRtbBannerAdTests {
  /// An adapter instance that is used to test loading a banner ad.
  GADMediationAdapterIronSource *_adapter;

  /// Mock instance of ISABannerAdLoader.
  id _isaBannerAdLoaderMock;

  /// Mock instance of ISABannerAdView.
  id _isaBannerAdViewMock;

  /// Captured loader delegate.
  __block id<ISABannerAdLoaderDelegate> _loaderDelegate;

  /// Captured banner ad request.
  __block ISABannerAdRequest *_capturedAdRequest;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterIronSource alloc] init];
  _isaBannerAdLoaderMock = OCMClassMock([ISABannerAdLoader class]);
  _isaBannerAdViewMock = OCMClassMock([ISABannerAdView class]);
}

- (void)tearDown {
  [_isaBannerAdLoaderMock stopMocking];
  [_isaBannerAdViewMock stopMocking];
  [super tearDown];
}

- (AUTKMediationBannerAdEventDelegate *)loadBannerAdWithSettings:
                                            (nullable NSDictionary<NSString *, id> *)settings
                                                       watermark:(nullable NSData *)watermark {
  OCMStub(ClassMethod([_isaBannerAdLoaderMock loadAdWithAdRequest:[OCMArg any]
                                                         delegate:[OCMArg any]]))
      .andDo(^(NSInvocation *invocation) {
        ISABannerAdRequest *request;
        id<ISABannerAdLoaderDelegate> delegate;
        [invocation getArgument:&request atIndex:2];
        [invocation getArgument:&delegate atIndex:3];
        self->_capturedAdRequest = request;
        self->_loaderDelegate = delegate;
        [delegate bannerAdDidLoad:self->_isaBannerAdViewMock];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = settings;
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  configuration.adSize = GADAdSizeBanner;
  configuration.watermark = watermark;

  AUTKMediationBannerAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);
  XCTAssertNotNil(eventDelegate);
  return eventDelegate;
}

- (AUTKMediationBannerAdEventDelegate *)loadBannerAd {
  NSDictionary<NSString *, id> *settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  return [self loadBannerAdWithSettings:settings watermark:nil];
}

- (void)testLoadBannerAdWithCustomInstanceId {
  NSDictionary<NSString *, id> *settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  [self loadBannerAdWithSettings:settings watermark:nil];

  XCTAssertEqualObjects(_adapter.rtbBannerAd.instanceID, kInstanceId);
}

- (void)testLoadBannerAdWithDefaultInstanceId {
  NSDictionary<NSString *, id> *settings = @{GADMAdapterIronSourceAppKey : kAppKey};
  [self loadBannerAdWithSettings:settings watermark:nil];

  XCTAssertEqualObjects(_adapter.rtbBannerAd.instanceID, GADMIronSourceDefaultRtbInstanceId);
}

- (void)testLoadBannerAdWithWatermark {
  NSData *watermarkData = [@"watermark_data" dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary<NSString *, id> *settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};

  id requestBuilderMock = OCMClassMock([ISABannerAdRequestBuilder class]);
  OCMStub([requestBuilderMock alloc]).andReturn(requestBuilderMock);
  OCMStub([requestBuilderMock initWithInstanceId:kInstanceId adm:kBidResponse size:[OCMArg any]])
      .andReturn(requestBuilderMock);
  OCMExpect([requestBuilderMock
                withExtraParams:[OCMArg checkWithBlock:^BOOL(id obj) {
                  NSDictionary *params = (NSDictionary *)obj;
                  NSString *expectedBase64 = [watermarkData base64EncodedStringWithOptions:0];
                  return [params[GADMAdapterIronSourceWatermark] isEqualToString:expectedBase64];
                }]])
      .andReturn(requestBuilderMock);
  OCMStub([requestBuilderMock withViewController:[OCMArg any]]).andReturn(requestBuilderMock);
  OCMStub([requestBuilderMock build]).andReturn([OCMArg any]);

  [self loadBannerAdWithSettings:settings watermark:watermarkData];

  OCMVerifyAll(requestBuilderMock);
  [requestBuilderMock stopMocking];
}

- (void)testLoadBannerAdFailureWhenIronSourceFails {
  NSError *ironSourceLoadError =
      [NSError errorWithDomain:@"com.ironsource.error"
                          code:1
                      userInfo:@{NSLocalizedDescriptionKey : @"IronSource banner load failed."}];
  OCMStub(ClassMethod([_isaBannerAdLoaderMock loadAdWithAdRequest:[OCMArg any]
                                                         delegate:[OCMArg any]]))
      .andDo(^(NSInvocation *invocation) {
        id<ISABannerAdLoaderDelegate> delegate;
        [invocation getArgument:&delegate atIndex:3];
        [delegate bannerAdDidFailToLoadWithError:ironSourceLoadError];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  configuration.adSize = GADAdSizeBanner;

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, ironSourceLoadError);
}

- (void)testViewReturnsLoadedIronSourceBannerAdView {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAd];
  id<GADMediationBannerAd> bannerAd = eventDelegate.bannerAd;

  XCTAssertEqual(bannerAd.view, _isaBannerAdViewMock);
}

- (void)testBannerAdViewDidShowReportsImpression {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAd];
  id<ISABannerAdViewDelegate> bannerDelegate = (id<ISABannerAdViewDelegate>)_adapter.rtbBannerAd;

  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  [bannerDelegate bannerAdViewDidShow:_isaBannerAdViewMock];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testBannerAdViewDidClickReportsClick {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAd];
  id<ISABannerAdViewDelegate> bannerDelegate = (id<ISABannerAdViewDelegate>)_adapter.rtbBannerAd;

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);
  [bannerDelegate bannerAdViewDidClick:_isaBannerAdViewMock];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testBannerAdViewEventsWithNilDelegateDoesNotCrash {
  GADMAdapterIronSourceRtbBannerAd *rtbBannerAd = [[GADMAdapterIronSourceRtbBannerAd alloc] init];
  rtbBannerAd.bannerAdEventDelegate = nil;

  XCTAssertNoThrow([rtbBannerAd bannerAdViewDidShow:_isaBannerAdViewMock]);
  XCTAssertNoThrow([rtbBannerAd bannerAdViewDidClick:_isaBannerAdViewMock]);
}

- (void)testBannerAdDidLoadWithNilCompletionHandlerDoesNotCrash {
  GADMAdapterIronSourceRtbBannerAd *rtbBannerAd = [[GADMAdapterIronSourceRtbBannerAd alloc] init];
  rtbBannerAd.bannerAdLoadCompletionHandler = nil;

  XCTAssertNoThrow([rtbBannerAd bannerAdDidLoad:_isaBannerAdViewMock]);
}

- (void)testBannerAdDidFailToLoadWithNilCompletionHandlerDoesNotCrash {
  GADMAdapterIronSourceRtbBannerAd *rtbBannerAd = [[GADMAdapterIronSourceRtbBannerAd alloc] init];
  rtbBannerAd.bannerAdLoadCompletionHandler = nil;
  NSError *testError = [NSError errorWithDomain:@"test" code:1 userInfo:nil];

  XCTAssertNoThrow([rtbBannerAd bannerAdDidFailToLoadWithError:testError]);
}

- (void)testLoadBannerRoutesToRtbBannerWhenBidResponsePresent {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  configuration.adSize = GADAdSizeBanner;

  id rtbBannerMock = OCMClassMock([GADMAdapterIronSourceRtbBannerAd class]);
  OCMStub([rtbBannerMock alloc]).andReturn(rtbBannerMock);
  OCMExpect([rtbBannerMock loadBannerAdForConfiguration:configuration
                                      completionHandler:[OCMArg any]]);

  [_adapter loadBannerForAdConfiguration:configuration
                       completionHandler:^id<GADMediationBannerAdEventDelegate>(
                           id<GADMediationBannerAd> ad, NSError *error) {
                         return nil;
                       }];

  OCMVerifyAll(rtbBannerMock);
  XCTAssertNotNil(_adapter.rtbBannerAd);
  [rtbBannerMock stopMocking];
}

- (void)testLoadBannerRoutesToWaterfallBannerWhenBidResponseNil {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = nil;
  configuration.adSize = GADAdSizeBanner;

  id bannerMock = OCMClassMock([GADMAdapterIronSourceBannerAd class]);
  OCMStub([bannerMock alloc]).andReturn(bannerMock);
  OCMExpect([bannerMock loadBannerAdForAdConfiguration:configuration
                                     completionHandler:[OCMArg any]]);

  [_adapter loadBannerForAdConfiguration:configuration
                       completionHandler:^id<GADMediationBannerAdEventDelegate>(
                           id<GADMediationBannerAd> ad, NSError *error) {
                         return nil;
                       }];

  OCMVerifyAll(bannerMock);
  XCTAssertNil(_adapter.rtbBannerAd);
  [bannerMock stopMocking];
}

@end
