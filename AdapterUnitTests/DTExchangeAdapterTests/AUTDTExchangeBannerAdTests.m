#import "GADMediationAdapterFyber.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationBannerAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IASDKCore/IASDKCore.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterFyberConstants.h"
#import "GADMAdapterFyberExtras.h"

@interface AUTDTExchangeBannerAdTests : XCTestCase
@end

static NSString *const kDTExchangeAppID = @"12345";
static NSString *const kDTExchangeSpotID = @"67890";
static CGFloat const kDTExchangeTestViewWidth = 1;
static CGFloat const kDTExchangeTestViewHeight = 1;

@implementation AUTDTExchangeBannerAdTests {
  /// An adapter instance that is used to test loading an interstitial ad.
  GADMediationAdapterFyber *_adapter;

  /// IASDKCore mock.
  id _IASDKCoreMock;

  /// IAAdSpot mock.
  id _IAAdSpotMock;

  /// IAAdRequest mock.
  id _IAAdRequestMock;

  /// IAAdRequestBuilder mock.
  id _IAAdRequestBuilderMock;

  /// IAAdSpotBuilder mock.
  id _IAAdSpotBuilderMock;

  /// IAMRAIDContentController mock.
  id _IAMRAIDContentControllerMock;

  /// IAMRAIDContentController mock.
  id _IAMRAIDContentControllerBuilderMock;

  // IAViewUnitController mock
  id _IAViewUnitControllerMock;

  /// IAViewUnitControllerBuilder mock.
  id _IAViewUnitControllerBuilderMock;
}

- (void)setUp {
  [super setUp];

  _adapter = [[GADMediationAdapterFyber alloc] init];

  _IASDKCoreMock = OCMClassMock([IASDKCore class]);
  OCMStub(ClassMethod([_IASDKCoreMock sharedInstance])).andReturn(_IASDKCoreMock);
  OCMStub([_IASDKCoreMock setMediationType:[OCMArg isKindOfClass:[IAMediationAdMob class]]]);

  _IAMRAIDContentControllerBuilderMock =
      OCMProtocolMock(@protocol(IAMRAIDContentControllerBuilder));
  _IAMRAIDContentControllerMock = OCMClassMock([IAMRAIDContentController class]);
  OCMStub(ClassMethod([_IAMRAIDContentControllerMock build:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(id<IAMRAIDContentControllerBuilder>);
        [invocation getArgument:&completionHandler atIndex:2];
        completionHandler(self->_IAAdRequestBuilderMock);
      })
      .andReturn(_IAMRAIDContentControllerMock);

  _IAAdRequestBuilderMock = OCMProtocolMock(@protocol(IAAdRequestBuilder));
  OCMStub([_IAAdRequestBuilderMock setUseSecureConnections:NO]);
  OCMStub([_IAAdRequestBuilderMock setTimeout:10]);
  _IAAdRequestMock = OCMClassMock([IAAdRequest class]);
  OCMStub(ClassMethod([_IAAdRequestMock build:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(id<IAAdRequestBuilder>);
        [invocation getArgument:&completionHandler atIndex:2];
        completionHandler(self->_IAAdRequestBuilderMock);
      })
      .andReturn(_IAAdRequestMock);

  _IAAdSpotBuilderMock = OCMProtocolMock(@protocol(IAAdSpotBuilder));
  OCMStub([_IAAdSpotBuilderMock setAdRequest:_IAAdRequestMock]);
  _IAAdSpotMock = OCMClassMock([IAAdSpot class]);
  OCMStub(ClassMethod([_IAAdSpotMock build:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(id<IAAdSpotBuilder>);
        [invocation getArgument:&completionHandler atIndex:2];
        completionHandler(self->_IAAdSpotBuilderMock);
      })
      .andReturn(_IAAdSpotMock);

  _IAViewUnitControllerMock = OCMClassMock([IAViewUnitController class]);
  UIView *testView = [[UIView alloc]
      initWithFrame:CGRectMake(0, 0, kDTExchangeTestViewWidth, kDTExchangeTestViewHeight)];
  OCMStub([_IAViewUnitControllerMock adView]).andReturn(testView);
  _IAViewUnitControllerBuilderMock = OCMProtocolMock(@protocol(IAViewUnitControllerBuilder));
  OCMStub([_IAViewUnitControllerBuilderMock setUnitDelegate:OCMOCK_ANY]);
  OCMStub([_IAViewUnitControllerBuilderMock addSupportedContentController:OCMOCK_ANY]);
  OCMStub(ClassMethod([_IAViewUnitControllerMock build:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(id<IAViewUnitControllerBuilder>);
        [invocation getArgument:&completionHandler atIndex:2];
        completionHandler(self->_IAViewUnitControllerBuilderMock);
      })
      .andReturn(_IAViewUnitControllerMock);
}

- (AUTKMediationBannerAdEventDelegate *)loadWithBidResponse:(nullable NSString *)bidResponse {
  OCMStub([_IASDKCoreMock initWithAppID:kDTExchangeAppID
                        completionBlock:OCMOCK_ANY
                        completionQueue:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(YES, nil);
      });
  OCMExpect([_IAAdRequestBuilderMock setSpotID:kDTExchangeSpotID]);
  OCMStub([_IAAdSpotMock fetchAdWithCompletion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained void (^completionHandler)(
        IAAdSpot *_Nullable adSpot, IAAdModel *_Nullable adModel, NSError *_Nullable error);
    [invocation getArgument:&completionHandler atIndex:2];
    completionHandler(nil, nil, nil);
  });
  OCMStub([_IAAdSpotMock loadAdWithMarkup:bidResponse withCompletion:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(
            IAAdSpot *_Nullable adSpot, IAAdModel *_Nullable adModel, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(nil, nil, nil);
      });

  GADMAdapterFyberExtras *extras = [[GADMAdapterFyberExtras alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterFyberApplicationID : kDTExchangeAppID,
    GADMAdapterFyberSpotID : kDTExchangeSpotID
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.adSize =
      GADAdSizeFromCGSize(CGSizeMake(kDTExchangeTestViewWidth, kDTExchangeTestViewHeight));
  configuration.credentials = credentials;
  configuration.bidResponse = bidResponse;
  configuration.extras = extras;
  configuration.topViewController = [[UIViewController alloc] init];
  AUTKMediationBannerAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);
  XCTAssertNotNil(eventDelegate);
  return eventDelegate;
}

- (void)testLoadingWaterfallBanner {
  [self loadWithBidResponse:nil];
}

- (void)testLoadingWaterfallBannerFailureForSizeMismatch {
  NSString *bidResponse = nil;
  NSError *expectedError = [[NSError alloc] initWithDomain:@"com.google.mediation.fyber"
                                                      code:102
                                                  userInfo:@{NSLocalizedDescriptionKey : @"test"}];
  OCMStub([_IASDKCoreMock initWithAppID:kDTExchangeAppID
                        completionBlock:OCMOCK_ANY
                        completionQueue:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(YES, nil);
      });
  OCMExpect([_IAAdRequestBuilderMock setSpotID:kDTExchangeSpotID]);
  OCMStub([_IAAdSpotMock fetchAdWithCompletion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained void (^completionHandler)(
        IAAdSpot *_Nullable adSpot, IAAdModel *_Nullable adModel, NSError *_Nullable error);
    [invocation getArgument:&completionHandler atIndex:2];
    completionHandler(nil, nil, nil);
  });

  GADMAdapterFyberExtras *extras = [[GADMAdapterFyberExtras alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterFyberApplicationID : kDTExchangeAppID,
    GADMAdapterFyberSpotID : kDTExchangeSpotID
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.adSize = GADAdSizeFromCGSize(CGSizeMake(0, 0));
  configuration.credentials = credentials;
  configuration.bidResponse = bidResponse;
  configuration.extras = extras;
  configuration.topViewController = [[UIViewController alloc] init];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadingBiddingBanner {
  [self loadWithBidResponse:@"test_response"];
}

- (void)testLoadingBiddingBannerFailure {
  NSString *bidResponse = @"test_response";
  NSError *expectedError = [[NSError alloc] initWithDomain:@"test"
                                                      code:-1
                                                  userInfo:@{NSLocalizedDescriptionKey : @"test"}];
  OCMStub([_IASDKCoreMock initWithAppID:kDTExchangeAppID
                        completionBlock:OCMOCK_ANY
                        completionQueue:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(YES, nil);
      });
  OCMExpect([_IAAdRequestBuilderMock setSpotID:kDTExchangeSpotID]);
  OCMStub([_IAAdSpotMock loadAdWithMarkup:bidResponse withCompletion:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(
            IAAdSpot *_Nullable adSpot, IAAdModel *_Nullable adModel, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(nil, nil, expectedError);
      });

  GADMAdapterFyberExtras *extras = [[GADMAdapterFyberExtras alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterFyberApplicationID : kDTExchangeAppID,
    GADMAdapterFyberSpotID : kDTExchangeSpotID
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = bidResponse;
  configuration.extras = extras;
  configuration.topViewController = [[UIViewController alloc] init];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testBannerView {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadWithBidResponse:@"test_response"];
  XCTAssertNotNil(eventDelegate.bannerAd.view);
}

- (void)testClick {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadWithBidResponse:@"test_response"];
  id<IAUnitDelegate> delegate = (id<IAUnitDelegate>)eventDelegate.bannerAd;
  [delegate IAAdDidReceiveClick:_IAViewUnitControllerMock];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testImpression {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadWithBidResponse:@"test_response"];
  id<IAUnitDelegate> delegate = (id<IAUnitDelegate>)eventDelegate.bannerAd;
  [delegate IAAdWillLogImpression:_IAViewUnitControllerMock];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

@end
