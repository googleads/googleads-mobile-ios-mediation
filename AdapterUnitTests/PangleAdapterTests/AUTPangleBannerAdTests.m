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

  /// Mock for PAGSdk;
  id _sdkMock;

  /// Mock for PAGBannerRequest.
  id _request;

  /// Mock for PAGBannerAd.
  id _ad;

  /// Adapter under tests.
  GADMediationAdapterPangle *_adapter;
}

- (void)setUp {
  _configMock = OCMClassMock([PAGConfig class]);
  _sdkMock = OCMClassMock([PAGSdk class]);
  _request = OCMClassMock([PAGBannerRequest class]);
  _ad = OCMClassMock([PAGBannerAd class]);
  OCMStub(ClassMethod([_sdkMock initializationState])).andReturn(PAGSDKInitializationStateReady);
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

- (nonnull AUTKMediationBannerAdEventDelegate *)loadAdWithPlacementID:
                                                    (nullable NSString *)placementID
                                                               adSize:(GADAdSize)adSize {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterPanglePlacementID : placementID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = @"bidResponse";
  configuration.adSize = adSize;
  NSString *watermarkString = @"watermark";
  NSData *watermarkData = [watermarkString dataUsingEncoding:NSUTF8StringEncoding];
  configuration.watermark = watermarkData;
  OCMExpect([_request setAdString:@"bidResponse"]);
  OCMExpect([_request setExtraInfo:@{@"admob_watermark" : watermarkData}]);
  OCMExpect(ClassMethod([_ad loadAdWithSlotID:placementID
                                      request:_request
                            completionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(PAGBannerAd *_Nullable BannerAd,
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
                       expectedError:(nonnull NSError *)expectedError {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterPanglePlacementID : placementID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = @"bidResponse";
  configuration.adSize = adSize;
  NSString *watermarkString = @"watermark";
  NSData *watermarkData = [watermarkString dataUsingEncoding:NSUTF8StringEncoding];
  configuration.watermark = watermarkData;
  OCMStub(ClassMethod([_ad loadAdWithSlotID:placementID
                                    request:_request
                          completionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(PAGBannerAd *_Nullable BannerAd,
                                                      NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:4];
        completionHandler(nil, expectedError);
      });
  OCMStub([_ad setDelegate:[OCMArg checkWithBlock:^BOOL(id delegate) {
                 return [delegate conformsToProtocol:@protocol(PAGBannerAdDelegate)];
               }]]);

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadAdWithSize320x50 {
  OCMExpect(ClassMethod([_request requestWithBannerSize:kPAGBannerSize320x50])).andReturn(_request);
  OCMExpect([_configMock setChildDirected:PAGChildDirectedTypeDefault]);

  [self loadAdWithPlacementID:@"ID" adSize:GADAdSizeBanner];
}

- (void)testLoadAdWithSize320x50ForChildAudience {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  OCMExpect([_configMock setChildDirected:PAGChildDirectedTypeChild]);
  OCMExpect(ClassMethod([_request requestWithBannerSize:kPAGBannerSize320x50])).andReturn(_request);

  [self loadAdWithPlacementID:@"ID" adSize:GADAdSizeBanner];
}

- (void)testLoadAdWithSize320x50ForNonChildAudience {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect([_configMock setChildDirected:PAGChildDirectedTypeNonChild]);
  OCMExpect(ClassMethod([_request requestWithBannerSize:kPAGBannerSize320x50])).andReturn(_request);

  [self loadAdWithPlacementID:@"ID" adSize:GADAdSizeBanner];
}

- (void)testLoadAdWithSize728x90 {
  OCMExpect(ClassMethod([_request requestWithBannerSize:kPAGBannerSize728x90])).andReturn(_request);

  [self loadAdWithPlacementID:@"ID" adSize:GADAdSizeLeaderboard];
}

- (void)testLoadAdWithSize300x250 {
  OCMExpect(ClassMethod([_request requestWithBannerSize:kPAGBannerSize300x250]))
      .andReturn(_request);

  [self loadAdWithPlacementID:@"ID" adSize:GADAdSizeMediumRectangle];
}

- (void)testLoadFailureWithUnsupportedAdSize {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorBannerSizeMismatch
                                                  userInfo:nil];
  [self loadAdFailureWithPlacementID:@"ID" adSize:GADAdSizeSkyscraper expectedError:expectedError];
}

- (void)testLoadFailureWithEmptyPlacementID {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterPangleErrorDomain
                                                      code:GADPangleErrorInvalidServerParameters
                                                  userInfo:nil];
  [self loadAdFailureWithPlacementID:@"" adSize:GADAdSizeBanner expectedError:expectedError];
}

- (void)testLoadFailureWithNoAdFromPangle {
  OCMStub(ClassMethod([_request requestWithBannerSize:kPAGBannerSize320x50])).andReturn(_request);
  NSError *expectedError = [[NSError alloc] initWithDomain:@"pangle" code:12345 userInfo:nil];
  [self loadAdFailureWithPlacementID:@"ID" adSize:GADAdSizeBanner expectedError:expectedError];
}

- (void)testClick {
  OCMStub(ClassMethod([_request requestWithBannerSize:kPAGBannerSize320x50])).andReturn(_request);
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                           adSize:GADAdSizeBanner];
  id<PAGBannerAdDelegate> adDelegate = (id<PAGBannerAdDelegate>)eventDelegate.bannerAd;

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);
  [adDelegate adDidClick:_ad];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testAdDidShow {
  OCMStub(ClassMethod([_request requestWithBannerSize:kPAGBannerSize320x50])).andReturn(_request);
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadAdWithPlacementID:@"ID"
                                                                           adSize:GADAdSizeBanner];
  id<PAGBannerAdDelegate> adDelegate = (id<PAGBannerAdDelegate>)eventDelegate.bannerAd;

  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  [adDelegate adDidShow:_ad];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

@end
