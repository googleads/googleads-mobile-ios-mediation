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
#import <AdapterUnitTestKit/AUTKMediationBannerAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <MTGSDK/MTGSDK.h>
#import <MTGSDKBanner/MTGBannerAdView.h>
#import <MTGSDKBanner/MTGBannerAdViewDelegate.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMediationAdapterMintegralConstants.h"

static NSString *const kPlacementID = @"12345";
static NSString *const kUnitID = @"67890";

@interface AUTMintegralWaterfallBannerAdTests : XCTestCase
@end

@implementation AUTMintegralWaterfallBannerAdTests {
  /// An adapter instance that is used to test loading a banner ad.
  GADMediationAdapterMintegral *_adapter;

  /// A mock instance of MTGBannerAdView.
  id _bannerAdMock;

  /// A banner ad delegate.
  __block id<MTGBannerAdViewDelegate> _bannerAdDelegate;

  /// The banner ad loader.
  __block id<GADMediationBannerAd> _adLoader;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterMintegral alloc] init];
  _bannerAdMock = OCMClassMock([MTGBannerAdView class]);
  OCMStub([_bannerAdMock alloc]).andReturn(_bannerAdMock);
  OCMStub([_bannerAdMock initBannerAdViewWithAdSize:CGSizeMake(0, 0)
                                        placementId:kPlacementID
                                             unitId:kUnitID
                                 rootViewController:OCMOCK_ANY])
      .ignoringNonObjectArgs()
      .andReturn(_bannerAdMock);

  // Whenever a delegate is set, save it and assert that it has the appropriate delegate type.
  OCMStub([_bannerAdMock setDelegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                           self->_bannerAdDelegate = obj;
                           if ([obj conformsToProtocol:@protocol(GADMediationBannerAd)]) {
                             self->_adLoader = obj;
                           }
                           return [obj conformsToProtocol:@protocol(MTGBannerAdViewDelegate)];
                         }]]);
}

- (void)tearDown {
  [_bannerAdMock stopMocking];
  _bannerAdDelegate = nil;
  _adLoader = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  [super tearDown];
}

- (nonnull AUTKMediationBannerAdEventDelegate *)loadAdWithSize:(CGSize)size {
  // All banners must have refresh disabled.
  OCMExpect([_bannerAdMock setAutoRefreshTime:0]);

  OCMStub([_bannerAdMock loadBannerAd]).andDo(^(NSInvocation *invocation) {
    [self->_bannerAdDelegate adViewLoadSuccess:self->_bannerAdMock];
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeFromCGSize(size);

  AUTKMediationBannerAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);
  XCTAssertNotNil(_bannerAdDelegate);

  [_bannerAdMock verify];
  return eventDelegate;
}

- (void)testLoadBannerSuccess {
  [self loadAdWithSize:CGSizeMake(320, 50)];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolUnknown);
}

- (void)testLoadBannerSuccessWithTagForChildIsYes {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  [self loadAdWithSize:CGSizeMake(320, 50)];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolYes);
}

- (void)testLoadBannerSuccessWithTagForChildIsNo {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  [self loadAdWithSize:CGSizeMake(320, 50)];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolNo);
}

- (void)testLoadBannerSuccessWithTagForUnderAgeIsYes {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  [self loadAdWithSize:CGSizeMake(320, 50)];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolYes);
}

- (void)testLoadBannerSuccessWithTagForUnderAgeIsNo {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  [self loadAdWithSize:CGSizeMake(320, 50)];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolNo);
}

- (void)testLoadBannerSuccessWithAgeRestrictedTreatmentIsChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  [self loadAdWithSize:CGSizeMake(320, 50)];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolYes);
}

- (void)testLoadBannerSuccessWithAgeRestrictedTreatmentIsTeen {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;
  [self loadAdWithSize:CGSizeMake(320, 50)];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolUnknown);
}

- (void)testLoadBannerSuccessWithAgeRestrictedTreatmentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  [self loadAdWithSize:CGSizeMake(320, 50)];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolUnknown);
}

- (void)testBannerDelegateCallbacks {
  AUTKMediationBannerAdEventDelegate *delegate = [self loadAdWithSize:CGSizeMake(320, 50)];

  XCTAssertNotNil(_bannerAdDelegate);

  [_bannerAdDelegate adViewWillLogImpression:_bannerAdMock];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);

  [_bannerAdDelegate adViewDidClicked:_bannerAdMock];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);

  [_bannerAdDelegate adViewWillOpenFullScreen:_bannerAdMock];
  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 1);

  [_bannerAdDelegate adViewCloseFullScreen:_bannerAdMock];
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testBannerDelegateCallbacksNotImplemented {
  [self loadAdWithSize:CGSizeMake(320, 50)];
  [_bannerAdDelegate adViewWillLeaveApplication:_bannerAdMock];
  [_bannerAdDelegate adViewClosed:_bannerAdMock];
}

- (void)testBannerView {
  [self loadAdWithSize:CGSizeMake(320, 50)];
  XCTAssertEqual([_adLoader view], _bannerAdMock);
}

- (void)testLoadFailureWithNoAdUnitID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralPlacementID : kPlacementID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeFromCGSize(CGSizeMake(320, 50));

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureWithEmptyAdUnitID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : @""};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeFromCGSize(CGSizeMake(320, 50));

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureWithNoPlacementID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeFromCGSize(CGSizeMake(320, 50));

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureWithEmptyPlacementID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : @"", GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeFromCGSize(CGSizeMake(320, 50));

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureWithInvalidBannerSize {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeFromCGSize(CGSizeMake(0, 0));

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegtalErrorBannerSizeInValid
                                                  userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadBannerFailureIfMintegralFailsToLoadAd {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorAdNotAvailable
                                                  userInfo:nil];
  OCMStub([_bannerAdMock loadBannerAd]).andDo(^(NSInvocation *invocation) {
    [self->_bannerAdDelegate adViewLoadFailedWithError:expectedError adView:self->_bannerAdMock];
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeFromCGSize(CGSizeMake(320, 50));

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

@end
