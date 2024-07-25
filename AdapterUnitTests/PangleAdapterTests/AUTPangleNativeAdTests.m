#import "GADMediationAdapterPangle.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationNativeAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <PAGAdSDK/PAGAdSDK.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterPangleConstants.h"

@interface AUTPangleNativeAdTests : XCTestCase
@end

@implementation AUTPangleNativeAdTests {
  /// Mock for PAGConfig.
  id _configMock;

  /// Mock for PAGSdk;
  id _sdkMock;

  /// Mock for PAGNativeRequest.
  id _request;

  /// Mock for PAGLNativeAd.
  id _ad;

  /// Mock for PAGLMaterialMeta.
  id _data;

  /// Mock for PAGLImage.
  id _icon;

  /// Adapter under tests.
  GADMediationAdapterPangle *_adapter;
}

- (void)setUp {
  _configMock = OCMClassMock([PAGConfig class]);
  _sdkMock = OCMClassMock([PAGSdk class]);
  _request = OCMClassMock([PAGNativeRequest class]);
  _ad = OCMClassMock([PAGLNativeAd class]);
  _data = OCMClassMock([PAGLMaterialMeta class]);
  _icon = OCMClassMock([PAGLImage class]);
  id sessionMock = OCMClassMock([NSURLSession class]);
  OCMStub(ClassMethod([sessionMock sharedSession])).andReturn(sessionMock);
  id dataTask = OCMClassMock([NSURLSessionDataTask class]);
  __block __unsafe_unretained void (^completionHandler)(
      NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error);
  OCMExpect([sessionMock dataTaskWithURL:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&completionHandler atIndex:3];
      })
      .andReturn(dataTask);
  id nativeAdImageMock = OCMClassMock([GADNativeAdImage class]);
  OCMStub([nativeAdImageMock initWithImage:OCMOCK_ANY]).andReturn(nativeAdImageMock);
  OCMStub([dataTask resume]).andDo(^(NSInvocation *invocation) {
    completionHandler([[NSData alloc] init], nil, nil);
  });
  OCMStub([_ad data]).andReturn(_data);
  OCMStub([_data icon]).andReturn(_icon);
  OCMStub([_icon imageURL]).andReturn(@"https://imageURL.com");
  OCMStub(ClassMethod([_sdkMock initializationState])).andReturn(PAGSDKInitializationStateReady);
  OCMStub(ClassMethod([_request request])).andReturn(_request);
  OCMStub(ClassMethod([_configMock shareConfig])).andReturn(_configMock);
  _adapter = [[GADMediationAdapterPangle alloc] init];
}

- (void)tearDown {
  OCMVerifyAll(_configMock);
  OCMVerifyAll(_sdkMock);
  OCMVerifyAll(_request);
  OCMVerifyAll(_ad);
  OCMVerifyAll(_data);
  OCMVerifyAll(_icon);
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
}

- (nonnull AUTKMediationNativeAdEventDelegate *)loadAdWithPlacementID:
    (nullable NSString *)placementID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterPanglePlacementID : placementID};
  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = @"bidResponse";
  configuration.topViewController = [[UIViewController alloc] init];
  NSString *watermarkString = @"watermark";
  NSData *watermarkData = [watermarkString dataUsingEncoding:NSUTF8StringEncoding];
  configuration.watermark = watermarkData;
  OCMExpect([_request setAdString:@"bidResponse"]);
  OCMExpect([_request setExtraInfo:@{@"admob_watermark" : watermarkData}]);
  OCMExpect(ClassMethod([_ad loadAdWithSlotID:placementID
                                      request:_request
                            completionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(PAGLNativeAd *_Nullable nativeAd,
                                                      NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:4];
        completionHandler(self->_ad, nil);
      });
  OCMExpect([_ad setDelegate:[OCMArg checkWithBlock:^BOOL(id delegate) {
                   return [delegate conformsToProtocol:@protocol(PAGLNativeAdDelegate)];
                 }]]);

  return AUTKWaitAndAssertLoadNativeAd(_adapter, configuration);
}

- (void)loadAdFailureWithPlacementID:(nullable NSString *)placementID
                       expectedError:(nonnull NSError *)expectedError {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterPanglePlacementID : placementID};
  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = @"bidResponse";
  NSString *watermarkString = @"watermark";
  NSData *watermarkData = [watermarkString dataUsingEncoding:NSUTF8StringEncoding];
  configuration.watermark = watermarkData;
  OCMStub(ClassMethod([_ad loadAdWithSlotID:placementID
                                    request:_request
                          completionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(PAGLNativeAd *_Nullable nativeAd,
                                                      NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:4];
        completionHandler(nil, expectedError);
      });
  OCMStub([_ad setDelegate:[OCMArg checkWithBlock:^BOOL(id delegate) {
                 return [delegate conformsToProtocol:@protocol(PAGLNativeAdDelegate)];
               }]]);

  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadAd {
  OCMExpect([_configMock setChildDirected:PAGChildDirectedTypeDefault]);

  [self loadAdWithPlacementID:@"12345"];
}

- (void)testLoadAdForChildAudience {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  OCMExpect([_configMock setChildDirected:PAGChildDirectedTypeChild]);

  [self loadAdWithPlacementID:@"12345"];
}

- (void)testLoadAdForNonChildAudience {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect([_configMock setChildDirected:PAGChildDirectedTypeNonChild]);

  [self loadAdWithPlacementID:@"12345"];
}

- (void)testLoadFailureWithEmptyPlacementID {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorInvalidServerParameters
                                                  userInfo:nil];
  [self loadAdFailureWithPlacementID:@"" expectedError:expectedError];
}

- (void)testLoadFailureWithNoAdFromPangle {
  NSError *expectedError = [[NSError alloc] initWithDomain:@"pangle" code:12345 userInfo:nil];
  [self loadAdFailureWithPlacementID:@"ID" expectedError:expectedError];
}

- (void)testIcon {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"12345"];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertEqual([nativeAd.icon class], [GADNativeAdImage class]);
}

- (void)testMediaView {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"12345"];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertTrue([nativeAd.mediaView isKindOfClass:[UIView class]]);
}

- (void)testAdChoicesView {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"12345"];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertTrue([nativeAd.adChoicesView isKindOfClass:[UIView class]]);
}

- (void)testHeadline {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"12345"];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;
  NSString *expectedTitle = @"title";
  OCMStub([_data AdTitle]).andReturn(expectedTitle);

  XCTAssertTrue([nativeAd.headline isEqualToString:expectedTitle]);
}

- (void)testBody {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"12345"];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;
  NSString *expectedBody = @"description";
  OCMStub([_data AdDescription]).andReturn(expectedBody);

  XCTAssertTrue([nativeAd.body isEqualToString:expectedBody]);
}

- (void)testCallToAction {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"12345"];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;
  NSString *expectedCallToAction = @"callToAction";
  OCMStub([_data buttonText]).andReturn(expectedCallToAction);

  XCTAssertTrue([nativeAd.callToAction isEqualToString:expectedCallToAction]);
}

- (void)testAdvertiser {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"12345"];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;
  NSString *expectedAdvertiser = @"advertiser";
  OCMStub([_data AdTitle]).andReturn(expectedAdvertiser);

  XCTAssertTrue([nativeAd.advertiser isEqualToString:expectedAdvertiser]);
}

- (void)testUnusedNativeAdMetaData {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"12345"];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertNil(nativeAd.starRating);
  XCTAssertNil(nativeAd.images);
  XCTAssertNil(nativeAd.store);
  XCTAssertNil(nativeAd.price);
  XCTAssertNil(nativeAd.extraAssets);
}

- (void)testHasVideoContent {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"12345"];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertTrue(nativeAd.hasVideoContent);
}

- (void)testHandlesUserClicks {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"12345"];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertTrue(nativeAd.handlesUserClicks);
}

- (void)testHandlesUserImpressions {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"12345"];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertTrue(nativeAd.handlesUserImpressions);
}

- (void)testDidUntrackView {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"12345"];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  OCMExpect([_ad unregisterView]);
  [nativeAd didUntrackView:[[UIView alloc] init]];
}

- (void)testDidRenderRegistersNativeAssets {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"12345"];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;
  UIView *expectedView = [[UIView alloc] init];
  NSDictionary<GADNativeAssetIdentifier, UIView *> *clickableAssetViews =
      @{GADNativeHeadlineAsset : expectedView};
  OCMExpect([_ad registerContainer:expectedView withClickableViews:@[ expectedView ]]);

  [nativeAd didRenderInView:expectedView
         clickableAssetViews:clickableAssetViews
      nonclickableAssetViews:@{}
              viewController:[[UIViewController alloc] init]];
}

- (void)testImpression {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"12345"];
  id<PAGLNativeAdDelegate> adDelegate = (id<PAGLNativeAdDelegate>)eventDelegate.nativeAd;

  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  [adDelegate adDidShow:_ad];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testClick {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"12345"];
  id<PAGLNativeAdDelegate> adDelegate = (id<PAGLNativeAdDelegate>)eventDelegate.nativeAd;

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);
  [adDelegate adDidClick:_ad];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

@end
