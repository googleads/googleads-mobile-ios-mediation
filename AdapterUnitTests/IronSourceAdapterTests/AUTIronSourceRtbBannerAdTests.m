#import <IronSource/IronSource.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "GADMAdapterIronSourceBannerAd.h"
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceRtbBannerAd.h"
#import "GADMAdapterIronSourceUtils.h"
#import "GADMediationAdapterIronSource.h"

@interface AUTIronSourceRtbBannerAdTests : XCTestCase

@property(nonatomic, strong) GADMAdapterIronSourceRtbBannerAd *adapter;
@property(nonatomic, strong) GADMediationBannerAdConfiguration *mockAdConfiguration;
@property(nonatomic, strong) id mockBannerAd;
@property(nonatomic, strong) id mockBannerAdEventDelegate;
@property(nonatomic, strong) id mockCredentials;
@property(nonatomic, strong) id mockISABannerAdLoader;

// Properties for GADMediationAdapterIronSource tests
@property(nonatomic, strong) GADMediationAdapterIronSource *mediationAdapter;
@property(nonatomic, strong) id mockRtbBannerAd;

@end

@implementation AUTIronSourceRtbBannerAdTests

- (void)setUp {
  [super setUp];
  self.adapter = [[GADMAdapterIronSourceRtbBannerAd alloc] init];
  self.mockAdConfiguration = OCMClassMock([GADMediationBannerAdConfiguration class]);
  self.mockBannerAd = OCMClassMock([ISABannerAdView class]);
  self.mockBannerAdEventDelegate = OCMProtocolMock(@protocol(GADMediationBannerAdEventDelegate));
  self.mockCredentials = OCMClassMock([GADMediationCredentials class]);
  self.mockISABannerAdLoader = OCMClassMock([ISABannerAdLoader class]);

  // Setup for GADMediationAdapterIronSource tests
  self.mediationAdapter = [[GADMediationAdapterIronSource alloc] init];
  self.mockRtbBannerAd = OCMClassMock([GADMAdapterIronSourceRtbBannerAd class]);
}

- (void)tearDown {
  [super tearDown];
}

- (void)testLoadBannerAdWithCustomInstanceId {
  // Given
  NSString *customInstanceId = @"customInstanceId";
  OCMStub([self.mockAdConfiguration credentials]).andReturn(self.mockCredentials);
  OCMStub([self.mockCredentials settings]).andReturn(@{
    GADMAdapterIronSourceInstanceId : customInstanceId
  });

  // When
  [self.adapter loadBannerAdForConfiguration:self.mockAdConfiguration
                           completionHandler:^id<GADMediationBannerAdEventDelegate>(
                               id<GADMediationBannerAd> ad, NSError *error) {
                             return nil;
                           }];

  // Then
  XCTAssertEqualObjects(self.adapter.instanceID, customInstanceId);
}

- (void)testLoadBannerAdWithDefaultInstanceId {
  // Given
  OCMStub([self.mockAdConfiguration credentials]).andReturn(self.mockCredentials);
  OCMStub([self.mockCredentials settings]).andReturn(@{});

  // When
  [self.adapter loadBannerAdForConfiguration:self.mockAdConfiguration
                           completionHandler:^id<GADMediationBannerAdEventDelegate>(
                               id<GADMediationBannerAd> ad, NSError *error) {
                             return nil;
                           }];

  // Then
  XCTAssertEqualObjects(self.adapter.instanceID, GADMIronSourceDefaultRtbInstanceId);
}

- (void)testLoadBannerAdCallsISABannerAdLoader {
  // Given
  OCMStub([self.mockAdConfiguration credentials]).andReturn(self.mockCredentials);
  OCMStub([self.mockCredentials settings]).andReturn(@{});

  // When
  [self.adapter loadBannerAdForConfiguration:self.mockAdConfiguration
                           completionHandler:^id<GADMediationBannerAdEventDelegate>(
                               id<GADMediationBannerAd> ad, NSError *error) {
                             return nil;
                           }];

  // Then
  OCMVerify([self.mockISABannerAdLoader loadAdWithAdRequest:[OCMArg any] delegate:[OCMArg any]]);
}

- (void)testBannerAdDidLoad {
  // Given
  __block BOOL completionHandlerCalled = NO;
  __weak typeof(self) weakSelf = self;
  self.adapter.bannerAdLoadCompletionHandler =
      ^id<GADMediationBannerAdEventDelegate>(id<GADMediationBannerAd> ad, NSError *error) {
    completionHandlerCalled = YES;
    return weakSelf.mockBannerAdEventDelegate;
  };

  // When
  [self.adapter bannerAdDidLoad:self.mockBannerAd];

  // Then
  XCTAssertTrue(completionHandlerCalled);
  XCTAssertEqual(self.adapter.biddingISABannerAd, self.mockBannerAd);
  XCTAssertNotNil(self.adapter.bannerAdEventDelegate);
}

- (void)testBannerAdDidFailToLoad {
  // Given
  NSError *testError = [NSError errorWithDomain:@"TestDomain" code:1 userInfo:nil];
  __block BOOL completionHandlerCalled = NO;
  self.adapter.bannerAdLoadCompletionHandler =
      ^id<GADMediationBannerAdEventDelegate>(id<GADMediationBannerAd> ad, NSError *error) {
    completionHandlerCalled = YES;
    XCTAssertNil(ad);
    XCTAssertEqual(error, testError);
    return nil;
  };

  // When
  [self.adapter bannerAdDidFailToLoadWithError:testError];

  // Then
  XCTAssertTrue(completionHandlerCalled);
}

- (void)testBannerAdViewDidShow {
  // Given
  self.adapter.bannerAdEventDelegate = self.mockBannerAdEventDelegate;

  // When
  [self.adapter bannerAdViewDidShow:self.mockBannerAd];

  // Then
  OCMVerify([self.mockBannerAdEventDelegate reportImpression]);
}

- (void)testBannerAdViewDidClick {
  // Given
  self.adapter.bannerAdEventDelegate = self.mockBannerAdEventDelegate;

  // When
  [self.adapter bannerAdViewDidClick:self.mockBannerAd];

  // Then
  OCMVerify([self.mockBannerAdEventDelegate reportClick]);
}

- (void)testView {
  // Given
  self.adapter.biddingISABannerAd = self.mockBannerAd;

  // When
  UIView *returnedView = [self.adapter view];

  // Then
  XCTAssertEqual(returnedView, self.mockBannerAd);
}

// Tests for GADMediationAdapterIronSource
- (void)testLoadBannerWithBidResponse {
  // Given
  OCMStub([self.mockAdConfiguration bidResponse]).andReturn(@"bidResponse");
  id mockRtbBannerAd = OCMClassMock([GADMAdapterIronSourceRtbBannerAd class]);
  OCMStub([mockRtbBannerAd alloc]).andReturn(mockRtbBannerAd);

  // Expect
  OCMExpect([mockRtbBannerAd loadBannerAdForConfiguration:self.mockAdConfiguration
                                        completionHandler:[OCMArg any]]);

  // When
  [self.mediationAdapter loadBannerForAdConfiguration:self.mockAdConfiguration
                                    completionHandler:^id<GADMediationBannerAdEventDelegate>(
                                        id<GADMediationBannerAd> ad, NSError *error) {
                                      return nil;
                                    }];

  // Then
  OCMVerifyAll(mockRtbBannerAd);
  XCTAssertNotNil(self.mediationAdapter.rtbBannerAd);
}

- (void)testLoadBannerWithoutBidResponse {
  // Given
  OCMStub([self.mockAdConfiguration bidResponse]).andReturn(nil);
  id mockBannerAd = OCMClassMock([GADMAdapterIronSourceBannerAd class]);
  OCMStub([mockBannerAd alloc]).andReturn(mockBannerAd);

  // Expect
  OCMExpect([mockBannerAd loadBannerAdForAdConfiguration:self.mockAdConfiguration
                                       completionHandler:[OCMArg any]]);

  // When
  [self.mediationAdapter loadBannerForAdConfiguration:self.mockAdConfiguration
                                    completionHandler:^id<GADMediationBannerAdEventDelegate>(
                                        id<GADMediationBannerAd> ad, NSError *error) {
                                      return nil;
                                    }];

  // Then
  OCMVerifyAll(mockBannerAd);
  XCTAssertNil(self.mediationAdapter.rtbBannerAd);
}

- (void)testLoadBannerCompletionHandlerCalled {
  // Given
  OCMStub([self.mockAdConfiguration bidResponse]).andReturn(nil);

  XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];

  // When
  [self.mediationAdapter loadBannerForAdConfiguration:self.mockAdConfiguration
                                    completionHandler:^id<GADMediationBannerAdEventDelegate>(
                                        id<GADMediationBannerAd> ad, NSError *error) {
                                      [expectation fulfill];
                                      return nil;
                                    }];

  // Then
  [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

@end
