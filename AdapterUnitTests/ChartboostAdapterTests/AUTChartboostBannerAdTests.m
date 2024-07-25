#import "GADMediationAdapterChartboost.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationBannerAdLoadAssertions.h>
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

@interface AUTChartboostBannerAdTests : XCTestCase
@end

@implementation AUTChartboostBannerAdTests {
  /// An adapter instance that is used to test loading an ad.
  GADMediationAdapterChartboost *_adapter;

  /// Class mock for the Chartboost singleton.
  id _mockChartboost;

  /// A mock instance of CHBBanner.
  id _bannerAdMock;

  /// The banner delegate that was passed to _bannerAdMock.
  __block id<CHBBannerDelegate, GADMediationBannerAd> _bannerDelegate;

  // The location argument that was passed to _bannerAdMock.
  NSString *_observedLocation;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterChartboost alloc] init];
  _bannerAdMock = OCMClassMock([CHBBanner class]);
  OCMStub([_bannerAdMock alloc]).andReturn(_bannerAdMock);

  OCMStub([_bannerAdMock initWithSize:CHBBannerSizeStandard
                             location:[OCMArg checkWithBlock:^BOOL(NSString *location) {
                               self->_observedLocation = location;
                               return YES;
                             }]
                            mediation:OCMOCK_ANY
                             delegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                               self->_bannerDelegate = obj;
                               return YES;
                             }]])
      .andReturn(_bannerAdMock);
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

- (nonnull AUTKMediationBannerAdEventDelegate *)loadAdWithLocation:(nonnull NSString *)location {
  OCMStub([_bannerAdMock cache]).andDo(^(NSInvocation *invocation) {
    [self->_bannerDelegate didCacheAd:[[CHBCacheEvent alloc] init] error:nil];
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : location,
    GADMAdapterChartboostAppID : @"app_id",
    GADMAdapterChartboostAppSignature : @"signature"
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;
  configuration.topViewController = [[UIViewController alloc] init];
  AUTKMediationBannerAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);
  XCTAssertNotNil(_bannerDelegate);

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

- (void)testLoadFailureForCharboostFailedToLoadAd {
  [self mockSuccessfulAppStart];

  OCMStub([_bannerAdMock cache]).andDo(^(NSInvocation *invocation) {
    CHBCacheError *error = [[CHBCacheError alloc] initWithDomain:@"domain" code:1 userInfo:nil];
    [self->_bannerDelegate didCacheAd:[[CHBCacheEvent alloc] init] error:error];
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : @"ad_location",
    GADMAdapterChartboostAppID : @"app_id",
    GADMAdapterChartboostAppSignature : @"signature"
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;
  configuration.topViewController = [[UIViewController alloc] init];
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                                      code:201
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureForBannerSizeMismatch {
  [self mockSuccessfulAppStart];

  OCMStub([_bannerAdMock cache]).andDo(^(NSInvocation *invocation) {
    CHBCacheError *error = [[CHBCacheError alloc] initWithDomain:@"domain" code:1 userInfo:nil];
    [self->_bannerDelegate didCacheAd:[[CHBCacheEvent alloc] init] error:error];
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : @"ad_location",
    GADMAdapterChartboostAppID : @"app_id",
    GADMAdapterChartboostAppSignature : @"signature"
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.topViewController = [[UIViewController alloc] init];
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                 code:GADMAdapterChartboostErrorBannerSizeMismatch
                             userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testImpression {
  [self mockSuccessfulAppStart];
  OCMStub([_bannerAdMock isCached]).andReturn(YES);
  UIViewController *controller = [[UIViewController alloc] init];
  OCMStub([_bannerAdMock showFromViewController:controller]).andDo(^(NSInvocation *invocation) {
    [self->_bannerDelegate didShowAd:[[CHBShowEvent alloc] init] error:nil];
  });

  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadAdWithLocation:@"ad_location"];
  [_bannerDelegate didRecordImpression:OCMOCK_ANY];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testClick {
  [self mockSuccessfulAppStart];
  OCMStub([_bannerAdMock isCached]).andReturn(YES);

  UIViewController *controller = [[UIViewController alloc] init];
  OCMStub([_bannerAdMock showFromViewController:controller]).andDo(^(NSInvocation *invocation) {
    [self->_bannerDelegate didShowAd:[[CHBShowEvent alloc] init] error:nil];
  });

  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadAdWithLocation:@"ad_location"];
  [_bannerDelegate didClickAd:[[CHBClickEvent alloc] init] error:nil];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testShowError {
  [self mockSuccessfulAppStart];
  OCMStub([_bannerAdMock isCached]).andReturn(YES);
  OCMStub([_bannerAdMock showFromViewController:OCMOCK_ANY]);
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadAdWithLocation:@"ad_location"];
  CHBShowError *error = [[CHBShowError alloc] initWithDomain:@"domain" code:1 userInfo:nil];
  [self->_bannerDelegate didShowAd:[[CHBShowEvent alloc] init] error:error];

  XCTAssertNotNil(eventDelegate.didFailToPresentError);
  XCTAssertEqual(eventDelegate.didFailToPresentError.code, 301);
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
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;
  configuration.topViewController = [[UIViewController alloc] init];
  NSError *expectedError = [[NSError alloc] initWithDomain:@"test_domain" code:1 userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testMissingAppID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : @"ad_location",
    GADMAdapterChartboostAppSignature : @"signature",
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                 code:GADMAdapterChartboostErrorInvalidServerParameters
                             userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testAppIDOnlyWhitespace {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : @"ad_location",
    GADMAdapterChartboostAppID : @"    ",
    GADMAdapterChartboostAppSignature : @"signature",
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                 code:GADMAdapterChartboostErrorInvalidServerParameters
                             userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testSignatureOnlyWhitespace {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : @"ad_location",
    GADMAdapterChartboostAppID : @"app_id",
    GADMAdapterChartboostAppSignature : @"    ",
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                 code:GADMAdapterChartboostErrorInvalidServerParameters
                             userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testMissingSignature {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterChartboostAdLocation : @"ad_location",
    GADMAdapterChartboostAppID : @"app_id",
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                 code:GADMAdapterChartboostErrorInvalidServerParameters
                             userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
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
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterChartboostErrorDomain
                                 code:GADMAdapterChartboostErrorMinimumOSVersion
                             userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

@end
