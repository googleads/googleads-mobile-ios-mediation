#import "GADMAdapterInMobiRewardedAd.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationRewardedAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <InMobiSDK/InMobiSDK-Swift.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AUTInMobiUtils.h"
#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiDelegateManager.h"
#import "GADMAdapterInMobiInitializer.h"
#import "GADMAdapterInMobiUtils.h"
#import "GADMediationAdapterInMobi.h"

@interface AUTInMobiRewardedAdTest : XCTestCase
@end

@implementation AUTInMobiRewardedAdTest {
  /// Adapter instance used to load rewarded ads.
  GADMediationAdapterInMobi *_adapter;

  /// Mock instance for IMInterstitial.
  IMInterstitial *_rewardedMock;

  /// Class mock for IMInterstitial.
  id _interstitialClassMock;

  /// Class mock for IMSdk.
  id _imsdkMock;

  /// Class mock for GADMAdapterInMobiInitializer.
  id _initializerMock;

  /// Class mock for GADMAdapterInMobiDelegateManager.
  id _delegateManagerMock;

  /// Delegate captured from IMInterstitial initialization.
  __block id<IMInterstitialDelegate> _capturedRewardedDelegate;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterInMobi alloc] init];
  _initializerMock = AUTMockGADMAdapterInMobiInitializer();
  _delegateManagerMock = AUTMockGADMAdapterInMobiDelegateManager();
  _imsdkMock = AUTMockIMSDKInit();

  _rewardedMock = OCMClassMock([IMInterstitial class]);
  _interstitialClassMock = OCMClassMock([IMInterstitial class]);
  OCMStub([_interstitialClassMock alloc]).andReturn(_interstitialClassMock);
  OCMStub([[_interstitialClassMock ignoringNonObjectArgs]
              initWithPlacementId:[AUTInMobiPlacementID longLongValue]
                         delegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                           self->_capturedRewardedDelegate = obj;
                           return YES;
                         }]])
      .andReturn(_rewardedMock);
  OCMStub([[_interstitialClassMock ignoringNonObjectArgs]
              initWithPlacementId:0
                         delegate:[OCMArg checkWithBlock:^BOOL(id obj) {
                           self->_capturedRewardedDelegate = obj;
                           return YES;
                         }]])
      .andReturn(_rewardedMock);
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  [(id)_rewardedMock stopMocking];
  _rewardedMock = nil;
  [_interstitialClassMock stopMocking];
  _interstitialClassMock = nil;
  [_imsdkMock stopMocking];
  _imsdkMock = nil;
  [_initializerMock stopMocking];
  _initializerMock = nil;
  [_delegateManagerMock stopMocking];
  _delegateManagerMock = nil;

  [super tearDown];
}

- (nonnull AUTKMediationRewardedAdConfiguration *)
    rewardedAdConfigurationWithPlacementID:(nullable NSString *)placementID
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

  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = extras;
  configuration.bidResponse = bidResponse;
  return configuration;
}

- (void)testLoadRewardedAdSuccessWaterfall {
  OCMStub([_rewardedMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedRewardedDelegate interstitialDidFinishLoading:self->_rewardedMock];
  });

  AUTKMediationRewardedAdConfiguration *configuration =
      [self rewardedAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);

  XCTAssertNotNil(eventDelegate);
  XCTAssertNotNil(eventDelegate.rewardedAd);
}

- (void)testLoadRewardedAdSuccessRTB {
  NSString *bidResponse = @"test_bid_response";
  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];

  OCMStub([_rewardedMock load:bidResponseData]).andDo(^(NSInvocation *invocation) {
    [self->_capturedRewardedDelegate interstitialDidFinishLoading:self->_rewardedMock];
  });

  AUTKMediationRewardedAdConfiguration *configuration =
      [self rewardedAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:bidResponse];

  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);

  XCTAssertNotNil(eventDelegate);
  XCTAssertNotNil(eventDelegate.rewardedAd);
}

- (void)testLoadRTBRewardedAdWithoutPlacementID {
  NSString *bidResponse = @"test_bid_response";
  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];

  OCMStub([_rewardedMock load:bidResponseData]).andDo(^(NSInvocation *invocation) {
    [self->_capturedRewardedDelegate interstitialDidFinishLoading:self->_rewardedMock];
  });

  AUTKMediationRewardedAdConfiguration *configuration =
      [self rewardedAdConfigurationWithPlacementID:nil bidResponse:bidResponse];

  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);

  XCTAssertNotNil(eventDelegate);
}

- (void)testLoadRewardedAdWatermarkDataForwarding {
  NSString *bidResponse = @"test_bid_response";
  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];
  NSData *watermarkData = [AUTInMobiTestWatermarkString dataUsingEncoding:NSUTF8StringEncoding];

  OCMStub([_rewardedMock load:bidResponseData]).andDo(^(NSInvocation *invocation) {
    [self->_capturedRewardedDelegate interstitialDidFinishLoading:self->_rewardedMock];
  });

  OCMExpect([_rewardedMock setWatermarkWith:[OCMArg checkWithBlock:^BOOL(id obj) {
                             return [obj isKindOfClass:[IMWatermark class]];
                           }]]);

  AUTKMediationRewardedAdConfiguration *configuration =
      [self rewardedAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:bidResponse];
  configuration.watermark = watermarkData;

  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);

  XCTAssertNotNil(eventDelegate);
  OCMVerifyAll((id)_rewardedMock);
}

- (void)testLoadRewardedAdFailureMissingPlacementID {
  AUTKMediationRewardedAdConfiguration *configuration =
      [self rewardedAdConfigurationWithPlacementID:nil bidResponse:nil];

  NSError *expectedError = GADMAdapterInMobiErrorWithCodeAndDescription(
      GADMAdapterInMobiErrorInvalidServerParameters, @"Placement ID not specified.");

  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadRewardedAdFailureDuplicatePlacementLoad {
  OCMStub([_rewardedMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedRewardedDelegate interstitialDidFinishLoading:self->_rewardedMock];
  });

  AUTKMediationRewardedAdConfiguration *configuration =
      [self rewardedAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKMediationRewardedAdEventDelegate *firstEventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);
  XCTAssertNotNil(firstEventDelegate);

  // Attempting to load another ad for the same placement before dismissal should fail.
  NSError *expectedError = GADMAdapterInMobiErrorWithCodeAndDescription(
      GADMAdapterInMobiErrorAdAlreadyLoaded,
      @"cannot request multiple ads using same placement ID.");

  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadRewardedAdFailureInitializerError {
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

  AUTKMediationRewardedAdConfiguration *configuration =
      [self rewardedAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, initError);
}

- (void)testLoadRewardedAdFailureInMobiSDKError {
  id sdkError = OCMClassMock([IMRequestStatus class]);
  OCMStub([_rewardedMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedRewardedDelegate interstitial:self->_rewardedMock
                           didFailToLoadWithError:sdkError];
  });

  AUTKMediationRewardedAdConfiguration *configuration =
      [self rewardedAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, (NSError *)sdkError);
}

- (void)testPresentRewardedAd {
  OCMStub([_rewardedMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedRewardedDelegate interstitialDidFinishLoading:self->_rewardedMock];
  });

  AUTKMediationRewardedAdConfiguration *configuration =
      [self rewardedAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);

  OCMStub([_rewardedMock isReady]).andReturn(YES);
  OCMStub([_rewardedMock showFrom:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [self->_capturedRewardedDelegate interstitialWillPresent:self->_rewardedMock];
    [self->_capturedRewardedDelegate interstitialDidPresent:self->_rewardedMock];
  });

  UIViewController *viewController = [[UIViewController alloc] init];
  [eventDelegate.rewardedAd presentFromViewController:viewController];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 1);
}

- (void)testPresentRewardedAdFailureWhenNotReady {
  OCMStub([_rewardedMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedRewardedDelegate interstitialDidFinishLoading:self->_rewardedMock];
  });

  AUTKMediationRewardedAdConfiguration *configuration =
      [self rewardedAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);

  OCMStub([_rewardedMock isReady]).andReturn(NO);
  OCMReject([_rewardedMock showFrom:OCMOCK_ANY]);

  UIViewController *viewController = [[UIViewController alloc] init];
  [eventDelegate.rewardedAd presentFromViewController:viewController];

  XCTAssertNotNil(eventDelegate.didFailToPresentError);
  XCTAssertEqual(eventDelegate.didFailToPresentError.code, GADMAdapterInMobiErrorAdNotReady);
}

- (void)testPresentRewardedAdFailureWithErrorFromSDK {
  OCMStub([_rewardedMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedRewardedDelegate interstitialDidFinishLoading:self->_rewardedMock];
  });

  AUTKMediationRewardedAdConfiguration *configuration =
      [self rewardedAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);

  id sdkError = OCMClassMock([IMRequestStatus class]);
  OCMStub([_rewardedMock isReady]).andReturn(YES);
  OCMStub([_rewardedMock showFrom:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [self->_capturedRewardedDelegate interstitial:self->_rewardedMock
                        didFailToPresentWithError:sdkError];
  });

  UIViewController *viewController = [[UIViewController alloc] init];
  [eventDelegate.rewardedAd presentFromViewController:viewController];

  XCTAssertEqualObjects(eventDelegate.didFailToPresentError, (NSError *)sdkError);
}

- (void)testRewardCompletion {
  OCMStub([_rewardedMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedRewardedDelegate interstitialDidFinishLoading:self->_rewardedMock];
  });

  AUTKMediationRewardedAdConfiguration *configuration =
      [self rewardedAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);

  [_capturedRewardedDelegate interstitial:self->_rewardedMock
         rewardActionCompletedWithRewards:@{@"reward" : @1}];

  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 1);
}

- (void)testRewardedDelegateLifecycleEvents {
  OCMStub([_rewardedMock load]).andDo(^(NSInvocation *invocation) {
    [self->_capturedRewardedDelegate interstitialDidFinishLoading:self->_rewardedMock];
  });

  AUTKMediationRewardedAdConfiguration *configuration =
      [self rewardedAdConfigurationWithPlacementID:AUTInMobiPlacementID bidResponse:nil];

  AUTKMediationRewardedAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);

  // Test impression.
  [_capturedRewardedDelegate interstitialAdImpressed:_rewardedMock];
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);

  // Test click.
  [_capturedRewardedDelegate interstitial:_rewardedMock didInteractWithParams:nil];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);

  // Test dismiss events.
  [_capturedRewardedDelegate interstitialWillDismiss:_rewardedMock];
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);

  [_capturedRewardedDelegate interstitialDidDismiss:_rewardedMock];
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

@end
