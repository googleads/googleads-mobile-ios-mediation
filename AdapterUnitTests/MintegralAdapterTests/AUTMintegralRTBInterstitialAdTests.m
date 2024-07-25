#import "GADMediationAdapterMintegral.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationInterstitialAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <MTGSDK/MTGSDK.h>
#import <MTGSDKNewInterstitial/MTGNewInterstitialBidAdManager.h>
#import <MTGSDKNewInterstitial/MTGSDKNewInterstitial.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterMintegralConstants.h"

static NSString *const kPlacementID = @"12345";
static NSString *const kUnitID = @"67890";
static NSString *const kBidResponse = @"bidResponse";

@interface AUTMintegralRTBInterstitialAdTests : XCTestCase
@end

@implementation AUTMintegralRTBInterstitialAdTests {
  /// An adapter instance that is used to test loading an ad.
  GADMediationAdapterMintegral *_adapter;

  /// A mock instance of MTGNewInterstitialBidAdManager.
  id _interstitialAdMock;

  /// An ad loader.
  __block id<MTGNewInterstitialBidAdDelegate, GADMediationInterstitialAd> _adLoader;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterMintegral alloc] init];
  _interstitialAdMock = OCMClassMock([MTGNewInterstitialBidAdManager class]);
  OCMStub([_interstitialAdMock alloc]).andReturn(_interstitialAdMock);
  OCMStub(
      [_interstitialAdMock
          initWithPlacementId:kPlacementID
                       unitId:kUnitID
                     delegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                       self->_adLoader = obj;
                       return [obj conformsToProtocol:@protocol(MTGNewInterstitialBidAdDelegate)] &&
                              [obj conformsToProtocol:@protocol(GADMediationInterstitialAd)];
                     }]])
      .andReturn(_interstitialAdMock);
}

- (nonnull AUTKMediationInterstitialAdEventDelegate *)loadAd {
  NSData *watermarkData = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
  // Must pass through the enigma watermark.
  OCMExpect([_interstitialAdMock setExtraInfo:watermarkData forKey:@"admob_watermark"]);

  OCMStub([_interstitialAdMock loadAdWithBidToken:kBidResponse]).andDo(^(NSInvocation *invocation) {
    [self->_adLoader newInterstitialBidAdResourceLoadSuccess:self->_interstitialAdMock];
  });
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  configuration.watermark = watermarkData;

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);
  XCTAssertNotNil(_adLoader);

  [_interstitialAdMock verify];
  return eventDelegate;
}

- (void)testloadAd {
  [self loadAd];
}

- (void)testloadAdFailureForMissingPlacementID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
}

- (void)testloadAdFailureForMissingAdUnit {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralPlacementID : kPlacementID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadAdFailure {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorAdNotAvailable
                                                  userInfo:nil];
  OCMStub([_interstitialAdMock loadAdWithBidToken:kBidResponse]).andDo(^(NSInvocation *invocation) {
    [self->_adLoader newInterstitialBidAdLoadFail:expectedError
                                        adManager:self->_interstitialAdMock];
  });
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;

  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
  XCTAssertNotNil(_adLoader);
}

- (void)testShowSuccess {
  UIViewController *controller = [[UIViewController alloc] init];
  OCMStub([_interstitialAdMock showFromViewController:controller])
      .andDo(^(NSInvocation *invocation) {
        [self->_adLoader newInterstitialBidAdShowSuccess:self->_interstitialAdMock];
      });
  OCMStub([_interstitialAdMock isAdReady]).andReturn(YES);
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];
  // Assert the initial values of the counts before they are verified after the "Act" steps.
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);

  [_adLoader presentFromViewController:controller];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);

  [_adLoader newInterstitialBidAdDismissedWithConverted:YES adManager:_interstitialAdMock];
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);

  [_adLoader newInterstitialBidAdDidClosed:_interstitialAdMock];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testShowFailureForAdNotReadyToShow {
  OCMStub([_interstitialAdMock isAdReady]).andReturn(NO);
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];

  [_adLoader presentFromViewController:[[UIViewController alloc] init]];

  XCTAssertEqual(eventDelegate.didFailToPresentError.code, GADMintegralErrorAdFailedToShow);
}

- (void)testShowFailureForAdShowFail {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorAdFailedToShow
                                                  userInfo:nil];
  UIViewController *controller = [[UIViewController alloc] init];
  OCMStub([_interstitialAdMock showFromViewController:controller])
      .andDo(^(NSInvocation *invocation) {
        [self->_adLoader newInterstitialBidAdShowFail:expectedError
                                            adManager:self->_interstitialAdMock];
      });
  OCMStub([_interstitialAdMock isAdReady]).andReturn(YES);
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);

  [_adLoader presentFromViewController:controller];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqualObjects(eventDelegate.didFailToPresentError, expectedError);
}

- (void)testClick {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);

  [_adLoader newInterstitialBidAdClicked:_interstitialAdMock];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

@end
