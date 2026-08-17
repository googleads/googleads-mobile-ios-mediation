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
#import <AdapterUnitTestKit/AUTKMediationInterstitialAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <ImobileSdkAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterIMobileConstants.h"
#import "GADMAdapterIMobileManager.h"
#import "GADMAdapterIMobileUtils.h"

static NSString *const kAUTPublisherID = @"test_publisher_id";
static NSString *const kAUTMediaID = @"test_media_id";
static NSString *const kAUTSpotID = @"test_spot_id";

@interface AUTIMobileInterstitialAdTests : XCTestCase
@end

@implementation AUTIMobileInterstitialAdTests {
  /// The adapter under test.
  GADMediationAdapterIMobile *_adapter;

  /// Class mock for ImobileSdkAds.
  id _sdkMock;

  /// Delegate passed to setSpotDelegate:delegate: (GADMAdapterIMobileManager instance).
  __block id<IMobileSdkAdsDelegate> _managerDelegate;
}

- (void)setUp {
  [super setUp];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  _adapter = [[GADMediationAdapterIMobile alloc] init];
  _sdkMock = OCMClassMock([ImobileSdkAds class]);
  _managerDelegate = nil;

  OCMStub(ClassMethod([_sdkMock setSpotDelegate:OCMOCK_ANY delegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<IMobileSdkAdsDelegate> delegate = nil;
        [invocation getArgument:&delegate atIndex:3];
        self->_managerDelegate = delegate;
      });
}

- (void)tearDown {
  id<IMobileSdkAdsDelegate> manager =
      (id<IMobileSdkAdsDelegate>)GADMAdapterIMobileManager.sharedInstance;
  [manager imobileSdkAdsSpotDidClose:kAUTSpotID];
  [manager imobileSdkAdsSpotDidClose:@"ready_spot_id"];
  [manager imobileSdkAdsSpotDidClose:@"duplicate_spot_id"];
  [manager imobileSdkAdsSpotDidClose:@"fail_spot_id"];

  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  OCMVerifyAll(_sdkMock);
  [_sdkMock stopMocking];
  _sdkMock = nil;
  [super tearDown];
}

- (nonnull AUTKMediationInterstitialAdEventDelegate *)loadInterstitialAdWithSpotId:
    (nonnull NSString *)spotID {
  OCMStub(ClassMethod([_sdkMock startBySpotID:spotID])).andDo(^(NSInvocation *invocation) {
    [self->_managerDelegate imobileSdkAdsSpot:spotID didReadyWithValue:IMOBILESDKADS_READY_AD];
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : spotID
  };

  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);
  XCTAssertNotNil(eventDelegate);
  XCTAssertNotNil(eventDelegate.interstitialAd);

  return eventDelegate;
}

- (void)loadInterstitialAdFailureWithConfiguration:
            (nonnull GADMediationInterstitialAdConfiguration *)configuration
                                     expectedError:(nonnull NSError *)expectedError {
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
}

- (void)loadInterstitialAdFailureForChildUser {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSString *errorDescription = @"The request had age-restricted treatment, but i-mobile SDK "
                               @"cannot receive age-restricted signals.";
  NSDictionary<NSString *, NSString *> *errorUserInfo = @{
    NSLocalizedDescriptionKey : errorDescription,
    NSLocalizedFailureReasonErrorKey : errorDescription
  };
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                                      code:GADMAdapterIMobileErrorChildUser
                                                  userInfo:errorUserInfo];

  [self loadInterstitialAdFailureWithConfiguration:configuration expectedError:expectedError];
}

#pragma mark - Success Tests

- (void)testLoadInterstitialAdSucceeds {
  [self loadInterstitialAdWithSpotId:kAUTSpotID];
}

- (void)testLoadInterstitialAdWhenStatusAlreadyReady {
  NSString *spotID = @"ready_spot_id";
  OCMStub(ClassMethod([_sdkMock getStatusBySpotID:spotID])).andReturn(IMOBILESDKADS_STATUS_READY);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : spotID
  };

  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);
  XCTAssertNotNil(eventDelegate.interstitialAd);

  // Clean up
  [(id<IMobileSdkAdsDelegate>)GADMAdapterIMobileManager.sharedInstance
      imobileSdkAdsSpotDidClose:spotID];
}

- (void)testLoadInterstitialAdSucceedsWhenTagForChildDirectedTreatmentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  [self loadInterstitialAdWithSpotId:kAUTSpotID];
}

- (void)testLoadInterstitialAdSucceedsWhenTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  [self loadInterstitialAdWithSpotId:kAUTSpotID];
}

- (void)testLoadInterstitialAdSucceedsWhenAgeRestrictedTreatmentIsTeen {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;
  [self loadInterstitialAdWithSpotId:kAUTSpotID];
}

#pragma mark - Child User Tests

- (void)testLoadInterstitialAdFailsWhenTagForChildDirectedTreatmentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  [self loadInterstitialAdFailureForChildUser];
}

- (void)testLoadInterstitialAdFailsWhenTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  [self loadInterstitialAdFailureForChildUser];
}

- (void)testLoadInterstitialAdFailsWhenAgeRestrictedTreatmentIsChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  [self loadInterstitialAdFailureForChildUser];
}

#pragma mark - Parameter Validation Tests

- (void)testLoadInterstitialAdFailsWithMissingPublisherId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterIMobileMediaIdKey : kAUTMediaID, GADMAdapterIMobileSpotIdKey : kAUTSpotID};

  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorInvalidServerParameters
                             userInfo:nil];

  [self loadInterstitialAdFailureWithConfiguration:configuration expectedError:expectedError];
}

- (void)testLoadInterstitialAdFailsWithEmptyPublisherId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : @"",
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorInvalidServerParameters
                             userInfo:nil];

  [self loadInterstitialAdFailureWithConfiguration:configuration expectedError:expectedError];
}

- (void)testLoadInterstitialAdFailsWithMissingMediaId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorInvalidServerParameters
                             userInfo:nil];

  [self loadInterstitialAdFailureWithConfiguration:configuration expectedError:expectedError];
}

- (void)testLoadInterstitialAdFailsWithEmptyMediaId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : @"",
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorInvalidServerParameters
                             userInfo:nil];

  [self loadInterstitialAdFailureWithConfiguration:configuration expectedError:expectedError];
}

- (void)testLoadInterstitialAdFailsWithMissingSpotId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID
  };

  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorInvalidServerParameters
                             userInfo:nil];

  [self loadInterstitialAdFailureWithConfiguration:configuration expectedError:expectedError];
}

- (void)testLoadInterstitialAdFailsWithEmptySpotId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : @""
  };

  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorInvalidServerParameters
                             userInfo:nil];

  [self loadInterstitialAdFailureWithConfiguration:configuration expectedError:expectedError];
}

#pragma mark - Duplicate Load Tests

- (void)testLoadInterstitialAdFailsWhenAdAlreadyLoadingForSpotID {
  NSString *spotID = @"duplicate_spot_id";
  [self loadInterstitialAdWithSpotId:spotID];

  // Requesting second ad with same spot ID while first is active.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : spotID
  };

  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                                      code:GADMAdapterIMobileErrorAdAlreadyLoaded
                                                  userInfo:nil];

  [self loadInterstitialAdFailureWithConfiguration:configuration expectedError:expectedError];

  // Clean up
  [(id<IMobileSdkAdsDelegate>)GADMAdapterIMobileManager.sharedInstance
      imobileSdkAdsSpotDidClose:spotID];
}

#pragma mark - SDK Failure Tests

- (void)testLoadInterstitialAdFailsWhenIMobileFails {
  const NSInteger failResultCode = 12345;
  NSString *spotID = @"fail_spot_id";
  OCMStub(ClassMethod([_sdkMock startBySpotID:spotID])).andDo(^(NSInvocation *invocation) {
    [self->_managerDelegate imobileSdkAdsSpot:spotID
                             didFailWithValue:(ImobileSdkAdsFailResult)failResultCode];
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : spotID
  };

  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                                      code:failResultCode
                                                  userInfo:nil];

  [self loadInterstitialAdFailureWithConfiguration:configuration expectedError:expectedError];
}

#pragma mark - Presentation & Event Lifecycle Tests

- (void)testPresentInterstitialAdSucceeds {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadInterstitialAdWithSpotId:kAUTSpotID];

  OCMStub(ClassMethod([_sdkMock showBySpotID:kAUTSpotID])).andReturn(YES);

  UIViewController *viewController = [[UIViewController alloc] init];
  [eventDelegate.interstitialAd presentFromViewController:viewController];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertNil(eventDelegate.didFailToPresentError);
}

- (void)testPresentInterstitialAdFailsWhenShowReturnsNO {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadInterstitialAdWithSpotId:kAUTSpotID];

  OCMStub(ClassMethod([_sdkMock showBySpotID:kAUTSpotID])).andReturn(NO);

  UIViewController *viewController = [[UIViewController alloc] init];
  [eventDelegate.interstitialAd presentFromViewController:viewController];

  XCTAssertNotNil(eventDelegate.didFailToPresentError);
  XCTAssertEqualObjects(eventDelegate.didFailToPresentError.domain, GADMAdapterIMobileErrorDomain);
  XCTAssertEqual(eventDelegate.didFailToPresentError.code, GADMAdapterIMobileErrorAdNotPresented);
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
}

- (void)testAdDidClick {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadInterstitialAdWithSpotId:kAUTSpotID];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);

  [_managerDelegate imobileSdkAdsSpotDidClick:kAUTSpotID];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testAdDidClose {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadInterstitialAdWithSpotId:kAUTSpotID];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);

  [_managerDelegate imobileSdkAdsSpotDidClose:kAUTSpotID];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);

  // Verifies that after closing, the spot is unregistered and a new ad can be loaded with the same
  // spot ID.
  [self loadInterstitialAdWithSpotId:kAUTSpotID];
}

#pragma mark - Manager Safety Tests

- (void)testManagerDelegateCallbacksWithUnknownSpotIDDoNotCrash {
  id<IMobileSdkAdsDelegate> manager =
      (id<IMobileSdkAdsDelegate>)GADMAdapterIMobileManager.sharedInstance;
  NSString *unknownSpotID = @"unknown_spot_id";

  XCTAssertNoThrow([manager imobileSdkAdsSpot:unknownSpotID
                            didReadyWithValue:IMOBILESDKADS_READY_AD]);
  XCTAssertNoThrow([manager imobileSdkAdsSpot:unknownSpotID
                             didFailWithValue:IMOBILESDKADS_ERROR_PARAM]);
  XCTAssertNoThrow([manager imobileSdkAdsSpotDidClick:unknownSpotID]);
  XCTAssertNoThrow([manager imobileSdkAdsSpotDidClose:unknownSpotID]);
}

@end
