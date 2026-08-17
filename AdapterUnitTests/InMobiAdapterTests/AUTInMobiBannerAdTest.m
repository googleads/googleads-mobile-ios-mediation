#import "GADMAdapterInMobiBannerAd.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationBannerAdLoadAssertions.h>
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

@interface GADMAdapterInMobiBannerAd (Test)
- (void)stopBeingDelegate;
@end

@interface AUTInMobiBannerAdTest : XCTestCase
@end

@implementation AUTInMobiBannerAdTest {
  /// Adapter instance used to load banner ads.
  GADMediationAdapterInMobi *_adapter;

  /// Mock instance for IMBanner.
  IMBanner *_bannerMock;

  /// Class mock for IMBanner.
  id _bannerClassMock;

  /// Class mock for IMSdk.
  id _imsdkMock;

  /// Class mock for GADMAdapterInMobiInitializer.
  id _initializerMock;

  /// Delegate captured from IMBanner initialization.
  __block id<IMBannerDelegate> _capturedBannerDelegate;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterInMobi alloc] init];
  _initializerMock = AUTMockGADMAdapterInMobiInitializer();
  _imsdkMock = AUTMockIMSDKInit();

  _bannerMock = OCMClassMock([IMBanner class]);
  _bannerClassMock = OCMClassMock([IMBanner class]);
  OCMStub([_bannerClassMock alloc]).andReturn(_bannerClassMock);
  OCMStub([[_bannerClassMock ignoringNonObjectArgs]
              initWithFrame:CGRectMake(0, 0, 320, 50)
                placementId:[AUTInMobiPlacementID longLongValue]
                   delegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                     self->_capturedBannerDelegate = obj;
                     return YES;
                   }]])
      .andReturn(_bannerMock);
  OCMStub([[_bannerClassMock ignoringNonObjectArgs]
              initWithFrame:CGRectZero
                placementId:[AUTInMobiPlacementID longLongValue]
                   delegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                     self->_capturedBannerDelegate = obj;
                     return YES;
                   }]])
      .andReturn(_bannerMock);
  OCMStub([[_bannerClassMock ignoringNonObjectArgs]
              initWithFrame:CGRectZero
                placementId:0
                   delegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                     self->_capturedBannerDelegate = obj;
                     return YES;
                   }]])
      .andReturn(_bannerMock);
  OCMStub([[_bannerClassMock ignoringNonObjectArgs]
              initWithFrame:CGRectMake(0, 0, 320, 50)
                placementId:0
                   delegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                     self->_capturedBannerDelegate = obj;
                     return YES;
                   }]])
      .andReturn(_bannerMock);
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  [(id)_bannerMock stopMocking];
  _bannerMock = nil;
  [_bannerClassMock stopMocking];
  _bannerClassMock = nil;
  [_imsdkMock stopMocking];
  _imsdkMock = nil;
  [_initializerMock stopMocking];
  _initializerMock = nil;

  [super tearDown];
}

- (nonnull AUTKMediationBannerAdConfiguration *)
    bannerAdConfigurationWithPlacementID:(nullable NSString *)placementID
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

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = extras;
  configuration.adSize = GADAdSizeBanner;
  configuration.bidResponse = bidResponse;
  return configuration;
}

- (void)testLoadBannerAdSuccessWaterfall {
  OCMStub([_bannerMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedBannerDelegate bannerDidFinishLoading:self->_bannerMock];
  });

  AUTKMediationBannerAdConfiguration *configuration =
      [self bannerAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKMediationBannerAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);

  XCTAssertNotNil(eventDelegate);
  XCTAssertNotNil(eventDelegate.bannerAd);
  XCTAssertEqualObjects([eventDelegate.bannerAd view], _bannerMock);
}

- (void)testLoadBannerAdSuccessRTB {
  NSString *bidResponse = @"test_bid_response";
  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];

  OCMStub([_bannerMock load:bidResponseData]).andDo(^(NSInvocation *invocation) {
    [self->_capturedBannerDelegate bannerDidFinishLoading:self->_bannerMock];
  });

  AUTKMediationBannerAdConfiguration *configuration =
      [self bannerAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:bidResponse];

  AUTKMediationBannerAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);

  XCTAssertNotNil(eventDelegate);
  XCTAssertNotNil(eventDelegate.bannerAd);
  XCTAssertEqualObjects([eventDelegate.bannerAd view], _bannerMock);
}

- (void)testLoadBannerAdWatermarkDataForwarding {
  NSString *bidResponse = @"test_bid_response";
  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];
  NSData *watermarkData = [AUTInMobiTestWatermarkString dataUsingEncoding:NSUTF8StringEncoding];

  OCMStub([_bannerMock load:bidResponseData]).andDo(^(NSInvocation *invocation) {
    [self->_capturedBannerDelegate bannerDidFinishLoading:self->_bannerMock];
  });

  OCMExpect([_bannerMock setWatermarkWith:[OCMArg checkWithBlock:^BOOL(id obj) {
                           return [obj isKindOfClass:[IMWatermark class]];
                         }]]);

  AUTKMediationBannerAdConfiguration *configuration =
      [self bannerAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:bidResponse];
  configuration.watermark = watermarkData;

  AUTKMediationBannerAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);

  XCTAssertNotNil(eventDelegate);
  OCMVerifyAll((id)_bannerMock);
}

- (void)testLoadRTBBannerWithoutPlacementID {
  NSString *bidResponse = @"test_bid_response";
  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];

  OCMStub([_bannerMock load:bidResponseData]).andDo(^(NSInvocation *invocation) {
    [self->_capturedBannerDelegate bannerDidFinishLoading:self->_bannerMock];
  });

  AUTKMediationBannerAdConfiguration *configuration =
      [self bannerAdConfigurationWithPlacementID:nil bidResponse:bidResponse];

  AUTKMediationBannerAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);

  XCTAssertNotNil(eventDelegate);
}

- (void)testLoadBannerAdFailureMissingPlacementID {
  AUTKMediationBannerAdConfiguration *configuration =
      [self bannerAdConfigurationWithPlacementID:nil bidResponse:nil];

  NSError *expectedError = GADMAdapterInMobiErrorWithCodeAndDescription(
      GADMAdapterInMobiErrorInvalidServerParameters, @"Placement ID not specified.");

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadBannerAdFailureInvalidBannerSize {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterInMobiAccountID : AUTInMobiAccountID,
    GADMAdapterInMobiPlacementID : AUTInMobiPlacementID
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterInMobiErrorDomain
                                                      code:GADMAdapterInMobiErrorBannerSizeMismatch
                                                  userInfo:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadBannerAdFailureInitializerError {
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

  AUTKMediationBannerAdConfiguration *configuration =
      [self bannerAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, initError);
}

- (void)testLoadBannerAdFailureInMobiSDKError {
  id sdkError = OCMClassMock([IMRequestStatus class]);
  OCMStub([_bannerMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedBannerDelegate banner:self->_bannerMock didFailToLoadWithError:sdkError];
  });

  AUTKMediationBannerAdConfiguration *configuration =
      [self bannerAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, (NSError *)sdkError);
}

- (void)testBannerDelegateLifecycleEvents {
  OCMStub([_bannerMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedBannerDelegate bannerDidFinishLoading:self->_bannerMock];
  });

  AUTKMediationBannerAdConfiguration *configuration =
      [self bannerAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKMediationBannerAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);

  XCTAssertNotNil(eventDelegate);

  // Test impression event.
  [_capturedBannerDelegate bannerAdImpressed:_bannerMock];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);

  // Test click event.
  [_capturedBannerDelegate banner:_bannerMock didInteractWithParams:nil];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);

  // Test full screen presentation event.
  [_capturedBannerDelegate bannerWillPresentScreen:_bannerMock];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);

  // Test full screen dismissal events.
  [_capturedBannerDelegate bannerWillDismissScreen:_bannerMock];
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);

  [_capturedBannerDelegate bannerDidDismissScreen:_bannerMock];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testStopBeingDelegate {
  GADMAdapterInMobiBannerAd *bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];
  OCMExpect([_bannerMock setDelegate:nil]);
  [bannerAd setValue:_bannerMock forKey:@"_adView"];

  [bannerAd stopBeingDelegate];

  OCMVerifyAll((id)_bannerMock);
}

@end
