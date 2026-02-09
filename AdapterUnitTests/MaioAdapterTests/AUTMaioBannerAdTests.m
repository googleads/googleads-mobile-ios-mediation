#import "GADMediationAdapterMaio.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationBannerAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <Maio/Maio-Swift.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterMaioBannerAd.h"
#import "GADMMaioConstants.h"

static const NSInteger kMaioLoadFailureErroCode = 10000;
static const NSInteger kMaioShowFailureErroCode = 20000;
static const NSInteger kMaioUnknownFailureErroCode = 99999;

@interface AUTMaioBannerAdTests : XCTestCase
@end

@implementation AUTMaioBannerAdTests {
  /// The adapte under test.
  GADMediationAdapterMaio *_adapter;

  /// Mock for MaioBannerView.
  id _bannerMock;
}

- (void)setUp {
  _adapter = [[GADMediationAdapterMaio alloc] init];
  _bannerMock = OCMClassMock([MaioBannerView class]);
  OCMStub([_bannerMock alloc]).andReturn(_bannerMock);
}

- (void)tearDown {
  OCMVerifyAll(_bannerMock);
}

- (AUTKMediationBannerAdEventDelegate *)loadBannerAd {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMMaioAdapterZoneIdKey : @"zoneID"};
  AUTKMediationBannerAdConfiguration *config =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  config.credentials = credentials;
  config.adSize = GADAdSizeBanner;
  config.isTestRequest = YES;

  OCMExpect([_bannerMock initWithZoneId:@"zoneID" size:MaioBannerSize.banner]).andReturn(_bannerMock);
  OCMStub([_bannerMock setDelegate:[OCMArg checkWithBlock:^BOOL(id obj) {
    if ([obj conformsToProtocol:@protocol(MaioBannerDelegate)]) {
      id<MaioBannerDelegate> maioDelegate = obj;
      [maioDelegate didLoad:self->_bannerMock];
      return YES;
    }
    return NO;
  }]]);

  AUTKMediationBannerAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, config);
  XCTAssertNotNil(delegate);

  return delegate;
}

- (void)loadBannerAdFailureWithInvalidAdSize {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMMaioAdapterZoneIdKey : @"zoneID"};
  AUTKMediationBannerAdConfiguration *config =
    [[AUTKMediationBannerAdConfiguration alloc] init];
  config.credentials = credentials;
  config.isTestRequest = YES;

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMMaioSDKErrorDomain
                                                      code:0
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, config, expectedError);
}

- (void)loadBannerAdFailureWithErrorCode:(NSInteger)errorCode {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMMaioAdapterZoneIdKey : @"zoneID"};
  AUTKMediationBannerAdConfiguration *config =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  config.credentials = credentials;
  config.adSize = GADAdSizeBanner;
  config.isTestRequest = YES;

  OCMExpect([_bannerMock initWithZoneId:@"zoneID" size:MaioBannerSize.banner]).andReturn(_bannerMock);
  OCMStub([_bannerMock setDelegate:[OCMArg checkWithBlock:^BOOL(id obj) {
    if ([obj conformsToProtocol:@protocol(MaioBannerDelegate)]) {
      id<MaioBannerDelegate> maioDelegate = obj;
      [maioDelegate didFailToLoad:self->_bannerMock errorCode:errorCode];
      return YES;
    }
    return NO;
  }]]);

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMMaioSDKErrorDomain
                                                      code:errorCode
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, config, expectedError);
}

- (void)testLoadBannerAd {
  [self loadBannerAd];
}

- (void)testLoadFailureWithInvalidAdSize {
  [self loadBannerAdFailureWithInvalidAdSize];
}

- (void)testMaioAdLoadFailure {
  [self loadBannerAdFailureWithErrorCode:kMaioLoadFailureErroCode];
}

- (void)testMaioUnknownFailure {
  [self loadBannerAdFailureWithErrorCode:kMaioUnknownFailureErroCode];
}

- (void)testAdDidShow {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAd];
  id<MaioBannerDelegate> adDelegate = (id<MaioBannerDelegate>)eventDelegate.bannerAd;

  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  [adDelegate didMakeImpression:_bannerMock];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testAdDidClick {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAd];
  id<MaioBannerDelegate> adDelegate = (id<MaioBannerDelegate>)eventDelegate.bannerAd;

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);
  [adDelegate didClick:_bannerMock];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

@end
