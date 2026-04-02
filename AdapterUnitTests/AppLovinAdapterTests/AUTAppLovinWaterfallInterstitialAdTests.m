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
#import <AdapterUnitTestKit/AUTKMediationInterstitialAdLoadAssertions.h>
#import <AppLovinSDK/AppLovinSDK.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterAppLovinConstant.h"
#import "GADMWaterfallAppLovinInterstitialRenderer.h"

/// Tests for loading and showing AppLovin interstitial ads through Waterfall.
@interface AUTAppLovinWaterfallInterstitialAdTests : XCTestCase
@end

// AppLovin expects an SDK Key of 86 characters
static NSString *const kSdkKey =
    @"12345678901234567890123456789012345678901234567890123456789012345678901234567890123456";
// AppLovin expects a zone ID of 16 characters
static NSString *const kZoneId = @"1234567890123456";

@implementation AUTAppLovinWaterfallInterstitialAdTests {
  /// An adapter instance that is used to test loading an ad.
  GADMediationAdapterAppLovin *_adapter;
  /// Mock for ALSdk.
  id _appLovinSdkMock;
  /// Mock for ALInterstitialAd.
  id _interstitialAdMock;
  /// Mock for ALAdService
  id _serviceMock;

  /// Delegate for handling AppLovin SDK callbacks.
  id<ALAdLoadDelegate, ALAdDisplayDelegate, ALAdVideoPlaybackDelegate> _appLovinDelegate;

  /// Mock loaded ad.
  id _adMock;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterAppLovin alloc] init];

  _appLovinSdkMock = OCMClassMock([ALSdk class]);
  _interstitialAdMock = OCMClassMock([ALInterstitialAd class]);
  _serviceMock = OCMClassMock([ALAdService class]);

  OCMStub([_interstitialAdMock alloc]).andReturn(_interstitialAdMock);
  OCMStub([_interstitialAdMock initWithSdk:_appLovinSdkMock]).andReturn(_interstitialAdMock);
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

- (nonnull AUTKMediationInterstitialAdEventDelegate *)loadAd {
  AUTKMediationInterstitialAdConfiguration *config =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  GADMediationAdapterAppLovin *adapter = [[GADMediationAdapterAppLovin alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{@"sdkKey" : kSdkKey};
  config.credentials = credentials;

  OCMStub([_serviceMock loadNextAd:ALAdSize.interstitial
                         andNotify:[OCMArg checkWithBlock:^BOOL(id obj) {
                           self->_appLovinDelegate = obj;
                           return obj;
                         }]])
      .andDo(^(NSInvocation *invocation) {
        [self->_appLovinDelegate adService:self->_serviceMock didLoadAd:_adMock];
      });

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(adapter, config);
  XCTAssertNotNil(eventDelegate);
  OCMVerifyAll(_interstitialAdMock);
  return eventDelegate;
}

#pragma mark - Ad Load events

- (void)testLoadInterstitialAdWithoutZoneId {
  [self loadAd];
}

- (void)testLoadInterstitialAdWithZoneId {
  AUTKMediationInterstitialAdConfiguration *config =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  GADMediationAdapterAppLovin *adapter = [[GADMediationAdapterAppLovin alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{@"sdkKey" : kSdkKey, @"zone_id" : kZoneId};
  config.credentials = credentials;
  id adMock = OCMClassMock([ALAd class]);

  OCMStub([_serviceMock loadNextAdForZoneIdentifier:kZoneId
                                          andNotify:[OCMArg checkWithBlock:^BOOL(id obj) {
                                            self->_appLovinDelegate = obj;
                                            return obj;
                                          }]])
      .andDo(^(NSInvocation *invocation) {
        [self->_appLovinDelegate adService:self->_serviceMock didLoadAd:adMock];
      });

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(adapter, config);
  XCTAssertNotNil(eventDelegate);
  OCMVerifyAll(_interstitialAdMock);
}

- (void)testLoadFailureIfAppLovinFailsToLoad {
  AUTKMediationInterstitialAdConfiguration *config =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{@"sdkKey" : kSdkKey, @"zone_id" : kZoneId};
  config.credentials = credentials;
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
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, config, expectedError);
}

- (void)testLoadFailureForInvalidAppLovinZoneId {
  AUTKMediationInterstitialAdConfiguration *config =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  // AppLovin expects a zone ID of 16 characters. This is an invalid zone ID.
  NSString *invalidZoneID = @"12";
  credentials.settings = @{@"sdkKey" : kSdkKey, @"zone_id" : invalidZoneID};
  config.credentials = credentials;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterAppLovinErrorDomain
                                 code:GADMAdapterAppLovinErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, config, expectedError);
}

- (void)testLoadFailureIfAppLovinSdkKeyIsAbsent {
  AUTKMediationInterstitialAdConfiguration *config =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{@"zone_id" : kZoneId};
  config.credentials = credentials;

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterAppLovinErrorDomain
                                                      code:GADMAdapterAppLovinErrorMissingSDKKey
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, config, expectedError);
}

- (void)testLoadFailureIfUserIsTaggedAsChild {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  AUTKMediationInterstitialAdConfiguration *config =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterAppLovinErrorDomain
                                                      code:GADMAdapterAppLovinErrorChildUser
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, config, expectedError);
}

- (void)testLoadFailureIfUserIsTaggedAsUnderAge {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  AUTKMediationInterstitialAdConfiguration *config =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterAppLovinErrorDomain
                                                      code:GADMAdapterAppLovinErrorChildUser
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, config, expectedError);
}

- (void)testSecondAdLoadSuccessAfterPreviousAdIsLoadedForSingleZoneId {
  GADMediationAdapterAppLovin *adapter = [[GADMediationAdapterAppLovin alloc] init];
  AUTKMediationInterstitialAdConfiguration *config =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{@"sdkKey" : kSdkKey, @"zone_id" : kZoneId};
  config.credentials = credentials;
  id adMock = OCMClassMock([ALAd class]);
  OCMStub([_serviceMock loadNextAdForZoneIdentifier:kZoneId
                                          andNotify:[OCMArg checkWithBlock:^BOOL(id obj) {
                                            self->_appLovinDelegate = obj;
                                            return obj;
                                          }]])
      .andDo(^(NSInvocation *invocation) {
        [self->_appLovinDelegate adService:self->_serviceMock didLoadAd:adMock];
      });
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(adapter, config);
  XCTAssertNotNil(eventDelegate);

  // Load should succeed after previous ad load.
  eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, config);
  XCTAssertNotNil(eventDelegate);
}

- (void)testSecondAdLoadFailureIfPreviousAdIsStillLoadingForSingleZoneId {
  GADMediationAdapterAppLovin *adapter = [[GADMediationAdapterAppLovin alloc] init];
  AUTKMediationInterstitialAdConfiguration *config =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  // AppLovin expects a zone ID of 16 characters. Note: The zone ID used in this test is different
  // from the zone ID used in other tests in this file to avoid interference with the other tests.
  NSString *zoneID = @"1234567890123457";
  credentials.settings = @{@"sdkKey" : kSdkKey, @"zone_id" : zoneID};
  config.credentials = credentials;
  OCMStub([_serviceMock loadNextAdForZoneIdentifier:zoneID
                                          andNotify:[OCMArg checkWithBlock:^BOOL(id obj) {
                                            self->_appLovinDelegate = obj;
                                            return obj;
                                          }]]);
  OCMStub([_appLovinSdkMock initializeWithConfiguration:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(ALSdkConfiguration *configuration);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(nil);
      });
  GADMediationInterstitialLoadCompletionHandler completionHandler =
      ^(id<GADMediationInterstitialAd> _Nullable ad, NSError *_Nullable error) {
        return [[AUTKMediationInterstitialAdEventDelegate alloc] init];
      };

  [adapter loadInterstitialForAdConfiguration:config completionHandler:completionHandler];

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterAppLovinErrorDomain
                                                      code:GADMAdapterAppLovinErrorAdAlreadyLoaded
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, config, expectedError);
}

#pragma mark - Ad Show

- (void)testPresentCallsShowAdOnAppLovinSdk {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate = [self loadAd];
  UIViewController *rootViewController = [[UIViewController alloc] init];

  [eventDelegate.interstitialAd presentFromViewController:rootViewController];

  OCMVerify([_interstitialAdMock showAd:OCMOCK_ANY]);
}

#pragma mark - Ad Lifecycle events

- (void)testAdShownEvents {
  AUTKMediationInterstitialAdEventDelegate *delegate = [self loadAd];
  [self->_appLovinDelegate ad:_adMock wasDisplayedIn:OCMOCK_ANY];
  XCTAssertTrue(delegate.willPresentFullScreenViewInvokeCount == 1);
  XCTAssertTrue(delegate.reportImpressionInvokeCount == 1);
}

- (void)testAdClickEvents {
  AUTKMediationInterstitialAdEventDelegate *delegate = [self loadAd];
  [self->_appLovinDelegate ad:_adMock wasClickedIn:OCMOCK_ANY];
  XCTAssertTrue(delegate.reportClickInvokeCount == 1);
}

- (void)testAdClosedEvents {
  AUTKMediationInterstitialAdEventDelegate *delegate = [self loadAd];
  [self->_appLovinDelegate ad:_adMock wasHiddenIn:OCMOCK_ANY];
  XCTAssertTrue(delegate.willDismissFullScreenViewInvokeCount == 1);
  XCTAssertTrue(delegate.didDismissFullScreenViewInvokeCount == 1);
}

- (void)testUnhandledEventsResultInNoCrash {
  [self loadAd];
  [self->_appLovinDelegate videoPlaybackBeganInAd:OCMOCK_ANY];
  [self->_appLovinDelegate videoPlaybackEndedInAd:OCMOCK_ANY
                                atPlaybackPercent:@98.0f
                                     fullyWatched:OCMOCK_ANY];
}

@end
