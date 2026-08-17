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
  [super setUp];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  _adapter = [[GADMediationAdapterMaio alloc] init];
  _bannerMock = OCMClassMock([MaioBannerView class]);
  OCMStub([_bannerMock alloc]).andReturn(_bannerMock);
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  OCMVerifyAll(_bannerMock);
  [_bannerMock stopMocking];
  [super tearDown];
}

- (AUTKMediationBannerAdEventDelegate *)loadBannerAd {
  return [self loadBannerAdWithSize:GADAdSizeBanner expectedMaioSize:[MaioBannerSize banner]];
}

- (AUTKMediationBannerAdEventDelegate *)loadBannerAdWithSize:(GADAdSize)adSize
                                           expectedMaioSize:(MaioBannerSize *)expectedMaioSize {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMMaioAdapterZoneIdKey : @"zoneID"};
  AUTKMediationBannerAdConfiguration *config = [[AUTKMediationBannerAdConfiguration alloc] init];
  config.credentials = credentials;
  config.adSize = adSize;
  config.isTestRequest = YES;

  OCMExpect([_bannerMock initWithZoneId:@"zoneID" size:expectedMaioSize])
      .andReturn(_bannerMock);
  OCMStub([_bannerMock setDelegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                         if ([obj conformsToProtocol:@protocol(MaioBannerDelegate)]) {
                           id<MaioBannerDelegate> maioDelegate = obj;
                           [maioDelegate didLoad:self->_bannerMock];
                           return YES;
                         }
                         return NO;
                       }]]);

  AUTKMediationBannerAdEventDelegate *delegate = AUTKWaitAndAssertLoadBannerAd(_adapter, config);
  XCTAssertNotNil(delegate);

  return delegate;
}

- (void)loadBannerAdFailureWithInvalidAdSize {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMMaioAdapterZoneIdKey : @"zoneID"};
  AUTKMediationBannerAdConfiguration *config = [[AUTKMediationBannerAdConfiguration alloc] init];
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
  AUTKMediationBannerAdConfiguration *config = [[AUTKMediationBannerAdConfiguration alloc] init];
  config.credentials = credentials;
  config.adSize = GADAdSizeBanner;
  config.isTestRequest = YES;

  OCMExpect([_bannerMock initWithZoneId:@"zoneID" size:MaioBannerSize.banner])
      .andReturn(_bannerMock);
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

- (void)loadBannerAdFailureForChildUser {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMMaioAdapterZoneIdKey : @"zoneID"};
  AUTKMediationBannerAdConfiguration *config = [[AUTKMediationBannerAdConfiguration alloc] init];
  config.credentials = credentials;
  config.adSize = GADAdSizeBanner;
  config.isTestRequest = YES;

  NSString *errorDescription = @"The request had age-restricted treatment, but maio SDK "
                               @"cannot receive age-restricted signals.";
  NSDictionary *errorUserInfo = @{
    NSLocalizedDescriptionKey : errorDescription,
    NSLocalizedFailureReasonErrorKey : errorDescription
  };
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMMaioErrorDomain
                                                      code:GADMAdapterMaioErrorChildUser
                                                  userInfo:errorUserInfo];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, config, expectedError);
}

- (void)testLoadBannerAdSucceeds {
  [self loadBannerAd];
}

- (void)testLoadBannerAdSucceedsWithLargeBannerSize {
  AUTKMediationBannerAdEventDelegate *delegate =
      [self loadBannerAdWithSize:GADAdSizeLargeBanner
                expectedMaioSize:[MaioBannerSize bigBanner]];
  XCTAssertNotNil(delegate);
}

- (void)testLoadBannerAdSucceedsWithMediumRectangleSize {
  AUTKMediationBannerAdEventDelegate *delegate =
      [self loadBannerAdWithSize:GADAdSizeMediumRectangle
                expectedMaioSize:[MaioBannerSize mediumRectangle]];
  XCTAssertNotNil(delegate);
}

- (void)testLoadBannerAdSucceedsWhenTagForChildDirectedTreatmentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  [self loadBannerAd];
}

- (void)testLoadBannerAdSucceedsWhenTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  [self loadBannerAd];
}

- (void)testLoadFailureWithInvalidAdSize {
  [self loadBannerAdFailureWithInvalidAdSize];
}

- (void)testLoadBannerAdFailsWhenTagForChildDirectedTreatmentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  [self loadBannerAdFailureForChildUser];
}

- (void)testLoadBannerAdFailsWhenTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  [self loadBannerAdFailureForChildUser];
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

- (void)testAdDidLeaveApplication {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAd];
  id<MaioBannerDelegate> adDelegate = (id<MaioBannerDelegate>)eventDelegate.bannerAd;

  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  [adDelegate didLeaveApplication:_bannerMock];
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);
}

- (void)testAdDidFailToShow {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAd];
  id<MaioBannerDelegate> adDelegate = (id<MaioBannerDelegate>)eventDelegate.bannerAd;

  XCTAssertNil(eventDelegate.didFailToPresentError);
  [adDelegate didFailToShow:_bannerMock errorCode:kMaioShowFailureErroCode];
  XCTAssertNotNil(eventDelegate.didFailToPresentError);
  XCTAssertEqualObjects(eventDelegate.didFailToPresentError.domain, GADMMaioSDKErrorDomain);
  XCTAssertEqual(eventDelegate.didFailToPresentError.code, kMaioShowFailureErroCode);
}

@end
