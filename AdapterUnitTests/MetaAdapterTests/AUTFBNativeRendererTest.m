#import "GADMediationAdapterFacebook.h"

#import <XCTest/XCTest.h>

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>

#import "AdapterUnitTestKit/AdapterUnitTestKit.h"
#import "GADFBExtraAssets.h"
#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"

@interface AUTFBNativeRendererTest : XCTestCase
@end

static NSString *const AUTKNativeBidResponse = @"bidResponse";
static NSString *const AUTKNativeWatermark = @"watermark";

AUTKMediationNativeAdConfiguration *_Nonnull AUTMediationNativeAdConfiguration() {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatNative;
  credentials.settings = @{GADMAdapterFacebookBiddingPubID : GADMAdapterFacebookBiddingPubID};

  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = nil;
  configuration.bidResponse = AUTKNativeBidResponse;
  configuration.watermark = [AUTKNativeWatermark dataUsingEncoding:NSUTF8StringEncoding];

  return configuration;
}

@implementation AUTFBNativeRendererTest {
  GADMediationAdapterFacebook *_adapter;
  id _mockFBNativeAdBase;
  id _mockFBNativeAd;
  id _mockFBNativeBannerAd;
  id _fbAdSettingsMock;
  id _mockMediaView;
  __weak id _nativeAdDelegate;  // This will be GADFBNativeRenderer
  BOOL _shouldReturnNativeBannerAd;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterFacebook alloc] init];
  _shouldReturnNativeBannerAd = NO;

  _mockFBNativeAd = OCMClassMock([FBNativeAd class]);
  _mockFBNativeBannerAd = OCMClassMock([FBNativeBannerAd class]);

  _mockFBNativeAdBase = OCMClassMock([FBNativeAdBase class]);


  OCMStub([_mockFBNativeAdBase nativeAdWithPlacementId:[OCMArg any]
                                            bidPayload:[OCMArg any]
                                                 error:[OCMArg anyObjectRef]])
  .andDo(^(NSInvocation *invocation) {
      id resultAd = self->_shouldReturnNativeBannerAd ? self->_mockFBNativeBannerAd : self->_mockFBNativeAd;
      [invocation setReturnValue:&resultAd];
  });

  id delegateSave = [OCMArg checkWithBlock:^BOOL(id obj) {
    self->_nativeAdDelegate = obj;
    return YES;
  }];
  OCMStub([(FBNativeAd *)_mockFBNativeAd setDelegate:delegateSave]);
  OCMStub([(FBNativeBannerAd *)_mockFBNativeBannerAd setDelegate:delegateSave]);

  _fbAdSettingsMock = OCMClassMock([FBAdSettings class]);

  _mockMediaView = OCMClassMock([FBMediaView class]);
  OCMStub([_mockMediaView alloc]).andReturn(_mockMediaView);
//  OCMStub([_mockMediaView init]).andReturn(_mockMediaView);
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  [_fbAdSettingsMock stopMocking];
  [super tearDown];
}

- (void)stubNativeAdProperties {
  OCMStub([_mockFBNativeAd advertiserName]).andReturn(@"advertiser");
  OCMStub([_mockFBNativeAd bodyText]).andReturn(@"body");
  OCMStub([_mockFBNativeAd callToAction]).andReturn(@"cta");
  OCMStub([_mockFBNativeAd headline]).andReturn(@"headline");
  OCMStub([_mockFBNativeAd socialContext]).andReturn(@"social");
  OCMStub([_mockFBNativeAd iconImage]).andReturn([[UIImage alloc] init]);
}

- (void)stubNativeBannerAdProperties {
  OCMStub([_mockFBNativeBannerAd advertiserName]).andReturn(@"advertiser");
  OCMStub([_mockFBNativeBannerAd bodyText]).andReturn(@"body");
  OCMStub([_mockFBNativeBannerAd callToAction]).andReturn(@"cta");
  OCMStub([_mockFBNativeBannerAd headline]).andReturn(@"headline");
  OCMStub([_mockFBNativeBannerAd socialContext]).andReturn(@"social");
  OCMStub([_mockFBNativeBannerAd iconImage]).andReturn([[UIImage alloc] init]);
}

- (void)testRenderNativeAd {


  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:AUTKNativeBidResponse])
  .andDo(^(NSInvocation *invocation) {
    FBNativeAd *ad = (FBNativeAd *)invocation.target;
    [self->_nativeAdDelegate nativeAdDidLoad:ad];
  });

  AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
}

- (void)testRenderNativeBannerAd {
  _shouldReturnNativeBannerAd = YES;
  OCMStub([(FBNativeBannerAd *)_mockFBNativeBannerAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
      FBNativeBannerAd *ad = (FBNativeBannerAd *)invocation.target;
      [self->_nativeAdDelegate nativeBannerAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
}

- (void)testRenderNativeAdFailureWithAdDidNotLoad {
  NSError *expectedError = [NSError errorWithDomain:@"GADFBErrorDomain" code:101 userInfo:nil];
  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
      FBNativeAd *ad = (FBNativeAd *)invocation.target;
      [self->_nativeAdDelegate nativeAd:ad didFailWithError:expectedError];
      });

  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, AUTMediationNativeAdConfiguration(),
                                       expectedError);
}

- (void)testRenderNativeBannerAdFailureWithAdDidNotLoad {
  _shouldReturnNativeBannerAd = YES;
  NSError *expectedError = [NSError errorWithDomain:@"GADFBErrorDomain" code:101 userInfo:nil];
  OCMStub([(FBNativeBannerAd *)_mockFBNativeBannerAd loadAdWithBidPayload:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
      FBNativeBannerAd *ad = (FBNativeBannerAd *)invocation.target;
      [self->_nativeAdDelegate nativeBannerAd:ad didFailWithError:expectedError];
      });

  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, AUTMediationNativeAdConfiguration(),
                                       expectedError);
}

- (void)testRenderNativeAdFailureWithNoPlacementID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatNative;

  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError = [NSError errorWithDomain:@"com.google.mediation.facebook"
                                               code:GADFBErrorInvalidRequest
                                           userInfo:nil];
  OCMReject([_mockFBNativeAd loadAdWithBidPayload:[OCMArg any]]);

  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, configuration, expectedError);
}

- (void)testRenderNativeBannerAdFailureWithNoPlacementID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatNative;

  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError = [NSError errorWithDomain:@"com.google.mediation.facebook"
                                               code:GADFBErrorInvalidRequest
                                           userInfo:nil];
  OCMReject([_mockFBNativeBannerAd loadAdWithBidPayload:[OCMArg any]]);

  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, configuration, expectedError);
}



- (void)testNativeAdData {
  [self stubNativeAdProperties];
  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
      FBNativeAd *ad = (FBNativeAd *)invocation.target;
      [self->_nativeAdDelegate nativeAdDidLoad:ad];
    });

  AUTKMediationNativeAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  id<GADMediationNativeAd> nativeAd = delegate.nativeAd;

  XCTAssertEqualObjects(nativeAd.advertiser, @"advertiser");
  XCTAssertEqualObjects(nativeAd.body, @"body");
  XCTAssertEqualObjects(nativeAd.callToAction, @"cta");
  XCTAssertEqualObjects(nativeAd.headline, @"headline");
  NSDictionary *expectedExtraAssets = @{GADFBSocialContext : @"social"};
  XCTAssertEqualObjects(nativeAd.extraAssets, expectedExtraAssets);
  XCTAssertNil(nativeAd.price);
  XCTAssertNil(nativeAd.starRating);
  XCTAssertNil(nativeAd.store);
  XCTAssertNil(nativeAd.images);
  XCTAssertTrue([nativeAd.adChoicesView isKindOfClass:[FBAdOptionsView class]]);
  XCTAssertTrue([nativeAd.icon isKindOfClass:[GADNativeAdImage class]]);
  XCTAssertTrue(nativeAd.hasVideoContent);
  XCTAssertTrue([nativeAd.mediaView isKindOfClass:[FBMediaView class]]);
}

- (void)testNativeBannerAdData {
  _shouldReturnNativeBannerAd = YES;
  [self stubNativeBannerAdProperties];
  OCMStub([(FBNativeBannerAd *)_mockFBNativeBannerAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
        FBNativeBannerAd *ad = (FBNativeBannerAd *)invocation.target;
        [self->_nativeAdDelegate nativeBannerAdDidLoad:ad];
      });

  AUTKMediationNativeAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  id<GADMediationNativeAd> nativeAd = delegate.nativeAd;

  XCTAssertEqualObjects(nativeAd.advertiser, @"advertiser");
  XCTAssertEqualObjects(nativeAd.body, @"body");
  XCTAssertEqualObjects(nativeAd.callToAction, @"cta");
  XCTAssertEqualObjects(nativeAd.headline, @"headline");
  NSDictionary *expectedExtraAssets = @{GADFBSocialContext : @"social"};
  XCTAssertEqualObjects(nativeAd.extraAssets, expectedExtraAssets);
  XCTAssertNil(nativeAd.price);
  XCTAssertNil(nativeAd.starRating);
  XCTAssertNil(nativeAd.store);
  XCTAssertNil(nativeAd.images);
  XCTAssertTrue([nativeAd.adChoicesView isKindOfClass:[FBAdOptionsView class]]);
  XCTAssertTrue([nativeAd.icon isKindOfClass:[GADNativeAdImage class]]);
  XCTAssertTrue(nativeAd.hasVideoContent);
  XCTAssertNil(nativeAd.mediaView);  // NativeBannerAd has no mediaView
}

- (void)testNativeAdRegisterViews {
  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:AUTKNativeBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBNativeAd *ad = (FBNativeAd *)invocation.target;
        [self->_nativeAdDelegate nativeAdDidLoad:ad];
      });

  AUTKMediationNativeAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  id<GADMediationNativeAd> nativeAd = delegate.nativeAd;

  UIView *view = [[UIView alloc] init];
  UIImageView *iconView = [[UIImageView alloc] init];
  UIView *mediaView = nativeAd.mediaView;
  UIViewController *vc = [[UIViewController alloc] init];
  NSDictionary<GADNativeAssetIdentifier, UIView *> *clickableViews = @{GADNativeIconAsset : iconView};

  OCMExpect([(FBNativeAd *)_mockFBNativeAd registerViewForInteraction:view
                                                            mediaView:mediaView
                                                        iconImageView:iconView
                                                       viewController:vc
                                                       clickableViews:@[ iconView ]]);

  [nativeAd didRenderInView:view
        clickableAssetViews:clickableViews
     nonclickableAssetViews:@{}
             viewController:vc];

  OCMVerifyAll(_mockFBNativeAd);
}

- (void)testNativeBannerAdRegisterViews {
  _shouldReturnNativeBannerAd = YES;
  OCMStub([(FBNativeBannerAd *)_mockFBNativeBannerAd loadAdWithBidPayload:AUTKNativeBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBNativeBannerAd *ad = (FBNativeBannerAd *)invocation.target;
        [self->_nativeAdDelegate nativeBannerAdDidLoad:ad];
      });

  AUTKMediationNativeAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  id<GADMediationNativeAd> nativeAd = delegate.nativeAd;

  UIView *view = [[UIView alloc] init];
  UIImageView *iconView = [[UIImageView alloc] init];
  UIViewController *vc = [[UIViewController alloc] init];
  NSDictionary<GADNativeAssetIdentifier, UIView *> *clickableViews = @{GADNativeIconAsset : iconView};

  OCMExpect([(FBNativeBannerAd *)_mockFBNativeBannerAd registerViewForInteraction:view
                                                                   iconImageView:iconView
                                                                  viewController:vc
                                                                  clickableViews:@[ iconView ]]);

  [nativeAd didRenderInView:view
        clickableAssetViews:clickableViews
     nonclickableAssetViews:@{}
             viewController:vc];

  OCMVerifyAll(_mockFBNativeBannerAd);
}

- (void)testNativeAdUnregisterView {
  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
      FBNativeAd *ad = (FBNativeAd *)invocation.target;
      [self->_nativeAdDelegate nativeAdDidLoad:ad];
    });

  AUTKMediationNativeAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  id<GADMediationNativeAd> nativeAd = delegate.nativeAd;

  OCMExpect([(FBNativeAd *)_mockFBNativeAd unregisterView]);
  [nativeAd didUntrackView:nil];
  OCMVerifyAll(_mockFBNativeAd);
}

- (void)testNativeBannerAdUnregisterView {
  _shouldReturnNativeBannerAd = YES;
  OCMStub([(FBNativeBannerAd *)_mockFBNativeBannerAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
        FBNativeBannerAd *ad = (FBNativeBannerAd *)invocation.target;
        [self->_nativeAdDelegate nativeBannerAdDidLoad:ad];
      });

  AUTKMediationNativeAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  id<GADMediationNativeAd> nativeAd = delegate.nativeAd;

  OCMExpect([(FBNativeBannerAd *)_mockFBNativeBannerAd unregisterView]);
  [nativeAd didUntrackView:nil];
  OCMVerifyAll(_mockFBNativeBannerAd);
}

- (void)testNativeAdClick {
  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
      FBNativeAd *ad = (FBNativeAd *)invocation.target;
      [self->_nativeAdDelegate nativeAdDidLoad:ad];
    });

  AUTKMediationNativeAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());

  XCTAssertEqual(delegate.reportClickInvokeCount, 0);
  [self->_nativeAdDelegate nativeAdDidClick:_mockFBNativeAd];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);
}

- (void)testNativeBannerAdClick {
  _shouldReturnNativeBannerAd = YES;
  OCMStub([(FBNativeBannerAd *)_mockFBNativeBannerAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
        FBNativeBannerAd *ad = (FBNativeBannerAd *)invocation.target;
        [self->_nativeAdDelegate nativeBannerAdDidLoad:ad];
      });

  AUTKMediationNativeAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());

  XCTAssertEqual(delegate.reportClickInvokeCount, 0);
  [self->_nativeAdDelegate nativeBannerAdDidClick:_mockFBNativeBannerAd];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);
}

- (void)testNativeAdImpression {
  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
      FBNativeAd *ad = (FBNativeAd *)invocation.target;
      [self->_nativeAdDelegate nativeAdDidLoad:ad];
    });

  AUTKMediationNativeAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());

  XCTAssertEqual(delegate.reportImpressionInvokeCount, 0);
  [self->_nativeAdDelegate nativeAdWillLogImpression:_mockFBNativeAd];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);
  // Second impression should be ignored.
  [self->_nativeAdDelegate nativeAdWillLogImpression:_mockFBNativeAd];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);
}

- (void)testNativeBannerAdImpression {
  _shouldReturnNativeBannerAd = YES;
  OCMStub([(FBNativeBannerAd *)_mockFBNativeBannerAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
        FBNativeBannerAd *ad = (FBNativeBannerAd *)invocation.target;
        [self->_nativeAdDelegate nativeBannerAdDidLoad:ad];
      });

  AUTKMediationNativeAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());

  XCTAssertEqual(delegate.reportImpressionInvokeCount, 0);
  [self->_nativeAdDelegate nativeBannerAdWillLogImpression:_mockFBNativeBannerAd];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);
  // Second impression should be ignored.
  [self->_nativeAdDelegate nativeBannerAdWillLogImpression:_mockFBNativeBannerAd];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);
}

#pragma mark - Native Ad Video playback delegate methods

- (void)testNativeAdMediaPlay {
  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
      FBNativeAd *ad = (FBNativeAd *)invocation.target;
      [self->_nativeAdDelegate nativeAdDidLoad:ad];
    });

  AUTKMediationNativeAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  id<GADMediationNativeAd> nativeAd = delegate.nativeAd;
  XCTAssertEqual(delegate.didPlayVideoInvokeCount, 0);
  [(id<FBMediaViewDelegate>)nativeAd mediaViewVideoDidPlay:(FBMediaView *)nativeAd.mediaView];
  XCTAssertEqual(delegate.didPlayVideoInvokeCount, 1);
}

- (void)testNativeAdEndVideo {
  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
      FBNativeAd *ad = (FBNativeAd *)invocation.target;
      [self->_nativeAdDelegate nativeAdDidLoad:ad];
    });

  AUTKMediationNativeAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  id<GADMediationNativeAd> nativeAd = delegate.nativeAd;
  XCTAssertEqual(delegate.didEndVideoInvokeCount, 0);
  [(id<FBMediaViewDelegate>)nativeAd mediaViewVideoDidComplete:(FBMediaView *)nativeAd.mediaView];
  XCTAssertEqual(delegate.didEndVideoInvokeCount, 1);
}

- (void)testNativeAdMediaPause {
  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
      FBNativeAd *ad = (FBNativeAd *)invocation.target;
      [self->_nativeAdDelegate nativeAdDidLoad:ad];
    });

  AUTKMediationNativeAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  id<GADMediationNativeAd> nativeAd = delegate.nativeAd;
  XCTAssertEqual(delegate.didPauseVideoInvokeCount, 0);
  [(id<FBMediaViewDelegate>)nativeAd mediaViewVideoDidPause:(FBMediaView *)nativeAd.mediaView];
  XCTAssertEqual(delegate.didPauseVideoInvokeCount, 1);
}

- (void)testNativeAdMediaFullscreen {
  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
      FBNativeAd *ad = (FBNativeAd *)invocation.target;
      [self->_nativeAdDelegate nativeAdDidLoad:ad];
    });

  AUTKMediationNativeAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  id<GADMediationNativeAd> nativeAd = delegate.nativeAd;
  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 0);
  [(id<FBMediaViewDelegate>)nativeAd mediaViewWillEnterFullscreen:(FBMediaView *)nativeAd.mediaView];
  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 1);
  [(id<FBMediaViewDelegate>)nativeAd mediaViewDidExitFullscreen:(FBMediaView *)nativeAd.mediaView];
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 1);
}

#pragma mark - Native Ad COPPA

- (void)testLoadNativeAdWhenChildDirectedIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);
  GADMAdapterFacebookSetMixedAudienceIfNeeded();

  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
      FBNativeAd *ad = (FBNativeAd *)invocation.target;
      [self->_nativeAdDelegate nativeAdDidLoad:ad];
    });

  AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadNativeAdWhenUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);
  GADMAdapterFacebookSetMixedAudienceIfNeeded();

  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
      FBNativeAd *ad = (FBNativeAd *)invocation.target;
      [self->_nativeAdDelegate nativeAdDidLoad:ad];
    });

  AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadNativeAdWhenBothChildDirectedAndUnderAgeOfConsentAreFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);
  GADMAdapterFacebookSetMixedAudienceIfNeeded();

  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
      FBNativeAd *ad = (FBNativeAd *)invocation.target;
      [self->_nativeAdDelegate nativeAdDidLoad:ad];
    });

  AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadNativeAdWhenChildDirectedIsTrueAndUnderAgeIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);
  GADMAdapterFacebookSetMixedAudienceIfNeeded();

  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
      FBNativeAd *ad = (FBNativeAd *)invocation.target;
      [self->_nativeAdDelegate nativeAdDidLoad:ad];
    });

  AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadNativeAdWhenChildDirectedIsFalseAndUnderAgeIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);
  GADMAdapterFacebookSetMixedAudienceIfNeeded();

  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
      FBNativeAd *ad = (FBNativeAd *)invocation.target;
      [self->_nativeAdDelegate nativeAdDidLoad:ad];
    });

  AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadNativeAdWhenBothChildDirectedAndUnderAgeOfConsentAreTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);
  GADMAdapterFacebookSetMixedAudienceIfNeeded();

  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
      FBNativeAd *ad = (FBNativeAd *)invocation.target;
      [self->_nativeAdDelegate nativeAdDidLoad:ad];
    });

  AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadNativeAdWhenChildDirectedIsFalseAndUnderAgeIsNil {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);
  GADMAdapterFacebookSetMixedAudienceIfNeeded();

  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
      FBNativeAd *ad = (FBNativeAd *)invocation.target;
      [self->_nativeAdDelegate nativeAdDidLoad:ad];
    });

  AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadNativeAdWhenUnderAgeIsFalseAndChildDirectedIsNil {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);
  GADMAdapterFacebookSetMixedAudienceIfNeeded();

  OCMStub([(FBNativeAd *)_mockFBNativeAd loadAdWithBidPayload:AUTKNativeBidResponse])
    .andDo(^(NSInvocation *invocation) {
      FBNativeAd *ad = (FBNativeAd *)invocation.target;
      [self->_nativeAdDelegate nativeAdDidLoad:ad];
    });

  AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  OCMVerifyAll(_fbAdSettingsMock);
}

#pragma mark - Native Banner COPPA

- (void)testLoadNativeBannerAdWhenChildDirectedIsTrue {
  _shouldReturnNativeBannerAd = YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);
  GADMAdapterFacebookSetMixedAudienceIfNeeded();

  OCMStub([(FBNativeBannerAd *)_mockFBNativeBannerAd loadAdWithBidPayload:AUTKNativeBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBNativeBannerAd *ad = (FBNativeBannerAd *)invocation.target;
        [self->_nativeAdDelegate nativeBannerAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadNativeBannerAdWhenUnderAgeOfConsentIsTrue {
  _shouldReturnNativeBannerAd = YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);
  GADMAdapterFacebookSetMixedAudienceIfNeeded();

  OCMStub([(FBNativeBannerAd *)_mockFBNativeBannerAd loadAdWithBidPayload:AUTKNativeBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBNativeBannerAd *ad = (FBNativeBannerAd *)invocation.target;
        [self->_nativeAdDelegate nativeBannerAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadNativeBannerAdWhenChildDirectedAndUnderAgeOfConsentAreFalse {
  _shouldReturnNativeBannerAd = YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);
  GADMAdapterFacebookSetMixedAudienceIfNeeded();

  OCMStub([(FBNativeBannerAd *)_mockFBNativeBannerAd loadAdWithBidPayload:AUTKNativeBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBNativeBannerAd *ad = (FBNativeBannerAd *)invocation.target;
        [self->_nativeAdDelegate nativeBannerAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadNativeBannerAdWhenChildDirectedIsTrueAndUnderAgeIsFalse {
  _shouldReturnNativeBannerAd = YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);
  GADMAdapterFacebookSetMixedAudienceIfNeeded();

  OCMStub([(FBNativeBannerAd *)_mockFBNativeBannerAd loadAdWithBidPayload:AUTKNativeBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBNativeBannerAd *ad = (FBNativeBannerAd *)invocation.target;
        [self->_nativeAdDelegate nativeBannerAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadNativeBannerAdWhenChildDirectedIsFalseAndUnderAgeIsTrue {
  _shouldReturnNativeBannerAd = YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);
  GADMAdapterFacebookSetMixedAudienceIfNeeded();

  OCMStub([(FBNativeBannerAd *)_mockFBNativeBannerAd loadAdWithBidPayload:AUTKNativeBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBNativeBannerAd *ad = (FBNativeBannerAd *)invocation.target;
        [self->_nativeAdDelegate nativeBannerAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadNativeBannerAdWhenChildDirectedAndUnderAgeOfConsentAreTrue {
  _shouldReturnNativeBannerAd = YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);
  GADMAdapterFacebookSetMixedAudienceIfNeeded();

  OCMStub([(FBNativeBannerAd *)_mockFBNativeBannerAd loadAdWithBidPayload:AUTKNativeBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBNativeBannerAd *ad = (FBNativeBannerAd *)invocation.target;
        [self->_nativeAdDelegate nativeBannerAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadNativeBannerAdWhenChildDirectedIsFalseAndUnderAgeIsNil {
  _shouldReturnNativeBannerAd = YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);
  GADMAdapterFacebookSetMixedAudienceIfNeeded();

  OCMStub([(FBNativeBannerAd *)_mockFBNativeBannerAd loadAdWithBidPayload:AUTKNativeBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBNativeBannerAd *ad = (FBNativeBannerAd *)invocation.target;
        [self->_nativeAdDelegate nativeBannerAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadNativeBannerAdWhenUnderAgeIsFalseAndChildDirectedIsNil {
  _shouldReturnNativeBannerAd = YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);
  GADMAdapterFacebookSetMixedAudienceIfNeeded();

  OCMStub([(FBNativeBannerAd *)_mockFBNativeBannerAd loadAdWithBidPayload:AUTKNativeBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBNativeBannerAd *ad = (FBNativeBannerAd *)invocation.target;
        [self->_nativeAdDelegate nativeBannerAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadNativeAd(_adapter, AUTMediationNativeAdConfiguration());
  OCMVerifyAll(_fbAdSettingsMock);
}

@end
