#import "GADMediationAdapterMyTarget.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationBannerAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <MyTargetSDK/MyTargetSDK.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtras.h"

static NSUInteger AUTSlotID = 12345;

AUTKMediationBannerAdEventDelegate *_Nonnull AUTLoadBannerAd(MTRGAdView *_Nonnull adView) {
  MTRGAdView *adViewMock = OCMPartialMock(adView);
  OCMStub([adViewMock load]).andDo(^(NSInvocation *invocation) {
    [adViewMock.delegate onLoadWithAdView:adViewMock];
  });
  id adViewClassMock = OCMClassMock([MTRGAdView class]);
  OCMStub([adViewClassMock adViewWithSlotId:AUTSlotID shouldRefreshAd:NO]).andReturn(adViewMock);
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationBannerAdConfiguration *bannerAdConfiguration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  bannerAdConfiguration.adSize = GADAdSizeBanner;
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @(AUTSlotID),
  };
  bannerAdConfiguration.credentials = credentials;
  GADMAdapterMyTargetExtras *extras = [[GADMAdapterMyTargetExtras alloc] init];
  extras.isDebugMode = YES;
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

void AUTFailToLoadBannerAd(MTRGAdView *_Nonnull bannerAd, GADAdSize adSize,
                           NSError *expectedError) {
  MTRGAdView *adViewMock = OCMPartialMock(bannerAd);
  NSError *loadError = [[NSError alloc] initWithDomain:@"MyFyberDomain" code:12345 userInfo:nil];
  OCMStub([adViewMock load]).andDo(^(NSInvocation *invocation) {
    [adViewMock.delegate onLoadFailedWithError:loadError adView:adViewMock];
  });
  id adViewClassMock = OCMClassMock([MTRGAdView class]);
  OCMStub([adViewClassMock adViewWithSlotId:AUTSlotID shouldRefreshAd:NO]).andReturn(adViewMock);
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

@interface AUTMyTargetBannerAdTests : XCTestCase
@end

@implementation AUTMyTargetBannerAdTests

- (void)testOnLoadWithBannerAd {
  MTRGAdView *adView = [MTRGAdView adViewWithSlotId:AUTSlotID shouldRefreshAd:NO];
  AUTLoadBannerAd(adView);
}

- (void)testMyFyberLoadFailure {
  MTRGAdView *adView = [MTRGAdView adViewWithSlotId:AUTSlotID shouldRefreshAd:NO];
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                                      code:GADMAdapterMyTargetErrorNoFill
                                                  userInfo:@{
                                                    NSLocalizedDescriptionKey : @"foobar",
                                                    NSLocalizedFailureReasonErrorKey : @"foobar",
                                                  }];
  AUTFailToLoadBannerAd(adView, GADAdSizeBanner, expectedError);
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
  AUTFailToLoadBannerAd(adView, GADAdSizeInvalid, expectedError);
}

- (void)testOnClickWithBannerAd {
  MTRGAdView *adView = [MTRGAdView adViewWithSlotId:AUTSlotID shouldRefreshAd:NO];
  AUTKMediationBannerAdEventDelegate *eventDelegate = AUTLoadBannerAd(adView);
  [adView.delegate onAdClickWithAdView:adView];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testOnDisplayWithBannerAd {
  MTRGAdView *adView = [MTRGAdView adViewWithSlotId:AUTSlotID shouldRefreshAd:NO];
  AUTKMediationBannerAdEventDelegate *eventDelegate = AUTLoadBannerAd(adView);
  [adView.delegate onAdShowWithAdView:adView];
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
