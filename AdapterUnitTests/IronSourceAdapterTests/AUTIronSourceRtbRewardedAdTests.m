#import "GADMediationAdapterIronSource.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationRewardedAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/IronSource.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceRewardedAd.h"
#import "GADMAdapterIronSourceRtbRewardedAd.h"
#import "GADMAdapterIronSourceUtils.h"

static NSString *const kAppKey = @"AppKey";
static NSString *const kInstanceId = @"1234";
static NSString *const kBidResponse = @"bidResponse";

@interface AUTIronSourceRtbRewardedAdTests : XCTestCase

@end

@implementation AUTIronSourceRtbRewardedAdTests {
  /// An adapter instance that is used to test loading a rewarded ad.
  GADMediationAdapterIronSource *_adapter;

  /// Mock instance of ISARewardedAdLoader.
  id _isaRewardedAdLoaderMock;

  /// Mock instance of ISARewardedAd.
  id _isaRewardedAdMock;

  /// Captured loader delegate.
  __block id<ISARewardedAdLoaderDelegate> _loaderDelegate;

  /// Captured rewarded ad request.
  __block ISARewardedAdRequest *_capturedAdRequest;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterIronSource alloc] init];
  _isaRewardedAdLoaderMock = OCMClassMock([ISARewardedAdLoader class]);
  _isaRewardedAdMock = OCMClassMock([ISARewardedAd class]);
}

- (void)tearDown {
  [_isaRewardedAdLoaderMock stopMocking];
  [_isaRewardedAdMock stopMocking];
  [super tearDown];
}

- (AUTKMediationRewardedAdEventDelegate *)loadRewardedAdWithSettings:
                                              (nullable NSDictionary<NSString *, id> *)settings
                                                           watermark:(nullable NSData *)watermark {
  OCMStub(ClassMethod([_isaRewardedAdLoaderMock loadAdWithAdRequest:[OCMArg any]
                                                           delegate:[OCMArg any]]))
      .andDo(^(NSInvocation *invocation) {
        ISARewardedAdRequest *request;
        id<ISARewardedAdLoaderDelegate> delegate;
        [invocation getArgument:&request atIndex:2];
        [invocation getArgument:&delegate atIndex:3];
        self->_capturedAdRequest = request;
        self->_loaderDelegate = delegate;
        [delegate rewardedAdDidLoad:self->_isaRewardedAdMock];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = settings;
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  configuration.watermark = watermark;

  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);
  XCTAssertNotNil(eventDelegate);
  return eventDelegate;
}

- (AUTKMediationRewardedAdEventDelegate *)loadRewardedAd {
  NSDictionary<NSString *, id> *settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  return [self loadRewardedAdWithSettings:settings watermark:nil];
}

- (void)testLoadRewardedAdWithCustomInstanceId {
  NSDictionary<NSString *, id> *settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  [self loadRewardedAdWithSettings:settings watermark:nil];

  XCTAssertEqualObjects(_adapter.rtbRewardedAd.instanceID, kInstanceId);
}

- (void)testLoadRewardedAdWithDefaultInstanceId {
  NSDictionary<NSString *, id> *settings = @{GADMAdapterIronSourceAppKey : kAppKey};
  [self loadRewardedAdWithSettings:settings watermark:nil];

  XCTAssertEqualObjects(_adapter.rtbRewardedAd.instanceID, GADMIronSourceDefaultRtbInstanceId);
}

- (void)testLoadRewardedAdWithWatermark {
  NSData *watermarkData = [@"watermark_data" dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary<NSString *, id> *settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};

  id requestBuilderMock = OCMClassMock([ISARewardedAdRequestBuilder class]);
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

  [self loadRewardedAdWithSettings:settings watermark:watermarkData];

  OCMVerifyAll(requestBuilderMock);
  [requestBuilderMock stopMocking];
}

- (void)testLoadRewardedAdFailureWhenIronSourceFails {
  NSError *ironSourceLoadError =
      [NSError errorWithDomain:@"com.ironsource.error"
                          code:1
                      userInfo:@{NSLocalizedDescriptionKey : @"IronSource rewarded load failed."}];
  OCMStub(ClassMethod([_isaRewardedAdLoaderMock loadAdWithAdRequest:[OCMArg any]
                                                           delegate:[OCMArg any]]))
      .andDo(^(NSInvocation *invocation) {
        id<ISARewardedAdLoaderDelegate> delegate;
        [invocation getArgument:&delegate atIndex:3];
        [delegate rewardedAdDidFailToLoadWithError:ironSourceLoadError];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;

  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, ironSourceLoadError);
}

- (void)testPresentFromViewControllerWhenLoadedCallsShowAndInvokesWillPresentFullScreenView {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAd];
  UIViewController *viewController = [[UIViewController alloc] init];

  OCMExpect([_isaRewardedAdMock setDelegate:_adapter.rtbRewardedAd]);
  OCMExpect([_isaRewardedAdMock showFromViewController:viewController]);

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  [eventDelegate.rewardedAd presentFromViewController:viewController];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);

  OCMVerifyAll(_isaRewardedAdMock);
}

- (void)testPresentFromViewControllerWhenAdIsNilInvokesDidFailToPresentWithError {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAd];
  _adapter.rtbRewardedAd.biddingISARewardedAd = nil;
  UIViewController *viewController = [[UIViewController alloc] init];

  [eventDelegate.rewardedAd presentFromViewController:viewController];

  NSError *presentationError = eventDelegate.didFailToPresentError;
  XCTAssertNotNil(presentationError);
  XCTAssertEqual(presentationError.code, GADMAdapterIronSourceErrorFailedToShow);
  XCTAssertEqualObjects(presentationError.domain, GADMAdapterIronSourceErrorDomain);
}

- (void)testPresentFromViewControllerWhenAdIsNilAndEventDelegateIsNilDoesNotCrash {
  GADMAdapterIronSourceRtbRewardedAd *rtbRewardedAd =
      [[GADMAdapterIronSourceRtbRewardedAd alloc] init];
  rtbRewardedAd.rewardedAdEventDelegate = nil;
  rtbRewardedAd.biddingISARewardedAd = nil;
  UIViewController *viewController = [[UIViewController alloc] init];

  XCTAssertNoThrow([rtbRewardedAd presentFromViewController:viewController]);
}

- (void)testRewardedAdDidShowReportsImpressionAndStartsVideo {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAd];
  id<ISARewardedAdDelegate> delegate = (id<ISARewardedAdDelegate>)_adapter.rtbRewardedAd;

  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  [delegate rewardedAdDidShow:_isaRewardedAdMock];
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 1);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testRewardedAdDidClickReportsClick {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAd];
  id<ISARewardedAdDelegate> delegate = (id<ISARewardedAdDelegate>)_adapter.rtbRewardedAd;

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);
  [delegate rewardedAdDidClick:_isaRewardedAdMock];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testRewardedAdDidDismissInvokesDismissCallbacks {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAd];
  id<ISARewardedAdDelegate> delegate = (id<ISARewardedAdDelegate>)_adapter.rtbRewardedAd;

  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);
  [delegate rewardedAdDidDismiss:_isaRewardedAdMock];
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testRewardedAdDidUserEarnRewardInvokesRewardAndEndVideo {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAd];
  id<ISARewardedAdDelegate> delegate = (id<ISARewardedAdDelegate>)_adapter.rtbRewardedAd;

  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 0);
  [delegate rewardedAdDidUserEarnReward:_isaRewardedAdMock];
  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 1);
}

- (void)testRewardedAdDidFailToShowWithErrorInvokesDidFailToPresentWithError {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAd];
  id<ISARewardedAdDelegate> delegate = (id<ISARewardedAdDelegate>)_adapter.rtbRewardedAd;
  NSError *showError = [NSError errorWithDomain:@"com.ironsource.error"
                                           code:2
                                       userInfo:@{NSLocalizedDescriptionKey : @"Show failed."}];

  [delegate rewardedAd:_isaRewardedAdMock didFailToShowWithError:showError];

  XCTAssertEqualObjects(eventDelegate.didFailToPresentError, showError);
}

- (void)testRewardedAdEventsWithNilDelegateDoesNotCrash {
  GADMAdapterIronSourceRtbRewardedAd *rtbRewardedAd =
      [[GADMAdapterIronSourceRtbRewardedAd alloc] init];
  rtbRewardedAd.rewardedAdEventDelegate = nil;
  NSError *testError = [NSError errorWithDomain:@"test" code:1 userInfo:nil];

  XCTAssertNoThrow([rtbRewardedAd rewardedAdDidShow:_isaRewardedAdMock]);
  XCTAssertNoThrow([rtbRewardedAd rewardedAdDidClick:_isaRewardedAdMock]);
  XCTAssertNoThrow([rtbRewardedAd rewardedAdDidDismiss:_isaRewardedAdMock]);
  XCTAssertNoThrow([rtbRewardedAd rewardedAdDidUserEarnReward:_isaRewardedAdMock]);
  XCTAssertNoThrow([rtbRewardedAd rewardedAd:_isaRewardedAdMock didFailToShowWithError:testError]);
}

- (void)testRewardedAdDidLoadWithNilCompletionHandlerDoesNotCrash {
  GADMAdapterIronSourceRtbRewardedAd *rtbRewardedAd =
      [[GADMAdapterIronSourceRtbRewardedAd alloc] init];
  rtbRewardedAd.rewardedAdLoadCompletionHandler = nil;

  XCTAssertNoThrow([rtbRewardedAd rewardedAdDidLoad:_isaRewardedAdMock]);
}

- (void)testRewardedAdDidFailToLoadWithNilCompletionHandlerDoesNotCrash {
  GADMAdapterIronSourceRtbRewardedAd *rtbRewardedAd =
      [[GADMAdapterIronSourceRtbRewardedAd alloc] init];
  rtbRewardedAd.rewardedAdLoadCompletionHandler = nil;
  NSError *testError = [NSError errorWithDomain:@"test" code:1 userInfo:nil];

  XCTAssertNoThrow([rtbRewardedAd rewardedAdDidFailToLoadWithError:testError]);
}

- (void)testLoadRewardedAdRoutesToRtbRewardedWhenBidResponsePresent {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;

  id rtbRewardedMock = OCMClassMock([GADMAdapterIronSourceRtbRewardedAd class]);
  OCMStub([rtbRewardedMock alloc]).andReturn(rtbRewardedMock);
  OCMExpect([rtbRewardedMock loadRewardedAdForConfiguration:configuration
                                          completionHandler:[OCMArg any]]);

  [_adapter loadRewardedAdForAdConfiguration:configuration
                           completionHandler:^id<GADMediationRewardedAdEventDelegate>(
                               id<GADMediationRewardedAd> ad, NSError *error) {
                             return nil;
                           }];

  OCMVerifyAll(rtbRewardedMock);
  XCTAssertNotNil(_adapter.rtbRewardedAd);
  [rtbRewardedMock stopMocking];
}

- (void)testLoadRewardedAdRoutesToWaterfallRewardedWhenBidResponseNil {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = nil;

  id rewardedMock = OCMClassMock([GADMAdapterIronSourceRewardedAd class]);
  OCMStub([rewardedMock alloc]).andReturn(rewardedMock);
  OCMExpect([rewardedMock loadRewardedAdForConfiguration:configuration
                                       completionHandler:[OCMArg any]]);

  [_adapter loadRewardedAdForAdConfiguration:configuration
                           completionHandler:^id<GADMediationRewardedAdEventDelegate>(
                               id<GADMediationRewardedAd> ad, NSError *error) {
                             return nil;
                           }];

  OCMVerifyAll(rewardedMock);
  XCTAssertNil(_adapter.rtbRewardedAd);
  [rewardedMock stopMocking];
}

- (void)testLoadRewardedInterstitialRoutesToRewardedAdFlow {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;

  id rtbRewardedMock = OCMClassMock([GADMAdapterIronSourceRtbRewardedAd class]);
  OCMStub([rtbRewardedMock alloc]).andReturn(rtbRewardedMock);
  OCMExpect([rtbRewardedMock loadRewardedAdForConfiguration:configuration
                                          completionHandler:[OCMArg any]]);

  [_adapter loadRewardedInterstitialAdForAdConfiguration:configuration
                                       completionHandler:^id<GADMediationRewardedAdEventDelegate>(
                                           id<GADMediationRewardedAd> ad, NSError *error) {
                                         return nil;
                                       }];

  OCMVerifyAll(rtbRewardedMock);
  XCTAssertNotNil(_adapter.rtbRewardedAd);
  [rtbRewardedMock stopMocking];
}

@end
