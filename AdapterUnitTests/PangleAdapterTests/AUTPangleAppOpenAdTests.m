#import "GADMediationAdapterPangle.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationAppOpenAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <PAGAdSDK/PAGAdSDK.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterPangleConstants.h"

@interface AUTPangleAppOpenAdTests : XCTestCase
@end

@implementation AUTPangleAppOpenAdTests {
  /// Mock for PAGConfig.
  id _configMock;

  /// Mock for PAGSdk.
  id _sdkMock;

  /// Mock for PAGAppOpenRequest.
  id _request;

  /// Mock for PAGLAppOpenAd.
  id _ad;

  /// Adapter under test.
  GADMediationAdapterPangle *_adapter;
}

- (void)setUp {
  [super setUp];
  _configMock = OCMClassMock([PAGConfig class]);
  _sdkMock = OCMClassMock([PAGSdk class]);
  _request = OCMClassMock([PAGAppOpenRequest class]);
  _ad = OCMClassMock([PAGLAppOpenAd class]);
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

- (nonnull AUTKMediationAppOpenAdEventDelegate *)
    loadAdWithPlacementID:(nullable NSString *)placementID
                    isRTB:(BOOL)isRTB
                watermark:(nullable NSData *)watermark {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  if (placementID) {
    credentials.settings = @{GADMAdapterPanglePlacementID : placementID};
  }
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
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
        __unsafe_unretained void (^completionHandler)(PAGLAppOpenAd *_Nullable appOpenAd,
                                                      NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:4];
        completionHandler(self->_ad, nil);
      });
  OCMExpect([_ad setDelegate:[OCMArg checkWithBlock:^BOOL(id delegate) {
                   return [delegate conformsToProtocol:@protocol(PAGLAppOpenAdDelegate)];
                 }]]);

  return AUTKWaitAndAssertLoadAppOpenAd(_adapter, configuration);
}

- (void)loadAdFailureWithPlacementID:(nullable NSString *)placementID
                               isRTB:(BOOL)isRTB
                           watermark:(nullable NSData *)watermark
                       expectedError:(nonnull NSError *)expectedError {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  if (placementID) {
    credentials.settings = @{GADMAdapterPanglePlacementID : placementID};
  }
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
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
        __unsafe_unretained void (^completionHandler)(PAGLAppOpenAd *_Nullable appOpenAd,
                                                      NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:4];
        completionHandler(nil, expectedError);
      });
  OCMStub([_ad setDelegate:[OCMArg checkWithBlock:^BOOL(id delegate) {
                 return [delegate conformsToProtocol:@protocol(PAGLAppOpenAdDelegate)];
               }]]);

  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, expectedError);
}

#pragma mark - Load Tests

- (void)testLoadRTBAdSuccess {
  NSData *watermarkData = [@"watermark" dataUsingEncoding:NSUTF8StringEncoding];
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                             isRTB:YES
                                                                         watermark:watermarkData];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_request);
  OCMVerifyAll(_ad);
}

- (void)testLoadWaterfallAdSuccess {
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                             isRTB:NO
                                                                         watermark:nil];
  XCTAssertNotNil(eventDelegate);

  OCMVerifyAll(_ad);
}

- (void)testLoadWaterfallAdWithWatermarkSuccess {
  NSData *watermarkData = [@"watermark" dataUsingEncoding:NSUTF8StringEncoding];
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
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
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                             isRTB:YES
                                                                         watermark:nil];
  XCTAssertNotNil(eventDelegate);
}

- (void)testLoadAdForChildAudienceWithTagForUnderAgeOfConsent {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorChildUser
                                                  userInfo:nil];
  [self loadAdFailureWithPlacementID:@"ID" isRTB:YES watermark:nil expectedError:expectedError];
}

- (void)testLoadAdForNonChildAudienceWithTagForUnderAgeOfConsent {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                             isRTB:YES
                                                                         watermark:nil];
  XCTAssertNotNil(eventDelegate);
}

- (void)testLoadAdForChildAudienceWithAgeRestrictedTreatment {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorChildUser
                                                  userInfo:nil];
  [self loadAdFailureWithPlacementID:@"ID" isRTB:YES watermark:nil expectedError:expectedError];
}

- (void)testLoadAdForNonChildAudienceWithAgeRestrictedTreatment {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                             isRTB:YES
                                                                         watermark:nil];
  XCTAssertNotNil(eventDelegate);
}

- (void)testLoadAdForNonChildAudienceWithAgeRestrictedTreatmentUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
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
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                             isRTB:YES
                                                                         watermark:nil];
  OCMStub([_ad presentFromRootViewController:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    id<PAGLAppOpenAdDelegate> adDelegate = (id<PAGLAppOpenAdDelegate>)eventDelegate.appOpenAd;
    [adDelegate adDidShow:self->_ad];
  });

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  [eventDelegate.appOpenAd presentFromViewController:[[UIViewController alloc] init]];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testAdDidShowFail {
  NSError *showError = [[NSError alloc] initWithDomain:@"pangle" code:12345 userInfo:nil];
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                             isRTB:YES
                                                                         watermark:nil];
  OCMStub([_ad presentFromRootViewController:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    id<PAGLAppOpenAdDelegate> adDelegate = (id<PAGLAppOpenAdDelegate>)eventDelegate.appOpenAd;
    [adDelegate adDidShowFail:self->_ad error:showError];
  });

  XCTAssertNil(eventDelegate.didFailToPresentError);
  [eventDelegate.appOpenAd presentFromViewController:[[UIViewController alloc] init]];
  XCTAssertEqualObjects(eventDelegate.didFailToPresentError, showError);
}

- (void)testAdDismiss {
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                             isRTB:YES
                                                                         watermark:nil];
  id<PAGLAppOpenAdDelegate> adDelegate = (id<PAGLAppOpenAdDelegate>)eventDelegate.appOpenAd;

  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);
  [adDelegate adDidDismiss:_ad];
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testClick {
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                             isRTB:YES
                                                                         watermark:nil];
  id<PAGLAppOpenAdDelegate> adDelegate = (id<PAGLAppOpenAdDelegate>)eventDelegate.appOpenAd;

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);
  [adDelegate adDidClick:_ad];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

@end
