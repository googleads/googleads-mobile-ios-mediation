#import "GADMediationAdapterMyTarget.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationBannerAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <MyTargetSDK/MyTargetSDK.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtras.h"
#import "GADMAdapterMyTargetUtils.h"

static NSUInteger AUTSlotID = 12345;

@interface AUTMyTargetBannerAdTests : XCTestCase
@end

@implementation AUTMyTargetBannerAdTests {
  id _mockPrivacy;
  id _adViewClassMock;
  MTRGAdView *_adViewMock;
  id _customParamsMock;
}

- (void)setUp {
  [super setUp];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  _mockPrivacy = OCMClassMock([MTRGPrivacy class]);
}

- (void)tearDown {
  [_customParamsMock stopMocking];
  [(id)_adViewMock stopMocking];
  [_adViewClassMock stopMocking];
  [_mockPrivacy stopMocking];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  [super tearDown];
}

- (AUTKMediationBannerAdEventDelegate *)loadBannerAdWithAdSize:(GADAdSize)adSize
                                                        extras:
                                                            (nullable GADMAdapterMyTargetExtras *)
                                                                extras {
  MTRGAdView *adView = [MTRGAdView adViewWithSlotId:AUTSlotID shouldRefreshAd:NO];
  _adViewMock = OCMPartialMock(adView);
  OCMStub([_adViewMock load]).andDo(^(NSInvocation *invocation) {
    [self->_adViewMock.delegate onLoadWithAdView:self->_adViewMock];
  });
  _adViewClassMock = OCMClassMock([MTRGAdView class]);
  OCMStub([_adViewClassMock adViewWithSlotId:AUTSlotID shouldRefreshAd:NO]).andReturn(_adViewMock);
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationBannerAdConfiguration *bannerAdConfiguration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  bannerAdConfiguration.adSize = adSize;
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @(AUTSlotID),
  };
  bannerAdConfiguration.credentials = credentials;
  bannerAdConfiguration.extras = extras;
  AUTKMediationBannerAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadBannerAd(adapter, bannerAdConfiguration);
  XCTAssertNotNil(eventDelegate.bannerAd);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertNil(eventDelegate.didFailToPresentError);
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);
  XCTAssertNotNil(eventDelegate.bannerAd.view);
  return eventDelegate;
}

- (void)failToLoadBannerAd:(MTRGAdView *)bannerAd
                    adSize:(GADAdSize)adSize
             expectedError:(NSError *)expectedError {
  _adViewMock = OCMPartialMock(bannerAd);
  NSError *loadError =
      [NSError errorWithDomain:GADMAdapterMyTargetSDKErrorDomain
                          code:12345
                      userInfo:@{
                        NSLocalizedDescriptionKey : @"foobar",
                        NSLocalizedFailureReasonErrorKey : @"foobar",
                      }];
  OCMStub([_adViewMock load]).andDo(^(NSInvocation *invocation) {
    [self->_adViewMock.delegate onLoadFailedWithError:loadError adView:self->_adViewMock];
  });
  _adViewClassMock = OCMClassMock([MTRGAdView class]);
  OCMStub([_adViewClassMock adViewWithSlotId:AUTSlotID shouldRefreshAd:NO]).andReturn(_adViewMock);
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationBannerAdConfiguration *bannerAdConfiguration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  bannerAdConfiguration.adSize = adSize;
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @(AUTSlotID),
  };
  GADMAdapterMyTargetExtras *extras = [[GADMAdapterMyTargetExtras alloc] init];
  extras.isDebugMode = YES;
  bannerAdConfiguration.extras = extras;
  bannerAdConfiguration.credentials = credentials;
  AUTKWaitAndAssertLoadBannerAdFailure(adapter, bannerAdConfiguration, expectedError);
}

- (void)testOnLoadWithBannerAd {
  OCMReject(ClassMethod([_mockPrivacy setUserAgeRestricted:OCMOCK_ANY]));

  [self loadBannerAdWithAdSize:GADAdSizeBanner extras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithBannerAdWithTagForChildYes {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  [self loadBannerAdWithAdSize:GADAdSizeBanner extras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithBannerAdWithTagForChildNo {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:NO]));

  [self loadBannerAdWithAdSize:GADAdSizeBanner extras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithBannerAdWithTagForUnderAgeYes {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  [self loadBannerAdWithAdSize:GADAdSizeBanner extras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithBannerAdWithTagForUnderAgeNo {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:NO]));

  [self loadBannerAdWithAdSize:GADAdSizeBanner extras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithBannerAdWithAgeRestrictedTreatmentChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  [self loadBannerAdWithAdSize:GADAdSizeBanner extras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithBannerAdWithAgeRestrictedTreatmentTeen {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;
  OCMExpect(ClassMethod([_mockPrivacy setUserAgeRestricted:YES]));

  [self loadBannerAdWithAdSize:GADAdSizeBanner extras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testOnLoadWithBannerAdWithAgeRestrictedTreatmentUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  OCMReject(ClassMethod([_mockPrivacy setUserAgeRestricted:OCMOCK_ANY]));

  [self loadBannerAdWithAdSize:GADAdSizeBanner extras:nil];
  OCMVerifyAll(_mockPrivacy);
}

- (void)testLoadFailure {
  MTRGAdView *adView = [MTRGAdView adViewWithSlotId:AUTSlotID shouldRefreshAd:NO];
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                                      code:GADMAdapterMyTargetErrorNoFill
                                                  userInfo:@{
                                                    NSLocalizedDescriptionKey : @"foobar",
                                                    NSLocalizedFailureReasonErrorKey : @"foobar",
                                                  }];
  [self failToLoadBannerAd:adView adSize:GADAdSizeBanner expectedError:expectedError];
}

- (void)testLoadFailureForBannerSizeMismatch {
  MTRGAdView *adView = [MTRGAdView adViewWithSlotId:AUTSlotID shouldRefreshAd:NO];
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                 code:GADMAdapterMyTargetErrorBannerSizeMismatch
                             userInfo:@{
                               NSLocalizedDescriptionKey : @"foobar",
                               NSLocalizedFailureReasonErrorKey : @"foobar",
                             }];
  [self failToLoadBannerAd:adView adSize:GADAdSizeInvalid expectedError:expectedError];
}

- (void)testLoadMediumRectangleBannerAd {
  AUTKMediationBannerAdEventDelegate *eventDelegate =
      [self loadBannerAdWithAdSize:GADAdSizeMediumRectangle extras:nil];
  XCTAssertNotNil(eventDelegate.bannerAd);
  XCTAssertEqual(eventDelegate.bannerAd.view.frame.size.width, 300);
  XCTAssertEqual(eventDelegate.bannerAd.view.frame.size.height, 250);
}

- (void)testLoadLeaderboardBannerAd {
  AUTKMediationBannerAdEventDelegate *eventDelegate =
      [self loadBannerAdWithAdSize:GADAdSizeLeaderboard extras:nil];
  XCTAssertNotNil(eventDelegate.bannerAd);
  XCTAssertEqual(eventDelegate.bannerAd.view.frame.size.width, 728);
  XCTAssertEqual(eventDelegate.bannerAd.view.frame.size.height, 90);
}

- (void)testLoadAdaptiveBannerAd {
  GADAdSize adaptiveSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(320);
  MTRGAdSize *expectedMyTargetSize = [MTRGAdSize adSizeForCurrentOrientationForWidth:320];
  AUTKMediationBannerAdEventDelegate *eventDelegate =
      [self loadBannerAdWithAdSize:adaptiveSize extras:nil];
  XCTAssertNotNil(eventDelegate.bannerAd);
  XCTAssertEqual(eventDelegate.bannerAd.view.frame.size.width, expectedMyTargetSize.size.width);
  XCTAssertEqual(eventDelegate.bannerAd.view.frame.size.height, expectedMyTargetSize.size.height);
}

- (void)testCustomParametersExtras {
  MTRGAdView *adView = [MTRGAdView adViewWithSlotId:AUTSlotID shouldRefreshAd:NO];
  _adViewMock = OCMPartialMock(adView);
  OCMStub([_adViewMock load]).andDo(^(NSInvocation *invocation) {
    [self->_adViewMock.delegate onLoadWithAdView:self->_adViewMock];
  });
  _adViewClassMock = OCMClassMock([MTRGAdView class]);
  OCMStub([_adViewClassMock adViewWithSlotId:AUTSlotID shouldRefreshAd:NO]).andReturn(_adViewMock);

  _customParamsMock = OCMPartialMock(_adViewMock.customParams);
  OCMExpect([_customParamsMock setCustomParam:@"custom_value" forKey:@"custom_key"]);

  GADMAdapterMyTargetExtras *extras = [[GADMAdapterMyTargetExtras alloc] init];
  [extras setParameter:@"custom_value" forKey:@"custom_key"];

  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationBannerAdConfiguration *bannerAdConfiguration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  bannerAdConfiguration.adSize = GADAdSizeBanner;
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @(AUTSlotID),
  };
  bannerAdConfiguration.credentials = credentials;
  bannerAdConfiguration.extras = extras;
  AUTKMediationBannerAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadBannerAd(adapter, bannerAdConfiguration);
  XCTAssertNotNil(eventDelegate.bannerAd);

  OCMVerifyAll(_customParamsMock);
}

- (void)testOnClickWithBannerAd {
  AUTKMediationBannerAdEventDelegate *eventDelegate =
      [self loadBannerAdWithAdSize:GADAdSizeBanner extras:nil];
  [_adViewMock.delegate onAdClickWithAdView:_adViewMock];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testOnDisplayWithBannerAd {
  AUTKMediationBannerAdEventDelegate *eventDelegate =
      [self loadBannerAdWithAdSize:GADAdSizeBanner extras:nil];
  [_adViewMock.delegate onAdShowWithAdView:_adViewMock];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testNilSlotIDFailure {
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  GADMediationBannerAdConfiguration *bannerAdConfiguration =
      [[GADMediationBannerAdConfiguration alloc] init];
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                 code:GADMAdapterMyTargetErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(adapter, bannerAdConfiguration, expectedError);
}

- (void)testEmptyStringSlotIDFailure {
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationBannerAdConfiguration *bannerAdConfiguration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @"",
  };
  bannerAdConfiguration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                 code:GADMAdapterMyTargetErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(adapter, bannerAdConfiguration, expectedError);
}

- (void)testNonNumericStringSlotIDFailure {
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationBannerAdConfiguration *bannerAdConfiguration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @"foobar",
  };
  bannerAdConfiguration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                 code:GADMAdapterMyTargetErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(adapter, bannerAdConfiguration, expectedError);
}

- (void)testZeroSlotIDFailure {
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationBannerAdConfiguration *bannerAdConfiguration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @0,
  };
  bannerAdConfiguration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                 code:GADMAdapterMyTargetErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(adapter, bannerAdConfiguration, expectedError);
}

@end
