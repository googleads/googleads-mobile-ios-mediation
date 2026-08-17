#import "GADMediationAdapterPangle.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationBannerAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <PAGAdSDK/PAGAdSDK.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterPangleConstants.h"

@interface AUTPangleBannerAdTests : XCTestCase
@end

@implementation AUTPangleBannerAdTests {
  /// Mock for PAGConfig.
  id _configMock;

  /// Mock for PAGSdk.
  id _sdkMock;

  /// Mock for PAGBannerRequest.
  id _request;

  /// Mock for PAGBannerAd.
  id _ad;

  /// Adapter under test.
  GADMediationAdapterPangle *_adapter;
}

- (void)setUp {
  [super setUp];
  _configMock = OCMClassMock([PAGConfig class]);
  _sdkMock = OCMClassMock([PAGSdk class]);
  _request = OCMClassMock([PAGBannerRequest class]);
  _ad = OCMClassMock([PAGBannerAd class]);
  OCMStub(ClassMethod([_sdkMock initializationState])).andReturn(PAGSDKInitializationStateReady);
  OCMStub(ClassMethod([_configMock shareConfig])).andReturn(_configMock);
  _adapter = [[GADMediationAdapterPangle alloc] init];
}

- (void)tearDown {
  [_configMock stopMocking];
  [_sdkMock stopMocking];
  [_request stopMocking];
  [_ad stopMocking];

  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  [super tearDown];
}

- (nonnull AUTKMediationBannerAdEventDelegate *)loadAdWithPlacementID:
                                                    (nullable NSString *)placementID
                                                               adSize:(GADAdSize)adSize
                                                                isRTB:(BOOL)isRTB
                                                            watermark:(nullable NSData *)watermark {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  if (placementID) {
    credentials.settings = @{GADMAdapterPanglePlacementID : placementID};
  }
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = adSize;
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
        __unsafe_unretained void (^completionHandler)(PAGBannerAd *_Nullable bannerAd,
                                                      NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:4];
        completionHandler(self->_ad, nil);
      });
  OCMExpect([_ad setDelegate:[OCMArg checkWithBlock:^BOOL(id delegate) {
                   return [delegate conformsToProtocol:@protocol(PAGBannerAdDelegate)];
                 }]]);

  return AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);
}

- (void)loadAdFailureWithPlacementID:(nullable NSString *)placementID
                              adSize:(GADAdSize)adSize
                               isRTB:(BOOL)isRTB
                           watermark:(nullable NSData *)watermark
                       expectedError:(nonnull NSError *)expectedError {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  if (placementID) {
    credentials.settings = @{GADMAdapterPanglePlacementID : placementID};
  }
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = adSize;
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
        __unsafe_unretained void (^completionHandler)(PAGBannerAd *_Nullable bannerAd,
                                                      NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:4];
        completionHandler(nil, expectedError);
      });
  OCMStub([_ad setDelegate:[OCMArg checkWithBlock:^BOOL(id delegate) {
                 return [delegate conformsToProtocol:@protocol(PAGBannerAdDelegate)];
               }]]);

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

#pragma mark - Load Tests

- (void)testLoadRTBAdWithSize320x50 {
  OCMExpect(ClassMethod([_request requestWithBannerSize:kPAGBannerSize320x50])).andReturn(_request);
  NSData *watermarkData = [@"watermark" dataUsingEncoding:NSUTF8StringEncoding];
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                           adSize:GADAdSizeBanner
                                                                            isRTB:YES
                                                                        watermark:watermarkData];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_request);
  OCMVerifyAll(_ad);
}

- (void)testLoadWaterfallAdWithSize320x50 {
  OCMExpect(ClassMethod([_request requestWithBannerSize:kPAGBannerSize320x50])).andReturn(_request);
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                           adSize:GADAdSizeBanner
                                                                            isRTB:NO
                                                                        watermark:nil];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_request);
  OCMVerifyAll(_ad);
}

- (void)testLoadWaterfallAdWithWatermarkWithSize320x50 {
  OCMExpect(ClassMethod([_request requestWithBannerSize:kPAGBannerSize320x50])).andReturn(_request);
  NSData *watermarkData = [@"watermark" dataUsingEncoding:NSUTF8StringEncoding];
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                           adSize:GADAdSizeBanner
                                                                            isRTB:NO
                                                                        watermark:watermarkData];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_request);
  OCMVerifyAll(_ad);
}

- (void)testLoadAdWithSize728x90 {
  OCMExpect(ClassMethod([_request requestWithBannerSize:kPAGBannerSize728x90])).andReturn(_request);
  AUTKMediationBannerAdEventDelegate *eventDelegate =
      [self loadAdWithPlacementID:@"ID" adSize:GADAdSizeLeaderboard isRTB:YES watermark:nil];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_request);
  OCMVerifyAll(_ad);
}

- (void)testLoadAdWithSize300x250 {
  OCMExpect(ClassMethod([_request requestWithBannerSize:kPAGBannerSize300x250]))
      .andReturn(_request);
  AUTKMediationBannerAdEventDelegate *eventDelegate =
      [self loadAdWithPlacementID:@"ID" adSize:GADAdSizeMediumRectangle isRTB:YES watermark:nil];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_request);
  OCMVerifyAll(_ad);
}

- (void)testLoadAdWithAnchoredAdaptiveBannerSize {
  PAGBannerAdSize pagAnchored = PAGCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(375);
  OCMExpect(ClassMethod([_request requestWithBannerSize:pagAnchored])).andReturn(_request);
  AUTKMediationBannerAdEventDelegate *eventDelegate =
      [self loadAdWithPlacementID:@"ID"
                           adSize:GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(375)
                            isRTB:YES
                        watermark:nil];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_request);
  OCMVerifyAll(_ad);
}

- (void)testLoadAdWithInlineAdaptiveBannerSizeWithMaxHeight {
  PAGBannerAdSize pagInline = PAGInlineAdaptiveBannerAdSizeWithWidthAndMaxHeight(320, 100);
  OCMExpect(ClassMethod([_request requestWithBannerSize:pagInline])).andReturn(_request);
  AUTKMediationBannerAdEventDelegate *eventDelegate =
      [self loadAdWithPlacementID:@"ID"
                           adSize:GADInlineAdaptiveBannerAdSizeWithWidthAndMaxHeight(320, 100)
                            isRTB:YES
                        watermark:nil];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_request);
  OCMVerifyAll(_ad);
}

- (void)testLoadAdWithCurrentOrientationInlineAdaptiveBannerSize {
  PAGBannerAdSize pagInline = PAGCurrentOrientationInlineAdaptiveBannerAdSizeWithWidth(320);
  OCMExpect(ClassMethod([_request requestWithBannerSize:pagInline])).andReturn(_request);
  AUTKMediationBannerAdEventDelegate *eventDelegate =
      [self loadAdWithPlacementID:@"ID"
                           adSize:GADCurrentOrientationInlineAdaptiveBannerAdSizeWithWidth(320)
                            isRTB:YES
                        watermark:nil];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_request);
  OCMVerifyAll(_ad);
}

- (void)testLoadAdForChildAudience {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorChildUser
                                                  userInfo:nil];
  [self loadAdFailureWithPlacementID:@"ID"
                              adSize:GADAdSizeBanner
                               isRTB:YES
                           watermark:nil
                       expectedError:expectedError];
}

- (void)testLoadAdForNonChildAudience {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect(ClassMethod([_request requestWithBannerSize:kPAGBannerSize320x50])).andReturn(_request);
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                           adSize:GADAdSizeBanner
                                                                            isRTB:YES
                                                                        watermark:nil];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_request);
  OCMVerifyAll(_ad);
}

- (void)testLoadAdForUnderAgeOfConsent {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorChildUser
                                                  userInfo:nil];
  [self loadAdFailureWithPlacementID:@"ID"
                              adSize:GADAdSizeBanner
                               isRTB:YES
                           watermark:nil
                       expectedError:expectedError];
}

- (void)testLoadAdForNonUnderAgeOfConsent {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect(ClassMethod([_request requestWithBannerSize:kPAGBannerSize320x50])).andReturn(_request);
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                           adSize:GADAdSizeBanner
                                                                            isRTB:YES
                                                                        watermark:nil];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_request);
  OCMVerifyAll(_ad);
}

- (void)testLoadAdForAgeRestrictedChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorChildUser
                                                  userInfo:nil];
  [self loadAdFailureWithPlacementID:@"ID"
                              adSize:GADAdSizeBanner
                               isRTB:YES
                           watermark:nil
                       expectedError:expectedError];
}

- (void)testLoadAdForAgeRestrictedTeen {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;
  OCMExpect(ClassMethod([_request requestWithBannerSize:kPAGBannerSize320x50])).andReturn(_request);
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                           adSize:GADAdSizeBanner
                                                                            isRTB:YES
                                                                        watermark:nil];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_request);
  OCMVerifyAll(_ad);
}

- (void)testLoadAdForAgeRestrictedUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  OCMExpect(ClassMethod([_request requestWithBannerSize:kPAGBannerSize320x50])).andReturn(_request);
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                           adSize:GADAdSizeBanner
                                                                            isRTB:YES
                                                                        watermark:nil];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_request);
  OCMVerifyAll(_ad);
}

- (void)testLoadFailureWithEmptyPlacementID {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorInvalidServerParameters
                                                  userInfo:nil];
  [self loadAdFailureWithPlacementID:@""
                              adSize:GADAdSizeBanner
                               isRTB:YES
                           watermark:nil
                       expectedError:expectedError];
}

- (void)testLoadFailureWithNilPlacementID {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorInvalidServerParameters
                                                  userInfo:nil];
  [self loadAdFailureWithPlacementID:nil
                              adSize:GADAdSizeBanner
                               isRTB:YES
                           watermark:nil
                       expectedError:expectedError];
}

- (void)testLoadFailureWithNoAdFromPangle {
  OCMStub(ClassMethod([_request requestWithBannerSize:kPAGBannerSize320x50])).andReturn(_request);
  NSError *expectedError = [[NSError alloc] initWithDomain:@"pangle" code:12345 userInfo:nil];
  [self loadAdFailureWithPlacementID:@"ID"
                              adSize:GADAdSizeBanner
                               isRTB:YES
                           watermark:nil
                       expectedError:expectedError];
}

#pragma mark - Presentation & Event Tests

- (void)testBannerView {
  OCMStub(ClassMethod([_request requestWithBannerSize:kPAGBannerSize320x50])).andReturn(_request);
  UIView *expectedView = [[UIView alloc] init];
  OCMStub([_ad bannerView]).andReturn(expectedView);

  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                           adSize:GADAdSizeBanner
                                                                            isRTB:YES
                                                                        watermark:nil];
  XCTAssertEqualObjects([eventDelegate.bannerAd view], expectedView);
}

- (void)testAdDidShow {
  OCMStub(ClassMethod([_request requestWithBannerSize:kPAGBannerSize320x50])).andReturn(_request);
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                           adSize:GADAdSizeBanner
                                                                            isRTB:YES
                                                                        watermark:nil];
  id<PAGBannerAdDelegate> adDelegate = (id<PAGBannerAdDelegate>)eventDelegate.bannerAd;

  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  [adDelegate adDidShow:_ad];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testClick {
  OCMStub(ClassMethod([_request requestWithBannerSize:kPAGBannerSize320x50])).andReturn(_request);
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                           adSize:GADAdSizeBanner
                                                                            isRTB:YES
                                                                        watermark:nil];
  id<PAGBannerAdDelegate> adDelegate = (id<PAGBannerAdDelegate>)eventDelegate.bannerAd;

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);
  [adDelegate adDidClick:_ad];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

@end
