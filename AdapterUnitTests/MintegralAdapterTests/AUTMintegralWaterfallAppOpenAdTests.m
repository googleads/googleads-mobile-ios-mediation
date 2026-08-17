// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMediationAdapterMintegral.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationAppOpenAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <MTGSDK/MTGSDK.h>
#import <MTGSDKSplash/MTGSplashAD.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterMintegralConstants.h"

static NSString *const kPlacementID = @"12345";
static NSString *const kUnitID = @"67890";

@interface AUTMintegralWaterfallAppOpenAdTests : XCTestCase
@end

@implementation AUTMintegralWaterfallAppOpenAdTests {
  /// An adapter instance that is used to test loading an app open ad.
  GADMediationAdapterMintegral *_adapter;

  /// A mock instance of MTGSplashAD.
  id _splashAdMock;

  /// An app open ad loader.
  __block id<MTGSplashADDelegate, GADMediationAppOpenAd> _adLoader;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterMintegral alloc] init];
  _splashAdMock = OCMClassMock([MTGSplashAD class]);
  OCMStub([_splashAdMock alloc]).andReturn(_splashAdMock);
  OCMStub([_splashAdMock initWithPlacementID:kPlacementID
                                      unitID:kUnitID
                                   countdown:GADMAdapterMintegralAppOpenSkipCountDownInSeconds
                                   allowSkip:YES])
      .andReturn(_splashAdMock);
}

- (void)tearDown {
  [_splashAdMock stopMocking];
  _adLoader = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  [super tearDown];
}

- (nonnull AUTKMediationAppOpenAdEventDelegate *)loadWaterfallAppOpenAd {
  OCMStub([_splashAdMock setDelegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                           self->_adLoader = obj;
                           return [obj conformsToProtocol:@protocol(MTGSplashADDelegate)] &&
                                  [obj conformsToProtocol:@protocol(GADMediationAppOpenAd)];
                         }]]);
  OCMStub([_splashAdMock preload]).andDo(^(NSInvocation *invocation) {
    [self->_adLoader splashADPreloadSuccess:self->_splashAdMock];
  });
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;

  AUTKMediationAppOpenAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadAppOpenAd(_adapter, configuration);
  XCTAssertNotNil(_adLoader);
  return eventDelegate;
}

- (void)testLoadWaterfallAppOpenAd {
  [self loadWaterfallAppOpenAd];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolUnknown);
}

- (void)testLoadWaterfallAppOpenAdWithTagForChildIsYes {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  [self loadWaterfallAppOpenAd];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolYes);
}

- (void)testLoadWaterfallAppOpenAdWithTagForChildIsNo {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  [self loadWaterfallAppOpenAd];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolNo);
}

- (void)testLoadWaterfallAppOpenAdWithTagForUnderAgeIsYes {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  [self loadWaterfallAppOpenAd];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolYes);
}

- (void)testLoadWaterfallAppOpenAdWithTagForUnderAgeIsNo {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  [self loadWaterfallAppOpenAd];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolNo);
}

- (void)testLoadWaterfallAppOpenAdWithAgeRestrictedTreatmentIsChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  [self loadWaterfallAppOpenAd];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolYes);
}

- (void)testLoadWaterfallAppOpenAdWithAgeRestrictedTreatmentIsTeen {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;
  [self loadWaterfallAppOpenAd];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolUnknown);
}

- (void)testLoadWaterfallAppOpenAdWithAgeRestrictedTreatmentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  [self loadWaterfallAppOpenAd];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolUnknown);
}

- (void)testLoadWaterfallAppOpenAdFailureForMissingPlacementID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadWaterfallAppOpenAdFailureForEmptyPlacementID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : @"", GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadWaterfallAppOpenAdFailureForMissingAdUnitID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralPlacementID : kPlacementID};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadWaterfallAppOpenAdFailureForEmptyAdUnitID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : @""};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadWaterfallAppOpenAdFailureForSplashAdLoadFail {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorAdNotAvailable
                                                  userInfo:nil];
  __block id<MTGSplashADDelegate> delegate = nil;
  OCMStub([_splashAdMock setDelegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                           delegate = obj;
                           return [obj conformsToProtocol:@protocol(MTGSplashADDelegate)];
                         }]]);
  OCMStub([_splashAdMock preload]).andDo(^(NSInvocation *invocation) {
    [delegate splashADPreloadFail:self->_splashAdMock error:expectedError];
  });
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;

  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, expectedError);
  XCTAssertNotNil(delegate);
}

- (void)testShowSuccess {
  UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
  OCMStub([_splashAdMock showInKeyWindow:keyWindow customView:nil])
      .andDo(^(NSInvocation *invocation) {
        [self->_adLoader splashADShowSuccess:self->_splashAdMock];
      });
  OCMStub([_splashAdMock isADReadyToShow]).andReturn(YES);
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadWaterfallAppOpenAd];

  [_adLoader presentFromViewController:[[UIViewController alloc] init]];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);

  [_adLoader splashADWillClose:self->_splashAdMock];

  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);

  [_adLoader splashADDidClose:self->_splashAdMock];

  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testShowFailureForAdNotReadyToShow {
  OCMStub([_splashAdMock isADReadyToShow]).andReturn(NO);
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadWaterfallAppOpenAd];

  [_adLoader presentFromViewController:[[UIViewController alloc] init]];

  XCTAssertEqual(eventDelegate.didFailToPresentError.code, GADMintegralErrorAdFailedToShow);
}

- (void)testShowFailureForAdShowFail {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorAdFailedToShow
                                                  userInfo:nil];
  UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
  OCMStub([_splashAdMock showInKeyWindow:keyWindow customView:nil])
      .andDo(^(NSInvocation *invocation) {
        [self->_adLoader splashADShowFail:self->_splashAdMock error:expectedError];
      });
  OCMStub([_splashAdMock isADReadyToShow]).andReturn(YES);
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadWaterfallAppOpenAd];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);

  [_adLoader presentFromViewController:[[UIViewController alloc] init]];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqualObjects(eventDelegate.didFailToPresentError, expectedError);
}

- (void)testClick {
  AUTKMediationAppOpenAdEventDelegate *eventDelegate = [self loadWaterfallAppOpenAd];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);

  [_adLoader splashADDidClick:self->_splashAdMock];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testUnusedDelegateMethodsNotCrashing {
  [self loadWaterfallAppOpenAd];

  [_adLoader splashADLoadSuccess:self->_splashAdMock];
  [_adLoader splashADLoadFail:self->_splashAdMock error:self->_splashAdMock];
  [_adLoader splashAD:self->_splashAdMock timeLeft:2];
  [_adLoader pointForSplashZoomOutADViewToAddOn:self->_splashAdMock];
  [_adLoader splashADDidLeaveApplication:self->_splashAdMock];
  [_adLoader splashZoomOutADViewClosed:self->_splashAdMock];
  [_adLoader splashZoomOutADViewDidShow:self->_splashAdMock];
  [_adLoader superViewForSplashZoomOutADViewToAddOn:self->_splashAdMock];
}

@end
