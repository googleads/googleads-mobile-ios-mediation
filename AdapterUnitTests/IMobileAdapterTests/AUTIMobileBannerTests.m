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

#import "GADMediationAdapterIMobile.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationBannerAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <ImobileSdkAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterIMobileConstants.h"
#import "GADMAdapterIMobileUtils.h"

static NSString *const kAUTPublisherID = @"test_publisher_id";
static NSString *const kAUTMediaID = @"test_media_id";
static NSString *const kAUTSpotID = @"test_spot_id";

@interface AUTIMobileBannerTests : XCTestCase
@end

@implementation AUTIMobileBannerTests {
  /// The adapter under test.
  GADMediationAdapterIMobile *_adapter;

  /// Class mock for ImobileSdkAds.
  id _sdkMock;

  /// Delegate passed to setSpotDelegate:delegate:.
  __block id<IMobileSdkAdsDelegate> _spotDelegate;
}

- (void)setUp {
  [super setUp];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  _adapter = [[GADMediationAdapterIMobile alloc] init];
  _sdkMock = OCMClassMock([ImobileSdkAds class]);
  _spotDelegate = nil;

  OCMStub(ClassMethod([_sdkMock setSpotDelegate:OCMOCK_ANY delegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<IMobileSdkAdsDelegate> delegate = nil;
        [invocation getArgument:&delegate atIndex:3];
        self->_spotDelegate = delegate;
      });
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  OCMVerifyAll(_sdkMock);
  [_sdkMock stopMocking];
  _sdkMock = nil;
  [super tearDown];
}

- (nonnull AUTKMediationBannerAdEventDelegate *)loadBannerAdWithSize:(GADAdSize)adSize {
  OCMStub(ClassMethod([_sdkMock showBySpotIDForAdMobMediation:OCMOCK_ANY
                                                         View:OCMOCK_ANY
                                                        Ratio:1.0f]))
      .andDo(^(NSInvocation *invocation) {
        [self->_spotDelegate imobileSdkAdsSpot:kAUTSpotID didReadyWithValue:IMOBILESDKADS_READY_AD];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = adSize;

  AUTKMediationBannerAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);
  XCTAssertNotNil(eventDelegate);
  XCTAssertNotNil(eventDelegate.bannerAd);

  return eventDelegate;
}

- (void)loadBannerAdFailureWithConfiguration:
            (nonnull GADMediationBannerAdConfiguration *)configuration
                               expectedError:(nonnull NSError *)expectedError {
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)loadBannerAdFailureForChildUser {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;

  NSString *errorDescription = @"The request had age-restricted treatment, but i-mobile SDK "
                               @"cannot receive age-restricted signals.";
  NSDictionary<NSString *, NSString *> *errorUserInfo = @{
    NSLocalizedDescriptionKey : errorDescription,
    NSLocalizedFailureReasonErrorKey : errorDescription
  };
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                                      code:GADMAdapterIMobileErrorChildUser
                                                  userInfo:errorUserInfo];

  [self loadBannerAdFailureWithConfiguration:configuration expectedError:expectedError];
}

#pragma mark - Success Tests

- (void)testLoadBannerAdSucceedsFor320x50 {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAdWithSize:GADAdSizeBanner];
  XCTAssertNotNil(eventDelegate.bannerAd.view);
  XCTAssertEqual(eventDelegate.bannerAd.view.frame.size.width, 320);
  XCTAssertEqual(eventDelegate.bannerAd.view.frame.size.height, 50);
}

- (void)testLoadBannerAdSucceedsFor320x100 {
  AUTKMediationBannerAdEventDelegate *eventDelegate =
      [self loadBannerAdWithSize:GADAdSizeLargeBanner];
  XCTAssertNotNil(eventDelegate.bannerAd.view);
  XCTAssertEqual(eventDelegate.bannerAd.view.frame.size.width, 320);
  XCTAssertEqual(eventDelegate.bannerAd.view.frame.size.height, 100);
}

- (void)testLoadBannerAdSucceedsFor300x250 {
  AUTKMediationBannerAdEventDelegate *eventDelegate =
      [self loadBannerAdWithSize:GADAdSizeMediumRectangle];
  XCTAssertNotNil(eventDelegate.bannerAd.view);
  XCTAssertEqual(eventDelegate.bannerAd.view.frame.size.width, 300);
  XCTAssertEqual(eventDelegate.bannerAd.view.frame.size.height, 250);
}

- (void)testLoadBannerAdSucceedsWhenTagForChildDirectedTreatmentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  [self loadBannerAdWithSize:GADAdSizeBanner];
}

- (void)testLoadBannerAdSucceedsWhenTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  [self loadBannerAdWithSize:GADAdSizeBanner];
}

- (void)testLoadBannerAdSucceedsWhenAgeRestrictedTreatmentIsTeen {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;
  [self loadBannerAdWithSize:GADAdSizeBanner];
}

#pragma mark - Child User Tests

- (void)testLoadBannerAdFailsWhenTagForChildDirectedTreatmentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  [self loadBannerAdFailureForChildUser];
}

- (void)testLoadBannerAdFailsWhenTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  [self loadBannerAdFailureForChildUser];
}

- (void)testLoadBannerAdFailsWhenAgeRestrictedTreatmentIsChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  [self loadBannerAdFailureForChildUser];
}

#pragma mark - Parameter Validation Tests

- (void)testLoadBannerAdFailsWithInvalidBannerSize {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeSkyscraper;

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                                      code:GADMAdapterIMobileErrorBannerSizeMismatch
                                                  userInfo:nil];

  [self loadBannerAdFailureWithConfiguration:configuration expectedError:expectedError];
}

- (void)testLoadBannerAdFailsWithMissingPublisherId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterIMobileMediaIdKey : kAUTMediaID, GADMAdapterIMobileSpotIdKey : kAUTSpotID};

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorInvalidServerParameters
                             userInfo:nil];

  [self loadBannerAdFailureWithConfiguration:configuration expectedError:expectedError];
}

- (void)testLoadBannerAdFailsWithEmptyPublisherId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : @"",
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorInvalidServerParameters
                             userInfo:nil];

  [self loadBannerAdFailureWithConfiguration:configuration expectedError:expectedError];
}

- (void)testLoadBannerAdFailsWithMissingMediaId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorInvalidServerParameters
                             userInfo:nil];

  [self loadBannerAdFailureWithConfiguration:configuration expectedError:expectedError];
}

- (void)testLoadBannerAdFailsWithEmptyMediaId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : @"",
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorInvalidServerParameters
                             userInfo:nil];

  [self loadBannerAdFailureWithConfiguration:configuration expectedError:expectedError];
}

- (void)testLoadBannerAdFailsWithMissingSpotId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID
  };

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorInvalidServerParameters
                             userInfo:nil];

  [self loadBannerAdFailureWithConfiguration:configuration expectedError:expectedError];
}

- (void)testLoadBannerAdFailsWithEmptySpotId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : @""
  };

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorInvalidServerParameters
                             userInfo:nil];

  [self loadBannerAdFailureWithConfiguration:configuration expectedError:expectedError];
}

#pragma mark - SDK Failure Tests

- (void)testLoadBannerAdFailsWhenIMobileFails {
  const NSInteger failResultCode = 12345;
  OCMStub(ClassMethod([_sdkMock showBySpotIDForAdMobMediation:OCMOCK_ANY
                                                         View:OCMOCK_ANY
                                                        Ratio:1.0f]))
      .andDo(^(NSInvocation *invocation) {
        [self->_spotDelegate imobileSdkAdsSpot:kAUTSpotID
                              didFailWithValue:(ImobileSdkAdsFailResult)failResultCode];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                                      code:failResultCode
                                                  userInfo:nil];

  [self loadBannerAdFailureWithConfiguration:configuration expectedError:expectedError];
}

#pragma mark - Event Delegate Tests

- (void)testAdDidShow {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAdWithSize:GADAdSizeBanner];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);

  [_spotDelegate imobileSdkAdsSpotDidShow:kAUTSpotID];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testAdDidClick {
  AUTKMediationBannerAdEventDelegate *eventDelegate = [self loadBannerAdWithSize:GADAdSizeBanner];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);

  [_spotDelegate imobileSdkAdsSpotDidClick:kAUTSpotID];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

@end
