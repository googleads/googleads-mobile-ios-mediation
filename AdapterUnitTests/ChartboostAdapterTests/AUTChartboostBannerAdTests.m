#import "GADMediationAdapterChartboost.h"
#import "GADMediationAdapterChartboostBannerAd.h"

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

#import "ChartboostAdapter-Swift.h"

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

  // Stub every banner size at once. Tests that care about the size verify it with OCMVerify.
  OCMStub([[_bannerAdMock ignoringNonObjectArgs]
              initWithSize:CHBBannerSizeStandard
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

- (void)tearDown {
  [_bannerAdMock stopMocking];
  [_mockChartboost stopMocking];
  [super tearDown];
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

- (nonnull AUTKMediationBannerAdConfiguration *)
    configurationWithSize:(GADAdSize)adSize
                 location:(nonnull NSString *)location
        topViewController:(nullable UIViewController *)topViewController {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    [GADMAdapterChartboostConstants adLocation] : location,
    [GADMAdapterChartboostConstants appID] : @"app_id",
    [GADMAdapterChartboostConstants appSignature] : @"signature"
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = adSize;
  configuration.topViewController = topViewController;
  return configuration;
}

- (nonnull AUTKMediationBannerAdEventDelegate *)loadAdWithSize:(GADAdSize)adSize
                                                      location:(nonnull NSString *)location {
  OCMStub([_bannerAdMock cache]).andDo(^(NSInvocation *invocation) {
    [self->_bannerDelegate didCacheAd:[[CHBCacheEvent alloc] init] error:nil];
  });

  AUTKMediationBannerAdConfiguration *configuration =
      [self configurationWithSize:adSize
                         location:location
                topViewController:[[UIViewController alloc] init]];
  AUTKMediationBannerAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);
  XCTAssertNotNil(_bannerDelegate);

  return eventDelegate;
}

- (nonnull AUTKMediationBannerAdEventDelegate *)loadAdWithLocation:(nonnull NSString *)location {
  return [self loadAdWithSize:GADAdSizeBanner location:location];
}

- (void)testLoadAd {
  [self mockSuccessfulAppStart];
  [self loadAdWithLocation:@"ad_location"];
}

- (void)testLoadBannerAdSizeStandard {
  [self mockSuccessfulAppStart];
  [self loadAdWithSize:GADAdSizeBanner location:@"ad_location"];

  OCMVerify([_bannerAdMock initWithSize:CHBBannerSizeStandard
                               location:@"ad_location"
                              mediation:OCMOCK_ANY
                               delegate:OCMOCK_ANY]);
}

- (void)testLoadBannerAdSizeMediumRectangle {
  [self mockSuccessfulAppStart];
  [self loadAdWithSize:GADAdSizeMediumRectangle location:@"ad_location"];

  OCMVerify([_bannerAdMock initWithSize:CHBBannerSizeMedium
                               location:@"ad_location"
                              mediation:OCMOCK_ANY
                               delegate:OCMOCK_ANY]);
}

- (void)testLoadBannerAdSizeLeaderboard {
  [self mockSuccessfulAppStart];
  [self loadAdWithSize:GADAdSizeLeaderboard location:@"ad_location"];

  OCMVerify([_bannerAdMock initWithSize:CHBBannerSizeLeaderboard
                               location:@"ad_location"
                              mediation:OCMOCK_ANY
                               delegate:OCMOCK_ANY]);
}

- (void)testLoadBannerAdSizeHalfPage {
  [self mockSuccessfulAppStart];
  [self loadAdWithSize:GADAdSizeFromCGSize(CGSizeMake(300, 600)) location:@"ad_location"];

  OCMVerify([_bannerAdMock initWithSize:CHBBannerSizeHalfPage
                               location:@"ad_location"
                              mediation:OCMOCK_ANY
                               delegate:OCMOCK_ANY]);
}

- (void)testLoadStartsChartboostOnce {
  [self mockSuccessfulAppStart];
  [self loadAdWithLocation:@"ad_location"];

  OCMVerify(OCMTimes(1), ClassMethod([_mockChartboost startWithAppID:@"app_id"
                                                        appSignature:@"signature"
                                                          completion:OCMOCK_ANY]));
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

  AUTKMediationBannerAdConfiguration *configuration =
      [self configurationWithSize:GADAdSizeBanner
                         location:@"ad_location"
                topViewController:[[UIViewController alloc] init]];
  NSError *expectedError =
      [[NSError alloc] initWithDomain:[GADMAdapterChartboostConstants errorDomain]
                                 code:201
                             userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureForBannerSizeMismatch {
  [self mockSuccessfulAppStart];

  AUTKMediationBannerAdConfiguration *configuration =
      [self configurationWithSize:GADAdSizeFromCGSize(CGSizeMake(100, 100))
                         location:@"ad_location"
                topViewController:[[UIViewController alloc] init]];
  NSError *expectedError =
      [[NSError alloc] initWithDomain:[GADMAdapterChartboostConstants errorDomain]
                                 code:GADMAdapterChartboostErrorBannerSizeMismatch
                             userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureForNilTopViewController {
  [self mockSuccessfulAppStart];

  OCMStub([_bannerAdMock cache]).andDo(^(NSInvocation *invocation) {
    [self->_bannerDelegate didCacheAd:[[CHBCacheEvent alloc] init] error:nil];
  });

  AUTKMediationBannerAdConfiguration *configuration =
      [self configurationWithSize:GADAdSizeBanner
                         location:@"ad_location"
                topViewController:nil];
  NSError *expectedError =
      [[NSError alloc] initWithDomain:[GADMAdapterChartboostConstants errorDomain]
                                 code:GADMAdapterChartboostErrorNilViewController
                             userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
  OCMVerify(OCMNever(), [_bannerAdMock showFromViewController:OCMOCK_ANY]);
  OCMVerify([_bannerAdMock clearCache]);
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

- (void)testClickWithError {
  [self mockSuccessfulAppStart];
  OCMStub([_bannerAdMock isCached]).andReturn(YES);

  UIViewController *controller = [[UIViewController alloc] init];
  OCMStub([_bannerAdMock showFromViewController:controller]).andDo(^(NSInvocation *invocation) {
    [self->_bannerDelegate didShowAd:[[CHBShowEvent alloc] init] error:nil];
  });

  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadAdWithLocation:@"ad_location"];
  CHBClickError *clickError = [[CHBClickError alloc] initWithDomain:@"domain" code:1 userInfo:nil];
  [_bannerDelegate didClickAd:[[CHBClickEvent alloc] init] error:clickError];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);
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

- (void)testShowErrorAfterSuccessfulShowIsNotReported {
  [self mockSuccessfulAppStart];
  OCMStub([_bannerAdMock showFromViewController:OCMOCK_ANY]);
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadAdWithLocation:@"ad_location"];
  [self->_bannerDelegate didShowAd:[[CHBShowEvent alloc] init] error:nil];
  [self->_bannerDelegate didRecordImpression:[[CHBImpressionEvent alloc] init]];
  CHBShowError *error = [[CHBShowError alloc] initWithDomain:@"domain" code:1 userInfo:nil];
  [self->_bannerDelegate didShowAd:[[CHBShowEvent alloc] init] error:error];

  XCTAssertNil(eventDelegate.didFailToPresentError);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testDeallocClearsChartboostCache {
  // Build the wrapper directly and inject the mock, because OCMock retains the delegate passed to
  // the stubbed initializer, which would keep a loaded wrapper alive for the whole test.
  @autoreleasepool {
    AUTKMediationBannerAdConfiguration *configuration =
        [self configurationWithSize:GADAdSizeBanner
                           location:@"ad_location"
                  topViewController:[[UIViewController alloc] init]];
    GADMediationAdapterChartboostBannerAd *ad = [[GADMediationAdapterChartboostBannerAd alloc]
        initWithAdConfiguration:configuration
              completionHandler:^id<GADMediationBannerAdEventDelegate>(
                  id<GADMediationBannerAd> _Nullable loadedAd, NSError *_Nullable error) {
                return nil;
              }];
    // Fails as an assertion, rather than an exception, if the ivar is renamed.
    XCTAssertNoThrow([ad setValue:_bannerAdMock forKey:@"_banner"]);
  }

  OCMVerify([_bannerAdMock clearCache]);
}

- (void)testLoadAdFailsWhenStartFails {
  [self mockFailedAppStart];

  AUTKMediationBannerAdConfiguration *configuration =
      [self configurationWithSize:GADAdSizeBanner
                         location:@"ad_location"
                topViewController:[[UIViewController alloc] init]];
  NSError *expectedError =
      [[NSError alloc] initWithDomain:[GADMAdapterChartboostConstants errorDomain]
                                 code:GADMAdapterChartboostErrorInitializationFailure
                             userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testMissingAppID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    [GADMAdapterChartboostConstants adLocation] : @"ad_location",
    [GADMAdapterChartboostConstants appSignature] : @"signature",
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:[GADMAdapterChartboostConstants errorDomain]
                                 code:GADMAdapterChartboostErrorInvalidServerParameters
                             userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testAppIDOnlyWhitespace {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    [GADMAdapterChartboostConstants adLocation] : @"ad_location",
    [GADMAdapterChartboostConstants appID] : @"    ",
    [GADMAdapterChartboostConstants appSignature] : @"signature",
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:[GADMAdapterChartboostConstants errorDomain]
                                 code:GADMAdapterChartboostErrorInvalidServerParameters
                             userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testSignatureOnlyWhitespace {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    [GADMAdapterChartboostConstants adLocation] : @"ad_location",
    [GADMAdapterChartboostConstants appID] : @"app_id",
    [GADMAdapterChartboostConstants appSignature] : @"    ",
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:[GADMAdapterChartboostConstants errorDomain]
                                 code:GADMAdapterChartboostErrorInvalidServerParameters
                             userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testMissingSignature {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    [GADMAdapterChartboostConstants adLocation] : @"ad_location",
    [GADMAdapterChartboostConstants appID] : @"app_id",
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:[GADMAdapterChartboostConstants errorDomain]
                                 code:GADMAdapterChartboostErrorInvalidServerParameters
                             userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testLowSystemVersion {
  id mockDevice = OCMPartialMock(UIDevice.currentDevice);
  OCMStub([(UIDevice *)mockDevice systemVersion]).andReturn(@"10.0");

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    [GADMAdapterChartboostConstants adLocation] : @"ad_location",
    [GADMAdapterChartboostConstants appSignature] : @"signature",
    [GADMAdapterChartboostConstants appID] : @"app_id",
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:[GADMAdapterChartboostConstants errorDomain]
                                 code:GADMAdapterChartboostErrorMinimumOSVersion
                             userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
  [mockDevice stopMocking];
}

@end
