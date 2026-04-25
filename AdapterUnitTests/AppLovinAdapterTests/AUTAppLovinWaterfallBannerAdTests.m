// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMediationAdapterAppLovin.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationBannerAdLoadAssertions.h>
#import <AppLovinSDK/AppLovinSDK.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterAppLovinConstant.h"

/// Tests for loading and showing AppLovin banner ads through Waterfall.
@interface AUTAppLovinWaterfallBannerAdTests : XCTestCase
@end

// AppLovin expects an SDK Key of 86 characters
static NSString *const kSdkKey =
    @"12345678901234567890123456789012345678901234567890123456789012345678901234567890123456";
// AppLovin expects a zone ID of 16 characters
static NSString *const kZoneId = @"1234567890123456";

@implementation AUTAppLovinWaterfallBannerAdTests {
  /// An adapter instance that is used to test loading an ad.
  GADMediationAdapterAppLovin *_adapter;
  /// Mock for ALSdk.
  id _appLovinSdkMock;

  /// Mock for ALAdView..
  id _appLovinAdViewMock;
  /// Mock for ALAdService
  id _serviceMock;

  /// Delegate for handling AppLovin SDK callbacks.
  id<ALAdLoadDelegate, ALAdDisplayDelegate, ALAdViewEventDelegate> _appLovinDelegate;

  /// Mock loaded ad.
  id _adMock;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterAppLovin alloc] init];

  _appLovinSdkMock = OCMClassMock([ALSdk class]);
  _appLovinAdViewMock = OCMClassMock([ALAdView class]);
  _serviceMock = OCMClassMock([ALAdService class]);

  OCMStub([_appLovinAdViewMock alloc]).andReturn(_appLovinAdViewMock);
  OCMStub([_appLovinAdViewMock initWithSdk:_appLovinSdkMock size:ALAdSize.banner])
      .andReturn(_appLovinAdViewMock);

  OCMStub([_appLovinSdkMock adService]).andReturn(_serviceMock);
  OCMStub(ClassMethod([_appLovinSdkMock shared])).andReturn(_appLovinSdkMock);
  OCMStub(([_appLovinSdkMock
      initializeWithConfiguration:OCMOCK_ANY
                completionHandler:[OCMArg invokeBlockWithArgs:[NSNull null], nil]]));

  _adMock = OCMClassMock([ALAd class]);
}

- (void)tearDown {
  // Reset child-directed and under-age tags.
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  [super tearDown];
}

- (nonnull AUTKMediationBannerAdEventDelegate *)loadAd {
  AUTKMediationBannerAdConfiguration *config = [[AUTKMediationBannerAdConfiguration alloc] init];
  GADMediationAdapterAppLovin *adapter = [[GADMediationAdapterAppLovin alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{@"sdkKey" : kSdkKey};
  config.credentials = credentials;
  config.adSize = GADAdSizeBanner;
  OCMStub([_serviceMock loadNextAd:ALAdSize.banner
                         andNotify:[OCMArg checkWithBlock:^BOOL(id obj) {
                           self->_appLovinDelegate = obj;
                           return obj;
                         }]])
      .andDo(^(NSInvocation *invocation) {
        [self->_appLovinDelegate adService:self->_serviceMock didLoadAd:self->_adMock];
      });

  AUTKMediationBannerAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadBannerAd(adapter, config);
  XCTAssertNotNil(eventDelegate);
  return eventDelegate;
}

#pragma mark - Ad Load events

- (void)testLoadBannerAdWithoutZoneId {
  [self loadAd];
}

- (void)testLoadBannerAdWithZoneId {
  AUTKMediationBannerAdConfiguration *config = [[AUTKMediationBannerAdConfiguration alloc] init];
  GADMediationAdapterAppLovin *adapter = [[GADMediationAdapterAppLovin alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{@"sdkKey" : kSdkKey, @"zone_id" : kZoneId};
  config.credentials = credentials;
  config.adSize = GADAdSizeBanner;
  OCMStub([_serviceMock loadNextAdForZoneIdentifier:kZoneId
                                          andNotify:[OCMArg checkWithBlock:^BOOL(id obj) {
                                            self->_appLovinDelegate = obj;
                                            return obj;
                                          }]])
      .andDo(^(NSInvocation *invocation) {
        [self->_appLovinDelegate adService:self->_serviceMock didLoadAd:self->_adMock];
      });

  AUTKMediationBannerAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadBannerAd(adapter, config);
  XCTAssertNotNil(eventDelegate);
}

- (void)testLoadFailureIfAppLovinFailsToLoad {
  AUTKMediationBannerAdConfiguration *config = [[AUTKMediationBannerAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{@"sdkKey" : kSdkKey, @"zone_id" : kZoneId};
  config.credentials = credentials;
  config.adSize = GADAdSizeBanner;
  OCMStub([_serviceMock loadNextAdForZoneIdentifier:kZoneId
                                          andNotify:[OCMArg checkWithBlock:^BOOL(id obj) {
                                            self->_appLovinDelegate = obj;
                                            return obj;
                                          }]])
      .andDo(^(NSInvocation *invocation) {
        [self->_appLovinDelegate adService:self->_serviceMock didFailToLoadAdWithError:1001];
      });
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterAppLovinSDKErrorDomain
                                                      code:1001
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, config, expectedError);
}

- (void)testLoadFailureIfSizeIsNotSupportedByAppLovin {
  AUTKMediationBannerAdConfiguration *config = [[AUTKMediationBannerAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{@"sdkKey" : kSdkKey, @"zone_id" : kZoneId};
  config.credentials = credentials;
  config.adSize = GADAdSizeSkyscraper;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterAppLovinErrorDomain
                                 code:GADMAdapterAppLovinErrorBannerSizeMismatch
                             userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, config, expectedError);
}

- (void)testLoadFailureForInvalidAppLovinZoneId {
  AUTKMediationBannerAdConfiguration *config = [[AUTKMediationBannerAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  // AppLovin expects a zone ID of 16 characters. This is an invalid zone ID.
  NSString *invalidZoneID = @"12";
  credentials.settings = @{@"sdkKey" : kSdkKey, @"zone_id" : invalidZoneID};
  config.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterAppLovinErrorDomain
                                 code:GADMAdapterAppLovinErrorInvalidServerParameters
                             userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, config, expectedError);
}

- (void)testLoadFailureIfAppLovinSdkKeyIsAbsent {
  AUTKMediationBannerAdConfiguration *config = [[AUTKMediationBannerAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{@"zone_id" : kZoneId};
  config.credentials = credentials;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterAppLovinErrorDomain
                                                      code:GADMAdapterAppLovinErrorMissingSDKKey
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, config, expectedError);
}

- (void)testLoadFailureIfUserIsTaggedAsChild {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  AUTKMediationBannerAdConfiguration *config = [[AUTKMediationBannerAdConfiguration alloc] init];

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterAppLovinErrorDomain
                                                      code:GADMAdapterAppLovinErrorChildUser
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, config, expectedError);
}

- (void)testLoadFailureIfUserIsTaggedAsUnderAge {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  AUTKMediationBannerAdConfiguration *config = [[AUTKMediationBannerAdConfiguration alloc] init];

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterAppLovinErrorDomain
                                                      code:GADMAdapterAppLovinErrorChildUser
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, config, expectedError);
}

#pragma mark - Ad View

- (void)testGetView {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadAd];

  XCTAssertEqual([eventDelegate.bannerAd view], _appLovinAdViewMock);
}

#pragma mark - Ad Lifecycle events

- (void)testAdDisplayed {
  AUTKMediationBannerAdEventDelegate *delegate = [self loadAd];

  [self->_appLovinDelegate ad:_adMock wasDisplayedIn:_appLovinAdViewMock];

  XCTAssertTrue(delegate.reportImpressionInvokeCount == 1);
}

- (void)testAdFailedToDisplay {
  AUTKMediationBannerAdEventDelegate *delegate = [self loadAd];

  // Let AppLovin's ad display fail with a fictitious AppLovin error code 1005.
  [self->_appLovinDelegate ad:_adMock didFailToDisplayInAdView:_appLovinAdViewMock withError:1005];

  XCTAssertEqual(delegate.didFailToPresentError.code, 1005);
  XCTAssertEqual(delegate.didFailToPresentError.domain, GADMAdapterAppLovinSDKErrorDomain);
}

- (void)testAdClick {
  AUTKMediationBannerAdEventDelegate *delegate = [self loadAd];

  [self->_appLovinDelegate ad:_adMock wasClickedIn:_appLovinAdViewMock];

  XCTAssertTrue(delegate.reportClickInvokeCount == 1);
}

- (void)testDidPresentFullscreen {
  AUTKMediationBannerAdEventDelegate *delegate = [self loadAd];

  [self->_appLovinDelegate ad:_adMock didPresentFullscreenForAdView:_appLovinAdViewMock];

  XCTAssertTrue(delegate.willPresentFullScreenViewInvokeCount == 1);
}

- (void)testWillDismissFullscreen {
  AUTKMediationBannerAdEventDelegate *delegate = [self loadAd];

  [self->_appLovinDelegate ad:_adMock willDismissFullscreenForAdView:_appLovinAdViewMock];

  XCTAssertTrue(delegate.willDismissFullScreenViewInvokeCount == 1);
}

- (void)testDidDismissFullscreen {
  AUTKMediationBannerAdEventDelegate *delegate = [self loadAd];

  [self->_appLovinDelegate ad:_adMock didDismissFullscreenForAdView:_appLovinAdViewMock];

  XCTAssertTrue(delegate.didDismissFullScreenViewInvokeCount == 1);
}

- (void)testUnhandledEventsResultInNoCrash {
  [self loadAd];

  [self->_appLovinDelegate ad:_adMock wasHiddenIn:_appLovinAdViewMock];
  [self->_appLovinDelegate ad:_adMock willLeaveApplicationForAdView:_appLovinAdViewMock];
}

@end
