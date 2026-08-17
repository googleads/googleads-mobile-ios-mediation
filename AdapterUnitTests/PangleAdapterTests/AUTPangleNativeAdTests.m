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

  /// Mock for PAGSdk.
  id _sdkMock;

  /// Mock for PAGNativeRequest.
  id _request;

  /// Mock for PAGLNativeAd.
  id _ad;

  /// Mock for PAGLMaterialMeta.
  id _data;

  /// Mock for PAGLImage.
  id _icon;

  /// Mock for NSURLSession.
  id _sessionMock;

  /// Mock for NSURLSessionDataTask.
  id _dataTaskMock;

  /// Mock for GADNativeAdImage.
  id _nativeAdImageMock;

  /// Session data to return in URL task callback.
  NSData *_sessionData;

  /// Session error to return in URL task callback.
  NSError *_sessionError;

  /// Completion handler for URL session task.
  __block __unsafe_unretained void (^_urlSessionCompletionHandler)(
      NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error);

  /// Adapter under test.
  GADMediationAdapterPangle *_adapter;
}

- (void)setUp {
  [super setUp];
  _configMock = OCMClassMock([PAGConfig class]);
  _sdkMock = OCMClassMock([PAGSdk class]);
  _request = OCMClassMock([PAGNativeRequest class]);
  _ad = OCMClassMock([PAGLNativeAd class]);
  _data = OCMClassMock([PAGLMaterialMeta class]);
  _icon = OCMClassMock([PAGLImage class]);

  _sessionData = [[NSData alloc] init];
  _sessionError = nil;

  _sessionMock = OCMClassMock([NSURLSession class]);
  OCMStub(ClassMethod([_sessionMock sharedSession])).andReturn(_sessionMock);
  _dataTaskMock = OCMClassMock([NSURLSessionDataTask class]);
  OCMStub([_sessionMock dataTaskWithURL:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&self->_urlSessionCompletionHandler atIndex:3];
      })
      .andReturn(_dataTaskMock);
  _nativeAdImageMock = OCMClassMock([GADNativeAdImage class]);
  OCMStub([_nativeAdImageMock initWithImage:OCMOCK_ANY]).andReturn(_nativeAdImageMock);
  OCMStub([_dataTaskMock resume]).andDo(^(NSInvocation *invocation) {
    if (self->_urlSessionCompletionHandler) {
      self->_urlSessionCompletionHandler(self->_sessionData, nil, self->_sessionError);
    }
  });

  OCMStub([_ad data]).andReturn(_data);
  OCMStub([_data icon]).andReturn(_icon);
  OCMStub(ClassMethod([_sdkMock initializationState])).andReturn(PAGSDKInitializationStateReady);
  OCMStub(ClassMethod([_request request])).andReturn(_request);
  OCMStub(ClassMethod([_configMock shareConfig])).andReturn(_configMock);
  _adapter = [[GADMediationAdapterPangle alloc] init];
}

- (void)tearDown {
  [_configMock stopMocking];
  [_sdkMock stopMocking];
  [_request stopMocking];
  [_ad stopMocking];
  [_data stopMocking];
  [_icon stopMocking];
  [_sessionMock stopMocking];
  [_dataTaskMock stopMocking];
  [_nativeAdImageMock stopMocking];

  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  [super tearDown];
}

- (nonnull AUTKMediationNativeAdEventDelegate *)loadAdWithPlacementID:
                                                    (nullable NSString *)placementID
                                                             imageURL:(nullable NSString *)imageURL
                                                                isRTB:(BOOL)isRTB
                                                            watermark:(nullable NSData *)watermark {
  if (imageURL) {
    OCMStub([_icon imageURL]).andReturn(imageURL);
  } else {
    OCMStub([_icon imageURL]).andReturn(nil);
  }

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  if (placementID) {
    credentials.settings = @{GADMAdapterPanglePlacementID : placementID};
  }
  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.topViewController = [[UIViewController alloc] init];
  if (isRTB) {
    configuration.bidResponse = @"bidResponse";
    OCMExpect([_request setAdString:@"bidResponse"]);
  }
  if (watermark) {
    configuration.watermark = watermark;
    OCMExpect([_request setExtraInfo:@{@"admob_watermark" : watermark}]);
  }
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

- (nonnull AUTKMediationNativeAdEventDelegate *)loadAdWithPlacementID:
                                                    (nullable NSString *)placementID
                                                                isRTB:(BOOL)isRTB
                                                            watermark:(nullable NSData *)watermark {
  return [self loadAdWithPlacementID:placementID
                            imageURL:@"https://imageURL.com"
                               isRTB:isRTB
                           watermark:watermark];
}

- (void)loadAdFailureWithPlacementID:(nullable NSString *)placementID
                               isRTB:(BOOL)isRTB
                           watermark:(nullable NSData *)watermark
                       expectedError:(nonnull NSError *)expectedError {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  if (placementID) {
    credentials.settings = @{GADMAdapterPanglePlacementID : placementID};
  }
  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;
  if (isRTB) {
    configuration.bidResponse = @"bidResponse";
  }
  if (watermark) {
    configuration.watermark = watermark;
  }
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

#pragma mark - Load Tests

- (void)testLoadRTBAdSuccess {
  NSData *watermarkData = [@"watermark" dataUsingEncoding:NSUTF8StringEncoding];
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:watermarkData];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_request);
  OCMVerifyAll(_ad);
}

- (void)testLoadWaterfallAdSuccess {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:NO
                                                                        watermark:nil];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_ad);
}

- (void)testLoadWaterfallAdWithWatermarkSuccess {
  NSData *watermarkData = [@"watermark" dataUsingEncoding:NSUTF8StringEncoding];
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:NO
                                                                        watermark:watermarkData];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_request);
  OCMVerifyAll(_ad);
}

- (void)testLoadAdForChildAudience {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorChildUser
                                                  userInfo:nil];
  [self loadAdFailureWithPlacementID:@"ID" isRTB:YES watermark:nil expectedError:expectedError];
}

- (void)testLoadAdForNonChildAudience {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:nil];
  XCTAssertNotNil(eventDelegate);
}

- (void)testLoadAdForUnderAgeOfConsent {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorChildUser
                                                  userInfo:nil];
  [self loadAdFailureWithPlacementID:@"ID" isRTB:YES watermark:nil expectedError:expectedError];
}

- (void)testLoadAdForNonUnderAgeOfConsent {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:nil];
  XCTAssertNotNil(eventDelegate);
}

- (void)testLoadAdForAgeRestrictedChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorChildUser
                                                  userInfo:nil];
  [self loadAdFailureWithPlacementID:@"ID" isRTB:YES watermark:nil expectedError:expectedError];
}

- (void)testLoadAdForAgeRestrictedTeen {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:nil];
  XCTAssertNotNil(eventDelegate);
}

- (void)testLoadAdForAgeRestrictedUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:nil];
  XCTAssertNotNil(eventDelegate);
}

- (void)testLoadFailureWithEmptyPlacementID {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorInvalidServerParameters
                                                  userInfo:nil];
  [self loadAdFailureWithPlacementID:@"" isRTB:YES watermark:nil expectedError:expectedError];
}

- (void)testLoadFailureWithNilPlacementID {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorInvalidServerParameters
                                                  userInfo:nil];
  [self loadAdFailureWithPlacementID:nil isRTB:YES watermark:nil expectedError:expectedError];
}

- (void)testLoadFailureWithNoAdFromPangle {
  NSError *expectedError = [[NSError alloc] initWithDomain:@"pangle" code:12345 userInfo:nil];
  [self loadAdFailureWithPlacementID:@"ID" isRTB:YES watermark:nil expectedError:expectedError];
}

#pragma mark - Icon Download Tests

- (void)testIconImageDownloadSuccess {
  _sessionData = [[NSData alloc] init];
  _sessionError = nil;

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadAdWithPlacementID:@"ID" imageURL:@"https://imageURL.com" isRTB:YES watermark:nil];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertNotNil(nativeAd.icon);
  XCTAssertEqual([nativeAd.icon class], [GADNativeAdImage class]);
}

- (void)testIconImageDownloadNetworkFailure {
  _sessionData = nil;
  _sessionError = [NSError errorWithDomain:NSURLErrorDomain
                                      code:NSURLErrorNotConnectedToInternet
                                  userInfo:nil];

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadAdWithPlacementID:@"ID" imageURL:@"https://imageURL.com" isRTB:YES watermark:nil];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertNotNil(nativeAd);
  XCTAssertNil(nativeAd.icon);
}

- (void)testIconWithNilImageURL {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                         imageURL:nil
                                                                            isRTB:YES
                                                                        watermark:nil];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertNotNil(nativeAd);
  XCTAssertNil(nativeAd.icon);
}

- (void)testIconWithEmptyImageURL {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                         imageURL:@""
                                                                            isRTB:YES
                                                                        watermark:nil];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertNotNil(nativeAd);
  XCTAssertNil(nativeAd.icon);
}

#pragma mark - Asset Tests

- (void)testMediaView {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:nil];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertTrue([nativeAd.mediaView isKindOfClass:[UIView class]]);
}

- (void)testAdChoicesView {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:nil];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertTrue([nativeAd.adChoicesView isKindOfClass:[UIView class]]);
}

- (void)testHeadline {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:nil];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;
  NSString *expectedTitle = @"title";
  OCMStub([_data AdTitle]).andReturn(expectedTitle);

  XCTAssertTrue([nativeAd.headline isEqualToString:expectedTitle]);
}

- (void)testBody {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:nil];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;
  NSString *expectedBody = @"description";
  OCMStub([_data AdDescription]).andReturn(expectedBody);

  XCTAssertTrue([nativeAd.body isEqualToString:expectedBody]);
}

- (void)testCallToAction {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:nil];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;
  NSString *expectedCallToAction = @"callToAction";
  OCMStub([_data buttonText]).andReturn(expectedCallToAction);

  XCTAssertTrue([nativeAd.callToAction isEqualToString:expectedCallToAction]);
}

- (void)testAdvertiser {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:nil];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;
  NSString *expectedAdvertiser = @"advertiser";
  OCMStub([_data AdTitle]).andReturn(expectedAdvertiser);

  XCTAssertTrue([nativeAd.advertiser isEqualToString:expectedAdvertiser]);
}

- (void)testUnusedNativeAdMetaData {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:nil];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertNil(nativeAd.starRating);
  XCTAssertNil(nativeAd.images);
  XCTAssertNil(nativeAd.store);
  XCTAssertNil(nativeAd.price);
  XCTAssertNil(nativeAd.extraAssets);
}

- (void)testHasVideoContent {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:nil];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertTrue(nativeAd.hasVideoContent);
}

- (void)testHandlesUserClicks {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:nil];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertTrue(nativeAd.handlesUserClicks);
}

- (void)testHandlesUserImpressions {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:nil];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertTrue(nativeAd.handlesUserImpressions);
}

#pragma mark - Views & Interaction Tests

- (void)testDidUntrackView {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:nil];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  OCMExpect([_ad unregisterView]);
  [nativeAd didUntrackView:[[UIView alloc] init]];
  OCMVerifyAll(_ad);
}

- (void)testDidRenderRegistersNativeAssets {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:nil];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;
  UIView *expectedView = [[UIView alloc] init];
  NSDictionary<GADNativeAssetIdentifier, UIView *> *clickableAssetViews =
      @{GADNativeHeadlineAsset : expectedView};
  OCMExpect([_ad registerContainer:expectedView withClickableViews:@[ expectedView ]]);

  [nativeAd didRenderInView:expectedView
         clickableAssetViews:clickableAssetViews
      nonclickableAssetViews:@{}
              viewController:[[UIViewController alloc] init]];
  OCMVerifyAll(_ad);
}

#pragma mark - Delegate Event Tests

- (void)testImpression {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:nil];
  id<PAGLNativeAdDelegate> adDelegate = (id<PAGLNativeAdDelegate>)eventDelegate.nativeAd;

  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  [adDelegate adDidShow:_ad];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testClick {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                            isRTB:YES
                                                                        watermark:nil];
  id<PAGLNativeAdDelegate> adDelegate = (id<PAGLNativeAdDelegate>)eventDelegate.nativeAd;

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);
  [adDelegate adDidClick:_ad];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

@end
