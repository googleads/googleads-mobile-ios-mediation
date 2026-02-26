#import "GADMediationAdapterFacebook.h"

#import <XCTest/XCTest.h>

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>

#import "AUTTestUtils.h"
#import "AdapterUnitTestKit/AdapterUnitTestKit.h"
#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"

static NSString *const AUTKRewardedBidResponse = @"bidResponse";
static NSString *const AUTKRewardedWatermark = @"watermark";

@interface AUTFBRewardedRendererTest : XCTestCase
@end

/**
 * Returns a correctly configured rewarded ad configuration.
 */
AUTKMediationRewardedAdConfiguration *_Nonnull AUTGADMediationRewardedAdConfiguration() {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatRewarded;
  credentials.settings = @{GADMAdapterFacebookBiddingPubID : GADMAdapterFacebookBiddingPubID};

  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = nil;
  configuration.bidResponse = AUTKRewardedBidResponse;
  configuration.watermark = [AUTKRewardedWatermark dataUsingEncoding:NSUTF8StringEncoding];
  return configuration;
}

@implementation AUTFBRewardedRendererTest {
  GADMediationAdapterFacebook *_adapter;
  id _mockFBRewardedVideoAdClass;
  __weak id<FBRewardedVideoAdDelegate> _rewardedVideoAdDelegate;
  id _fbAdSettingsMock;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterFacebook alloc] init];
  _mockFBRewardedVideoAdClass = OCMClassMock([FBRewardedVideoAd class]);
  OCMStub([_mockFBRewardedVideoAdClass alloc]).andReturn(_mockFBRewardedVideoAdClass);
  OCMStub([_mockFBRewardedVideoAdClass initWithPlacementID:[OCMArg any]])
      .andReturn(_mockFBRewardedVideoAdClass);

  id delegateSave = [OCMArg checkWithBlock:^BOOL(id obj) {
    self->_rewardedVideoAdDelegate = obj;
    return YES;
  }];
  OCMStub([_mockFBRewardedVideoAdClass setDelegate:delegateSave]);
  _fbAdSettingsMock = OCMClassMock([FBAdSettings class]);
}

- (void)tearDown {
  // Reset the GMA SDK state to ensure test isolation.
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  [_fbAdSettingsMock stopMocking];
  [super tearDown];
}

- (void)testLoadRewardedAd {
  OCMExpect([_mockFBRewardedVideoAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKRewardedWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMExpect([_mockFBRewardedVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewarded];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass
              loadAdWithBidPayload:AUTKRewardedBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });
  AUTKWaitAndAssertLoadRewardedAd(_adapter, AUTGADMediationRewardedAdConfiguration());
}

- (void)testRenderRewardedFailureWithAdDidNotLoad {
  NSError *expectedError = [NSError errorWithDomain:@"GADFBErrorDomain" code:101 userInfo:nil];
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass loadAdWithBidPayload:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAd:ad didFailWithError:expectedError];
      });

  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, AUTGADMediationRewardedAdConfiguration(),
                                         expectedError);
}

- (void)testRenderRewardedFailureWithNoPlacementID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatRewarded;
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = nil;

  NSError *expectedError = [NSError errorWithDomain:@"com.google.mediation.facebook"
                                               code:GADFBErrorInvalidRequest
                                           userInfo:nil];
  OCMReject([_mockFBRewardedVideoAdClass loadAdWithBidPayload:[OCMArg any]]);

  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testRwardedClick {
  OCMExpect([_mockFBRewardedVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewarded];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass
              loadAdWithBidPayload:AUTKRewardedBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKMediationRewardedAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, AUTGADMediationRewardedAdConfiguration());

  XCTAssertEqual(delegate.reportClickInvokeCount, 0);
  [(id<FBRewardedVideoAdDelegate>)_rewardedVideoAdDelegate
      rewardedVideoAdDidClick:(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);
}

- (void)testRewardedImpressionReport {
  OCMExpect([_mockFBRewardedVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewarded];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass
              loadAdWithBidPayload:AUTKRewardedBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKMediationRewardedAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, AUTGADMediationRewardedAdConfiguration());

  XCTAssertEqual(delegate.reportImpressionInvokeCount, 0);
  [(id<FBRewardedVideoAdDelegate>)_rewardedVideoAdDelegate
      rewardedVideoAdWillLogImpression:(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);
}

- (void)testRewardedPresentFromViewController {
  OCMExpect([_mockFBRewardedVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewarded];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass
              loadAdWithBidPayload:AUTKRewardedBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });
  OCMStub(
      [(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass showAdFromRootViewController:[OCMArg any]])
      .andReturn(YES);

  AUTKMediationRewardedAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, AUTGADMediationRewardedAdConfiguration());

  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(delegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(delegate.didRewardUserInvokeCount, 0);
  XCTAssertEqual(delegate.didStartVideoInvokeCount, 0);
  XCTAssertEqual(delegate.didEndVideoInvokeCount, 0);

  UIViewController *viewController = [[UIViewController alloc] init];
  [delegate.rewardedAd presentFromViewController:viewController];
  [(id<FBRewardedVideoAdDelegate>)_rewardedVideoAdDelegate
      rewardedVideoAdWillClose:(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass];
  [(id<FBRewardedVideoAdDelegate>)_rewardedVideoAdDelegate
      rewardedVideoAdDidClose:(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass];
  [(id<FBRewardedVideoAdDelegate>)_rewardedVideoAdDelegate
      rewardedVideoAdVideoComplete:(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass];

  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(delegate.willDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(delegate.didRewardUserInvokeCount, 1);
  XCTAssertEqual(delegate.didStartVideoInvokeCount, 1);
  XCTAssertEqual(delegate.didEndVideoInvokeCount, 1);

  OCMVerify([(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass
      showAdFromRootViewController:viewController]);
}

- (void)testRewardedPresentFromViewControllerFailure {
  OCMExpect([_mockFBRewardedVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewarded];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass
              loadAdWithBidPayload:AUTKRewardedBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });
  OCMStub(
      [(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass showAdFromRootViewController:[OCMArg any]])
      .andReturn(NO);

  AUTKMediationRewardedAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, AUTGADMediationRewardedAdConfiguration());

  XCTAssertEqual(delegate.didFailToPresentError, nil);
  UIViewController *viewController = [[UIViewController alloc] init];
  [delegate.rewardedAd presentFromViewController:viewController];
  XCTAssertEqual(delegate.didFailToPresentError.code, GADFBErrorAdNotValid);

  OCMVerify([(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass
      showAdFromRootViewController:viewController]);
}

- (void)testLoadRewardedAdWhenChildDirectedIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBRewardedVideoAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKRewardedWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMExpect([_mockFBRewardedVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewarded];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass
              loadAdWithBidPayload:AUTKRewardedBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadRewardedAd(_adapter, AUTGADMediationRewardedAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadRewardedAdWhenUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBRewardedVideoAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKRewardedWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMExpect([_mockFBRewardedVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewarded];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass
              loadAdWithBidPayload:AUTKRewardedBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadRewardedAd(_adapter, AUTGADMediationRewardedAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadRewardedAdWhenChildDirectedIsTrueAndUnderAgeIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBRewardedVideoAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKRewardedWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMExpect([_mockFBRewardedVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewarded];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass
              loadAdWithBidPayload:AUTKRewardedBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadRewardedAd(_adapter, AUTGADMediationRewardedAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadRewardedAdWhenChildDirectedIsFalseAndUnderAgeIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBRewardedVideoAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKRewardedWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMExpect([_mockFBRewardedVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewarded];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass
              loadAdWithBidPayload:AUTKRewardedBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadRewardedAd(_adapter, AUTGADMediationRewardedAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadRewardedAdWhenBothAreTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBRewardedVideoAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKRewardedWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMExpect([_mockFBRewardedVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewarded];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass
              loadAdWithBidPayload:AUTKRewardedBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadRewardedAd(_adapter, AUTGADMediationRewardedAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadRewardedAdWhenBothAreFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBRewardedVideoAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKRewardedWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMExpect([_mockFBRewardedVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewarded];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass
              loadAdWithBidPayload:AUTKRewardedBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadRewardedAd(_adapter, AUTGADMediationRewardedAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadRewardedAdWhenChildDirectedIsFalseAndUnderAgeIsNil {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBRewardedVideoAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKRewardedWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMExpect([_mockFBRewardedVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewarded];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass
              loadAdWithBidPayload:AUTKRewardedBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadRewardedAd(_adapter, AUTGADMediationRewardedAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadRewardedAdWhenUnderAgeIsFalseAndChildDirectedIsNil {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBRewardedVideoAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKRewardedWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMExpect([_mockFBRewardedVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewarded];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedVideoAdClass
              loadAdWithBidPayload:AUTKRewardedBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadRewardedAd(_adapter, AUTGADMediationRewardedAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testConfigureMediationServiceSetsCorrectString {
  __block NSString *capturedMediationService = nil;
  OCMExpect([_fbAdSettingsMock setMediationService:[OCMArg checkWithBlock:^BOOL(NSString *service) {
                                 capturedMediationService = service;
                                 return YES;
                               }]]);

  GADFBConfigureMediationService();
  OCMVerifyAll(_fbAdSettingsMock);
  NSString *expectedMediationService =
      [NSString stringWithFormat:@"GOOGLE_afma-sdk-i-v%ld.%ld.%ld:%@",
                                 GADMobileAds.sharedInstance.versionNumber.majorVersion,
                                 GADMobileAds.sharedInstance.versionNumber.minorVersion,
                                 GADMobileAds.sharedInstance.versionNumber.patchVersion,
                                 GADMAdapterFacebookVersion];

  XCTAssertEqualObjects(
      capturedMediationService, expectedMediationService,
      @"GADFBConfigureMediationService did not set the correct mediation service string.");
}

@end
