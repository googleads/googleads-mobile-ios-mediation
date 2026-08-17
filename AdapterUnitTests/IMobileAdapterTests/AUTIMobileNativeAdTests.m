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
#import <AdapterUnitTestKit/AUTKMediationNativeAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <ImobileSdkAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterIMobileConstants.h"
#import "GADMAdapterIMobileUtils.h"

static NSString *const kAUTPublisherID = @"test_publisher_id";
static NSString *const kAUTMediaID = @"test_media_id";
static NSString *const kAUTSpotID = @"test_spot_id";
static NSString *const kAUTHeadline = @"Test Headline";
static NSString *const kAUTBody = @"Test Description";
static NSString *const kAUTAdvertiser = @"Test Sponsored";

@interface AUTIMobileNativeAdTests : XCTestCase
@end

@implementation AUTIMobileNativeAdTests {
  /// The adapter under test.
  GADMediationAdapterIMobile *_adapter;

  /// Class mock for ImobileSdkAds.
  id _sdkMock;

  /// Mock instance of ImobileSdkAdsNativeObject.
  id _nativeAdMock;

  /// Test image used for native ad assets.
  UIImage *_testImage;
}

- (void)setUp {
  [super setUp];
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  _adapter = [[GADMediationAdapterIMobile alloc] init];
  _sdkMock = OCMClassMock([ImobileSdkAds class]);
  _nativeAdMock = OCMClassMock([ImobileSdkAdsNativeObject class]);

  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(100, 50)];
  _testImage =
      [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull rendererContext){
      }];

  OCMStub([_nativeAdMock getAdTitle]).andReturn(kAUTHeadline);
  OCMStub([_nativeAdMock getAdDescription]).andReturn(kAUTBody);
  OCMStub([_nativeAdMock getAdSponsored]).andReturn(kAUTAdvertiser);
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  OCMVerifyAll(_sdkMock);
  OCMVerifyAll(_nativeAdMock);
  [_sdkMock stopMocking];
  [_nativeAdMock stopMocking];
  _sdkMock = nil;
  _nativeAdMock = nil;
  [super tearDown];
}

- (nonnull AUTKMediationNativeAdEventDelegate *)loadNativeAd {
  return [self loadNativeAdWithImage:_testImage];
}

- (nonnull AUTKMediationNativeAdEventDelegate *)loadNativeAdWithImage:(nullable UIImage *)image {
  OCMStub(ClassMethod([_sdkMock getNativeAdData:OCMOCK_ANY
                                           View:OCMOCK_ANY
                                         Params:OCMOCK_ANY
                                       Delegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<IMobileSdkAdsDelegate> delegate = nil;
        __unsafe_unretained NSString *spotID = nil;
        [invocation getArgument:&spotID atIndex:2];
        [invocation getArgument:&delegate atIndex:5];
        [delegate onNativeAdDataReciveCompleted:spotID nativeArray:@[ self->_nativeAdMock ]];
      });

  OCMStub([_nativeAdMock getAdImageCompleteHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained void (^imageHandler)(UIImage *_Nullable);
    [invocation getArgument:&imageHandler atIndex:2];
    imageHandler(image);
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, configuration);
  XCTAssertNotNil(eventDelegate);
  XCTAssertNotNil(eventDelegate.nativeAd);

  return eventDelegate;
}

- (void)loadNativeAdFailureWithConfiguration:
            (nonnull GADMediationNativeAdConfiguration *)configuration
                               expectedError:(nonnull NSError *)expectedError {
  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, configuration, expectedError);
}

- (void)loadNativeAdFailureForChildUser {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
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

  [self loadNativeAdFailureWithConfiguration:configuration expectedError:expectedError];
}

#pragma mark - Success Tests

- (void)testLoadNativeAdSucceeds {
  [self loadNativeAd];
}

- (void)testLoadNativeAdSucceedsWhenTagForChildDirectedTreatmentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  [self loadNativeAd];
}

- (void)testLoadNativeAdSucceedsWhenTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  [self loadNativeAd];
}

- (void)testLoadNativeAdSucceedsWhenAgeRestrictedTreatmentIsTeen {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;
  [self loadNativeAd];
}

#pragma mark - Child User Tests

- (void)testLoadNativeAdFailsWhenTagForChildDirectedTreatmentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  [self loadNativeAdFailureForChildUser];
}

- (void)testLoadNativeAdFailsWhenTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  [self loadNativeAdFailureForChildUser];
}

- (void)testLoadNativeAdFailsWhenAgeRestrictedTreatmentIsChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  [self loadNativeAdFailureForChildUser];
}

#pragma mark - Parameter Validation Tests

- (void)testLoadNativeAdFailsWithMissingPublisherId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterIMobileMediaIdKey : kAUTMediaID, GADMAdapterIMobileSpotIdKey : kAUTSpotID};

  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorInvalidServerParameters
                             userInfo:nil];

  [self loadNativeAdFailureWithConfiguration:configuration expectedError:expectedError];
}

- (void)testLoadNativeAdFailsWithEmptyPublisherId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : @"",
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorInvalidServerParameters
                             userInfo:nil];

  [self loadNativeAdFailureWithConfiguration:configuration expectedError:expectedError];
}

- (void)testLoadNativeAdFailsWithMissingMediaId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorInvalidServerParameters
                             userInfo:nil];

  [self loadNativeAdFailureWithConfiguration:configuration expectedError:expectedError];
}

- (void)testLoadNativeAdFailsWithEmptyMediaId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : @"",
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorInvalidServerParameters
                             userInfo:nil];

  [self loadNativeAdFailureWithConfiguration:configuration expectedError:expectedError];
}

- (void)testLoadNativeAdFailsWithMissingSpotId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID
  };

  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorInvalidServerParameters
                             userInfo:nil];

  [self loadNativeAdFailureWithConfiguration:configuration expectedError:expectedError];
}

- (void)testLoadNativeAdFailsWithEmptySpotId {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : @""
  };

  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorInvalidServerParameters
                             userInfo:nil];

  [self loadNativeAdFailureWithConfiguration:configuration expectedError:expectedError];
}

#pragma mark - SDK Failure Tests

- (void)testLoadNativeAdFailsWhenIMobileFails {
  const NSInteger failResultCode = 12345;
  OCMStub(ClassMethod([_sdkMock getNativeAdData:OCMOCK_ANY
                                           View:OCMOCK_ANY
                                         Params:OCMOCK_ANY
                                       Delegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<IMobileSdkAdsDelegate> delegate = nil;
        __unsafe_unretained NSString *spotID = nil;
        [invocation getArgument:&spotID atIndex:2];
        [invocation getArgument:&delegate atIndex:5];
        [delegate imobileSdkAdsSpot:spotID
                   didFailWithValue:(ImobileSdkAdsFailResult)failResultCode];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                                      code:failResultCode
                                                  userInfo:nil];

  [self loadNativeAdFailureWithConfiguration:configuration expectedError:expectedError];
}

- (void)testLoadNativeAdFailsWithEmptyNativeArray {
  OCMStub(ClassMethod([_sdkMock getNativeAdData:OCMOCK_ANY
                                           View:OCMOCK_ANY
                                         Params:OCMOCK_ANY
                                       Delegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<IMobileSdkAdsDelegate> delegate = nil;
        __unsafe_unretained NSString *spotID = nil;
        [invocation getArgument:&spotID atIndex:2];
        [invocation getArgument:&delegate atIndex:5];
        [delegate onNativeAdDataReciveCompleted:spotID nativeArray:@[]];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                                      code:GADMAdapterIMobileErrorEmptyNativeAdArray
                                                  userInfo:nil];

  [self loadNativeAdFailureWithConfiguration:configuration expectedError:expectedError];
}

- (void)testLoadNativeAdFailsWhenImageDownloadFails {
  OCMStub(ClassMethod([_sdkMock getNativeAdData:OCMOCK_ANY
                                           View:OCMOCK_ANY
                                         Params:OCMOCK_ANY
                                       Delegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<IMobileSdkAdsDelegate> delegate = nil;
        __unsafe_unretained NSString *spotID = nil;
        [invocation getArgument:&spotID atIndex:2];
        [invocation getArgument:&delegate atIndex:5];
        [delegate onNativeAdDataReciveCompleted:spotID nativeArray:@[ self->_nativeAdMock ]];
      });

  OCMStub([_nativeAdMock getAdImageCompleteHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained void (^imageHandler)(UIImage *_Nullable);
    [invocation getArgument:&imageHandler atIndex:2];
    imageHandler(nil);
  });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIMobilePublisherIdKey : kAUTPublisherID,
    GADMAdapterIMobileMediaIdKey : kAUTMediaID,
    GADMAdapterIMobileSpotIdKey : kAUTSpotID
  };

  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIMobileErrorDomain
                                 code:GADMAdapterIMobileErrorNativeAssetsDownloadFailed
                             userInfo:nil];

  [self loadNativeAdFailureWithConfiguration:configuration expectedError:expectedError];
}

#pragma mark - Native Ad Properties Tests

- (void)testHeadline {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAd];
  XCTAssertEqualObjects(eventDelegate.nativeAd.headline, kAUTHeadline);
}

- (void)testBody {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAd];
  XCTAssertEqualObjects(eventDelegate.nativeAd.body, kAUTBody);
}

- (void)testAdvertiser {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAd];
  XCTAssertEqualObjects(eventDelegate.nativeAd.advertiser, kAUTAdvertiser);
}

- (void)testCallToAction {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAd];
  XCTAssertEqualObjects(eventDelegate.nativeAd.callToAction, GADMAdapterIMobileCallToAction);
}

- (void)testImages {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAd];
  XCTAssertEqual(eventDelegate.nativeAd.images.count, 1);
  XCTAssertEqualObjects(eventDelegate.nativeAd.images[0].image, _testImage);
}

- (void)testIcon {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAd];
  XCTAssertNotNil(eventDelegate.nativeAd.icon);
  XCTAssertEqual(eventDelegate.nativeAd.icon.image.size.width, 40);
  XCTAssertEqual(eventDelegate.nativeAd.icon.image.size.height, 40);
}

- (void)testMediaView {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAd];
  XCTAssertNotNil(eventDelegate.nativeAd.mediaView);
  XCTAssertTrue([eventDelegate.nativeAd.mediaView isKindOfClass:[UIImageView class]]);
  XCTAssertEqualObjects(((UIImageView *)eventDelegate.nativeAd.mediaView).image, _testImage);
}

- (void)testMediaContentAspectRatio {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAd];
  // testImage is 100x50, so width / height = 2.0.
  XCTAssertEqualWithAccuracy(eventDelegate.nativeAd.mediaContentAspectRatio, 2.0, 0.001);
}

- (void)testMediaContentAspectRatioWhenImageHasSquareDimensions {
  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(60, 60)];
  UIImage *squareImage =
      [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull rendererContext){
      }];

  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAdWithImage:squareImage];
  XCTAssertEqualWithAccuracy(eventDelegate.nativeAd.mediaContentAspectRatio, 1.0, 0.001);
}

- (void)testUnusedNativeAdProperties {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAd];
  XCTAssertNil(eventDelegate.nativeAd.starRating);
  XCTAssertNil(eventDelegate.nativeAd.store);
  XCTAssertNil(eventDelegate.nativeAd.price);
  XCTAssertNil(eventDelegate.nativeAd.extraAssets);
  XCTAssertNil(eventDelegate.nativeAd.adChoicesView);
}

- (void)testDidRecordClickOnAsset {
  AUTKMediationNativeAdEventDelegate *eventDelegate = [self loadNativeAd];
  OCMExpect([_nativeAdMock sendClick]);

  [eventDelegate.nativeAd didRecordClickOnAssetWithName:GADNativeHeadlineAsset
                                                   view:[[UIView alloc] init]
                                         viewController:[[UIViewController alloc] init]];

  OCMVerifyAll(_nativeAdMock);
}

@end
