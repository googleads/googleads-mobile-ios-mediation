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

#import "GADMediationAdapterFyber.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationNativeAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IASDKCore/IASDKCore.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterFyberConstants.h"
#import "GADMAdapterFyberExtras.h"
#import "GADMAdapterFyberNativeAd.h"

static NSString *const kDTExchangeAppID = @"12345";
static NSString *const kDTExchangeSpotID = @"67890";
static NSString *const kDTExchangeBidResponse = @"test_bid_response";
static NSString *const kDTExchangeWatermark = @"test_watermark";

@interface AUTDTExchangeNativeAdTests : XCTestCase
@end

@implementation AUTDTExchangeNativeAdTests {
  /// An adapter instance that is used to test loading a native ad.
  GADMediationAdapterFyber *_adapter;

  /// IASDKCore mock.
  id _IASDKCoreMock;

  /// IANativeAdSpot mock.
  id _IANativeAdSpotMock;

  /// IANativeAdAssets mock.
  id _nativeAdAssetsMock;

  /// IAAdRequest mock.
  id _IAAdRequestMock;

  /// IAAdRequestBuilder mock.
  id _IAAdRequestBuilderMock;

  /// IANativeAdSpotBuilder mock.
  id _IANativeAdSpotBuilderMock;
}

- (void)setUp {
  [super setUp];

  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  _adapter = [[GADMediationAdapterFyber alloc] init];

  _IASDKCoreMock = OCMClassMock([IASDKCore class]);
  OCMStub(ClassMethod([_IASDKCoreMock sharedInstance])).andReturn(_IASDKCoreMock);
  OCMStub([_IASDKCoreMock setMediationType:[OCMArg isKindOfClass:[IAMediationAdMob class]]]);

  _IAAdRequestBuilderMock = OCMProtocolMock(@protocol(IAAdRequestBuilder));
  OCMStub([_IAAdRequestBuilderMock setTimeout:10]);

  _IAAdRequestMock = OCMClassMock([IAAdRequest class]);
  OCMStub(ClassMethod([_IAAdRequestMock build:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(id<IAAdRequestBuilder>);
        [invocation getArgument:&completionHandler atIndex:2];
        completionHandler(self->_IAAdRequestBuilderMock);
      })
      .andReturn(_IAAdRequestMock);

  _IANativeAdSpotBuilderMock = OCMProtocolMock(@protocol(IANativeAdSpotBuilder));
  OCMStub([_IANativeAdSpotBuilderMock setAdRequest:_IAAdRequestMock]);
  OCMStub([_IANativeAdSpotBuilderMock setDelegate:OCMOCK_ANY]);

  _IANativeAdSpotMock = OCMClassMock([IANativeAdSpot class]);
  OCMStub(ClassMethod([_IANativeAdSpotMock build:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(id<IANativeAdSpotBuilder>);
        [invocation getArgument:&completionHandler atIndex:2];
        completionHandler(self->_IANativeAdSpotBuilderMock);
      })
      .andReturn(_IANativeAdSpotMock);

  _nativeAdAssetsMock = OCMClassMock([IANativeAdAssets class]);
}

- (void)tearDown {
  [_IASDKCoreMock stopMocking];
  [_IANativeAdSpotMock stopMocking];
  [_nativeAdAssetsMock stopMocking];
  [_IAAdRequestMock stopMocking];

  [super tearDown];
}

- (nonnull AUTKMediationNativeAdConfiguration *)
    createAdConfigurationWithAppId:(nullable NSString *)appId
                            spotId:(nullable NSString *)spotId
                       bidResponse:(nullable NSString *)bidResponse
                         watermark:(nullable NSData *)watermark {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  NSMutableDictionary<NSString *, id> *settings = [[NSMutableDictionary alloc] init];
  if (appId) {
    settings[GADMAdapterFyberApplicationID] = appId;
  }
  if (spotId) {
    settings[GADMAdapterFyberSpotID] = spotId;
  }
  credentials.settings = settings;

  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.bidResponse = bidResponse;
  configuration.watermark = watermark;
  configuration.topViewController = [[UIViewController alloc] init];

  return configuration;
}

- (nonnull AUTKMediationNativeAdEventDelegate *)loadNativeAdSuccessWithSpotId:
    (nullable NSString *)spotId {
  NSData *watermarkData = [kDTExchangeWatermark dataUsingEncoding:NSUTF8StringEncoding];

  OCMStub([_IASDKCoreMock initWithAppID:kDTExchangeAppID
                        completionBlock:OCMOCK_ANY
                        completionQueue:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(YES, nil);
      });

  if (spotId.length) {
    OCMExpect([_IANativeAdSpotBuilderMock setUserInfo:@{@"DTSpotID" : spotId}]);
  }

  OCMStub([_IANativeAdSpotMock loadAdWithMarkup:kDTExchangeBidResponse
                              withWatermarkData:watermarkData
                                 withCompletion:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(IANativeAdAssets *_Nullable nativeAdAssets,
                                                      NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:4];
        completionHandler(self->_nativeAdAssetsMock, nil);
      });

  AUTKMediationNativeAdConfiguration *configuration =
      [self createAdConfigurationWithAppId:kDTExchangeAppID
                                    spotId:spotId
                               bidResponse:kDTExchangeBidResponse
                                 watermark:watermarkData];

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, configuration);
  XCTAssertNotNil(eventDelegate);
  XCTAssertNotNil(eventDelegate.nativeAd);
  return eventDelegate;
}

#pragma mark - Tests

- (void)testLoadNativeAdSuccess {
  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdSuccessWithSpotId:kDTExchangeSpotID];
  XCTAssertNotNil(eventDelegate);
  XCTAssertNotNil(eventDelegate.nativeAd);
}

- (void)testLoadNativeAdFailure_SDKInitError {
  NSError *expectedError = [[NSError alloc] initWithDomain:@"com.Fyber.domain"
                                                      code:123456
                                                  userInfo:nil];
  OCMStub([_IASDKCoreMock initWithAppID:kDTExchangeAppID
                        completionBlock:OCMOCK_ANY
                        completionQueue:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(NO, expectedError);
      });

  AUTKMediationNativeAdConfiguration *configuration =
      [self createAdConfigurationWithAppId:kDTExchangeAppID
                                    spotId:kDTExchangeSpotID
                               bidResponse:kDTExchangeBidResponse
                                 watermark:nil];

  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadNativeAdFailure_MissingAppId {
  OCMStub([_IASDKCoreMock isInitialised]).andReturn(NO);

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterFyberErrorDomain
                                 code:GADMAdapterFyberErrorInvalidServerParameters
                             userInfo:nil];

  AUTKMediationNativeAdConfiguration *configuration =
      [self createAdConfigurationWithAppId:nil
                                    spotId:kDTExchangeSpotID
                               bidResponse:kDTExchangeBidResponse
                                 watermark:nil];

  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadNativeAdFailure_SpotLoadError {
  NSError *spotLoadError = [[NSError alloc] initWithDomain:@"com.Fyber.native.spot"
                                                      code:999
                                                  userInfo:nil];
  NSData *watermarkData = [kDTExchangeWatermark dataUsingEncoding:NSUTF8StringEncoding];

  OCMStub([_IASDKCoreMock initWithAppID:kDTExchangeAppID
                        completionBlock:OCMOCK_ANY
                        completionQueue:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(YES, nil);
      });

  OCMStub([_IANativeAdSpotMock loadAdWithMarkup:kDTExchangeBidResponse
                              withWatermarkData:watermarkData
                                 withCompletion:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionHandler)(IANativeAdAssets *_Nullable nativeAdAssets,
                                                      NSError *_Nullable error);
        [invocation getArgument:&completionHandler atIndex:4];
        completionHandler(nil, spotLoadError);
      });

  AUTKMediationNativeAdConfiguration *configuration =
      [self createAdConfigurationWithAppId:kDTExchangeAppID
                                    spotId:kDTExchangeSpotID
                               bidResponse:kDTExchangeBidResponse
                                 watermark:watermarkData];

  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, configuration, spotLoadError);
}

- (void)testPrivacyFlagsCOPPA {
  // 1. COPPA Given when tagForChildDirectedTreatment is YES
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  OCMExpect([_IASDKCoreMock setCoppaApplies:IACoppaAppliesTypeGiven]);
  [self loadNativeAdSuccessWithSpotId:kDTExchangeSpotID];
  OCMVerifyAll(_IASDKCoreMock);

  // 2. COPPA Denied when tagForChildDirectedTreatment is NO
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect([_IASDKCoreMock setCoppaApplies:IACoppaAppliesTypeDenied]);
  [self loadNativeAdSuccessWithSpotId:kDTExchangeSpotID];
  OCMVerifyAll(_IASDKCoreMock);

  // 3. COPPA Given when tagForUnderAgeOfConsent is YES
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_IASDKCoreMock setCoppaApplies:IACoppaAppliesTypeGiven]);
  [self loadNativeAdSuccessWithSpotId:kDTExchangeSpotID];
  OCMVerifyAll(_IASDKCoreMock);

  // 4. COPPA Denied when tagForUnderAgeOfConsent is NO
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_IASDKCoreMock setCoppaApplies:IACoppaAppliesTypeDenied]);
  [self loadNativeAdSuccessWithSpotId:kDTExchangeSpotID];
  OCMVerifyAll(_IASDKCoreMock);

  // 5. COPPA Given when ageRestrictedTreatment is Child
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  OCMExpect([_IASDKCoreMock setCoppaApplies:IACoppaAppliesTypeGiven]);
  [self loadNativeAdSuccessWithSpotId:kDTExchangeSpotID];
  OCMVerifyAll(_IASDKCoreMock);

  // 6. COPPA Unknown when no flags are set
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;
  OCMExpect([_IASDKCoreMock setCoppaApplies:IACoppaAppliesTypeUnknown]);
  [self loadNativeAdSuccessWithSpotId:kDTExchangeSpotID];
  OCMVerifyAll(_IASDKCoreMock);
}

- (void)testHandlesUserClicksAndImpressionsReturnsYes {
  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdSuccessWithSpotId:kDTExchangeSpotID];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertTrue(nativeAd.handlesUserClicks);
  XCTAssertTrue(nativeAd.handlesUserImpressions);
}

- (void)testNativeAdAssetsGetters {
  NSString *expectedTitle = @"Test Headline";
  NSString *expectedBody = @"Test Body Description";
  NSString *expectedCallToAction = @"Install";
  NSDecimalNumber *expectedRating = [NSDecimalNumber decimalNumberWithString:@"4.5"];
  NSNumber *expectedAspectRatio = @(1.77f);
  UIView *expectedMediaView = [[UIView alloc] init];

  OCMStub([_nativeAdAssetsMock adTitle]).andReturn(expectedTitle);
  OCMStub([_nativeAdAssetsMock adDescription]).andReturn(expectedBody);
  OCMStub([_nativeAdAssetsMock callToActionText]).andReturn(expectedCallToAction);
  OCMStub([_nativeAdAssetsMock rating]).andReturn(expectedRating);
  OCMStub([(IANativeAdAssets *)_nativeAdAssetsMock mediaAspectRatio])
      .andReturn(expectedAspectRatio);
  OCMStub([_nativeAdAssetsMock mediaView]).andReturn(expectedMediaView);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdSuccessWithSpotId:kDTExchangeSpotID];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertEqualObjects(nativeAd.headline, expectedTitle);
  XCTAssertEqualObjects(nativeAd.body, expectedBody);
  XCTAssertEqualObjects(nativeAd.callToAction, expectedCallToAction);
  XCTAssertEqualObjects(nativeAd.starRating, expectedRating);
  XCTAssertEqualWithAccuracy(nativeAd.mediaContentAspectRatio, 1.77f, 0.001);
  XCTAssertEqualObjects(nativeAd.mediaView, expectedMediaView);
  XCTAssertTrue(nativeAd.hasVideoContent);
}

- (void)testNativeAdImagesAndIcon {
  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(10, 10)];
  UIImage *mediaImage =
      [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull rendererContext){
      }];
  UIImage *iconImage =
      [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull rendererContext){
      }];

  UIImageView *mediaImageView = [[UIImageView alloc] initWithImage:mediaImage];
  UIImageView *iconImageView = [[UIImageView alloc] initWithImage:iconImage];

  OCMStub([_nativeAdAssetsMock mediaView]).andReturn(mediaImageView);
  OCMStub([_nativeAdAssetsMock appIcon]).andReturn(iconImageView);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdSuccessWithSpotId:kDTExchangeSpotID];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  NSArray<GADNativeAdImage *> *images = nativeAd.images;
  XCTAssertEqual(images.count, 1);
  XCTAssertEqualObjects(images.firstObject.image, mediaImage);

  GADNativeAdImage *icon = nativeAd.icon;
  XCTAssertNotNil(icon);
  XCTAssertEqualObjects(icon.image, iconImage);
}

- (void)testNativeAdImagesAndIcon_FallbackWhenNotImageView {
  UIView *plainMediaView = [[UIView alloc] init];
  UIImageView *emptyIconImageView = [[UIImageView alloc] init];
  OCMStub([_nativeAdAssetsMock mediaView]).andReturn(plainMediaView);
  OCMStub([_nativeAdAssetsMock appIcon]).andReturn(emptyIconImageView);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdSuccessWithSpotId:kDTExchangeSpotID];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertEqualObjects(nativeAd.images, @[]);
  XCTAssertNil(nativeAd.icon);
}

- (void)testUnsupportedAssetsReturnNil {
  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdSuccessWithSpotId:kDTExchangeSpotID];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  XCTAssertNil(nativeAd.store);
  XCTAssertNil(nativeAd.price);
  XCTAssertNil(nativeAd.advertiser);
  XCTAssertNil(nativeAd.extraAssets);
  XCTAssertNil(nativeAd.adChoicesView);
}

- (void)testDidRenderInViewRegistersInteraction {
  static const NSInteger kViewTagMediaView = 2;
  static const NSInteger kViewTagIcon = 4;
  static const NSInteger kViewTagOther = 99;

  UIView *containerView = [[UIView alloc] init];
  UIView *mediaView = [[UIView alloc] init];
  mediaView.tag = kViewTagMediaView;
  UIView *iconView = [[UIView alloc] init];
  iconView.tag = kViewTagIcon;
  UIView *headlineView = [[UIView alloc] init];
  headlineView.tag = kViewTagOther;

  NSDictionary<GADNativeAssetIdentifier, UIView *> *clickableAssetViews = @{
    GADNativeMediaViewAsset : mediaView,
    GADNativeIconAsset : iconView,
    GADNativeHeadlineAsset : headlineView
  };

  OCMExpect([_nativeAdAssetsMock registerViewForInteraction:containerView
                                                  mediaView:mediaView
                                                   iconView:iconView
                                             clickableViews:@[ headlineView ]]);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdSuccessWithSpotId:kDTExchangeSpotID];
  id<GADMediationNativeAd> nativeAd = eventDelegate.nativeAd;

  [nativeAd didRenderInView:containerView
         clickableAssetViews:clickableAssetViews
      nonclickableAssetViews:@{}
              viewController:[[UIViewController alloc] init]];

  OCMVerifyAll(_nativeAdAssetsMock);
}

- (void)testIANativeAdDelegateCallbacks {
  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdSuccessWithSpotId:kDTExchangeSpotID];
  id<IANativeAdDelegate> nativeAdDelegate = (id<IANativeAdDelegate>)eventDelegate.nativeAd;

  // Click
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);
  [nativeAdDelegate iaNativeAdDidReceiveClick:_IANativeAdSpotMock origin:@"test_origin"];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);

  // Impression
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  [nativeAdDelegate iaNativeAdWillLogImpression:_IANativeAdSpotMock];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);

  // Fullscreen will present
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  [nativeAdDelegate iaNativeAdWillPresentFullscreen:_IANativeAdSpotMock];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);

  // Fullscreen will dismiss
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  [nativeAdDelegate iaNativeAdWillDismissFullscreen:_IANativeAdSpotMock];
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);

  // Fullscreen did dismiss
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);
  [nativeAdDelegate iaNativeAdDidDismissFullscreen:_IANativeAdSpotMock];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);

  // Video completed
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 0);
  [nativeAdDelegate iaNativeAdVideoCompleted:_IANativeAdSpotMock];
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 1);

  // Parent view controller
  UIViewController *parentVC =
      [nativeAdDelegate iaParentViewControllerForAdSpot:_IANativeAdSpotMock];
  XCTAssertNotNil(parentVC);
}

@end
