#import "GADMediationAdapterFacebook.h"

#import <XCTest/XCTest.h>

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>

#import "AUTTestUtils.h"
#import "AdapterUnitTestKit/AdapterUnitTestKit.h"
#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"

static NSString *const AUTKRewardedInterstitialBidResponse = @"bidResponse";
static NSString *const AUTKRewardedInterstitialWatermark = @"watermark";

@interface AUTFBRewardedInterstitialRendererTest : XCTestCase
@end

/**
 * Returns a correctly configured rewarded ad configuration.
 */
AUTKMediationRewardedAdConfiguration
    *_Nonnull AUTGADMediationRewardedInterstitialAdConfiguration() {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatRewardedInterstitial;
  credentials.settings = @{GADMAdapterFacebookBiddingPubID : GADMAdapterFacebookBiddingPubID};

  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = nil;
  configuration.bidResponse = AUTKRewardedInterstitialBidResponse;
  configuration.watermark =
      [AUTKRewardedInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];

  return configuration;
}

@implementation AUTFBRewardedInterstitialRendererTest {
  GADMediationAdapterFacebook *_adapter;
  id _mockFBRewardedInterstitialVideoAdClass;
  __weak id<FBRewardedVideoAdDelegate> _rewardedVideoAdDelegate;
  id _fbAdSettingsMock;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterFacebook alloc] init];
  _mockFBRewardedInterstitialVideoAdClass = OCMClassMock([FBRewardedVideoAd class]);
  OCMStub([_mockFBRewardedInterstitialVideoAdClass alloc])
      .andReturn(_mockFBRewardedInterstitialVideoAdClass);
  OCMStub([_mockFBRewardedInterstitialVideoAdClass initWithPlacementID:[OCMArg any]])
      .andReturn(_mockFBRewardedInterstitialVideoAdClass);

  id delegateSave = [OCMArg checkWithBlock:^BOOL(id obj) {
    self->_rewardedVideoAdDelegate = obj;
    return YES;
  }];
  OCMStub([_mockFBRewardedInterstitialVideoAdClass setDelegate:delegateSave]);
  _fbAdSettingsMock = OCMClassMock([FBAdSettings class]);
}

- (void)tearDown {
  // Reset the GMA SDK state to ensure test isolation.
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  [_fbAdSettingsMock stopMocking];
  [super tearDown];
}

- (void)testLoadRewardedInterstitialAd {
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData =
            [AUTKRewardedInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewardedInterstitial];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass
              loadAdWithBidPayload:AUTKRewardedInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });
  AUTKWaitAndAssertLoadRewardedInterstitialAd(_adapter,
                                              AUTGADMediationRewardedInterstitialAdConfiguration());
}

- (void)testRenderRewardedInterstitialFailureWithAdDidNotLoad {
  NSError *expectedError = [NSError errorWithDomain:@"GADFBErrorDomain" code:101 userInfo:nil];
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass
              loadAdWithBidPayload:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAd:ad didFailWithError:expectedError];
      });

  AUTKWaitAndAssertLoadRewardedInterstitialAdFailure(
      _adapter, AUTGADMediationRewardedInterstitialAdConfiguration(), expectedError);
}

- (void)testRenderRewardedInterstitialFailureWithNoPlacementID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatRewardedInterstitial;
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = nil;

  NSError *expectedError = [NSError errorWithDomain:@"com.google.mediation.facebook"
                                               code:GADFBErrorInvalidRequest
                                           userInfo:nil];
  OCMReject([_mockFBRewardedInterstitialVideoAdClass loadAdWithBidPayload:[OCMArg any]]);

  AUTKWaitAndAssertLoadRewardedInterstitialAdFailure(_adapter, configuration, expectedError);
}

- (void)testRwardedInterstitialClick {
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewardedInterstitial];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass
              loadAdWithBidPayload:AUTKRewardedInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKMediationRewardedAdEventDelegate *delegate = AUTKWaitAndAssertLoadRewardedInterstitialAd(
      _adapter, AUTGADMediationRewardedInterstitialAdConfiguration());

  XCTAssertEqual(delegate.reportClickInvokeCount, 0);
  [(id<FBRewardedVideoAdDelegate>)_rewardedVideoAdDelegate
      rewardedVideoAdDidClick:(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);
}

- (void)testRewardedInterstitialImpressionReport {
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewardedInterstitial];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass
              loadAdWithBidPayload:AUTKRewardedInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKMediationRewardedAdEventDelegate *delegate = AUTKWaitAndAssertLoadRewardedInterstitialAd(
      _adapter, AUTGADMediationRewardedInterstitialAdConfiguration());

  XCTAssertEqual(delegate.reportImpressionInvokeCount, 0);
  [(id<FBRewardedVideoAdDelegate>)_rewardedVideoAdDelegate
      rewardedVideoAdWillLogImpression:(FBRewardedVideoAd *)
                                           _mockFBRewardedInterstitialVideoAdClass];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);
}

- (void)testRewardedInterstitialPresentFromViewController {
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewardedInterstitial];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass
              loadAdWithBidPayload:AUTKRewardedInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass
              showAdFromRootViewController:[OCMArg any]])
      .andReturn(YES);

  AUTKMediationRewardedAdEventDelegate *delegate = AUTKWaitAndAssertLoadRewardedInterstitialAd(
      _adapter, AUTGADMediationRewardedInterstitialAdConfiguration());

  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(delegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(delegate.didRewardUserInvokeCount, 0);
  XCTAssertEqual(delegate.didStartVideoInvokeCount, 0);
  XCTAssertEqual(delegate.didEndVideoInvokeCount, 0);

  UIViewController *viewController = [[UIViewController alloc] init];
  [delegate.rewardedAd presentFromViewController:viewController];
  [(id<FBRewardedVideoAdDelegate>)_rewardedVideoAdDelegate
      rewardedVideoAdWillClose:(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass];
  [(id<FBRewardedVideoAdDelegate>)_rewardedVideoAdDelegate
      rewardedVideoAdDidClose:(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass];
  [(id<FBRewardedVideoAdDelegate>)_rewardedVideoAdDelegate
      rewardedVideoAdVideoComplete:(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass];

  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(delegate.willDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(delegate.didRewardUserInvokeCount, 1);
  XCTAssertEqual(delegate.didStartVideoInvokeCount, 1);
  XCTAssertEqual(delegate.didEndVideoInvokeCount, 1);

  OCMVerify([(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass
      showAdFromRootViewController:viewController]);
}

- (void)testRewardedInterstitialPresentFromViewControllerFailure {
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewardedInterstitial];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass
              loadAdWithBidPayload:AUTKRewardedInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass
              showAdFromRootViewController:[OCMArg any]])
      .andReturn(NO);

  AUTKMediationRewardedAdEventDelegate *delegate = AUTKWaitAndAssertLoadRewardedInterstitialAd(
      _adapter, AUTGADMediationRewardedInterstitialAdConfiguration());

  XCTAssertEqual(delegate.didFailToPresentError, nil);
  UIViewController *viewController = [[UIViewController alloc] init];
  [delegate.rewardedAd presentFromViewController:viewController];
  XCTAssertEqual(delegate.didFailToPresentError.code, GADFBErrorAdNotValid);

  OCMVerify([(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass
      showAdFromRootViewController:viewController]);
}

- (void)testLoadRewardedInterstitialAdWhenChildDirectedIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData =
            [AUTKRewardedInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewardedInterstitial];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass
              loadAdWithBidPayload:AUTKRewardedInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadRewardedInterstitialAd(_adapter,
                                              AUTGADMediationRewardedInterstitialAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadRewardedInterstitialAdWhenUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData =
            [AUTKRewardedInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewardedInterstitial];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass
              loadAdWithBidPayload:AUTKRewardedInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadRewardedInterstitialAd(_adapter,
                                              AUTGADMediationRewardedInterstitialAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadRewardedInterstitialAdWhenChildDirectedIsTrueAndUnderAgeIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData =
            [AUTKRewardedInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewardedInterstitial];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass
              loadAdWithBidPayload:AUTKRewardedInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadRewardedInterstitialAd(_adapter,
                                              AUTGADMediationRewardedInterstitialAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadRewardedInterstitialAdWhenChildDirectedIsFalseAndUnderAgeIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData =
            [AUTKRewardedInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewardedInterstitial];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass
              loadAdWithBidPayload:AUTKRewardedInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadRewardedInterstitialAd(_adapter,
                                              AUTGADMediationRewardedInterstitialAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadRewardedInterstitialAdWhenBothAreTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData =
            [AUTKRewardedInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewardedInterstitial];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass
              loadAdWithBidPayload:AUTKRewardedInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadRewardedInterstitialAd(_adapter,
                                              AUTGADMediationRewardedInterstitialAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadRewardedInterstitialAdWhenBothAreFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData =
            [AUTKRewardedInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewardedInterstitial];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass
              loadAdWithBidPayload:AUTKRewardedInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadRewardedInterstitialAd(_adapter,
                                              AUTGADMediationRewardedInterstitialAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadRewardedInterstitialAdWhenChildDirectedIsFalseAndUnderAgeIsNil {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData =
            [AUTKRewardedInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewardedInterstitial];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass
              loadAdWithBidPayload:AUTKRewardedInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadRewardedInterstitialAd(_adapter,
                                              AUTGADMediationRewardedInterstitialAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadRewardedInterstitialAdWhenUnderAgeIsFalseAndChildDirectedIsNil {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData =
            [AUTKRewardedInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMExpect([_mockFBRewardedInterstitialVideoAdClass
      setAdExperienceConfig:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExperienceConfig *config = (FBAdExperienceConfig *)obj;
        return [config.adExperienceType isEqualToString:FBAdExperienceTypeRewardedInterstitial];
      }]]);
  OCMStub([(FBRewardedVideoAd *)_mockFBRewardedInterstitialVideoAdClass
              loadAdWithBidPayload:AUTKRewardedInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBRewardedVideoAd *ad = (FBRewardedVideoAd *)invocation.target;
        [self->_rewardedVideoAdDelegate rewardedVideoAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadRewardedInterstitialAd(_adapter,
                                              AUTGADMediationRewardedInterstitialAdConfiguration());

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
