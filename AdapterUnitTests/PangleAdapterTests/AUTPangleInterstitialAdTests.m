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

  /// Mock for PAGSdk;
  id _sdkMock;

  /// Mock for PAGInterstitialRequest.
  id _request;

  /// Mock for PAGLInterstitialAd.
  id _ad;

  /// Adapter under tests.
  GADMediationAdapterPangle *_adapter;
}

- (void)setUp {
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
  OCMVerifyAll(_configMock);
  OCMVerifyAll(_sdkMock);
  OCMVerifyAll(_request);
  OCMVerifyAll(_ad);
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
}

- (nonnull AUTKMediationInterstitialAdEventDelegate *)loadAdWithPlacementID:
    (nullable NSString *)placementID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterPanglePlacementID : placementID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = @"bidResponse";
  NSString *watermarkString = @"watermark";
  NSData *watermarkData = [watermarkString dataUsingEncoding:NSUTF8StringEncoding];
  configuration.watermark = watermarkData;
  OCMExpect([_request setAdString:@"bidResponse"]);
  OCMExpect([_request setExtraInfo:@{@"admob_watermark" : watermarkData}]);
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
                       expectedError:(nonnull NSError *)expectedError {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterPanglePlacementID : placementID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = @"bidResponse";
  NSString *watermarkString = @"watermark";
  NSData *watermarkData = [watermarkString dataUsingEncoding:NSUTF8StringEncoding];
  configuration.watermark = watermarkData;
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

- (void)testLoadAd {
  OCMExpect([_configMock setChildDirected:PAGChildDirectedTypeDefault]);

  [self loadAdWithPlacementID:@"ID"];
}

- (void)testLoadAdForChildAudience {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  OCMExpect([_configMock setChildDirected:PAGChildDirectedTypeChild]);

  [self loadAdWithPlacementID:@"ID"];
}

- (void)testLoadAdForNonChildAudience {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect([_configMock setChildDirected:PAGChildDirectedTypeNonChild]);

  [self loadAdWithPlacementID:@"ID"];
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

- (void)testAdDidShow {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"];
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
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"];
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
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"];
  id<PAGLInterstitialAdDelegate> adDelegate =
      (id<PAGLInterstitialAdDelegate>)eventDelegate.interstitialAd;

  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);
  [adDelegate adDidDismiss:_ad];
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testClick {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"];
  id<PAGLInterstitialAdDelegate> adDelegate =
      (id<PAGLInterstitialAdDelegate>)eventDelegate.interstitialAd;

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);
  [adDelegate adDidClick:_ad];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

@end
