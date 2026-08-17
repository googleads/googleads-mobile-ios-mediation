#import "GADMediationAdapterPangle.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationInterstitialAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <PAGAdSDK/PAGAdSDK.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterPangleConstants.h"

@interface AUTPangleInterstitialAdTests : XCTestCase
@end

@implementation AUTPangleInterstitialAdTests {
  /// Mock for PAGConfig.
  id _configMock;

  /// Mock for PAGSdk.
  id _sdkMock;

  /// Mock for PAGInterstitialRequest.
  id _request;

  /// Mock for PAGLInterstitialAd.
  id _ad;

  /// Adapter under test.
  GADMediationAdapterPangle *_adapter;
}

- (void)setUp {
  [super setUp];
  _configMock = OCMClassMock([PAGConfig class]);
  _sdkMock = OCMClassMock([PAGSdk class]);
  _request = OCMClassMock([PAGInterstitialRequest class]);
  _ad = OCMClassMock([PAGLInterstitialAd class]);
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

  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  [super tearDown];
}

- (nonnull AUTKMediationInterstitialAdEventDelegate *)
    loadAdWithPlacementID:(nullable NSString *)placementID
                    isRTB:(BOOL)isRTB
                watermark:(nullable NSData *)watermark {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  if (placementID) {
    credentials.settings = @{GADMAdapterPanglePlacementID : placementID};
  }
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
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
        __unsafe_unretained void (^completionHandler)(PAGLInterstitialAd *_Nullable interstitialAd,
                                                      NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:4];
        completionHandler(self->_ad, nil);
      });
  OCMExpect([_ad setDelegate:[OCMArg checkWithBlock:^BOOL(id delegate) {
                   return [delegate conformsToProtocol:@protocol(PAGLInterstitialAdDelegate)];
                 }]]);

  return AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);
}

- (void)loadAdFailureWithPlacementID:(nullable NSString *)placementID
                               isRTB:(BOOL)isRTB
                           watermark:(nullable NSData *)watermark
                       expectedError:(nonnull NSError *)expectedError {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  if (placementID) {
    credentials.settings = @{GADMAdapterPanglePlacementID : placementID};
  }
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
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
        __unsafe_unretained void (^completionHandler)(PAGLInterstitialAd *_Nullable interstitialAd,
                                                      NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:4];
        completionHandler(nil, expectedError);
      });
  OCMStub([_ad setDelegate:[OCMArg checkWithBlock:^BOOL(id delegate) {
                 return [delegate conformsToProtocol:@protocol(PAGLInterstitialAdDelegate)];
               }]]);

  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
}

#pragma mark - Load Tests

- (void)testLoadRTBAdSuccess {
  NSData *watermarkData = [@"watermark" dataUsingEncoding:NSUTF8StringEncoding];
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadAdWithPlacementID:@"ID" isRTB:YES watermark:watermarkData];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_request);
  OCMVerifyAll(_ad);
}

- (void)testLoadWaterfallAdSuccess {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                                  isRTB:NO
                                                                              watermark:nil];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_ad);
}

- (void)testLoadWaterfallAdWithWatermarkSuccess {
  NSData *watermarkData = [@"watermark" dataUsingEncoding:NSUTF8StringEncoding];
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadAdWithPlacementID:@"ID" isRTB:NO watermark:watermarkData];
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
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
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
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
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
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                                  isRTB:YES
                                                                              watermark:nil];
  XCTAssertNotNil(eventDelegate);
}

- (void)testLoadAdForAgeRestrictedUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
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

#pragma mark - Presentation & Event Tests

- (void)testAdDidShow {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                                  isRTB:YES
                                                                              watermark:nil];
  OCMStub([_ad presentFromRootViewController:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    id<PAGLInterstitialAdDelegate> adDelegate =
        (id<PAGLInterstitialAdDelegate>)eventDelegate.interstitialAd;
    [adDelegate adDidShow:self->_ad];
  });

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  [eventDelegate.interstitialAd presentFromViewController:[[UIViewController alloc] init]];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testAdDidShowFail {
  NSError *showError = [[NSError alloc] initWithDomain:@"pangle" code:12345 userInfo:nil];
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                                  isRTB:YES
                                                                              watermark:nil];
  OCMStub([_ad presentFromRootViewController:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    id<PAGLInterstitialAdDelegate> adDelegate =
        (id<PAGLInterstitialAdDelegate>)eventDelegate.interstitialAd;
    [adDelegate adDidShowFail:self->_ad error:showError];
  });

  XCTAssertNil(eventDelegate.didFailToPresentError);
  [eventDelegate.interstitialAd presentFromViewController:[[UIViewController alloc] init]];
  XCTAssertEqualObjects(eventDelegate.didFailToPresentError, showError);
}

- (void)testAdDismiss {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                                  isRTB:YES
                                                                              watermark:nil];
  id<PAGLInterstitialAdDelegate> adDelegate =
      (id<PAGLInterstitialAdDelegate>)eventDelegate.interstitialAd;

  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);
  [adDelegate adDidDismiss:_ad];
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testClick {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                                  isRTB:YES
                                                                              watermark:nil];
  id<PAGLInterstitialAdDelegate> adDelegate =
      (id<PAGLInterstitialAdDelegate>)eventDelegate.interstitialAd;

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);
  [adDelegate adDidClick:_ad];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

@end
