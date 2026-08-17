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

#import "GADMediationAdapterFacebook.h"

#import <XCTest/XCTest.h>

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <AdapterUnitTestKit/AUTKConstants.h>
#import "GADFBNetworkExtras.h"
#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"

static NSString *const kAUTPlacementID1 = @"1234567890_1111111111";
static NSString *const kAUTPlacementID2 = @"1234567890_2222222222";

@interface AUTFBAdapterTests : XCTestCase
@end

@implementation AUTFBAdapterTests {
  GADMediationAdapterFacebook *_adapter;
  id _fbAdSettingsMock;
  id _fbAudienceNetworkAdsMock;
  id _fbAdInitSettingsMock;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterFacebook alloc] init];
  _fbAdSettingsMock = OCMClassMock([FBAdSettings class]);
  _fbAudienceNetworkAdsMock = OCMClassMock([FBAudienceNetworkAds class]);
}

- (void)tearDown {
  // Reset child-directed, under-age, and age-restricted tags to ensure test isolation.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
#pragma clang diagnostic pop
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  [_fbAdSettingsMock stopMocking];
  [_fbAudienceNetworkAdsMock stopMocking];
  [_fbAdInitSettingsMock stopMocking];

  _fbAdSettingsMock = nil;
  _fbAudienceNetworkAdsMock = nil;
  _fbAdInitSettingsMock = nil;
  _adapter = nil;

  [super tearDown];
}

#pragma mark - Version Tests

- (void)testAdapterVersion {
  GADVersionNumber version = [GADMediationAdapterFacebook adapterVersion];

  NSArray<NSString *> *components = [GADMAdapterFacebookVersion componentsSeparatedByString:@"."];
  XCTAssertEqual(components.count, 4);

  XCTAssertEqual(version.majorVersion, components[0].integerValue);
  XCTAssertEqual(version.minorVersion, components[1].integerValue);
  XCTAssertEqual(version.patchVersion,
                 components[2].integerValue * 100 + components[3].integerValue);

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 9999);
}

- (void)testAdSDKVersion {
  GADVersionNumber version = [GADMediationAdapterFacebook adSDKVersion];

  NSArray<NSString *> *components = [FB_AD_SDK_VERSION componentsSeparatedByString:@"."];
  XCTAssertEqual(components.count, 3);

  GADVersionNumber expectedSDKVersion = {
      .majorVersion = components[0].integerValue,
      .minorVersion = components[1].integerValue,
      .patchVersion = components[2].integerValue,
  };
  AUTKAssertEqualVersion(version, expectedSDKVersion);

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 99);
}

#pragma mark - Network Extras Class Test

- (void)testNetworkExtrasClass {
  XCTAssertEqual([GADMediationAdapterFacebook networkExtrasClass], [GADFBNetworkExtras class]);
}

#pragma mark - SetUp Tests

- (void)testSetUpWithConfiguration_Success {
  OCMStub(ClassMethod([_fbAudienceNetworkAdsMock initializeWithSettings:[OCMArg any]
                                                      completionHandler:[OCMArg any]]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(FBAdInitResults *results);
        [invocation getArgument:&completionHandler atIndex:3];
        id mockResults = OCMClassMock([FBAdInitResults class]);
        OCMStub([mockResults isSuccess]).andReturn(YES);
        completionHandler(mockResults);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterFacebookBiddingPubID : kAUTPlacementID1};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterFacebook class], credentials);
}

- (void)testSetUpWithConfiguration_Failure {
  NSString *errorMessage = @"Meta Audience Network failed to initialize.";
  OCMStub(ClassMethod([_fbAudienceNetworkAdsMock initializeWithSettings:[OCMArg any]
                                                      completionHandler:[OCMArg any]]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(FBAdInitResults *results);
        [invocation getArgument:&completionHandler atIndex:3];
        id mockResults = OCMClassMock([FBAdInitResults class]);
        OCMStub([mockResults isSuccess]).andReturn(NO);
        OCMStub([mockResults message]).andReturn(errorMessage);
        completionHandler(mockResults);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterFacebookBiddingPubID : kAUTPlacementID1};

  NSError *expectedError = [NSError errorWithDomain:@"com.google.mediation.facebook"
                                               code:GADFBErrorInitializationFailure
                                           userInfo:@{
                                             NSLocalizedDescriptionKey : errorMessage,
                                             NSLocalizedFailureReasonErrorKey : errorMessage,
                                           }];
  AUTKWaitAndAssertAdapterSetUpFailureWithCredentials([GADMediationAdapterFacebook class],
                                                      credentials, expectedError);
}

- (void)testSetUpWithConfiguration_MultipleCredentialsDeduplication {
  _fbAdInitSettingsMock = OCMClassMock([FBAdInitSettings class]);
  OCMStub([_fbAdInitSettingsMock alloc]).andReturn(_fbAdInitSettingsMock);

  id placementIDsCheck = [OCMArg checkWithBlock:^BOOL(id obj) {
    NSArray<NSString *> *placementIDs = (NSArray<NSString *> *)obj;
    NSSet<NSString *> *placementSet = [NSSet setWithArray:placementIDs];
    NSSet<NSString *> *expectedSet = [NSSet setWithArray:@[ kAUTPlacementID1, kAUTPlacementID2 ]];
    return placementIDs.count == 2 && [placementSet isEqualToSet:expectedSet];
  }];

  OCMExpect([_fbAdInitSettingsMock initWithPlacementIDs:placementIDsCheck
                                       mediationService:[OCMArg any]])
      .andReturn(_fbAdInitSettingsMock);

  OCMStub(ClassMethod([_fbAudienceNetworkAdsMock initializeWithSettings:[OCMArg any]
                                                      completionHandler:[OCMArg any]]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(FBAdInitResults *results);
        [invocation getArgument:&completionHandler atIndex:3];
        id mockResults = OCMClassMock([FBAdInitResults class]);
        OCMStub([mockResults isSuccess]).andReturn(YES);
        completionHandler(mockResults);
      });

  AUTKMediationCredentials *cred1 = [[AUTKMediationCredentials alloc] init];
  cred1.settings = @{GADMAdapterFacebookBiddingPubID : kAUTPlacementID1};

  AUTKMediationCredentials *cred2 = [[AUTKMediationCredentials alloc] init];
  cred2.settings = @{GADMAdapterFacebookPubID : kAUTPlacementID1};

  AUTKMediationCredentials *cred3 = [[AUTKMediationCredentials alloc] init];
  cred3.settings = @{GADMAdapterFacebookBiddingPubID : kAUTPlacementID2};

  AUTKMediationCredentials *cred4 = [[AUTKMediationCredentials alloc] init];
  cred4.settings = @{GADMAdapterFacebookPubID : kAUTPlacementID2};

  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray([GADMediationAdapterFacebook class],
                                                    @[ cred1, cred2, cred3, cred4 ]);

  OCMVerifyAll(_fbAdInitSettingsMock);
}

- (void)testSetUpWithConfiguration_MediationServiceString {
  NSString *expectedMediationService =
      [NSString stringWithFormat:@"GOOGLE_afma-sdk-i-v%ld.%ld.%ld:%@",
                                 (long)GADMobileAds.sharedInstance.versionNumber.majorVersion,
                                 (long)GADMobileAds.sharedInstance.versionNumber.minorVersion,
                                 (long)GADMobileAds.sharedInstance.versionNumber.patchVersion,
                                 GADMAdapterFacebookVersion];

  _fbAdInitSettingsMock = OCMClassMock([FBAdInitSettings class]);
  OCMStub([_fbAdInitSettingsMock alloc]).andReturn(_fbAdInitSettingsMock);

  id mediationServiceCheck = [OCMArg checkWithBlock:^BOOL(id obj) {
    NSString *mediationService = (NSString *)obj;
    return [mediationService isEqualToString:expectedMediationService];
  }];

  OCMExpect([_fbAdInitSettingsMock initWithPlacementIDs:[OCMArg any]
                                       mediationService:mediationServiceCheck])
      .andReturn(_fbAdInitSettingsMock);

  OCMStub(ClassMethod([_fbAudienceNetworkAdsMock initializeWithSettings:[OCMArg any]
                                                      completionHandler:[OCMArg any]]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(FBAdInitResults *results);
        [invocation getArgument:&completionHandler atIndex:3];
        id mockResults = OCMClassMock([FBAdInitResults class]);
        OCMStub([mockResults isSuccess]).andReturn(YES);
        completionHandler(mockResults);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterFacebookBiddingPubID : kAUTPlacementID1};

  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterFacebook class], credentials);

  OCMVerifyAll(_fbAdInitSettingsMock);
}

- (void)testSetUpWithConfiguration_EmptyCredentials {
  _fbAdInitSettingsMock = OCMClassMock([FBAdInitSettings class]);
  OCMStub([_fbAdInitSettingsMock alloc]).andReturn(_fbAdInitSettingsMock);

  OCMExpect([_fbAdInitSettingsMock initWithPlacementIDs:@[] mediationService:[OCMArg any]])
      .andReturn(_fbAdInitSettingsMock);

  OCMStub(ClassMethod([_fbAudienceNetworkAdsMock initializeWithSettings:[OCMArg any]
                                                      completionHandler:[OCMArg any]]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(FBAdInitResults *results);
        [invocation getArgument:&completionHandler atIndex:3];
        id mockResults = OCMClassMock([FBAdInitResults class]);
        OCMStub([mockResults isSuccess]).andReturn(YES);
        completionHandler(mockResults);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterFacebook class], credentials);

  OCMVerifyAll(_fbAdInitSettingsMock);
}

#pragma mark - Signal Collection Tests

- (void)testCollectSignals {
  NSString *testBidderToken = @"test_meta_bidder_token_xyz_123";
  OCMStub(ClassMethod([_fbAdSettingsMock bidderToken])).andReturn(testBidderToken);

  AUTKRTBRequestParameters *params = [[AUTKRTBRequestParameters alloc] init];
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Collect signals."];

  [_adapter
      collectSignalsForRequestParameters:params
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(error);
                         XCTAssertEqualObjects(signals, testBidderToken);
                         [expectation fulfill];
                       }];

  [self waitForExpectations:@[ expectation ] timeout:AUTKExpectationTimeout];
}

- (void)testCollectSignals_NilBidderToken {
  OCMStub(ClassMethod([_fbAdSettingsMock bidderToken])).andReturn(nil);

  AUTKRTBRequestParameters *params = [[AUTKRTBRequestParameters alloc] init];
  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Collect signals with nil token."];

  [_adapter
      collectSignalsForRequestParameters:params
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(error);
                         XCTAssertNil(signals);
                         [expectation fulfill];
                       }];

  [self waitForExpectations:@[ expectation ] timeout:AUTKExpectationTimeout];
}

#pragma mark - Format Routing & Mixed Audience Tests

- (void)testFormatRouting_SetsMixedAudience {
  // Test child directed = YES sets mixed audience to YES across all format loaders.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
#pragma clang diagnostic pop

  // 1. App Open
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);
  AUTKMediationAppOpenAdConfiguration *appOpenConfig =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  [_adapter loadAppOpenAdForAdConfiguration:appOpenConfig
                          completionHandler:^id<GADMediationAppOpenAdEventDelegate>(
                              id<GADMediationAppOpenAd> ad, NSError *error) {
                            return nil;
                          }];
  OCMVerifyAll(_fbAdSettingsMock);

  // 2. Banner
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);
  AUTKMediationBannerAdConfiguration *bannerConfig =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  [_adapter loadBannerForAdConfiguration:bannerConfig
                       completionHandler:^id<GADMediationBannerAdEventDelegate>(
                           id<GADMediationBannerAd> ad, NSError *error) {
                         return nil;
                       }];
  OCMVerifyAll(_fbAdSettingsMock);

  // 3. Interstitial
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);
  AUTKMediationInterstitialAdConfiguration *interstitialConfig =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  [_adapter loadInterstitialForAdConfiguration:interstitialConfig
                             completionHandler:^id<GADMediationInterstitialAdEventDelegate>(
                                 id<GADMediationInterstitialAd> ad, NSError *error) {
                               return nil;
                             }];
  OCMVerifyAll(_fbAdSettingsMock);

  // 4. Rewarded
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);
  AUTKMediationRewardedAdConfiguration *rewardedConfig =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  [_adapter loadRewardedAdForAdConfiguration:rewardedConfig
                           completionHandler:^id<GADMediationRewardedAdEventDelegate>(
                               id<GADMediationRewardedAd> ad, NSError *error) {
                             return nil;
                           }];
  OCMVerifyAll(_fbAdSettingsMock);

  // 5. Rewarded Interstitial
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);
  AUTKMediationRewardedAdConfiguration *rewardedInterstitialConfig =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  [_adapter loadRewardedInterstitialAdForAdConfiguration:rewardedInterstitialConfig
                                       completionHandler:^id<GADMediationRewardedAdEventDelegate>(
                                           id<GADMediationRewardedAd> ad, NSError *error) {
                                         return nil;
                                       }];
  OCMVerifyAll(_fbAdSettingsMock);

  // 6. Native
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);
  AUTKMediationNativeAdConfiguration *nativeConfig =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  [_adapter loadNativeAdForAdConfiguration:nativeConfig
                         completionHandler:^id<GADMediationNativeAdEventDelegate>(
                             id<GADMediationNativeAd> ad, NSError *error) {
                           return nil;
                         }];
  OCMVerifyAll(_fbAdSettingsMock);

  // Test child directed = NO and under age = NO sets mixed audience to NO across loaders.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
#pragma clang diagnostic pop

  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);
  [_adapter loadAppOpenAdForAdConfiguration:appOpenConfig
                          completionHandler:^id<GADMediationAppOpenAdEventDelegate>(
                              id<GADMediationAppOpenAd> ad, NSError *error) {
                            return nil;
                          }];
  OCMVerifyAll(_fbAdSettingsMock);

  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);
  [_adapter loadBannerForAdConfiguration:bannerConfig
                       completionHandler:^id<GADMediationBannerAdEventDelegate>(
                           id<GADMediationBannerAd> ad, NSError *error) {
                         return nil;
                       }];
  OCMVerifyAll(_fbAdSettingsMock);

  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);
  [_adapter loadInterstitialForAdConfiguration:interstitialConfig
                             completionHandler:^id<GADMediationInterstitialAdEventDelegate>(
                                 id<GADMediationInterstitialAd> ad, NSError *error) {
                               return nil;
                             }];
  OCMVerifyAll(_fbAdSettingsMock);

  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);
  [_adapter loadRewardedAdForAdConfiguration:rewardedConfig
                           completionHandler:^id<GADMediationRewardedAdEventDelegate>(
                               id<GADMediationRewardedAd> ad, NSError *error) {
                             return nil;
                           }];
  OCMVerifyAll(_fbAdSettingsMock);

  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);
  [_adapter loadRewardedInterstitialAdForAdConfiguration:rewardedInterstitialConfig
                                       completionHandler:^id<GADMediationRewardedAdEventDelegate>(
                                           id<GADMediationRewardedAd> ad, NSError *error) {
                                         return nil;
                                       }];
  OCMVerifyAll(_fbAdSettingsMock);

  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);
  [_adapter loadNativeAdForAdConfiguration:nativeConfig
                         completionHandler:^id<GADMediationNativeAdEventDelegate>(
                             id<GADMediationNativeAd> ad, NSError *error) {
                           return nil;
                         }];
  OCMVerifyAll(_fbAdSettingsMock);
}

@end
