#import "GADMediationAdapterLine.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationNativeAdLoadAssertions.h>
#import <FiveAd/FiveAd.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterLineConstants.h"
#import "GADMediationAdapterLineExtras.h"

@interface AUTLineNativeAdTest : XCTestCase
@end

static NSString *const AUTLineTestSlotID = @"12345";
static CGFloat const AUTLineTestVideoWidth = 123;

@implementation AUTLineNativeAdTest {
  /// An adapter instance that is used to test loading a native ad.
  GADMediationAdapterLine *_adapter;

  /// A mock instance of FADNative.
  id _nativeMock;
}

- (void)setUp {
  [super setUp];

  _adapter = [[GADMediationAdapterLine alloc] init];

  _nativeMock = OCMClassMock([FADNative class]);
  OCMStub([_nativeMock alloc]).andReturn(_nativeMock);

  id configClassMock = OCMClassMock([FADSettings class]);
  OCMStub([configClassMock registerConfig:OCMOCK_ANY]);
}

- (void)mockFiveAdNativeAdLoadWithVideoWidth:(CGFloat)width {
  OCMStub([_nativeMock initWithSlotId:AUTLineTestSlotID videoViewWidth:width])
      .andReturn(_nativeMock);
  __block id<FADLoadDelegate> loadDelegate = nil;
  OCMStub([_nativeMock setLoadDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  OCMStub([_nativeMock setEventListener:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    id<FADNativeEventListener> eventListener = nil;
    [invocation getArgument:&eventListener atIndex:2];
    XCTAssertTrue([eventListener conformsToProtocol:@protocol(FADNativeEventListener)]);
  });
  OCMStub([_nativeMock loadAdAsync]).andDo(^(NSInvocation *invocation) {
    OCMStub([self->_nativeMock state]).andReturn(kFADStateLoaded);
    [loadDelegate fiveAdDidLoad:self->_nativeMock];
  });
}

- (void)mockFiveAdImageAssetsLoadWithIconImage:(nullable UIImage *)iconImage
                          informationIconImage:(nullable UIImage *)informationIconImage {
  OCMStub([_nativeMock loadIconImageAsyncWithBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    void (^loadIconImageCompletionHandler)(UIImage *iconImage);
    [invocation getArgument:&loadIconImageCompletionHandler atIndex:2];
    loadIconImageCompletionHandler(iconImage);
  });
  OCMStub([_nativeMock loadInformationIconImageAsyncWithBlock:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        void (^loadInformationIconImageCompletionHandler)(UIImage *informationIconImage);
        [invocation getArgument:&loadInformationIconImageCompletionHandler atIndex:2];
        loadInformationIconImageCompletionHandler(informationIconImage);
      });
}

- (nonnull id<GADMediationNativeAdEventDelegate>)loadNativeAdWithVideoWidth:(CGFloat)videoWidth
                                                      shouldLoadImageAssets:
                                                          (BOOL)shouldLoadImageAssets
                                                           shouldStartMuted:(BOOL)shouldStartMuted {
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
                                             FADConfig *config = (FADConfig *)obj;
                                             XCTAssertTrue([config.appId isEqualToString:@"123"]);
                                             return YES;
                                           }]
                                                    outError:[OCMArg anyObjectRef]]));

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : @"123",
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };
  GADMediationAdapterLineExtras *extras = [[GADMediationAdapterLineExtras alloc] init];
  extras.nativeAdVideoWidth = AUTLineTestVideoWidth;
  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = extras;

  NSMutableArray *options = [[NSMutableArray alloc] init];
  if (!shouldLoadImageAssets) {
    GADNativeAdImageAdLoaderOptions *imageOptions = [[GADNativeAdImageAdLoaderOptions alloc] init];
    imageOptions.disableImageLoading = YES;
    [options addObject:imageOptions];
  }
  GADVideoOptions *videoOptions = [[GADVideoOptions alloc] init];
  videoOptions.startMuted = shouldStartMuted;
  [options addObject:videoOptions];
  configuration.options = [options copy];
  [_nativeMock enableSound:!shouldStartMuted];

  id<GADMediationNativeAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(_nativeMock);
  OCMVerifyAll(adLoaderClassMock);
  return delegate;
}

- (void)testLoadNativeAdWithImages {
  [self mockFiveAdNativeAdLoadWithVideoWidth:AUTLineTestVideoWidth];
  [self mockFiveAdImageAssetsLoadWithIconImage:[[UIImage alloc] init]
                          informationIconImage:[[UIImage alloc] init]];
  [self loadNativeAdWithVideoWidth:AUTLineTestVideoWidth
             shouldLoadImageAssets:YES
                  shouldStartMuted:YES];
}

- (void)testLoadBiddingNativeAd {
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMExpect(ClassMethod([adLoaderClassMock adLoaderForConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
                                             FADConfig *config = (FADConfig *)obj;
                                             XCTAssertTrue([config.appId isEqualToString:@"123"]);
                                             return YES;
                                           }]
                                                    outError:[OCMArg anyObjectRef]]))
      .andReturn(adLoaderClassMock);

  NSString *bidResponse = @"bidResponse";
  NSString *watermark = @"watermark";
  NSData *watermarkData = [watermark dataUsingEncoding:NSUTF8StringEncoding];
  id bidData = OCMClassMock([FADBidData class]);
  OCMStub([bidData alloc]).andReturn(bidData);
  OCMExpect([bidData initWithBidResponse:bidResponse withWatermark:watermark]).andReturn(bidData);

  OCMExpect([adLoaderClassMock loadNativeAdWithBidData:bidData withLoadCallback:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(FADAdViewCustomLayout *_Nullable customLayout,
                                                      NSError *_Nullable adLoadError);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(self->_nativeMock, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : @"123",
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };

  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.watermark = watermarkData;
  configuration.bidResponse = bidResponse;

  NSMutableArray *options = [[NSMutableArray alloc] init];
  GADNativeAdImageAdLoaderOptions *imageOptions = [[GADNativeAdImageAdLoaderOptions alloc] init];
  imageOptions.disableImageLoading = YES;
  [options addObject:imageOptions];
  configuration.options = options;

  id<GADMediationNativeAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(_nativeMock);
  OCMVerifyAll(adLoaderClassMock);
}

- (void)testLoadNativeAdWithoutImages {
  [self mockFiveAdNativeAdLoadWithVideoWidth:AUTLineTestVideoWidth];
  [self loadNativeAdWithVideoWidth:AUTLineTestVideoWidth
             shouldLoadImageAssets:NO
                  shouldStartMuted:YES];
}

- (void)testLoadNativeAdWithUnmuted {
  [self mockFiveAdNativeAdLoadWithVideoWidth:AUTLineTestVideoWidth];
  [self loadNativeAdWithVideoWidth:AUTLineTestVideoWidth
             shouldLoadImageAssets:NO
                  shouldStartMuted:NO];
}

- (void)testLoadNativeAdFailureForMissingSlotID {
  // Mock FiveAd SDK.
  OCMStub([_nativeMock initWithSlotId:AUTLineTestSlotID videoViewWidth:AUTLineTestVideoWidth])
      .andReturn(_nativeMock);
  OCMReject([_nativeMock loadAdAsync]);
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Test missing slot ID by omitting slot id from credential settings.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : @"123",
  };
  GADMediationAdapterLineExtras *extras = [[GADMediationAdapterLineExtras alloc] init];
  extras.nativeAdVideoWidth = AUTLineTestVideoWidth;
  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = extras;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMediationAdapterLineErrorDomain
                                 code:GADMediationAdapterLineErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, configuration, expectedError);
  OCMVerifyAll(_nativeMock);
}

- (void)testLoadNativeAdFailureForFiveAdSDKFailedToReceiveAd {
  // Mock FiveAd SDK.
  OCMStub([_nativeMock initWithSlotId:AUTLineTestSlotID videoViewWidth:AUTLineTestVideoWidth])
      .andReturn(_nativeMock);
  __block id<FADLoadDelegate> loadDelegate = nil;
  OCMStub([_nativeMock setLoadDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  FADErrorCode code = kFADErrorCodeNoAd;
  OCMStub([_nativeMock loadAdAsync]).andDo(^(NSInvocation *invocation) {
    [loadDelegate fiveAd:self->_nativeMock didFailedToReceiveAdWithError:code];
  });
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Test fail to receive an ad from FiveAd SDK.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : @"123",
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };
  GADMediationAdapterLineExtras *extras = [[GADMediationAdapterLineExtras alloc] init];
  extras.nativeAdVideoWidth = AUTLineTestVideoWidth;
  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = extras;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMediationAdapterFiveAdErrorDomain
                                                      code:code
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, configuration, expectedError);
}

- (void)testInformationIconImageLoadFailure {
  // Mock FiveAd SDK.
  [self mockFiveAdNativeAdLoadWithVideoWidth:AUTLineTestVideoWidth];
  [self mockFiveAdImageAssetsLoadWithIconImage:[[UIImage alloc] init] informationIconImage:nil];
  id adLoaderClassMock = OCMClassMock([FADAdLoader class]);
  OCMStub(ClassMethod([adLoaderClassMock adLoaderForConfig:OCMOCK_ANY
                                                  outError:[OCMArg anyObjectRef]]));

  // Test GADMediationAdapterLineErrorInformationIconLoadFailure.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMediationAdapterLineCredentialKeyApplicationID : @"123",
    GADMediationAdapterLineCredentialKeyAdUnit : AUTLineTestSlotID
  };
  GADMediationAdapterLineExtras *extras = [[GADMediationAdapterLineExtras alloc] init];
  extras.nativeAdVideoWidth = AUTLineTestVideoWidth;
  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = extras;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMediationAdapterLineErrorDomain
                                 code:GADMediationAdapterLineErrorInformationIconLoadFailure
                             userInfo:nil];
  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, configuration, expectedError);
}

- (void)testNativeAdUIsWithImageAssets {
  // Mock FiveAdSDK.
  [self mockFiveAdNativeAdLoadWithVideoWidth:AUTLineTestVideoWidth];
  UIImage *expectedIconImage = [[UIImage alloc] init];
  UIImage *expectedAdChoiceImage = [[UIImage alloc] init];
  [self mockFiveAdImageAssetsLoadWithIconImage:expectedIconImage
                          informationIconImage:expectedAdChoiceImage];
  // In addition to mocking the FiveAd loading methods, mock other native ad assets.
  NSString *expectedHeadline = @"adTitle";
  OCMStub([_nativeMock getAdTitle]).andReturn(expectedHeadline);
  NSString *expectedBody = @"body";
  OCMStub([_nativeMock getDescriptionText]).andReturn(expectedBody);
  NSString *expectedCallToAction = @"callToAction";
  OCMStub([_nativeMock getButtonText]).andReturn(expectedCallToAction);
  NSString *expectedAdvertiser = @"advertiserName";
  OCMStub([_nativeMock getAdvertiserName]).andReturn(expectedAdvertiser);
  UIView *expectedMediaView = [[UIView alloc] init];
  OCMStub([_nativeMock getAdMainView]).andReturn(expectedMediaView);

  // Test native ad assets are correctly loaded with the image assets.
  AUTKMediationNativeAdEventDelegate *delegate =
      [self loadNativeAdWithVideoWidth:AUTLineTestVideoWidth
                 shouldLoadImageAssets:YES
                      shouldStartMuted:YES];
  id<GADMediationNativeAd> nativeAd = delegate.nativeAd;
  XCTAssertEqualObjects(nativeAd.icon.image, expectedIconImage);
  XCTAssertEqual([nativeAd.adChoicesView class], [UIImageView class]);
  UIImageView *adChoiceImageView = (UIImageView *)nativeAd.adChoicesView;
  XCTAssertEqualObjects(adChoiceImageView.image, expectedAdChoiceImage);
  XCTAssertEqualObjects(nativeAd.headline, expectedHeadline);
  XCTAssertEqualObjects(nativeAd.body, expectedBody);
  XCTAssertEqualObjects(nativeAd.callToAction, expectedCallToAction);
  XCTAssertEqualObjects(nativeAd.advertiser, expectedAdvertiser);
  XCTAssertTrue(nativeAd.hasVideoContent);
  XCTAssertEqualObjects(nativeAd.mediaView, expectedMediaView);
  XCTAssertNil(nativeAd.images);
  XCTAssertNil(nativeAd.starRating);
  XCTAssertNil(nativeAd.store);
  XCTAssertNil(nativeAd.price);
  XCTAssertNil(nativeAd.extraAssets);
}

- (void)testNativeAdAssetsWithoutImageAssets {
  // Mock FiveAdSDK.
  [self mockFiveAdNativeAdLoadWithVideoWidth:AUTLineTestVideoWidth];
  [self mockFiveAdImageAssetsLoadWithIconImage:[[UIImage alloc] init]
                          informationIconImage:[[UIImage alloc] init]];
  // In addition to mocking the FiveAd loading methods, mock other native ad assets.
  NSString *expectedHeadline = @"adTitle";
  OCMStub([_nativeMock getAdTitle]).andReturn(expectedHeadline);
  NSString *expectedBody = @"body";
  OCMStub([_nativeMock getDescriptionText]).andReturn(expectedBody);
  NSString *expectedCallToAction = @"callToAction";
  OCMStub([_nativeMock getButtonText]).andReturn(expectedCallToAction);
  NSString *expectedAdvertiser = @"advertiserName";
  OCMStub([_nativeMock getAdvertiserName]).andReturn(expectedAdvertiser);
  UIView *expectedMediaView = [[UIView alloc] init];
  OCMStub([_nativeMock getAdMainView]).andReturn(expectedMediaView);

  // Test native ad assets are correctly loaded without the image assets.
  AUTKMediationNativeAdEventDelegate *delegate =
      [self loadNativeAdWithVideoWidth:AUTLineTestVideoWidth
                 shouldLoadImageAssets:NO
                      shouldStartMuted:YES];
  id<GADMediationNativeAd> nativeAd = delegate.nativeAd;
  XCTAssertNil(nativeAd.icon);
  XCTAssertNil(nativeAd.adChoicesView);
  XCTAssertEqualObjects(nativeAd.headline, expectedHeadline);
  XCTAssertEqualObjects(nativeAd.body, expectedBody);
  XCTAssertEqualObjects(nativeAd.callToAction, expectedCallToAction);
  XCTAssertEqualObjects(nativeAd.advertiser, expectedAdvertiser);
  XCTAssertTrue(nativeAd.hasVideoContent);
  XCTAssertEqualObjects(nativeAd.mediaView, expectedMediaView);
  XCTAssertNil(nativeAd.images);
  XCTAssertNil(nativeAd.starRating);
  XCTAssertNil(nativeAd.store);
  XCTAssertNil(nativeAd.price);
  XCTAssertNil(nativeAd.extraAssets);
}

- (void)testDidRenderInView {
  [self mockFiveAdNativeAdLoadWithVideoWidth:AUTLineTestVideoWidth];
  [self mockFiveAdImageAssetsLoadWithIconImage:[[UIImage alloc] init]
                          informationIconImage:[[UIImage alloc] init]];

  AUTKMediationNativeAdEventDelegate *delegate =
      [self loadNativeAdWithVideoWidth:AUTLineTestVideoWidth
                 shouldLoadImageAssets:YES
                      shouldStartMuted:YES];
  id<GADMediationNativeAd> nativeAd = delegate.nativeAd;

  UIView *expectedRegisterView = [[UIView alloc] init];
  NSDictionary<GADNativeAssetIdentifier, UIView *> *expectedClickableViews =
      @{GADNativeHeadlineAsset : [[UIView alloc] init]};
  OCMExpect([_nativeMock registerViewForInteraction:expectedRegisterView
                            withInformationIconView:nativeAd.adChoicesView
                                 withClickableViews:expectedClickableViews.allValues]);

  [nativeAd didRenderInView:expectedRegisterView
         clickableAssetViews:expectedClickableViews
      nonclickableAssetViews:@{}
              viewController:[[UIViewController alloc] init]];
  OCMVerifyAll(_nativeMock);
}

- (void)testAdImpression {
  [self mockFiveAdNativeAdLoadWithVideoWidth:AUTLineTestVideoWidth];
  [self mockFiveAdImageAssetsLoadWithIconImage:[[UIImage alloc] init]
                          informationIconImage:[[UIImage alloc] init]];
  AUTKMediationNativeAdEventDelegate *delegate =
      [self loadNativeAdWithVideoWidth:AUTLineTestVideoWidth
                 shouldLoadImageAssets:YES
                      shouldStartMuted:YES];

  id<FADNativeEventListener> listener = (id<FADNativeEventListener>)delegate.nativeAd;
  [listener fiveNativeAdDidImpression:_nativeMock];
  XCTAssertTrue(delegate.nativeAd.handlesUserImpressions);
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);
}

- (void)testAdClick {
  [self mockFiveAdNativeAdLoadWithVideoWidth:AUTLineTestVideoWidth];
  [self mockFiveAdImageAssetsLoadWithIconImage:[[UIImage alloc] init]
                          informationIconImage:[[UIImage alloc] init]];
  AUTKMediationNativeAdEventDelegate *delegate =
      [self loadNativeAdWithVideoWidth:AUTLineTestVideoWidth
                 shouldLoadImageAssets:YES
                      shouldStartMuted:YES];

  id<FADNativeEventListener> listener = (id<FADNativeEventListener>)delegate.nativeAd;
  [listener fiveNativeAdDidClick:_nativeMock];
  XCTAssertTrue(delegate.nativeAd.handlesUserClicks);
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);
}

- (void)testAdDidPlay {
  [self mockFiveAdNativeAdLoadWithVideoWidth:AUTLineTestVideoWidth];
  [self mockFiveAdImageAssetsLoadWithIconImage:[[UIImage alloc] init]
                          informationIconImage:[[UIImage alloc] init]];
  AUTKMediationNativeAdEventDelegate *delegate =
      [self loadNativeAdWithVideoWidth:AUTLineTestVideoWidth
                 shouldLoadImageAssets:YES
                      shouldStartMuted:YES];

  id<FADNativeEventListener> listener = (id<FADNativeEventListener>)delegate.nativeAd;
  [listener fiveNativeAdDidPlay:_nativeMock];
  XCTAssertEqual(delegate.didPlayVideoInvokeCount, 1);
}

- (void)testAdDidEnd {
  [self mockFiveAdNativeAdLoadWithVideoWidth:AUTLineTestVideoWidth];
  [self mockFiveAdImageAssetsLoadWithIconImage:[[UIImage alloc] init]
                          informationIconImage:[[UIImage alloc] init]];
  AUTKMediationNativeAdEventDelegate *delegate =
      [self loadNativeAdWithVideoWidth:AUTLineTestVideoWidth
                 shouldLoadImageAssets:YES
                      shouldStartMuted:YES];

  id<FADNativeEventListener> listener = (id<FADNativeEventListener>)delegate.nativeAd;
  [listener fiveNativeAdDidViewThrough:_nativeMock];
  XCTAssertEqual(delegate.didEndVideoInvokeCount, 1);
}

- (void)testAdDidPause {
  [self mockFiveAdNativeAdLoadWithVideoWidth:AUTLineTestVideoWidth];
  [self mockFiveAdImageAssetsLoadWithIconImage:[[UIImage alloc] init]
                          informationIconImage:[[UIImage alloc] init]];
  AUTKMediationNativeAdEventDelegate *delegate =
      [self loadNativeAdWithVideoWidth:AUTLineTestVideoWidth
                 shouldLoadImageAssets:YES
                      shouldStartMuted:YES];

  id<FADNativeEventListener> listener = (id<FADNativeEventListener>)delegate.nativeAd;
  [listener fiveNativeAdDidPause:_nativeMock];
  XCTAssertEqual(delegate.didPauseVideoInvokeCount, 1);
}

- (void)testFailToShowAd {
  [self mockFiveAdNativeAdLoadWithVideoWidth:AUTLineTestVideoWidth];
  [self mockFiveAdImageAssetsLoadWithIconImage:[[UIImage alloc] init]
                          informationIconImage:[[UIImage alloc] init]];
  AUTKMediationNativeAdEventDelegate *delegate =
      [self loadNativeAdWithVideoWidth:AUTLineTestVideoWidth
                 shouldLoadImageAssets:YES
                      shouldStartMuted:YES];
  id<FADNativeEventListener> listener = (id<FADNativeEventListener>)delegate.nativeAd;
  FADErrorCode expectedErrorCode = kFADErrorCodePlayerError;
  [listener fiveNativeAd:_nativeMock didFailedToShowAdWithError:expectedErrorCode];
  NSError *presentError = delegate.didFailToPresentError;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMediationAdapterFiveAdErrorDomain
                                                      code:expectedErrorCode
                                                  userInfo:nil];
  XCTAssertEqual(presentError.code, expectedError.code);
  XCTAssertEqualObjects(presentError.domain, expectedError.domain);
}

- (void)testUnhandledEvents {
  // Following events are not handled by the GoogleMobileAds's native event delegate, but
  // checking invoking them does not crash the running app.
  [self mockFiveAdNativeAdLoadWithVideoWidth:AUTLineTestVideoWidth];
  [self mockFiveAdImageAssetsLoadWithIconImage:[[UIImage alloc] init]
                          informationIconImage:[[UIImage alloc] init]];
  AUTKMediationNativeAdEventDelegate *delegate =
      [self loadNativeAdWithVideoWidth:AUTLineTestVideoWidth
                 shouldLoadImageAssets:YES
                      shouldStartMuted:YES];
  id<FADNativeEventListener> listener = (id<FADNativeEventListener>)delegate.nativeAd;
  [listener fiveNativeAdViewDidRemove:_nativeMock];
}

@end
