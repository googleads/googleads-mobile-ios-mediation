// Copyright 2025 Google LLC
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
#import <AdapterUnitTestKit/AUTKMediationAppOpenAdLoadAssertions.h>
#import <AppLovinSDK/AppLovinSDK.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterAppLovinConstant.h"

static NSString *const kAdUnitID = @"fake_ad_unit_id";
// AppLovin expects an SDK Key of 86 characters
static NSString *const kSDKKey =
    @"12345678901234567890123456789012345678901234567890123456789012345678901234567890123456";

@interface AUTAppLovinAppOpenAdTests : XCTestCase
@end

@implementation AUTAppLovinAppOpenAdTests {
  /// An adapter instance that is used to test loading an ad.
  GADMediationAdapterAppLovin *_adapter;
  /// Mock for ALSdk.
  id _appLovinSdkMock;
  /// Mock for MAAppOpenAd.
  id _appLovinAppOpenAd;

  id<MAAdDelegate> appLovinAddelegate;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterAppLovin alloc] init];

  _appLovinSdkMock = OCMClassMock([ALSdk class]);
  _appLovinAppOpenAd = OCMClassMock([MAAppOpenAd class]);

  OCMStub([_appLovinAppOpenAd alloc]).andReturn(_appLovinAppOpenAd);
  OCMStub(ClassMethod([_appLovinSdkMock shared])).andReturn(_appLovinSdkMock);

  OCMStub([_appLovinSdkMock initializeWithConfiguration:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(ALSdkConfiguration *configuration);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(nil);
      });
}

- (void)tearDown {
  // Reset child-directed and under-age tags.
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  [super tearDown];
}

- (nonnull AUTKMediationAppOpenAdEventDelegate *)loadAd {
  AUTKMediationAppOpenAdConfiguration *config = [[AUTKMediationAppOpenAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  config.credentials = credentials;
  credentials.settings = @{@"sdkKey" : kSDKKey, @"ad_unit_id" : kAdUnitID};

  OCMExpect([_appLovinAppOpenAd initWithAdUnitIdentifier:kAdUnitID]).andReturn(_appLovinAppOpenAd);
  __block id<MAAdDelegate> delegate = nil;
  OCMExpect([_appLovinAppOpenAd setDelegate:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&delegate atIndex:2];
    self->appLovinAddelegate = delegate;
  });
  OCMExpect([(MAAppOpenAd *)_appLovinAppOpenAd loadAd]).andDo(^(NSInvocation *invocation) {
    [delegate didLoadAd:OCMClassMock([MAAd class])];
  });
  AUTKMediationAppOpenAdEventDelegate *gmaAdEventDelegate =
      AUTKWaitAndAssertLoadAppOpenAd(_adapter, config);
  XCTAssertNotNil(gmaAdEventDelegate);
  OCMVerifyAll(_appLovinAppOpenAd);

  return gmaAdEventDelegate;
}

#pragma mark - Ad Load events

- (void)testLoadAppOpenAd {
  [self loadAd];
}

- (void)testLoadFailureIfUserIsTaggedAsChild {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  AUTKMediationAppOpenAdConfiguration *config = [[AUTKMediationAppOpenAdConfiguration alloc] init];

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterAppLovinErrorDomain
                                                      code:GADMAdapterAppLovinErrorChildUser
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, config, expectedError);
}

- (void)testLoadFailureIfUserIsTaggedAsUnderAge {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  AUTKMediationAppOpenAdConfiguration *config = [[AUTKMediationAppOpenAdConfiguration alloc] init];

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterAppLovinErrorDomain
                                                      code:GADMAdapterAppLovinErrorChildUser
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, config, expectedError);
}

- (void)testLoadFailureIfSDKKeyIsAbsent {
  AUTKMediationAppOpenAdConfiguration *config = [[AUTKMediationAppOpenAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  config.credentials = credentials;
  credentials.settings = @{@"ad_unit_id" : kAdUnitID};

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterAppLovinErrorDomain
                                                      code:GADMAdapterAppLovinErrorMissingSDKKey
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, config, expectedError);
}

- (void)testLoadFailureIfAdUnitIDIsAbsent {
  AUTKMediationAppOpenAdConfiguration *config = [[AUTKMediationAppOpenAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  config.credentials = credentials;
  credentials.settings = @{@"sdkKey" : kSDKKey};

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterAppLovinErrorDomain
                                                      code:GADMAdapterAppLovinErrorMissingAdUnitID
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, config, expectedError);
}

- (void)testLoadFailureCallbackIsInvokedIfAppLovinFailsToLoadAd {
  AUTKMediationAppOpenAdConfiguration *config = [[AUTKMediationAppOpenAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  config.credentials = credentials;
  credentials.settings = @{@"sdkKey" : kSDKKey, @"ad_unit_id" : kAdUnitID};
  __block id<MAAdDelegate> delegate = nil;
  OCMStub([_appLovinAppOpenAd initWithAdUnitIdentifier:kAdUnitID]).andReturn(_appLovinAppOpenAd);
  OCMStub([_appLovinAppOpenAd setDelegate:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&delegate atIndex:2];
    self->appLovinAddelegate = delegate;
  });
  OCMStub([(MAAppOpenAd *)_appLovinAppOpenAd loadAd]).andDo(^(NSInvocation *invocation) {
    MAError *appLovinError = OCMClassMock([MAError class]);
    // Return a fake error code of 1001 for ad load error.
    OCMStub([appLovinError code]).andReturn(1001);
    [delegate didFailToLoadAdForAdUnitIdentifier:kAdUnitID withError:appLovinError];
  });

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterAppLovinSDKErrorDomain
                                                      code:1001
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, config, expectedError);
}

#pragma mark - Ad Presentation tests

- (void)testPresentAppOpenAd {
  AUTKMediationAppOpenAdEventDelegate *gmaAdEventDelegate = [self loadAd];
  UIViewController *rootViewController = [[UIViewController alloc] init];
  OCMStub([_appLovinAppOpenAd isReady]).andReturn(YES);

  [gmaAdEventDelegate.appOpenAd presentFromViewController:rootViewController];

  OCMVerify([_appLovinAppOpenAd showAd]);
  XCTAssertTrue(gmaAdEventDelegate.willPresentFullScreenViewInvokeCount == 1);
}

- (void)testPresentInvokesFailureCallbackIfAdIsNotReady {
  AUTKMediationAppOpenAdEventDelegate *gmaAdEventDelegate = [self loadAd];
  UIViewController *rootViewController = [[UIViewController alloc] init];
  OCMStub([_appLovinAppOpenAd isReady]).andReturn(NO);

  [gmaAdEventDelegate.appOpenAd presentFromViewController:rootViewController];

  NSError *presentationError = gmaAdEventDelegate.didFailToPresentError;
  XCTAssertEqual(presentationError.domain, GADMAdapterAppLovinErrorDomain);
  XCTAssertEqual(presentationError.code, GADMAdapterAppLovinErrorAdNotReady);
}

#pragma mark - Ad Lifecycle events

- (void)testAdDisplayedEvents {
  AUTKMediationAppOpenAdEventDelegate *gmaAdEventDelegate = [self loadAd];
  [self->appLovinAddelegate didDisplayAd:OCMClassMock([MAAd class])];
  XCTAssertTrue(gmaAdEventDelegate.reportImpressionInvokeCount == 1);
}

- (void)testAdClickEvents {
  AUTKMediationAppOpenAdEventDelegate *gmaAdEventDelegate = [self loadAd];
  [self->appLovinAddelegate didClickAd:OCMClassMock([MAAd class])];
  XCTAssertTrue(gmaAdEventDelegate.reportClickInvokeCount == 1);
}

- (void)testAdClosedEvents {
  AUTKMediationAppOpenAdEventDelegate *gmaAdEventDelegate = [self loadAd];
  [self->appLovinAddelegate didHideAd:OCMClassMock([MAAd class])];
  XCTAssertTrue(gmaAdEventDelegate.willDismissFullScreenViewInvokeCount == 1);
  XCTAssertTrue(gmaAdEventDelegate.didDismissFullScreenViewInvokeCount == 1);
}

- (void)testAdFailedToBeDisplayedEvent {
  MAError *appLovinError = OCMClassMock([MAError class]);
  // Return a fake error code of 1002 for ad display error.
  OCMStub([appLovinError code]).andReturn(1002);
  AUTKMediationAppOpenAdEventDelegate *gmaAdEventDelegate = [self loadAd];

  [self->appLovinAddelegate didFailToDisplayAd:OCMClassMock([MAAd class]) withError:appLovinError];

  NSError *presentationError = gmaAdEventDelegate.didFailToPresentError;
  XCTAssertEqual(presentationError.domain, GADMAdapterAppLovinSDKErrorDomain);
  XCTAssertEqual(presentationError.code, 1002);
}

@end
