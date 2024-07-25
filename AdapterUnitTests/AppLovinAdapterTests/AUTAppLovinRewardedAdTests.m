#import "GADMediationAdapterAppLovin.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationRewardedAdLoadAssertions.h>
#import <AppLovinSDK/AppLovinSDK.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterAppLovinConstant.h"
#import "GADMAppLovinRewardedDelegate.h"

@interface AUTAppLovinRewardedAdTests : XCTestCase
@end

@implementation AUTAppLovinRewardedAdTests {
  /// An adapter instance that is used to test loading an ad.
  GADMediationAdapterAppLovin *_adapter;
  /// Mock for ALSdk.
  id _appLovinSdkMock;
  /// Mock for ALIncentivizedInterstitialAd.
  id _rewardedAdMock;
  /// Mock for ALAdService
  id _serviceMock;

  /// An ad loader.
  __block GADMAppLovinRewardedDelegate *_adLoader;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterAppLovin alloc] init];
  // AppLovin expects an SDK Key of 86 characters
  NSString *sdkKey =
      @"12345678901234567890123456789012345678901234567890123456789012345678901234567890123456";

  _appLovinSdkMock = OCMClassMock([ALSdk class]);
  _rewardedAdMock = OCMClassMock([ALIncentivizedInterstitialAd class]);
  _serviceMock = OCMClassMock([ALAdService class]);

  OCMStub(ClassMethod([_appLovinSdkMock sharedWithKey:sdkKey
                                             settings:GADMediationAdapterAppLovin.SDKSettings]))
      .andReturn(_appLovinSdkMock);
  OCMStub([_rewardedAdMock alloc]).andReturn(_rewardedAdMock);
  OCMStub([_rewardedAdMock initWithSdk:_appLovinSdkMock]).andReturn(_rewardedAdMock);
  OCMStub([_appLovinSdkMock adService]).andReturn(_serviceMock);
}

- (nonnull AUTKMediationRewardedAdEventDelegate *)loadAd {
  NSData *watermarkData = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];

  // Must pass through the enigma watermark.
  OCMExpect([_rewardedAdMock setExtraInfoForKey:@"google_watermark" value:watermarkData]);
  AUTKMediationRewardedAdConfiguration *config =
      [[AUTKMediationRewardedAdConfiguration alloc] init];

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
                                     return
                                         [obj isKindOfClass:[GADMAppLovinRewardedDelegate class]];
                                   }]])
      .andDo(^(NSInvocation *invocation) {
        [self->_adLoader adService:self->_serviceMock didLoadAd:adMock];
      });

  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(adapter, config);
  XCTAssertNotNil(eventDelegate);
  OCMVerifyAll(_rewardedAdMock);

  return eventDelegate;
}

#pragma mark - Ad Load events

- (void)testLoadRewardedAd {
  [self loadAd];
}

- (void)testMultipleAdsDisabled {
  GADMediationAdapterAppLovin *adapter = [[GADMediationAdapterAppLovin alloc] init];
  AUTKMediationRewardedAdConfiguration *config =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  config.credentials = credentials;

  // AppLovin expects an SDK Key of 86 characters
  NSString *sdkKey =
      @"12345678901234567890123456789012345678901234567890123456789012345678901234567890123456";
  // AppLovin expects a zone ID of 16 characters
  NSString *zoneID = @"1234567890123456";
  credentials.settings =
      @{@"sdkKey" : sdkKey, @"zone_id" : zoneID, @"enable_multiple_ads_per_unit" : @"false"};

  id adMock = OCMClassMock([ALAd class]);
  OCMStub([_serviceMock loadNextAdForZoneIdentifier:zoneID
                                          andNotify:[OCMArg checkWithBlock:^BOOL(id obj) {
                                            self->_adLoader = obj;
                                            return [obj
                                                isKindOfClass:[GADMAppLovinRewardedDelegate class]];
                                          }]])
      .andDo(^(NSInvocation *invocation) {
        [self->_adLoader adService:self->_serviceMock didLoadAd:adMock];
      });
  OCMStub([_appLovinSdkMock initializeSdkWithCompletionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(ALSdkConfiguration *configuration);
        [invocation getArgument:&completionHandler atIndex:2];
        completionHandler(nil);
      });

  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(adapter, config);
  XCTAssertNotNil(eventDelegate);

  // Load should fail after displaying an ad.
  [eventDelegate.rewardedAd presentFromViewController:[[UIViewController alloc] init]];
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterAppLovinErrorDomain
                                                      code:GADMAdapterAppLovinErrorAdAlreadyLoaded
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(adapter, config, expectedError);
}

- (void)testMultipleAdsEnabled {
  GADMediationAdapterAppLovin *adapter = [[GADMediationAdapterAppLovin alloc] init];
  AUTKMediationRewardedAdConfiguration *config =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  config.credentials = credentials;

  // AppLovin expects an SDK Key of 86 characters
  NSString *sdkKey =
      @"12345678901234567890123456789012345678901234567890123456789012345678901234567890123456";
  // AppLovin expects a zone ID of 16 characters
  NSString *zoneID = @"1234567890123456";
  credentials.settings =
      @{@"sdkKey" : sdkKey, @"zone_id" : zoneID, @"enable_multiple_ads_per_unit" : @"true"};

  id adMock = OCMClassMock([ALAd class]);
  OCMStub([_serviceMock loadNextAdForZoneIdentifier:zoneID
                                          andNotify:[OCMArg checkWithBlock:^BOOL(id obj) {
                                            self->_adLoader = obj;
                                            return [obj
                                                isKindOfClass:[GADMAppLovinRewardedDelegate class]];
                                          }]])
      .andDo(^(NSInvocation *invocation) {
        [self->_adLoader adService:self->_serviceMock didLoadAd:adMock];
      });
  OCMStub([_appLovinSdkMock initializeSdkWithCompletionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(ALSdkConfiguration *configuration);
        [invocation getArgument:&completionHandler atIndex:2];
        completionHandler(nil);
      });

  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(adapter, config);
  XCTAssertNotNil(eventDelegate);

  // Load should succeed after previous ad load.
  eventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, config);
  XCTAssertNotNil(eventDelegate);
}

#pragma mark - Ad Lifecycle events

- (void)testAdShownEvents {
  AUTKMediationRewardedAdEventDelegate *delegate = [self loadAd];
  [self->_adLoader ad:OCMOCK_ANY wasDisplayedIn:OCMOCK_ANY];
  XCTAssertTrue(delegate.willPresentFullScreenViewInvokeCount == 1);
  XCTAssertTrue(delegate.reportImpressionInvokeCount == 1);
}

- (void)testAdClickEvents {
  AUTKMediationRewardedAdEventDelegate *delegate = [self loadAd];
  [self->_adLoader ad:OCMOCK_ANY wasClickedIn:OCMOCK_ANY];
  XCTAssertTrue(delegate.reportClickInvokeCount == 1);
}

- (void)testAdClosedEvents {
  AUTKMediationRewardedAdEventDelegate *delegate = [self loadAd];
  [self->_adLoader ad:OCMOCK_ANY wasHiddenIn:OCMOCK_ANY];
  XCTAssertTrue(delegate.willDismissFullScreenViewInvokeCount == 1);
  XCTAssertTrue(delegate.didDismissFullScreenViewInvokeCount == 1);
}

- (void)testAdVideoStartEvents {
  AUTKMediationRewardedAdEventDelegate *delegate = [self loadAd];
  [self->_adLoader videoPlaybackBeganInAd:OCMOCK_ANY];
  XCTAssertTrue(delegate.didStartVideoInvokeCount == 1);
}

- (void)testAdVideoEndEvents {
  AUTKMediationRewardedAdEventDelegate *delegate = [self loadAd];
  [self->_adLoader videoPlaybackEndedInAd:OCMOCK_ANY
                        atPlaybackPercent:@98.0f
                             fullyWatched:OCMOCK_ANY];
  XCTAssertTrue(delegate.didEndVideoInvokeCount == 1);
}

- (void)testAdRewardedEvents {
  AUTKMediationRewardedAdEventDelegate *delegate = [self loadAd];
  [self->_adLoader videoPlaybackEndedInAd:OCMOCK_ANY atPlaybackPercent:@98.0f fullyWatched:YES];
  [self->_adLoader ad:OCMOCK_ANY wasHiddenIn:OCMOCK_ANY];
  XCTAssertTrue(delegate.didRewardUserInvokeCount == 1);
}

- (void)testAdDidNotRewardEvents {
  AUTKMediationRewardedAdEventDelegate *delegate = [self loadAd];
  [self->_adLoader videoPlaybackEndedInAd:OCMOCK_ANY atPlaybackPercent:@50.0f fullyWatched:NO];
  [self->_adLoader ad:OCMOCK_ANY wasHiddenIn:OCMOCK_ANY];
  XCTAssertTrue(delegate.didRewardUserInvokeCount == 0);
}

- (void)testUnhandledAdEvents {
  // The following events are not handled by the GoogleMobileAds SDK's event delegate,
  // but verify invoking them does not crash the running app.
  [self loadAd];

  NSDictionary<NSString *, NSString *> *successResponse =
      @{@"currency" : @"reward", @"amount" : @"20"};
  [self->_adLoader rewardValidationRequestForAd:OCMOCK_ANY didSucceedWithResponse:successResponse];
  [self->_adLoader rewardValidationRequestForAd:OCMOCK_ANY didFailWithError:9001];

  NSDictionary<NSString *, NSString *> *quotaResponse = @{@"response" : @"unknown"};
  [self->_adLoader rewardValidationRequestForAd:OCMOCK_ANY
                     didExceedQuotaWithResponse:quotaResponse];
  [self->_adLoader rewardValidationRequestForAd:OCMOCK_ANY wasRejectedWithResponse:quotaResponse];
}

@end
