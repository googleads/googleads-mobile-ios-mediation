#import "GADMAdapterInMobiUnifiedNativeAd.h"

#import <XCTest/XCTest.h>

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <InMobiSDK/InMobiSDK-Swift.h>

#import <OCMock/OCMock.h>

#import "AUTInMobiUtils.h"
#import "AUTTestUtils.h"
#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiInitializer.h"
#import "GADMAdapterInMobiUtils.h"
#import "GADMediation+AdapterUnitTests.h"
#import "GADMediationAdapterInMobi.h"
#import "NativeAdKeys.h"

/**
 * Returns a correctly configured native ad configuration.
 */
static GADMediationNativeAdConfiguration *_Nonnull AUTGADMediationNativeAdConfigurationForInMobi() {
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatNative
                                            credentials:@{
                                              GADMAdapterInMobiAccountID : AUTInMobiAccountID,
                                              GADMAdapterInMobiPlacementID : AUTInMobiPlacementID
                                            }];
  GADInMobiExtras *extras = [[GADInMobiExtras alloc] init];
  [extras setKeywords:AUTInMobiKeywords];
  GADMediationNativeAdConfiguration *adConfiguration =
      [[GADMediationNativeAdConfiguration alloc] initWithOptions:nil
                                                 adConfiguration:nil
                                                       targeting:nil
                                                     credentials:credentials
                                                          extras:extras];
  return adConfiguration;
}

@interface AUTInMobiUnifiedNativeAdTest : XCTestCase
@end

@implementation AUTInMobiUnifiedNativeAdTest {
  GADMAdapterInMobiUnifiedNativeAd *_nativeAd;
  IMNative *_nativeMock;
  // Variables used for mocking IMSDK.
  NSString *_title;
  NSString *_description;
  NSString *_callToAction;
  NSString *_price;
  NSDecimalNumber *_rating;
  GADNativeAdImage *_nativeImage;
  NSURL *_adLandingPageURL;
  NSURL *_iconURL;
  UIImage *_testImage;
  NSString *_advertiserName;
  id<GADMediationNativeAdEventDelegate> _nativeAdEventDelegate;
}

- (void)setUp {
  [super setUp];
  AUTMockGADMAdapterInMobiInitializer();
  AUTMockIMSDKInit();

  // Initialize test properties.
  _title = @"title";
  _description = @"description";
  _callToAction = @"call-to-action";
  _price = @"12345";
  _rating = [[NSDecimalNumber alloc] initWithInt:12345];
  _nativeImage = [[GADNativeAdImage alloc] init];
  _adLandingPageURL = [[NSURL alloc] initWithString:@"https://www.google.com/"];
  _iconURL = [[NSURL alloc] initWithString:@"https://www.google.com/"];
  _advertiserName = @"advName";
  _testImage = [[UIImage alloc] init];
  _nativeAdEventDelegate = OCMProtocolMock(@protocol(GADMediationNativeAdEventDelegate));

  _nativeAd = [[GADMAdapterInMobiUnifiedNativeAd alloc] init];

  // Mock IMNative convenience initializer.
  id nativeMock = OCMClassMock([IMNative class]);
  OCMStub([nativeMock alloc]).andReturn(nativeMock);
  OCMStub([nativeMock initWithPlacementId:[AUTInMobiPlacementID longLongValue] delegate:OCMOCK_ANY])
      .andReturn(nativeMock);
  _nativeMock = (IMNative *)nativeMock;

  // Mock IMNative property.
  OCMStub([_nativeMock adTitle]).andReturn(_title);
  OCMStub([_nativeMock adDescription]).andReturn(_description);
  OCMStub([_nativeMock adCtaText]).andReturn(_callToAction);
  OCMStub([_nativeMock adRating]).andReturn(_rating);
  UIView *primaryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
  OCMStub([_nativeMock getMediaView]).andReturn(primaryView);
  OCMStub([_nativeMock isVideoAd]).andReturn(true);
  OCMStub([_nativeMock advertiserName]).andReturn(_advertiserName);
}

/// Load native ad for given parameters.
- (void)loadNativeAdSuccessfullyForAdConfiguration:(nonnull GADMediationNativeAdConfiguration *)
                                                       adConfiguration {
  OCMStub([_nativeMock load]).andDo(^(NSInvocation *invocation) {
    id<IMNativeDelegate> delegate = (id<IMNativeDelegate>)_nativeAd;
    [delegate nativeDidFinishLoading:_nativeMock];
  });

  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Completion handler ran."];
  GADMediationNativeLoadCompletionHandler completionHandler =
      ^(id<GADMediationNativeAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertEqualObjects(ad, _nativeAd);
        XCTAssertNil(error);
        [expectation fulfill];
        return _nativeAdEventDelegate;
      };
  [_nativeAd loadNativeAdForAdConfiguration:adConfiguration completionHandler:completionHandler];

  [self waitForExpectations:@[ expectation ] timeout:AUTExpectationTimeout];
  OCMVerifyAll(_nativeMock);
}

- (void)testInitializerFailure {
  // Mock 3rd party SDK to call completion handler with an error.
  NSError *expectedError = OCMClassMock([NSError class]);
  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMStub(ClassMethod([IMSDKMock initWithAccountID:OCMOCK_ANY
                                 consentDictionary:OCMOCK_ANY
                              andCompletionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionBlock)(NSError *_Nullable);
        [invocation getArgument:&completionBlock atIndex:4];
        completionBlock(expectedError);
      });

  __block BOOL completionHandlerInvoked = NO;
  GADMediationNativeLoadCompletionHandler completionHandler =
      ^(id<GADMediationNativeAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNil(ad);
        XCTAssertEqualObjects(error, expectedError);
        completionHandlerInvoked = YES;
        return _nativeAdEventDelegate;
      };
  [_nativeAd loadNativeAdForAdConfiguration:AUTGADMediationNativeAdConfigurationForInMobi()
                          completionHandler:completionHandler];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testLoadNativeAdForAdConfiguration {
  GADMediationNativeAdConfiguration *configuration =
      AUTGADMediationNativeAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment);
  OCMExpect([_nativeMock setExtras:requestParameters]);

  [self loadNativeAdSuccessfullyForAdConfiguration:configuration];

  // Verify that the loaded native ad properties have the expected values.
  XCTAssertNil(_nativeAd.adChoicesView);
  XCTAssertNotNil(_nativeAd.mediaView);
  XCTAssertTrue(_nativeAd.hasVideoContent);
  XCTAssertEqualObjects(_nativeAd.headline, _title);
  XCTAssertEqualObjects(_nativeAd.body, _description);
  XCTAssertEqualObjects(_nativeAd.callToAction, _callToAction);
  XCTAssertEqualObjects(_nativeAd.starRating, _rating);
  XCTAssertEqualObjects(_nativeAd.advertiser, _advertiserName);
  XCTAssertNil(_nativeAd.extraAssets);
}

- (void)testLoadRTBNativeAdForAdConfiguration {
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatNative
                                            credentials:@{
                                              GADMAdapterInMobiAccountID : AUTInMobiAccountID,
                                              GADMAdapterInMobiPlacementID : AUTInMobiPlacementID
                                            }];
  GADInMobiExtras *extras = [[GADInMobiExtras alloc] init];
  [extras setKeywords:AUTInMobiKeywords];

  NSString *bidResponse = @"bidResponse";
  GADMediationNativeAdConfiguration *adConfiguration =
      [[GADMediationNativeAdConfiguration alloc] initWithOptions:nil
                                                 adConfiguration:@{@"bid_response" : bidResponse}
                                                       targeting:nil
                                                     credentials:credentials
                                                          extras:extras];

  GADMediationNativeAdConfiguration *configuration =
      AUTGADMediationNativeAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeRTB,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment);
  OCMExpect([_nativeMock setExtras:requestParameters]);

  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];
  OCMStub([_nativeMock load:bidResponseData]).andDo(^(NSInvocation *invocation) {
    XCTAssertTrue([_nativeAd conformsToProtocol:@protocol(IMNativeDelegate)]);
    id<IMNativeDelegate> delegate = (id<IMNativeDelegate>)_nativeAd;
    [delegate nativeDidFinishLoading:_nativeMock];
  });

  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Completion handler ran."];
  GADMediationNativeLoadCompletionHandler completionHandler =
      ^(id<GADMediationNativeAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertEqualObjects(ad, _nativeAd);
        XCTAssertNil(error);
        [expectation fulfill];
        return _nativeAdEventDelegate;
      };

  [_nativeAd loadNativeAdForAdConfiguration:adConfiguration completionHandler:completionHandler];

  [self waitForExpectations:@[ expectation ] timeout:AUTExpectationTimeout];
  OCMVerifyAll(_nativeMock);

  // Verify that the loaded native ad properties have the expected values.
  XCTAssertNil(_nativeAd.adChoicesView);
  XCTAssertNil(_nativeAd.images);
  XCTAssertNotNil(_nativeAd.mediaView);
  XCTAssertTrue(_nativeAd.hasVideoContent);
  XCTAssertEqualObjects(_nativeAd.headline, _title);
  XCTAssertEqualObjects(_nativeAd.body, _description);
  XCTAssertEqualObjects(_nativeAd.callToAction, _callToAction);
  XCTAssertEqualObjects(_nativeAd.starRating, _rating);
  XCTAssertEqualObjects(_nativeAd.advertiser, _advertiserName);
  XCTAssertNil(_nativeAd.extraAssets);
}

- (void)testLoadRTBNativeAdWithoutPlacementID {
  OCMStub([_nativeMock initWithPlacementId:0 delegate:OCMOCK_ANY]).andReturn(_nativeMock);
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatNative
                                            credentials:@{
                                              GADMAdapterInMobiAccountID : AUTInMobiAccountID,
                                            }];
  GADInMobiExtras *extras = [[GADInMobiExtras alloc] init];
  [extras setKeywords:AUTInMobiKeywords];

  NSString *bidResponse = @"bidResponse";
  GADMediationNativeAdConfiguration *adConfiguration =
      [[GADMediationNativeAdConfiguration alloc] initWithOptions:nil
                                                 adConfiguration:@{@"bid_response" : bidResponse}
                                                       targeting:nil
                                                     credentials:credentials
                                                          extras:extras];

  GADMediationNativeAdConfiguration *configuration =
      AUTGADMediationNativeAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeRTB,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment);
  OCMExpect([_nativeMock setExtras:requestParameters]);

  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];
  OCMStub([_nativeMock load:bidResponseData]).andDo(^(NSInvocation *invocation) {
    XCTAssertTrue([_nativeAd conformsToProtocol:@protocol(IMNativeDelegate)]);
    id<IMNativeDelegate> delegate = (id<IMNativeDelegate>)_nativeAd;
    [delegate nativeDidFinishLoading:_nativeMock];
  });

  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Completion handler ran."];
  GADMediationNativeLoadCompletionHandler completionHandler =
      ^(id<GADMediationNativeAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertEqualObjects(ad, _nativeAd);
        XCTAssertNil(error);
        [expectation fulfill];
        return _nativeAdEventDelegate;
      };

  [_nativeAd loadNativeAdForAdConfiguration:adConfiguration completionHandler:completionHandler];

  [self waitForExpectations:@[ expectation ] timeout:AUTExpectationTimeout];
  OCMVerifyAll(_nativeMock);

  // Verify that the loaded native ad properties have the expected values.
  XCTAssertNil(_nativeAd.adChoicesView);
  XCTAssertNil(_nativeAd.images);
  XCTAssertNil(_nativeAd.extraAssets);
  XCTAssertNotNil(_nativeAd.mediaView);
  XCTAssertTrue(_nativeAd.hasVideoContent);
  XCTAssertEqualObjects(_nativeAd.headline, _title);
  XCTAssertEqualObjects(_nativeAd.body, _description);
  XCTAssertEqualObjects(_nativeAd.callToAction, _callToAction);
  XCTAssertEqualObjects(_nativeAd.starRating, _rating);
  XCTAssertEqualObjects(_nativeAd.advertiser, _advertiserName);
}

- (void)testLoadNativeAdForAdConfigurationWithImageLoadDisabled {
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatNative
                                            credentials:@{
                                              GADMAdapterInMobiAccountID : AUTInMobiAccountID,
                                              GADMAdapterInMobiPlacementID : AUTInMobiPlacementID
                                            }];
  GADNativeAdImageAdLoaderOptions *options = [[GADNativeAdImageAdLoaderOptions alloc] init];
  [options setDisableImageLoading:YES];
  GADMediationNativeAdConfiguration *adConfiguration =
      [[GADMediationNativeAdConfiguration alloc] initWithOptions:@[ options ]
                                                 adConfiguration:nil
                                                       targeting:nil
                                                     credentials:credentials
                                                          extras:nil];

  [self loadNativeAdSuccessfullyForAdConfiguration:adConfiguration];

  // Verify the loaded native ad properties to have the expected values.
  XCTAssertNil(_nativeAd.adChoicesView);
  XCTAssertNil(_nativeAd.extraAssets);
  XCTAssertNil(_nativeAd.store);
  XCTAssertNil(_nativeAd.images);
  XCTAssertNotNil(_nativeAd.mediaView);
  XCTAssertTrue(_nativeAd.hasVideoContent);
  XCTAssertEqualObjects(_nativeAd.headline, _title);
  XCTAssertEqualObjects(_nativeAd.body, _description);
  XCTAssertEqualObjects(_nativeAd.callToAction, _callToAction);
  XCTAssertEqualObjects(_nativeAd.starRating, _rating);
  XCTAssertEqualObjects(_nativeAd.advertiser, _advertiserName);
}

- (void)testLoadNativeAdForAdConfigurationWithoutLandingPageURL {
  OCMStub([_nativeMock load]).andDo(^(NSInvocation *invocation) {
    id<IMNativeDelegate> delegate = (id<IMNativeDelegate>)_nativeAd;
    [delegate nativeDidFinishLoading:_nativeMock];
  });

  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Completion handler ran."];
  GADMediationNativeLoadCompletionHandler completionHandler =
      ^(id<GADMediationNativeAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNotNil(ad);
        XCTAssertNil(error);
        [expectation fulfill];
        return _nativeAdEventDelegate;
      };

  [_nativeAd loadNativeAdForAdConfiguration:AUTGADMediationNativeAdConfigurationForInMobi()
                          completionHandler:completionHandler];

  [self waitForExpectations:@[ expectation ] timeout:AUTExpectationTimeout];

  XCTAssertNil([_nativeAd extraAssets]);
}

- (void)testLoadNativeAdForAdConfigurationFailureWithNilPlacementID {
  // Omit placement ID from the credentials.
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatNative
                                            credentials:@{
                                              GADMAdapterInMobiAccountID : AUTInMobiAccountID,
                                            }];
  GADMediationNativeAdConfiguration *adConfiguration =
      [[GADMediationNativeAdConfiguration alloc] initWithOptions:nil
                                                 adConfiguration:nil
                                                       targeting:nil
                                                     credentials:credentials
                                                          extras:nil];

  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Completion handler ran."];
  GADMediationNativeLoadCompletionHandler completionHandler =
      ^(id<GADMediationNativeAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNil(ad);
        XCTAssertEqual(error.code, GADMAdapterInMobiErrorInvalidServerParameters);
        [expectation fulfill];
        return _nativeAdEventDelegate;
      };

  [_nativeAd loadNativeAdForAdConfiguration:adConfiguration completionHandler:completionHandler];

  [self waitForExpectations:@[ expectation ] timeout:AUTExpectationTimeout];
}

- (void)testLoadNativeAdFailureWithError {
  IMRequestStatus *expectedError = OCMClassMock([IMRequestStatus class]);
  OCMStub([_nativeMock load]).andDo(^(NSInvocation *invocation) {
    id<IMNativeDelegate> delegate = (id<IMNativeDelegate>)_nativeAd;
    [delegate native:_nativeMock didFailToLoadWithError:expectedError];
  });

  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Completion handler ran."];
  GADMediationNativeLoadCompletionHandler completionHandler =
      ^(id<GADMediationNativeAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNil(ad);
        XCTAssertEqualObjects(error, expectedError);
        [expectation fulfill];
        return _nativeAdEventDelegate;
      };

  [_nativeAd loadNativeAdForAdConfiguration:AUTGADMediationNativeAdConfigurationForInMobi()
                          completionHandler:completionHandler];

  [self waitForExpectations:@[ expectation ] timeout:AUTExpectationTimeout];
}

- (void)testNativeAdPresentationPresent {
  [self loadNativeAdSuccessfullyForAdConfiguration:AUTGADMediationNativeAdConfigurationForInMobi()];

  OCMExpect([_nativeAdEventDelegate willPresentFullScreenView]);
  id<IMNativeDelegate> nativeDelegate = (id<IMNativeDelegate>)_nativeAd;
  [nativeDelegate nativeWillPresentScreen:_nativeMock];
  OCMVerifyAll(_nativeAdEventDelegate);
}

- (void)testNativeAdPresentationDismiss {
  [self loadNativeAdSuccessfullyForAdConfiguration:AUTGADMediationNativeAdConfigurationForInMobi()];

  OCMExpect([_nativeAdEventDelegate willDismissFullScreenView]);
  OCMExpect([_nativeAdEventDelegate didDismissFullScreenView]);
  id<IMNativeDelegate> nativeDelegate = (id<IMNativeDelegate>)_nativeAd;
  [nativeDelegate nativeWillDismissScreen:_nativeMock];
  [nativeDelegate nativeDidDismissScreen:_nativeMock];
  OCMVerifyAll(_nativeAdEventDelegate);
}

- (void)testNativeAdImpression {
  [self loadNativeAdSuccessfullyForAdConfiguration:AUTGADMediationNativeAdConfigurationForInMobi()];

  OCMExpect([_nativeAdEventDelegate didPlayVideo]);
  OCMExpect([_nativeAdEventDelegate reportImpression]);
  id<IMNativeDelegate> nativeDelegate = (id<IMNativeDelegate>)_nativeAd;
  [nativeDelegate nativeAdImpressed:_nativeMock];
  OCMVerifyAll(_nativeAdEventDelegate);
}

- (void)testNativeAdClick {
  [self loadNativeAdSuccessfullyForAdConfiguration:AUTGADMediationNativeAdConfigurationForInMobi()];

  OCMExpect([_nativeAdEventDelegate reportClick]);
  id<IMNativeDelegate> nativeDelegate = (id<IMNativeDelegate>)_nativeAd;
  [nativeDelegate native:_nativeMock didInteractWithParams:@{}];
  OCMVerifyAll(_nativeAdEventDelegate);
}

- (void)testNativeAdMediaEndVideo {
  [self loadNativeAdSuccessfullyForAdConfiguration:AUTGADMediationNativeAdConfigurationForInMobi()];

  OCMExpect([_nativeAdEventDelegate didEndVideo]);
  id<IMNativeDelegate> nativeDelegate = (id<IMNativeDelegate>)_nativeAd;
  [nativeDelegate nativeDidFinishPlayingMedia:_nativeMock];
  OCMVerifyAll(_nativeAdEventDelegate);
}

- (void)testNativeAdMediaStateChange {
  [self loadNativeAdSuccessfullyForAdConfiguration:AUTGADMediationNativeAdConfigurationForInMobi()];

  OCMExpect([_nativeAdEventDelegate didMuteVideo]);
  id<IMNativeDelegate> nativeDelegate = (id<IMNativeDelegate>)_nativeAd;
  [nativeDelegate native:_nativeMock adAudioStateChanged:YES];
  OCMVerifyAll(_nativeAdEventDelegate);

  OCMExpect([_nativeAdEventDelegate didMuteVideo]);
  [nativeDelegate native:_nativeMock adAudioStateChanged:YES];
  OCMVerifyAll(_nativeAdEventDelegate);
}

- (void)testDidUntrackView {
  [self loadNativeAdSuccessfullyForAdConfiguration:AUTGADMediationNativeAdConfigurationForInMobi()];
  [_nativeAd didUntrackView:[[UIView alloc] init]];
  OCMVerifyAll(_nativeMock);
}

@end
