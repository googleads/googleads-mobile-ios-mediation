#import "GADMediationAdapterChartboost.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationRewardedAdLoadAssertions.h>
#import <ChartboostSDK/ChartboostSDK.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#if __has_include(<ChartboostSDK/ChartboostSDK.h>)
#import <ChartboostSDK/ChartboostSDK.h>
#else
#import "ChartboostSDK.h"
#endif

#import "GADMAdapterChartboostConstants.h"

typedef void (^AUTChartboostSetUpCompletionBlock)(CHBStartError *);

@interface AUTChartboostRewardedAdTests : XCTestCase
@end

@implementation AUTChartboostRewardedAdTests {
  /// An adapter instance that is used to test loading an ad.
  GADMediationAdapterChartboost *_adapter;

  /// Class mock for the Chartboost singleton.
  id _mockChartboost;

  /// A mock instance of CHBRewarded.
  id _rewardedAdMock;

  /// The rewarded delegate that was passed to _rewardedAdMock.
  __block id<CHBRewardedDelegate, GADMediationRewardedAd> _rewardedDelegate;

  // The location argument that was passed to _rewardedAdMock.
  NSString *_observedLocation;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterChartboost alloc] init];
  _rewardedAdMock = OCMClassMock([CHBRewarded class]);
  OCMStub([_rewardedAdMock alloc]).andReturn(_rewardedAdMock);

  OCMStub([_rewardedAdMock initWithLocation:[OCMArg checkWithBlock:^BOOL(NSString *location) {
                             self->_observedLocation = location;
                             return YES;
                           }]
                                  mediation:OCMOCK_ANY
                                   delegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                                     self->_rewardedDelegate = obj;
                                     return YES;
                                   }]])
      .andReturn(_rewardedAdMock);
}

- (void)mockAppStartWithError:(nullable CHBStartError *)error {
  _mockChartboost = OCMClassMock([Chartboost class]);
  OCMStub(ClassMethod([_mockChartboost
      startWithAppID:@"app_id"
        appSignature:@"signature"
          completion:[OCMArg
                         checkWithBlock:^BOOL(AUTChartboostSetUpCompletionBlock completionBlock) {
                           completionBlock(error);
                           return YES;
                         }]]));
}

- (void)mockSuccessfulAppStart {
  [self mockAppStartWithError:nil];
}

- (void)mockFailedAppStart {
  CHBStartError *startError = [[CHBStartError alloc] initWithDomain:@"test_domain"
                                                               code:1
                                                           userInfo:nil];
  [self mockAppStartWithError:startError];
}

- (nonnull AUTKMediationRewardedAdEventDelegate *)loadAdWithLocation:(nonnull NSString *)location {
  OCMStub([_rewardedAdMock cache]).andDo(^(NSInvocation *invocation) {
    [self->_rewardedDelegate didCacheAd:[[CHBCacheEvent alloc] init] error:nil];
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : location,
    GADMAdapterChartboostAppID : @"app_id",
    GADMAdapterChartboostAppSignature : @"signature"
  };
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);
  XCTAssertNotNil(_rewardedDelegate);

  return eventDelegate;
}

- (void)testLoadAd {
  [self mockSuccessfulAppStart];
  [self loadAdWithLocation:@"ad_location"];
}

- (void)testLocation {
  [self mockSuccessfulAppStart];
  [self loadAdWithLocation:@"ad_location"];

  XCTAssertEqualObjects(_observedLocation, @"ad_location");
}

- (void)testDefaultLocation {
  [self mockSuccessfulAppStart];
  [self loadAdWithLocation:@""];

  XCTAssertEqualObjects(_observedLocation, @"Default");
}

- (void)testLoadFailure {
  [self mockSuccessfulAppStart];

  OCMStub([_rewardedAdMock cache]).andDo(^(NSInvocation *invocation) {
    CHBCacheError *error = [[CHBCacheError alloc] initWithDomain:@"domain" code:1 userInfo:nil];
    [self->_rewardedDelegate didCacheAd:[[CHBCacheEvent alloc] init] error:error];
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : @"ad_location",
    GADMAdapterChartboostAppID : @"app_id",
    GADMAdapterChartboostAppSignature : @"signature"
  };
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                                      code:201
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testAdDelegateCallbacks {
  [self mockSuccessfulAppStart];
  OCMStub([_rewardedAdMock isCached]).andReturn(YES);

  UIViewController *controller = [[UIViewController alloc] init];
  OCMStub([_rewardedAdMock showFromViewController:controller]).andDo(^(NSInvocation *invocation) {
    [self->_rewardedDelegate didShowAd:[[CHBShowEvent alloc] init] error:nil];
  });

  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadAdWithLocation:@"ad_location"];

  XCTAssertNil(eventDelegate.didFailToPresentError);

  [_rewardedDelegate presentFromViewController:controller];
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 1);

  [_rewardedDelegate willShowAd:OCMOCK_ANY];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);

  [_rewardedDelegate didRecordImpression:OCMOCK_ANY];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);

  [_rewardedDelegate didEarnReward:[[CHBRewardEvent alloc] init]];
  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 1);

  [_rewardedDelegate didClickAd:[[CHBClickEvent alloc] init] error:nil];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);

  [_rewardedDelegate didDismissAd:[[CHBDismissEvent alloc] init]];
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testPresentationError {
  [self mockSuccessfulAppStart];
  OCMStub([_rewardedAdMock isCached]).andReturn(YES);
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadAdWithLocation:@"ad_location"];
  UIViewController *controller = [[UIViewController alloc] init];
  OCMStub([_rewardedAdMock showFromViewController:controller]).andDo(^(NSInvocation *invocation) {
    CHBShowError *error = [[CHBShowError alloc] initWithDomain:@"domain" code:1 userInfo:nil];
    [self->_rewardedDelegate didShowAd:[[CHBShowEvent alloc] init] error:error];
  });

  [_rewardedDelegate presentFromViewController:controller];

  XCTAssertNotNil(eventDelegate.didFailToPresentError);
  XCTAssertEqual(eventDelegate.didFailToPresentError.code, 301);

  // Must not trigger any presentation callbacks.
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
}

- (void)testNotCachedError {
  [self mockSuccessfulAppStart];
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadAdWithLocation:@"ad_location"];
  UIViewController *controller = [[UIViewController alloc] init];
  [_rewardedDelegate presentFromViewController:controller];

  XCTAssertNotNil(eventDelegate.didFailToPresentError);
  XCTAssertEqual(eventDelegate.didFailToPresentError.code, GADMAdapterChartboostErrorAdNotCached);

  // Must not trigger any presentation callbacks.
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
}

- (void)testLoadAdFailsWhenStartFails {
  [self mockFailedAppStart];

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : @"ad_location",
    GADMAdapterChartboostAppID : @"app_id",
    GADMAdapterChartboostAppSignature : @"signature"
  };
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError = [[NSError alloc] initWithDomain:@"test_domain" code:1 userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testMissingAppID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : @"ad_location",
    GADMAdapterChartboostAppSignature : @"signature",
  };
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                 code:GADMAdapterChartboostErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testAppIDOnlyWhitespace {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : @"ad_location",
    GADMAdapterChartboostAppID : @"    ",
    GADMAdapterChartboostAppSignature : @"signature",
  };
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                 code:GADMAdapterChartboostErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testSignatureOnlyWhitespace {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : @"ad_location",
    GADMAdapterChartboostAppID : @"app_id",
    GADMAdapterChartboostAppSignature : @"    ",
  };
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                 code:GADMAdapterChartboostErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testMissingSignature {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : @"ad_location",
    GADMAdapterChartboostAppID : @"app_id",
  };
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                 code:GADMAdapterChartboostErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testLowSystemVersion {
  id mockDevice = OCMPartialMock(UIDevice.currentDevice);
  OCMStub([(UIDevice *)mockDevice systemVersion]).andReturn(@"10.0");

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : @"ad_location",
    GADMAdapterChartboostAppSignature : @"signature",
    GADMAdapterChartboostAppID : @"app_id",
  };
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                 code:GADMAdapterChartboostErrorMinimumOSVersion
                             userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

@end
