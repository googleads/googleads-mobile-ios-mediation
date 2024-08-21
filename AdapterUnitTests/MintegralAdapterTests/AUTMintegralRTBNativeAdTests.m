#import "GADMediationAdapterMintegral.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationNativeAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

#import <MTGSDK/MTGBidNativeAdManager.h>

#import "GADMediationAdapterMintegralConstants.h"

#import <MTGSDK/MTGAdChoicesView.h>
#import <MTGSDK/MTGSDK.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

static NSString *const kPlacementID = @"12345";
static NSString *const kUnitID = @"67890";
static NSString *const kBidResponse = @"bidResponse";

@interface AUTMintegralRTBNativeAdTests : XCTestCase
@end

@implementation AUTMintegralRTBNativeAdTests {
  /// An adapter instance that is used to test loading an ad.
  GADMediationAdapterMintegral *_adapter;

  /// A mock instance of MTGBidNativeAdManager.
  id _nativeAdMock;

  /// A mock instance of MTGAdChoicesView.
  id _adChoicesViewMock;

  /// An ad loader.
  __block id<MTGBidNativeAdManagerDelegate, GADMediationNativeAd, MTGMediaViewDelegate> _adLoader;

  /// View controller for presentation passed to _nativeAdMock.
  UIViewController *_presentingViewController;

  MTGCampaign *_campaign;
}

- (void)setUp {
  [super setUp];

  _presentingViewController = [[UIViewController alloc] init];
  _campaign = [[MTGCampaign alloc] init];
  _campaign.appName = @"test app";
  _campaign.appDesc = @"app desc";
  _campaign.adCall = @"ad call";

  _campaign.iconUrl = @"https://www.fake_icon.com";
  _adapter = [[GADMediationAdapterMintegral alloc] init];

  _adChoicesViewMock = OCMClassMock([MTGAdChoicesView class]);
  OCMStub([_adChoicesViewMock alloc]).andReturn(_adChoicesViewMock);
  OCMStub([_adChoicesViewMock initWithFrame:CGRectZero]).andReturn(_adChoicesViewMock);

  _nativeAdMock = OCMClassMock([MTGBidNativeAdManager class]);
  OCMStub([_nativeAdMock alloc]).andReturn(_nativeAdMock);
  OCMStub([_nativeAdMock initWithPlacementId:kPlacementID
                                      unitID:kUnitID
                    presentingViewController:_presentingViewController])
      .andReturn(_nativeAdMock);

  // Whenever a delegate is set, save it and assert that it has the appropriate delegate type.
  OCMStub([_nativeAdMock setDelegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                           self->_adLoader = obj;
                           return [obj conformsToProtocol:@protocol(MTGBidNativeAdManagerDelegate)];
                         }]]);
}

- (nonnull AUTKMediationNativeAdEventDelegate *)loadAd {
  NSData *watermarkData = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
  // Must pass through the enigma watermark.
  OCMExpect([_nativeAdMock setExtraInfo:watermarkData forKey:@"admob_watermark"]);

  OCMStub([_nativeAdMock loadWithBidToken:kBidResponse]).andDo(^(NSInvocation *invocation) {
    [self->_adLoader nativeAdsLoaded:@[ self->_campaign ] bidNativeManager:self->_nativeAdMock];
  });
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  configuration.watermark = watermarkData;
  configuration.topViewController = _presentingViewController;

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, configuration);
  XCTAssertNotNil(_adLoader);

  [_nativeAdMock verify];
  return eventDelegate;
}

- (void)testLoadAd {
  [self loadAd];

  XCTAssertEqualObjects([_adLoader headline], @"test app");
  XCTAssertEqualObjects([_adLoader body], @"app desc");
  XCTAssertEqualObjects([_adLoader callToAction], @"ad call");

  // TODO(b/310973545): This crashes because MTGCampaign is not key-value compliant for the key
  // "star". Need to consult with the adapter team on whether this is a real issue.
  // XCTAssertNil([_adLoader starRating]);

  XCTAssertEqual([_adLoader adChoicesView], _adChoicesViewMock);

  XCTAssertTrue([_adLoader hasVideoContent]);
  XCTAssertTrue([_adLoader handlesUserImpressions]);
  XCTAssertTrue([_adLoader handlesUserClicks]);

  XCTAssertNil([_adLoader images]);
  XCTAssertNil([_adLoader store]);
  XCTAssertNil([_adLoader price]);
  XCTAssertNil([_adLoader advertiser]);
  XCTAssertNil([_adLoader extraAssets]);
}

- (void)testMediaViewDelegateMethods {
  AUTKMediationNativeAdEventDelegate *adEventDelegate = [self loadAd];

  MTGMediaView *mediaView = (MTGMediaView *)[_adLoader mediaView];
  XCTAssertNotNil(mediaView);

  [_adLoader MTGMediaViewWillEnterFullscreen:mediaView];
  XCTAssertEqual(adEventDelegate.willPresentFullScreenViewInvokeCount, 1);

  [_adLoader MTGMediaViewDidExitFullscreen:mediaView];
  XCTAssertEqual(adEventDelegate.didDismissFullScreenViewInvokeCount, 1);

  [_adLoader MTGMediaViewVideoDidStart:mediaView];
  XCTAssertEqual(adEventDelegate.didPlayVideoInvokeCount, 1);

  [_adLoader MTGMediaViewVideoPlayCompleted:mediaView];
  XCTAssertEqual(adEventDelegate.didEndVideoInvokeCount, 1);

  [_adLoader nativeAdDidClick:_campaign mediaView:mediaView];
  XCTAssertEqual(adEventDelegate.reportClickInvokeCount, 1);

  [_adLoader nativeAdImpressionWithType:MTGAD_SOURCE_API_OFFER mediaView:mediaView];
  XCTAssertEqual(adEventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testDelegateMethods {
  AUTKMediationNativeAdEventDelegate *adEventDelegate = [self loadAd];

  [_adLoader nativeAdDidClick:_campaign bidNativeManager:_nativeAdMock];
  XCTAssertEqual(adEventDelegate.reportClickInvokeCount, 1);

  [_adLoader nativeAdImpressionWithType:MTGAD_SOURCE_API_OFFER bidNativeManager:_nativeAdMock];
  XCTAssertEqual(adEventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testLoadAdFailureWithNoCampaigns {
  OCMStub([_nativeAdMock loadWithBidToken:kBidResponse]).andDo(^(NSInvocation *invocation) {
    [self->_adLoader nativeAdsLoaded:@[] bidNativeManager:self->_nativeAdMock];
  });
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  configuration.topViewController = _presentingViewController;

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorAdNotAvailable
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadAdFailureWithNoPlacementID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  configuration.topViewController = _presentingViewController;

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadAdFailureWithNoAdUnitID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  configuration.topViewController = _presentingViewController;

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, configuration, expectedError);
}

@end
