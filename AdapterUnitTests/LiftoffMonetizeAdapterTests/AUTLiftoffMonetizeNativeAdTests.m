#import "GADMediationAdapterVungle.h"
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationNativeAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <VungleAdsSDK/VungleAdsSDK.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

static NSString *const kPlacementID = @"12345";
static NSString *const kAppID = @"AppId";
static NSString *const kBidResponse = @"bidResponse";

@interface AUTLiftoffMonetizeNativeAdTests : XCTestCase

@end

@implementation AUTLiftoffMonetizeNativeAdTests {
  /// An adapter instance that is used to test loading an native ad.
  GADMediationAdapterVungle *_adapter;

  /// A mock instance of VungleNative.
  id _nativeMock;
}

- (void)setUp {
  [super setUp];

  _adapter = [[GADMediationAdapterVungle alloc] init];

  _nativeMock = OCMClassMock([VungleNative class]);
  OCMStub([_nativeMock alloc]).andReturn(_nativeMock);
}

- (void)testLoadNativeAdSetsCoppaYesWhenChildDirected {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment =
      [NSNumber numberWithInt:1];
  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  GADMediationNativeLoadCompletionHandler completionHandler =
      ^(id<GADMediationNativeAd> _Nullable ad, NSError *_Nullable error) {
        return [[AUTKMediationNativeAdEventDelegate alloc] init];
      };
  id vunglePrivacySettingsMock = OCMClassMock([VunglePrivacySettings class]);

  [_adapter loadNativeAdForAdConfiguration:configuration completionHandler:completionHandler];

  OCMVerify([vunglePrivacySettingsMock setCOPPAStatus:YES]);
}

- (void)testLoadNativeAdSetsCoppaNoWhenNotChildDirected {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment =
      [NSNumber numberWithInt:0];
  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  GADMediationNativeLoadCompletionHandler completionHandler =
      ^(id<GADMediationNativeAd> _Nullable ad, NSError *_Nullable error) {
        return [[AUTKMediationNativeAdEventDelegate alloc] init];
      };
  id vunglePrivacySettingsMock = OCMClassMock([VunglePrivacySettings class]);

  [_adapter loadNativeAdForAdConfiguration:configuration completionHandler:completionHandler];

  OCMVerify([vunglePrivacySettingsMock setCOPPAStatus:NO]);
}

- (AUTKMediationNativeAdEventDelegate *)
    loadNativeAdAndAssertLoadSuccessWithCredentials:(AUTKMediationCredentials *)credentials
                                          andExtras:(VungleAdNetworkExtras *)extras
                          andAssertNativeAdPosition:
                              (NativeAdOptionsPosition)expectedNativeAdPosition {
  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = extras;
  configuration.bidResponse = kBidResponse;
  __block id<VungleNativeDelegate> loadDelegate = nil;
  OCMExpect([_nativeMock initWithPlacementId:kPlacementID]).andReturn(_nativeMock);
  OCMExpect([_nativeMock setDelegate:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  OCMExpect([_nativeMock setAdOptionsPosition:expectedNativeAdPosition]);
  OCMExpect([_nativeMock load:kBidResponse]).andDo(^(NSInvocation *invocation) {
    [loadDelegate nativeAdDidLoad:self->_nativeMock];
  });
  NSData *const watermark = [@"watermark" dataUsingEncoding:NSUTF8StringEncoding];
  configuration.watermark = watermark;
  id vungleAdsExtrasMock = OCMClassMock([VungleAdsExtras class]);
  OCMStub([vungleAdsExtrasMock alloc]).andReturn(vungleAdsExtrasMock);
  OCMExpect([_nativeMock setWithExtras:vungleAdsExtrasMock]);

  id<GADMediationNativeAdEventDelegate> delegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  OCMVerifyAll(_nativeMock);
  OCMVerify([vungleAdsExtrasMock setWithWatermark:[watermark base64EncodedStringWithOptions:0]]);
  return delegate;
}

- (void)testLoadNativeAdSuccessWhenLiftoffSdkIsInitialized {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};

  [self loadNativeAdAndAssertLoadSuccessWithCredentials:credentials
                                              andExtras:nil
                              andAssertNativeAdPosition:NativeAdOptionsPositionTopRight];
}

- (void)testLoadNativeAdSuccessWhenLiftoffSdkIsNotYetInitialized {
  id vungleRouterMock = OCMClassMock([GADMAdapterVungleRouter class]);
  OCMStub([vungleRouterMock sharedInstance]).andReturn(vungleRouterMock);
  __block id<GADMAdapterVungleDelegate> initDelegate = nil;
  OCMExpect([vungleRouterMock initWithAppId:kAppID delegate:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&initDelegate atIndex:3];
        [initDelegate initialized:true error:nil];
      });
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterVunglePlacementID : kPlacementID, GADMAdapterVungleApplicationID : kAppID};

  [self loadNativeAdAndAssertLoadSuccessWithCredentials:credentials
                                              andExtras:nil
                              andAssertNativeAdPosition:NativeAdOptionsPositionTopRight];
  OCMVerifyAll(vungleRouterMock);
}

- (void)testLoadNativeAdSetsAdPositionTopLeft {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  VungleAdNetworkExtras *extras = [[VungleAdNetworkExtras alloc] init];
  // 1 means topLeft.
  extras.nativeAdOptionPosition = 1;

  [self loadNativeAdAndAssertLoadSuccessWithCredentials:credentials
                                              andExtras:extras
                              andAssertNativeAdPosition:NativeAdOptionsPositionTopLeft];
}

- (void)testLoadNativeAdSetsAdPositionTopRight {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  VungleAdNetworkExtras *extras = [[VungleAdNetworkExtras alloc] init];
  // 2 means topRight.
  extras.nativeAdOptionPosition = 2;

  [self loadNativeAdAndAssertLoadSuccessWithCredentials:credentials
                                              andExtras:extras
                              andAssertNativeAdPosition:NativeAdOptionsPositionTopRight];
}

- (void)testLoadNativeAdSetsAdPositionBottomLeft {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  VungleAdNetworkExtras *extras = [[VungleAdNetworkExtras alloc] init];
  // 3 means bottomLeft.
  extras.nativeAdOptionPosition = 3;

  [self loadNativeAdAndAssertLoadSuccessWithCredentials:credentials
                                              andExtras:extras
                              andAssertNativeAdPosition:NativeAdOptionsPositionBottomLeft];
}

- (void)testLoadNativeAdSetsAdPositionBottomRight {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  VungleAdNetworkExtras *extras = [[VungleAdNetworkExtras alloc] init];
  // 4 means bottomRight.
  extras.nativeAdOptionPosition = 4;

  [self loadNativeAdAndAssertLoadSuccessWithCredentials:credentials
                                              andExtras:extras
                              andAssertNativeAdPosition:NativeAdOptionsPositionBottomRight];
}

- (void)testLoadNativeAdFailureWhenLiftoffFailsToLoadAd {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;
  OCMStub([_nativeMock initWithPlacementId:kPlacementID]).andReturn(_nativeMock);
  __block id<VungleNativeDelegate> loadDelegate = nil;
  OCMStub([_nativeMock setDelegate:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&loadDelegate atIndex:2];
  });
  NSError *liftoffError =
      [NSError errorWithDomain:@"liftoff.domain"
                          code:1
                      userInfo:@{NSLocalizedDescriptionKey : @"Native ad load failed."}];
  OCMStub([_nativeMock load:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [loadDelegate nativeAdDidFailToLoad:self->_nativeMock withError:liftoffError];
  });

  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, configuration, liftoffError);
}

/// Mocks a successful load of a native ad, captures the instance of
/// AUTKMediationNativeAdEventDelegate and returns it.
- (AUTKMediationNativeAdEventDelegate *)loadNativeAdAndGetEventDelegate {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterVunglePlacementID : kPlacementID};
  return [self loadNativeAdAndAssertLoadSuccessWithCredentials:credentials
                                                     andExtras:nil
                                     andAssertNativeAdPosition:NativeAdOptionsPositionTopRight];
}

- (void)testNativeAdDidFailToPresentInvokesPresentErrorOnDelegate {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];
  id<VungleNativeDelegate> vungleNativeDelegate = (id<VungleNativeDelegate>)eventDelegate.nativeAd;
  NSError *liftoffError =
      [NSError errorWithDomain:@"liftoff.domain"
                          code:2
                      userInfo:@{NSLocalizedDescriptionKey : @"Native ad presentation failed."}];
  [vungleNativeDelegate nativeAdDidFailToPresent:_nativeMock withError:liftoffError];

  NSError *presentationError = eventDelegate.didFailToPresentError;
  XCTAssertEqualObjects(presentationError, liftoffError);
}

- (void)testNativeAdDidTrackImpressionInvokesReportImpressionOnDelegate {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];
  id<VungleNativeDelegate> vungleNativeDelegate = (id<VungleNativeDelegate>)eventDelegate.nativeAd;
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);

  [vungleNativeDelegate nativeAdDidTrackImpression:_nativeMock];

  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testNativeAdDidClickInvokesReportClickOnDelegate {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];
  id<VungleNativeDelegate> vungleNativeDelegate = (id<VungleNativeDelegate>)eventDelegate.nativeAd;
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);

  [vungleNativeDelegate nativeAdDidClick:_nativeMock];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testHeadlineReturnsLiftoffNativeAdTitle {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];
  NSString *nativeAdTitle = @"Ad title";
  OCMStub([_nativeMock title]).andReturn(nativeAdTitle);

  XCTAssertEqual([eventDelegate.nativeAd headline], nativeAdTitle);
}

- (void)testImagesReturnsNil {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];

  XCTAssertEqual([eventDelegate.nativeAd images], nil);
}

- (void)testBodyReturnsLiftoffNativeAdBodyText {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];
  NSString *nativeAdBodyText = @"Ad body text";
  OCMStub([_nativeMock bodyText]).andReturn(nativeAdBodyText);

  XCTAssertEqual([eventDelegate.nativeAd body], nativeAdBodyText);
}

- (void)testIconReturnsIconImageIfNativeAdIconIsNotNil {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];
  UIImage *nativeAdIcon = [[UIImage alloc] init];
  OCMStub([_nativeMock iconImage]).andReturn(nativeAdIcon);

  GADNativeAdImage *gadNativeAdImage = [eventDelegate.nativeAd icon];

  XCTAssertEqual(gadNativeAdImage.image, nativeAdIcon);
}

- (void)testIconReturnsNilIfNativeAdIconIsNil {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];
  OCMStub([_nativeMock iconImage]).andReturn(nil);

  XCTAssertEqual([eventDelegate.nativeAd icon], nil);
}

- (void)testCallToAction {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];
  NSString *nativeAdCallToAction = @"Ad call to action";
  OCMStub([_nativeMock callToAction]).andReturn(nativeAdCallToAction);

  XCTAssertEqual([eventDelegate.nativeAd callToAction], nativeAdCallToAction);
}

- (void)testStarRatingReturnsStarRatingDecimalNumber {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];
  double starRating = 4.5;
  OCMStub([_nativeMock adStarRating]).andReturn(starRating);

  NSDecimalNumber *starRatingDecimalNumber = [eventDelegate.nativeAd starRating];

  XCTAssertEqual(starRatingDecimalNumber.doubleValue, starRating);
}

- (void)testStoreReturnsNil {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];

  XCTAssertEqual([eventDelegate.nativeAd store], nil);
}

- (void)testPriceReturnsNil {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];

  XCTAssertEqual([eventDelegate.nativeAd price], nil);
}

- (void)testAdvertiserReturnsNativeAdSponsoredText {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];
  NSString *nativeAdSponsoredText = @"Ad sponsored text";
  OCMStub([_nativeMock sponsoredText]).andReturn(nativeAdSponsoredText);

  XCTAssertEqual([eventDelegate.nativeAd advertiser], nativeAdSponsoredText);
}

- (void)testExtraAssetsReturnsNil {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];

  XCTAssertEqual([eventDelegate.nativeAd extraAssets], nil);
}

- (void)testAdChoicesViewReturnsNil {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];

  XCTAssertEqual([eventDelegate.nativeAd adChoicesView], nil);
}

- (void)testMediaView {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];

  XCTAssertTrue([[eventDelegate.nativeAd mediaView] isKindOfClass:[MediaView class]]);
}

- (void)testHasVideoContentReturnsYes {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];

  XCTAssertTrue([eventDelegate.nativeAd hasVideoContent]);
}

- (void)testDidRenderInViewRegistersViewOnLiftoffNativeAd {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];
  UIView *view = [[UIView alloc] init];
  UIImageView *iconView = [[UIImageView alloc] init];
  NSDictionary<GADNativeAssetIdentifier, UIView *> *clickableAssetViews =
      @{GADNativeIconAsset : iconView};
  UIViewController *viewController = [[UIViewController alloc] init];

  [eventDelegate.nativeAd didRenderInView:view
                      clickableAssetViews:clickableAssetViews
                   nonclickableAssetViews:@{}
                           viewController:viewController];

  OCMVerify([_nativeMock registerViewForInteractionWithView:view
                                                  mediaView:[OCMArg isKindOfClass:[MediaView class]]
                                              iconImageView:iconView
                                             viewController:viewController
                                             clickableViews:clickableAssetViews.allValues]);
}

- (void)testDidUntrackViewUnregistersViewFromLiftoffNativeAd {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];

  [eventDelegate.nativeAd didUntrackView:nil];

  OCMVerify([_nativeMock unregisterView]);
}

- (void)testHandlesUserClicksReturnsYes {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];

  XCTAssertTrue([eventDelegate.nativeAd handlesUserClicks]);
}

- (void)testHandlesUserImpressionsReturnsYes {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdAndGetEventDelegate];

  XCTAssertTrue([eventDelegate.nativeAd handlesUserImpressions]);
}

@end
