#import "GADMediationAdapterChartboost.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationInterstitialAdLoadAssertions.h>
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

@interface AUTChartboostInterstitialAdTests : XCTestCase
@end

@implementation AUTChartboostInterstitialAdTests {
  /// An adapter instance that is used to test loading an ad.
  GADMediationAdapterChartboost *_adapter;

  /// Class mock for the Chartboost singleton.
  id _mockChartboost;

  /// A mock instance of CHBInterstitial.
  id _interstitialAdMock;

  /// The interstitial delegate that was passed to _interstitialAdMock.
  __block id<CHBInterstitialDelegate, GADMediationInterstitialAd> _interstitialDelegate;

  // The location argument that was passed to _interstitialAdMock.
  NSString *_observedLocation;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterChartboost alloc] init];
  _interstitialAdMock = OCMClassMock([CHBInterstitial class]);
  OCMStub([_interstitialAdMock alloc]).andReturn(_interstitialAdMock);

  OCMStub([_interstitialAdMock initWithLocation:[OCMArg checkWithBlock:^BOOL(NSString *location) {
                                 self->_observedLocation = location;
                                 return YES;
                               }]
                                      mediation:OCMOCK_ANY
                                       delegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                                         self->_interstitialDelegate = obj;
                                         return YES;
                                       }]])
      .andReturn(_interstitialAdMock);
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

- (nonnull AUTKMediationInterstitialAdEventDelegate *)loadAdWithLocation:
    (nonnull NSString *)location {
  OCMStub([_interstitialAdMock cache]).andDo(^(NSInvocation *invocation) {
    [self->_interstitialDelegate didCacheAd:[[CHBCacheEvent alloc] init] error:nil];
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : location,
    GADMAdapterChartboostAppID : @"app_id",
    GADMAdapterChartboostAppSignature : @"signature"
  };
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);
  XCTAssertNotNil(_interstitialDelegate);

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

  OCMStub([_interstitialAdMock cache]).andDo(^(NSInvocation *invocation) {
    CHBCacheError *error = [[CHBCacheError alloc] initWithDomain:@"domain" code:1 userInfo:nil];
    [self->_interstitialDelegate didCacheAd:[[CHBCacheEvent alloc] init] error:error];
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : @"ad_location",
    GADMAdapterChartboostAppID : @"app_id",
    GADMAdapterChartboostAppSignature : @"signature"
  };
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                                      code:201
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
}

- (void)testPresentation {
  [self mockSuccessfulAppStart];
  OCMStub([_interstitialAdMock isCached]).andReturn(YES);
  UIViewController *controller = [[UIViewController alloc] init];
  OCMStub([_interstitialAdMock showFromViewController:controller])
      .andDo(^(NSInvocation *invocation) {
        [self->_interstitialDelegate didShowAd:[[CHBShowEvent alloc] init] error:nil];
      });

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadAdWithLocation:@"ad_location"];

  [_interstitialDelegate willShowAd:OCMOCK_ANY];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);

  [_interstitialDelegate presentFromViewController:controller];
  XCTAssertNil(eventDelegate.didFailToPresentError);

  [_interstitialDelegate didRecordImpression:OCMOCK_ANY];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testDismiss {
  [self mockSuccessfulAppStart];
  OCMStub([_interstitialAdMock isCached]).andReturn(YES);

  UIViewController *controller = [[UIViewController alloc] init];
  OCMStub([_interstitialAdMock showFromViewController:controller])
      .andDo(^(NSInvocation *invocation) {
        [self->_interstitialDelegate didShowAd:[[CHBShowEvent alloc] init] error:nil];
      });

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadAdWithLocation:@"ad_location"];
  [_interstitialDelegate didDismissAd:[[CHBDismissEvent alloc] init]];

  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testClick {
  [self mockSuccessfulAppStart];
  OCMStub([_interstitialAdMock isCached]).andReturn(YES);

  UIViewController *controller = [[UIViewController alloc] init];
  OCMStub([_interstitialAdMock showFromViewController:controller])
      .andDo(^(NSInvocation *invocation) {
        [self->_interstitialDelegate didShowAd:[[CHBShowEvent alloc] init] error:nil];
      });

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadAdWithLocation:@"ad_location"];
  [_interstitialDelegate didClickAd:[[CHBClickEvent alloc] init] error:nil];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testPresentationError {
  [self mockSuccessfulAppStart];
  OCMStub([_interstitialAdMock isCached]).andReturn(YES);
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadAdWithLocation:@"ad_location"];
  UIViewController *controller = [[UIViewController alloc] init];
  OCMStub([_interstitialAdMock showFromViewController:controller])
      .andDo(^(NSInvocation *invocation) {
        CHBShowError *error = [[CHBShowError alloc] initWithDomain:@"domain" code:1 userInfo:nil];
        [self->_interstitialDelegate didShowAd:[[CHBShowEvent alloc] init] error:error];
      });

  [_interstitialDelegate presentFromViewController:controller];

  XCTAssertNotNil(eventDelegate.didFailToPresentError);
  XCTAssertEqual(eventDelegate.didFailToPresentError.code, 301);

  // Must not trigger any presentation callbacks.
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
}

- (void)testNotCachedError {
  [self mockSuccessfulAppStart];
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadAdWithLocation:@"ad_location"];
  UIViewController *controller = [[UIViewController alloc] init];
  [_interstitialDelegate presentFromViewController:controller];

  XCTAssertNotNil(eventDelegate.didFailToPresentError);
  XCTAssertEqual(eventDelegate.didFailToPresentError.code, GADMAdapterChartboostErrorAdNotCached);

  // Must not trigger any presentation callbacks.
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
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
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError = [[NSError alloc] initWithDomain:@"test_domain" code:1 userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
}

- (void)testMissingAppID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : @"ad_location",
    GADMAdapterChartboostAppSignature : @"signature",
  };
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                 code:GADMAdapterChartboostErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
}

- (void)testAppIDOnlyWhitespace {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : @"ad_location",
    GADMAdapterChartboostAppID : @"    ",
    GADMAdapterChartboostAppSignature : @"signature",
  };
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                 code:GADMAdapterChartboostErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
}

- (void)testSignatureOnlyWhitespace {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : @"ad_location",
    GADMAdapterChartboostAppID : @"app_id",
    GADMAdapterChartboostAppSignature : @"    ",
  };
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                 code:GADMAdapterChartboostErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
}

- (void)testMissingSignature {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : @"ad_location",
    GADMAdapterChartboostAppID : @"app_id",
  };
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                 code:GADMAdapterChartboostErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
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
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                 code:GADMAdapterChartboostErrorMinimumOSVersion
                             userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
}

@end
