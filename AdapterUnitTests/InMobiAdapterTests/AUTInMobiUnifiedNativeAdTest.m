#import "GADMAdapterInMobiUnifiedNativeAd.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationNativeAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <InMobiSDK/InMobiSDK-Swift.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AUTInMobiUtils.h"
#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiInitializer.h"
#import "GADMAdapterInMobiUtils.h"
#import "GADMediationAdapterInMobi.h"

@interface AUTInMobiUnifiedNativeAdTest : XCTestCase
@end

@implementation AUTInMobiUnifiedNativeAdTest {
  /// Adapter instance used to load native ads.
  GADMediationAdapterInMobi *_adapter;

  /// Mock instance for IMNative.
  IMNative *_nativeMock;

  /// Class mock for IMNative.
  id _nativeClassMock;

  /// Class mock for IMSdk.
  id _imsdkMock;

  /// Class mock for GADMAdapterInMobiInitializer.
  id _initializerMock;

  /// Delegate captured from IMNative initialization.
  __block id<IMNativeDelegate> _capturedNativeDelegate;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterInMobi alloc] init];
  _initializerMock = AUTMockGADMAdapterInMobiInitializer();
  _imsdkMock = AUTMockIMSDKInit();

  _nativeMock = OCMClassMock([IMNative class]);
  _nativeClassMock = OCMClassMock([IMNative class]);
  OCMStub([_nativeClassMock alloc]).andReturn(_nativeClassMock);
  OCMStub([[_nativeClassMock ignoringNonObjectArgs]
              initWithPlacementId:[AUTInMobiPlacementID longLongValue]
                         delegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                           self->_capturedNativeDelegate = obj;
                           return YES;
                         }]])
      .andReturn(_nativeMock);
  OCMStub([[_nativeClassMock ignoringNonObjectArgs]
              initWithPlacementId:0
                         delegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                           self->_capturedNativeDelegate = obj;
                           return YES;
                         }]])
      .andReturn(_nativeMock);

  // Setup default IMNative property stubs.
  OCMStub([_nativeMock adTitle]).andReturn(@"Test Headline");
  OCMStub([_nativeMock adDescription]).andReturn(@"Test Body");
  OCMStub([_nativeMock adCtaText]).andReturn(@"Test CTA");
  OCMStub([_nativeMock adRating]).andReturn([[NSDecimalNumber alloc] initWithInt:5]);
  OCMStub([_nativeMock getMediaView])
      .andReturn([[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)]);
  OCMStub([_nativeMock isVideoAd]).andReturn(YES);
  OCMStub([_nativeMock advertiserName]).andReturn(@"Test Advertiser");
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  [(id)_nativeMock stopMocking];
  _nativeMock = nil;
  [_nativeClassMock stopMocking];
  _nativeClassMock = nil;
  [_imsdkMock stopMocking];
  _imsdkMock = nil;
  [_initializerMock stopMocking];
  _initializerMock = nil;

  [super tearDown];
}

- (nonnull AUTKMediationNativeAdConfiguration *)
    nativeAdConfigurationWithPlacementID:(nullable NSString *)placementID
                             bidResponse:(nullable NSString *)bidResponse {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  NSMutableDictionary<NSString *, id> *settings =
      [@{GADMAdapterInMobiAccountID : AUTInMobiAccountID} mutableCopy];
  if (placementID) {
    settings[GADMAdapterInMobiPlacementID] = placementID;
  }
  credentials.settings = settings;

  GADInMobiExtras *extras = [[GADInMobiExtras alloc] init];
  extras.keywords = AUTInMobiKeywords;

  AUTKMediationNativeAdConfiguration *configuration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = extras;
  configuration.bidResponse = bidResponse;
  return configuration;
}

- (void)testLoadNativeAdSuccessWaterfall {
  OCMStub([_nativeMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedNativeDelegate nativeDidFinishLoading:self->_nativeMock];
  });

  AUTKMediationNativeAdConfiguration *configuration =
      [self nativeAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, configuration);

  XCTAssertNotNil(eventDelegate);
  XCTAssertNotNil(eventDelegate.nativeAd);
  XCTAssertEqualObjects(eventDelegate.nativeAd.headline, @"Test Headline");
  XCTAssertEqualObjects(eventDelegate.nativeAd.body, @"Test Body");
  XCTAssertEqualObjects(eventDelegate.nativeAd.callToAction, @"Test CTA");
  XCTAssertEqualObjects(eventDelegate.nativeAd.starRating, [[NSDecimalNumber alloc] initWithInt:5]);
  XCTAssertEqualObjects(eventDelegate.nativeAd.advertiser, @"Test Advertiser");
  XCTAssertTrue(eventDelegate.nativeAd.hasVideoContent);
  XCTAssertNotNil(eventDelegate.nativeAd.mediaView);
  XCTAssertTrue(eventDelegate.nativeAd.handlesUserImpressions);
  XCTAssertTrue(eventDelegate.nativeAd.handlesUserClicks);
}

- (void)testLoadNativeAdSuccessRTB {
  NSString *bidResponse = @"test_bid_response";
  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];

  OCMStub([_nativeMock load:bidResponseData]).andDo(^(NSInvocation *invocation) {
    [self->_capturedNativeDelegate nativeDidFinishLoading:self->_nativeMock];
  });

  AUTKMediationNativeAdConfiguration *configuration =
      [self nativeAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:bidResponse];

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, configuration);

  XCTAssertNotNil(eventDelegate);
  XCTAssertNotNil(eventDelegate.nativeAd);
  XCTAssertEqualObjects(eventDelegate.nativeAd.headline, @"Test Headline");
}

- (void)testLoadRTBNativeAdWithoutPlacementID {
  NSString *bidResponse = @"test_bid_response";
  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];

  OCMStub([_nativeMock load:bidResponseData]).andDo(^(NSInvocation *invocation) {
    [self->_capturedNativeDelegate nativeDidFinishLoading:self->_nativeMock];
  });

  AUTKMediationNativeAdConfiguration *configuration =
      [self nativeAdConfigurationWithPlacementID:nil bidResponse:bidResponse];

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, configuration);

  XCTAssertNotNil(eventDelegate);
}

- (void)testLoadNativeAdFailureMissingPlacementID {
  AUTKMediationNativeAdConfiguration *configuration =
      [self nativeAdConfigurationWithPlacementID:nil bidResponse:nil];

  NSError *expectedError = GADMAdapterInMobiErrorWithCodeAndDescription(
      GADMAdapterInMobiErrorInvalidServerParameters, @"Placement ID not specified.");

  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadNativeAdFailureInitializerError {
  [_imsdkMock stopMocking];
  _imsdkMock = OCMClassMock([IMSdk class]);
  NSError *initError = [NSError errorWithDomain:GADMAdapterInMobiErrorDomain
                                           code:GADMAdapterInMobiErrorInvalidServerParameters
                                       userInfo:nil];
  OCMStub(ClassMethod([_imsdkMock initWithAccountID:OCMOCK_ANY
                                  consentDictionary:OCMOCK_ANY
                               andCompletionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionBlock)(NSError *_Nullable);
        [invocation getArgument:&completionBlock atIndex:4];
        completionBlock(initError);
      });

  AUTKMediationNativeAdConfiguration *configuration =
      [self nativeAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, configuration, initError);
}

- (void)testLoadNativeAdFailureInMobiSDKError {
  id sdkError = OCMClassMock([IMRequestStatus class]);
  OCMStub([_nativeMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedNativeDelegate native:self->_nativeMock didFailToLoadWithError:sdkError];
  });

  AUTKMediationNativeAdConfiguration *configuration =
      [self nativeAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKWaitAndAssertLoadNativeAdFailure(_adapter, configuration, (NSError *)sdkError);
}

- (void)testNativeAdDelegateLifecycleEvents {
  OCMStub([_nativeMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedNativeDelegate nativeDidFinishLoading:self->_nativeMock];
  });

  AUTKMediationNativeAdConfiguration *configuration =
      [self nativeAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, configuration);

  // Test impression (and video start).
  [_capturedNativeDelegate nativeAdImpressed:_nativeMock];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didPlayVideoInvokeCount, 1);

  // Test click.
  [_capturedNativeDelegate native:_nativeMock didInteractWithParams:@{}];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);

  // Test full screen presentation.
  [_capturedNativeDelegate nativeWillPresentScreen:_nativeMock];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);

  // Test full screen dismissal.
  [_capturedNativeDelegate nativeWillDismissScreen:_nativeMock];
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);

  [_capturedNativeDelegate nativeDidDismissScreen:_nativeMock];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);

  // Test media playback events.
  [_capturedNativeDelegate nativeDidFinishPlayingMedia:_nativeMock];
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 1);

  // Test audio state changes.
  [_capturedNativeDelegate native:_nativeMock adAudioStateChanged:YES];
  XCTAssertEqual(eventDelegate.didMuteVideoInvokeCount, 1);

  [_capturedNativeDelegate native:_nativeMock adAudioStateChanged:NO];
  XCTAssertEqual(eventDelegate.didUnmuteVideoInvokeCount, 1);
}

- (void)testDidUntrackView {
  OCMStub([_nativeMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedNativeDelegate nativeDidFinishLoading:self->_nativeMock];
  });

  AUTKMediationNativeAdConfiguration *configuration =
      [self nativeAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadNativeAd(_adapter, configuration);

  [eventDelegate.nativeAd didUntrackView:[[UIView alloc] init]];
}

@end
