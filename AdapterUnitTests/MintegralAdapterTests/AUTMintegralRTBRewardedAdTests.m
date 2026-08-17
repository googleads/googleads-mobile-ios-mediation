// Copyright 2022 Google LLC
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
#import <AdapterUnitTestKit/AUTKMediationRewardedAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <MTGSDK/MTGSDK.h>
#import <MTGSDKReward/MTGBidRewardAdManager.h>
#import <MTGSDKReward/MTGRewardAd.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterMintegralExtras.h"
#import "GADMediationAdapterMintegralConstants.h"

static NSString *const kPlacementID = @"12345";
static NSString *const kUnitID = @"67890";
static NSString *const kBidResponse = @"bidResponse";

@interface AUTMintegralRTBRewardedAdTests : XCTestCase
@end

@implementation AUTMintegralRTBRewardedAdTests {
  /// An adapter instance that is used to test loading an ad.
  GADMediationAdapterMintegral *_adapter;

  /// A mock instance of MTGBidRewardAdManager.
  id _rewardedAdMock;

  /// An ad loader.
  __block id<MTGRewardAdLoadDelegate, MTGRewardAdShowDelegate, GADMediationRewardedAd> _adLoader;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterMintegral alloc] init];
  _rewardedAdMock = OCMClassMock([MTGBidRewardAdManager class]);
  OCMStub([_rewardedAdMock sharedInstance]).andReturn(_rewardedAdMock);
}

- (void)tearDown {
  [_rewardedAdMock stopMocking];
  _adLoader = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  [super tearDown];
}

- (void)stubLoadWithAndDoBlock:(void (^)(NSInvocation *))block {
  OCMStub([_rewardedAdMock
              loadVideoWithBidToken:kBidResponse
                        placementId:kPlacementID
                             unitId:kUnitID
                           delegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                             self->_adLoader = obj;
                             return [obj conformsToProtocol:@protocol(MTGRewardAdLoadDelegate)] &&
                                    [obj conformsToProtocol:@protocol(MTGRewardAdShowDelegate)];
                           }]])
      .andDo(block);
}

- (nonnull AUTKMediationRewardedAdEventDelegate *)loadAd {
  NSData *watermarkData = [@"watermark" dataUsingEncoding:NSUTF8StringEncoding];
  // Must pass through the watermark.
  OCMExpect([_rewardedAdMock setExtraInfo:watermarkData forKey:@"admob_watermark" unitId:kUnitID]);

  [self stubLoadWithAndDoBlock:^(NSInvocation *invocation) {
    [self->_adLoader onVideoAdLoadSuccess:kPlacementID unitId:kUnitID];
  }];

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  configuration.watermark = watermarkData;
  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);
  XCTAssertNotNil(_adLoader);

  [_rewardedAdMock verify];
  return eventDelegate;
}

- (void)testLoadAd {
  [self loadAd];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolUnknown);
}

- (void)testLoadAdWithTagForChildIsYes {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  [self loadAd];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolYes);
}

- (void)testLoadAdWithTagForChildIsNo {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  [self loadAd];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolNo);
}

- (void)testLoadAdWithTagForUnderAgeIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  [self loadAd];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolYes);
}

- (void)testLoadAdWithTagForUnderAgeIsNo {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  [self loadAd];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolNo);
}

- (void)testLoadAdWithAgeRestrictedTreatmentIsChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  [self loadAd];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolYes);
}

- (void)testLoadAdWithAgeRestrictedTreatmentIsTeen {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;
  [self loadAd];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolUnknown);
}

- (void)testLoadAdWithAgeRestrictedTreatmentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  [self loadAd];
  XCTAssertEqual([[MTGSDK sharedInstance] coppa], MTGBoolUnknown);
}

- (void)testLoadAdFailureForMissingPlacementID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadAdFailureForEmptyPlacementID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : @"", GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadAdFailureForMissingAdUnitID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterMintegralPlacementID : kPlacementID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadAdFailureForEmptyAdUnitID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : @""};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorInvalidServerParameters
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadAdFailure {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorAdNotAvailable
                                                  userInfo:nil];
  [self stubLoadWithAndDoBlock:^(NSInvocation *invocation) {
    [self->_adLoader onVideoAdLoadFailed:kPlacementID unitId:kUnitID error:expectedError];
  }];

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;

  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testShowSuccessWithNoReward {
  UIViewController *controller = [[UIViewController alloc] init];
  OCMStub([_rewardedAdMock showVideoWithPlacementId:kPlacementID
                                             unitId:kUnitID
                                       withRewardId:nil
                                             userId:nil
                                           delegate:OCMOCK_ANY
                                     viewController:controller])
      .andDo(^(NSInvocation *invocation) {
        [self->_adLoader onVideoAdShowSuccess:kPlacementID unitId:kUnitID];
      });
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadAd];
  // Assert the initial values of the counts before they are verified after the "Act" steps.
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 0);
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);

  [_adLoader presentFromViewController:controller];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 1);

  [_adLoader onVideoPlayCompleted:kPlacementID unitId:kUnitID];
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 1);

  [_adLoader onVideoAdDismissed:kPlacementID unitId:kUnitID withConverted:NO withRewardInfo:nil];
  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 0);
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);

  [_adLoader onVideoAdDidClosed:kPlacementID unitId:kUnitID];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testShowSuccessWithReward {
  UIViewController *controller = [[UIViewController alloc] init];
  OCMStub([_rewardedAdMock showVideoWithPlacementId:kPlacementID
                                             unitId:kUnitID
                                       withRewardId:nil
                                             userId:nil
                                           delegate:OCMOCK_ANY
                                     viewController:controller])
      .andDo(^(NSInvocation *invocation) {
        [self->_adLoader onVideoAdShowSuccess:kPlacementID unitId:kUnitID];
      });
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadAd];
  // Assert the initial values of the counts before they are verified after the "Act" steps.
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 0);
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);

  [_adLoader presentFromViewController:controller];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 1);

  [_adLoader onVideoAdDismissed:kPlacementID unitId:kUnitID withConverted:YES withRewardInfo:nil];
  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 1);
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);

  [_adLoader onVideoAdDidClosed:kPlacementID unitId:kUnitID];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testShowFailure {
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMintegralErrorDomain
                                                      code:GADMintegralErrorAdFailedToShow
                                                  userInfo:nil];
  UIViewController *controller = [[UIViewController alloc] init];
  OCMStub([_rewardedAdMock showVideoWithPlacementId:kPlacementID
                                             unitId:kUnitID
                                       withRewardId:nil
                                             userId:nil
                                           delegate:OCMOCK_ANY
                                     viewController:controller])
      .andDo(^(NSInvocation *invocation) {
        [self->_adLoader onVideoAdShowFailed:kPlacementID unitId:kUnitID withError:expectedError];
      });
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadAd];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);

  [_adLoader presentFromViewController:controller];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqualObjects(eventDelegate.didFailToPresentError, expectedError);
}

- (void)testClick {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadAd];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);

  [_adLoader onVideoAdClicked:kPlacementID unitId:kUnitID];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testExtrasMuteVideoAudio {
  GADMAdapterMintegralExtras *extras = [[GADMAdapterMintegralExtras alloc] init];
  extras.muteVideoAudio = YES;

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterMintegralPlacementID : kPlacementID, GADMAdapterMintegralAdUnitID : kUnitID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = kBidResponse;
  configuration.extras = extras;

  [self stubLoadWithAndDoBlock:^(NSInvocation *invocation) {
    [self->_adLoader onVideoAdLoadSuccess:kPlacementID unitId:kUnitID];
  }];

  AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);
  XCTAssertNotNil(_adLoader);

  OCMExpect([_rewardedAdMock setPlayVideoMute:YES]);
  UIViewController *controller = [[UIViewController alloc] init];
  [_adLoader presentFromViewController:controller];
  OCMVerifyAll(_rewardedAdMock);
}

@end
