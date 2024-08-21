#import "GADMediationAdapterAppLovin.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationInterstitialAdLoadAssertions.h>
#import <AppLovinSDK/AppLovinSDK.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinInterstitialDelegate.h"
#import "GADMAppLovinRTBInterstitialDelegate.h"

@interface AUTAppLovinInterstitialAdTests : XCTestCase
@end

@implementation AUTAppLovinInterstitialAdTests {
  /// An adapter instance that is used to test loading an ad.
  GADMediationAdapterAppLovin *_adapter;
  /// Mock for ALSdk.
  id _appLovinSdkMock;
  /// Mock for ALInterstitialAd
  id _interstitialAdMock;
  /// Mock for ALAdService
  id _serviceMock;

  /// An ad loader.
  __block GADMAppLovinRTBInterstitialDelegate *_adLoader;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterAppLovin alloc] init];
  // AppLovin expects an SDK Key of 86 characters
  NSString *sdkKey =
      @"12345678901234567890123456789012345678901234567890123456789012345678901234567890123456";

  _appLovinSdkMock = OCMClassMock([ALSdk class]);
  _interstitialAdMock = OCMClassMock([ALInterstitialAd class]);
  _serviceMock = OCMClassMock([ALAdService class]);

  OCMStub(ClassMethod([_appLovinSdkMock sharedWithKey:sdkKey
                                             settings:GADMediationAdapterAppLovin.SDKSettings]))
      .andReturn(_appLovinSdkMock);
  OCMStub([_interstitialAdMock alloc]).andReturn(_interstitialAdMock);
  OCMStub([_interstitialAdMock initWithSdk:_appLovinSdkMock]).andReturn(_interstitialAdMock);
  OCMStub([_appLovinSdkMock adService]).andReturn(_serviceMock);
}

- (nonnull AUTKMediationInterstitialAdEventDelegate *)loadAd {
  NSData *watermarkData = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];

  // Must pass through the enigma watermark.
  OCMExpect([_interstitialAdMock setExtraInfoForKey:@"google_watermark" value:watermarkData]);
  AUTKMediationInterstitialAdConfiguration *config =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];

  GADMediationAdapterAppLovin *adapter = [[GADMediationAdapterAppLovin alloc] init];

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  config.credentials = credentials;
  config.watermark = watermarkData;

  // AppLovin expects an SDK Key of 86 characters
  NSString *sdkKey =
      @"12345678901234567890123456789012345678901234567890123456789012345678901234567890123456";
  credentials.settings = @{@"sdkKey" : sdkKey};
  config.bidResponse = @"bidresponse";

  id adMock = OCMClassMock([ALAd class]);
  OCMStub([_serviceMock loadNextAdForAdToken:@"bidresponse"
                                   andNotify:[OCMArg checkWithBlock:^BOOL(id obj) {
                                     self->_adLoader = obj;
                                     return [obj
                                         isKindOfClass:[GADMAppLovinRTBInterstitialDelegate class]];
                                   }]])
      .andDo(^(NSInvocation *invocation) {
        [self->_adLoader adService:self->_serviceMock didLoadAd:adMock];
      });

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(adapter, config);
  XCTAssertNotNil(eventDelegate);
  OCMVerifyAll(_interstitialAdMock);

  return eventDelegate;
}

#pragma mark - Ad Load events

- (void)testLoadInterstitialAd {
  [self loadAd];
}

#pragma mark - Ad Lifecycle events

- (void)testAdShownEvents {
  AUTKMediationInterstitialAdEventDelegate *delegate = [self loadAd];
  [self->_adLoader ad:OCMOCK_ANY wasDisplayedIn:OCMOCK_ANY];
  XCTAssertTrue(delegate.willPresentFullScreenViewInvokeCount == 1);
  XCTAssertTrue(delegate.reportImpressionInvokeCount == 1);
}

- (void)testAdClickEvents {
  AUTKMediationInterstitialAdEventDelegate *delegate = [self loadAd];
  [self->_adLoader ad:OCMOCK_ANY wasClickedIn:OCMOCK_ANY];
  XCTAssertTrue(delegate.reportClickInvokeCount == 1);
}

- (void)testAdClosedEvents {
  AUTKMediationInterstitialAdEventDelegate *delegate = [self loadAd];
  [self->_adLoader ad:OCMOCK_ANY wasHiddenIn:OCMOCK_ANY];
  XCTAssertTrue(delegate.willDismissFullScreenViewInvokeCount == 1);
  XCTAssertTrue(delegate.didDismissFullScreenViewInvokeCount == 1);
}

- (void)testUnhandledAdEvents {
  // The following events are not handled by the GoogleMobileAds SDK's event delegate,
  // but verify invoking them does not crash the running app.
  [self loadAd];
  [self->_adLoader videoPlaybackBeganInAd:OCMOCK_ANY];
  [self->_adLoader videoPlaybackEndedInAd:OCMOCK_ANY
                        atPlaybackPercent:@98.0f
                             fullyWatched:OCMOCK_ANY];
}

@end
