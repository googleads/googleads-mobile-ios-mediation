#import "GADMAdapterInMobiInterstitialAd.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationInterstitialAdLoadAssertions.h>
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

@interface GADMAdapterInMobiInterstitialAd (Test)
- (void)stopBeingDelegate;
@end

@interface AUTInMobiInterstitialAdTest : XCTestCase
@end

@implementation AUTInMobiInterstitialAdTest {
  /// Adapter instance used to load interstitial ads.
  GADMediationAdapterInMobi *_adapter;

  /// Mock instance for IMInterstitial.
  IMInterstitial *_interstitialMock;

  /// Class mock for IMInterstitial.
  id _interstitialClassMock;

  /// Class mock for IMSdk.
  id _imsdkMock;

  /// Class mock for GADMAdapterInMobiInitializer.
  id _initializerMock;

  /// Delegate captured from IMInterstitial initialization.
  __block id<IMInterstitialDelegate> _capturedInterstitialDelegate;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterInMobi alloc] init];
  _initializerMock = AUTMockGADMAdapterInMobiInitializer();
  _imsdkMock = AUTMockIMSDKInit();

  _interstitialMock = OCMClassMock([IMInterstitial class]);
  _interstitialClassMock = OCMClassMock([IMInterstitial class]);
  OCMStub([_interstitialClassMock alloc]).andReturn(_interstitialClassMock);
  OCMStub([[_interstitialClassMock ignoringNonObjectArgs]
              initWithPlacementId:[AUTInMobiPlacementID longLongValue]
                         delegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                           self->_capturedInterstitialDelegate = obj;
                           return YES;
                         }]])
      .andReturn(_interstitialMock);
  OCMStub([[_interstitialClassMock ignoringNonObjectArgs]
              initWithPlacementId:0
                         delegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                           self->_capturedInterstitialDelegate = obj;
                           return YES;
                         }]])
      .andReturn(_interstitialMock);
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  [(id)_interstitialMock stopMocking];
  _interstitialMock = nil;
  [_interstitialClassMock stopMocking];
  _interstitialClassMock = nil;
  [_imsdkMock stopMocking];
  _imsdkMock = nil;
  [_initializerMock stopMocking];
  _initializerMock = nil;

  [super tearDown];
}

- (nonnull AUTKMediationInterstitialAdConfiguration *)
    interstitialAdConfigurationWithPlacementID:(nullable NSString *)placementID
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

  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = extras;
  configuration.bidResponse = bidResponse;
  return configuration;
}

- (void)testLoadInterstitialAdSuccessWaterfall {
  OCMStub([_interstitialMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedInterstitialDelegate interstitialDidFinishLoading:self->_interstitialMock];
  });

  AUTKMediationInterstitialAdConfiguration *configuration =
      [self interstitialAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);

  XCTAssertNotNil(eventDelegate);
  XCTAssertNotNil(eventDelegate.interstitialAd);
}

- (void)testLoadInterstitialAdSuccessRTB {
  NSString *bidResponse = @"test_bid_response";
  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];

  OCMStub([_interstitialMock load:bidResponseData]).andDo(^(NSInvocation *invocation) {
    [self->_capturedInterstitialDelegate interstitialDidFinishLoading:self->_interstitialMock];
  });

  AUTKMediationInterstitialAdConfiguration *configuration =
      [self interstitialAdConfigurationWithPlacementID:AUTInMobiPlacementID
                                           bidResponse:bidResponse];

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);

  XCTAssertNotNil(eventDelegate);
  XCTAssertNotNil(eventDelegate.interstitialAd);
}

- (void)testLoadRTBInterstitialAdWithoutPlacementID {
  NSString *bidResponse = @"test_bid_response";
  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];

  OCMStub([_interstitialMock load:bidResponseData]).andDo(^(NSInvocation *invocation) {
    [self->_capturedInterstitialDelegate interstitialDidFinishLoading:self->_interstitialMock];
  });

  AUTKMediationInterstitialAdConfiguration *configuration =
      [self interstitialAdConfigurationWithPlacementID:nil bidResponse:bidResponse];

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);

  XCTAssertNotNil(eventDelegate);
}

- (void)testLoadInterstitialAdWatermarkDataForwarding {
  NSString *bidResponse = @"test_bid_response";
  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];
  NSData *watermarkData = [AUTInMobiTestWatermarkString dataUsingEncoding:NSUTF8StringEncoding];

  OCMStub([_interstitialMock load:bidResponseData]).andDo(^(NSInvocation *invocation) {
    [self->_capturedInterstitialDelegate interstitialDidFinishLoading:self->_interstitialMock];
  });

  OCMExpect([_interstitialMock setWatermarkWith:[OCMArg checkWithBlock:^BOOL(id obj) {
                                 return [obj isKindOfClass:[IMWatermark class]];
                               }]]);

  AUTKMediationInterstitialAdConfiguration *configuration =
      [self interstitialAdConfigurationWithPlacementID:AUTInMobiPlacementID
                                           bidResponse:bidResponse];
  configuration.watermark = watermarkData;

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);

  XCTAssertNotNil(eventDelegate);
  OCMVerifyAll((id)_interstitialMock);
}

- (void)testLoadInterstitialAdFailureMissingPlacementID {
  AUTKMediationInterstitialAdConfiguration *configuration =
      [self interstitialAdConfigurationWithPlacementID:nil bidResponse:nil];

  NSError *expectedError = GADMAdapterInMobiErrorWithCodeAndDescription(
      GADMAdapterInMobiErrorInvalidServerParameters, @"Placement ID not specified.");

  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadInterstitialAdFailureInitializerError {
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

  AUTKMediationInterstitialAdConfiguration *configuration =
      [self interstitialAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, initError);
}

- (void)testLoadInterstitialAdFailureInMobiSDKError {
  id sdkError = OCMClassMock([IMRequestStatus class]);
  OCMStub([_interstitialMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedInterstitialDelegate interstitial:self->_interstitialMock
                               didFailToLoadWithError:sdkError];
  });

  AUTKMediationInterstitialAdConfiguration *configuration =
      [self interstitialAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, (NSError *)sdkError);
}

- (void)testPresentInterstitialAd {
  OCMStub([_interstitialMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedInterstitialDelegate interstitialDidFinishLoading:self->_interstitialMock];
  });

  AUTKMediationInterstitialAdConfiguration *configuration =
      [self interstitialAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);

  OCMStub([_interstitialMock isReady]).andReturn(YES);
  OCMStub([_interstitialMock showFrom:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [self->_capturedInterstitialDelegate interstitialWillPresent:self->_interstitialMock];
    [self->_capturedInterstitialDelegate interstitialDidPresent:self->_interstitialMock];
  });

  UIViewController *viewController = [[UIViewController alloc] init];
  [eventDelegate.interstitialAd presentFromViewController:viewController];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
}

- (void)testPresentInterstitialAdFailureWhenNotReady {
  OCMStub([_interstitialMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedInterstitialDelegate interstitialDidFinishLoading:self->_interstitialMock];
  });

  AUTKMediationInterstitialAdConfiguration *configuration =
      [self interstitialAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);

  OCMStub([_interstitialMock isReady]).andReturn(NO);
  OCMReject([_interstitialMock showFrom:OCMOCK_ANY]);

  UIViewController *viewController = [[UIViewController alloc] init];
  [eventDelegate.interstitialAd presentFromViewController:viewController];

  XCTAssertNotNil(eventDelegate.didFailToPresentError);
  XCTAssertEqual(eventDelegate.didFailToPresentError.code, GADMAdapterInMobiErrorAdNotReady);
}

- (void)testPresentInterstitialAdFailureWithErrorFromSDK {
  OCMStub([_interstitialMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedInterstitialDelegate interstitialDidFinishLoading:self->_interstitialMock];
  });

  AUTKMediationInterstitialAdConfiguration *configuration =
      [self interstitialAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);

  id sdkError = OCMClassMock([IMRequestStatus class]);
  OCMStub([_interstitialMock isReady]).andReturn(YES);
  OCMStub([_interstitialMock showFrom:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [self->_capturedInterstitialDelegate interstitial:self->_interstitialMock
                            didFailToPresentWithError:sdkError];
  });

  UIViewController *viewController = [[UIViewController alloc] init];
  [eventDelegate.interstitialAd presentFromViewController:viewController];

  XCTAssertEqualObjects(eventDelegate.didFailToPresentError, (NSError *)sdkError);
}

- (void)testInterstitialDelegateLifecycleEvents {
  OCMStub([_interstitialMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedInterstitialDelegate interstitialDidFinishLoading:self->_interstitialMock];
  });

  AUTKMediationInterstitialAdConfiguration *configuration =
      [self interstitialAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);

  // Test impression.
  [_capturedInterstitialDelegate interstitialAdImpressed:_interstitialMock];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);

  // Test click.
  [_capturedInterstitialDelegate interstitial:_interstitialMock didInteractWithParams:nil];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);

  // Test dismiss events.
  [_capturedInterstitialDelegate interstitialWillDismiss:_interstitialMock];
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);

  [_capturedInterstitialDelegate interstitialDidDismiss:_interstitialMock];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testStopBeingDelegate {
  GADMAdapterInMobiInterstitialAd *interstitialAd = [[GADMAdapterInMobiInterstitialAd alloc] init];
  OCMExpect([_interstitialMock setDelegate:nil]);
  [interstitialAd setValue:_interstitialMock forKey:@"_interstitialAd"];

  [interstitialAd stopBeingDelegate];

  OCMVerifyAll((id)_interstitialMock);
}

@end
