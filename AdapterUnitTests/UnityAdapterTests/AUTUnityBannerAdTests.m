#import "GADMediationAdapterUnity.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationBannerAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <UnityAds/UnityAds.h>

#import "AUTUnityTestCase.h"
#import "GADMAdapterUnityConstants.h"

@interface AUTUnityBannerAdTests : AUTUnityTestCase
@end

@implementation AUTUnityBannerAdTests

- (void)testLoadWaterfallBannerAd {
  UADSBannerView *bannerView =
      OCMPartialMock([[UADSBannerView alloc] initWithPlacementId:AUTUnityPlacementID
                                                            size:GADAdSizeBanner.size]);
  OCMStub([OCMClassMock([UADSBannerView class]) alloc]).andReturn(bannerView);
  OCMStub([bannerView initWithPlacementId:AUTUnityPlacementID size:GADAdSizeBanner.size])
      .andReturn(bannerView);
  OCMStub([bannerView loadWithOptions:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [bannerView.delegate bannerViewDidLoad:bannerView];
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;
  AUTKWaitAndAssertLoadBannerAd(self.adapter, configuration);
  id<GADMediationBannerAd> bannerAd = (id<GADMediationBannerAd>)self.adapter;
  XCTAssertEqualObjects(bannerAd.view, bannerView);
}

- (void)testLoadBiddingBannerAd {
  UADSBannerView *bannerView =
      OCMPartialMock([[UADSBannerView alloc] initWithPlacementId:AUTUnityPlacementID
                                                            size:GADAdSizeBanner.size]);
  OCMStub([OCMClassMock([UADSBannerView class]) alloc]).andReturn(bannerView);
  OCMStub([bannerView initWithPlacementId:AUTUnityPlacementID size:GADAdSizeBanner.size])
      .andReturn(bannerView);
  OCMStub([bannerView loadWithOptions:[OCMArg checkWithBlock:^BOOL(id value) {
                        XCTAssertTrue([value isKindOfClass:[UADSLoadOptions class]]);
                        UADSLoadOptions *options = (UADSLoadOptions *)value;
                        return [options.adMarkup isEqualToString:AUTUnityBidResponse] &&
                               [options.dictionary[@"watermark"]
                                   isEqualToString:AUTUnityWatermarkBase64];
                      }]])
      .andDo(^(NSInvocation *invocation) {
        [bannerView.delegate bannerViewDidLoad:bannerView];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.bidResponse = AUTUnityBidResponse;
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;
  configuration.watermark = [[NSData alloc] initWithBase64EncodedString:AUTUnityWatermarkBase64
                                                                options:0];
  AUTKWaitAndAssertLoadBannerAd(self.adapter, configuration);
  id<GADMediationBannerAd> bannerAd = (id<GADMediationBannerAd>)self.adapter;
  XCTAssertEqualObjects(bannerAd.view, bannerView);
}

- (void)testLoadBiddingBannerAdWithEmptySignal {
  UADSBannerView *bannerView =
      OCMPartialMock([[UADSBannerView alloc] initWithPlacementId:AUTUnityPlacementID
                                                            size:GADAdSizeBanner.size]);
  OCMStub([OCMClassMock([UADSBannerView class]) alloc]).andReturn(bannerView);
  OCMStub([bannerView initWithPlacementId:AUTUnityPlacementID size:GADAdSizeBanner.size])
      .andReturn(bannerView);
  OCMStub([bannerView loadWithOptions:[OCMArg checkWithBlock:^BOOL(id value) {
                        XCTAssertTrue([value isKindOfClass:[UADSLoadOptions class]]);
                        UADSLoadOptions *options = (UADSLoadOptions *)value;
                        return [options.adMarkup isEqualToString:@""];
                      }]])
      .andDo(^(NSInvocation *invocation) {
        [bannerView.delegate bannerViewDidLoad:bannerView];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.bidResponse = @"";
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;
  AUTKWaitAndAssertLoadBannerAd(self.adapter, configuration);
  id<GADMediationBannerAd> bannerAd = (id<GADMediationBannerAd>)self.adapter;
  XCTAssertEqualObjects(bannerAd.view, bannerView);
}

- (void)testLoadBannerAdFailure {
  UADSBannerView *bannerView =
      OCMPartialMock([[UADSBannerView alloc] initWithPlacementId:AUTUnityPlacementID
                                                            size:GADAdSizeBanner.size]);
  OCMStub([OCMClassMock([UADSBannerView class]) alloc]).andReturn(bannerView);
  OCMStub([bannerView initWithPlacementId:AUTUnityPlacementID size:GADAdSizeBanner.size])
      .andReturn(bannerView);
  UADSBannerError *bannerLoadError =
      [[UADSBannerError alloc] initWithCode:UADSBannerErrorCodeNoFillError userInfo:nil];
  OCMStub([bannerView loadWithOptions:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [bannerView.delegate bannerViewDidError:bannerView error:bannerLoadError];
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;
  AUTKWaitAndAssertLoadBannerAdFailure(self.adapter, configuration, bannerLoadError);
}

- (void)testAdClick {
  UADSBannerView *bannerView =
      OCMPartialMock([[UADSBannerView alloc] initWithPlacementId:AUTUnityPlacementID
                                                            size:GADAdSizeBanner.size]);
  OCMStub([OCMClassMock([UADSBannerView class]) alloc]).andReturn(bannerView);
  OCMStub([bannerView initWithPlacementId:AUTUnityPlacementID size:GADAdSizeBanner.size])
      .andReturn(bannerView);
  OCMStub([bannerView loadWithOptions:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [bannerView.delegate bannerViewDidLoad:bannerView];
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;

  AUTKMediationBannerAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadBannerAd(self.adapter, configuration);

  // Simulate ad clicking.
  XCTAssertEqual(delegate.reportClickInvokeCount, 0);
  [bannerView.delegate bannerViewDidClick:bannerView];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);
}

- (void)testImpression {
  UADSBannerView *bannerView =
      OCMPartialMock([[UADSBannerView alloc] initWithPlacementId:AUTUnityPlacementID
                                                            size:GADAdSizeBanner.size]);
  OCMStub([OCMClassMock([UADSBannerView class]) alloc]).andReturn(bannerView);
  OCMStub([bannerView initWithPlacementId:AUTUnityPlacementID size:GADAdSizeBanner.size])
      .andReturn(bannerView);
  OCMStub([bannerView loadWithOptions:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [bannerView.delegate bannerViewDidLoad:bannerView];
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;

  AUTKMediationBannerAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadBannerAd(self.adapter, configuration);

  // Simulate ad clicking.
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 0);
  [bannerView.delegate bannerViewDidShow:bannerView];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);
}

@end
