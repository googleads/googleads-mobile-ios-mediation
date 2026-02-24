#import "GADMediationAdapterFacebook.h"

#import <XCTest/XCTest.h>

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>

#import "AUTTestUtils.h"
#import "AdapterUnitTestKit/AdapterUnitTestKit.h"
#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"

static NSString *const AUTKInterstitialBidResponse = @"bidResponse";
static NSString *const AUTKInterstitialWatermark = @"watermark";

@interface AUTFBInterstitialRendererTest : XCTestCase
@end


/**
 * Returns a correctly configured interstitial ad configuration.
 */
AUTKMediationInterstitialAdConfiguration *_Nonnull AUTGADMediationInterstitialAdConfiguration() {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatInterstitial;
  credentials.settings = @{GADMAdapterFacebookBiddingPubID : GADMAdapterFacebookBiddingPubID};

  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = nil;
  configuration.bidResponse = AUTKInterstitialBidResponse;
  configuration.watermark = [AUTKInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];

  return configuration;
}


@implementation AUTFBInterstitialRendererTest {
  GADMediationAdapterFacebook *_adapter;
  id _mockFBInterstitialAdClass;
  __weak id<FBInterstitialAdDelegate> _interstitialAdDelegate;
  id _fbAdSettingsMock;
//  GADFBInterstitialRenderer *_renderer;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterFacebook alloc] init];
  _mockFBInterstitialAdClass = OCMClassMock([FBInterstitialAd class]);
  OCMStub([_mockFBInterstitialAdClass alloc]).andReturn(_mockFBInterstitialAdClass);
  OCMStub([_mockFBInterstitialAdClass initWithPlacementID:[OCMArg any]])
      .andReturn(_mockFBInterstitialAdClass);

  id delegateSave = [OCMArg checkWithBlock:^BOOL(id obj) {
    self->_interstitialAdDelegate = obj;
    return YES;
  }];
  OCMStub([_mockFBInterstitialAdClass setDelegate:delegateSave]);
  _fbAdSettingsMock = OCMClassMock([FBAdSettings class]);
}

- (void)tearDown {
  // Reset the GMA SDK state to ensure test isolation.
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  [_fbAdSettingsMock stopMocking];
  [super tearDown];
}

- (void)testRenderInterstitial {

  OCMExpect([_mockFBInterstitialAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadInterstitialAd(_adapter, AUTGADMediationInterstitialAdConfiguration());
}

- (void)testRenderInterstitialFailureWithAdDidNotLoad {

  NSError *expectedError = [NSError errorWithDomain:@"GADFBErrorDomain" code:101 userInfo:nil];
  OCMStub([(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = invocation.target;
        [self->_interstitialAdDelegate interstitialAd:ad didFailWithError:expectedError];
      });

  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, AUTGADMediationInterstitialAdConfiguration(),expectedError);
}

- (void)testRenderInterstitialFailureWithCredentialsWithoutPubID {

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format=GADAdFormatInterstitial;

  AUTKMediationInterstitialAdConfiguration *configuration = [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError = [NSError errorWithDomain:@"com.google.mediation.facebook"
                                               code:GADFBErrorInvalidRequest
                                           userInfo:nil];
  OCMReject([_mockFBInterstitialAdClass loadAdWithBidPayload:[OCMArg any]]);
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);

}

- (void)testInterstitialClick {
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKMediationInterstitialAdEventDelegate *delegate = AUTKWaitAndAssertLoadInterstitialAd(_adapter, AUTGADMediationInterstitialAdConfiguration());

  XCTAssertEqual(delegate.reportClickInvokeCount, 0);
  [(id<FBInterstitialAdDelegate>)_interstitialAdDelegate
      interstitialAdDidClick:(FBInterstitialAd *)_mockFBInterstitialAdClass];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);
}

- (void)testInterstitialImpressionReport {
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKMediationInterstitialAdEventDelegate *delegate = AUTKWaitAndAssertLoadInterstitialAd(_adapter, AUTGADMediationInterstitialAdConfiguration());

  XCTAssertEqual(delegate.reportImpressionInvokeCount, 0);
  [(id<FBInterstitialAdDelegate>)_interstitialAdDelegate
      interstitialAdWillLogImpression:(FBInterstitialAd *)_mockFBInterstitialAdClass];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);
}

- (void)testInterstitialPresentFromViewController {
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass showAdFromRootViewController:[OCMArg any]])
      .andReturn(YES);

  AUTKMediationInterstitialAdEventDelegate *delegate = AUTKWaitAndAssertLoadInterstitialAd(_adapter, AUTGADMediationInterstitialAdConfiguration());

  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(delegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 0);

  UIViewController *viewController = [[UIViewController alloc] init];
  [delegate.interstitialAd presentFromViewController:viewController];
  [(id<FBInterstitialAdDelegate>)_interstitialAdDelegate
      interstitialAdWillClose:(FBInterstitialAd *)_mockFBInterstitialAdClass];
  [(id<FBInterstitialAdDelegate>)_interstitialAdDelegate
      interstitialAdDidClose:(FBInterstitialAd *)_mockFBInterstitialAdClass];

  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(delegate.willDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 1);

  OCMVerify(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass showAdFromRootViewController:viewController]);
}

- (void)testInterstitialPresentFromViewControllerFailure {
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass showAdFromRootViewController:[OCMArg any]])
      .andReturn(NO);

  AUTKMediationInterstitialAdEventDelegate *delegate = AUTKWaitAndAssertLoadInterstitialAd(_adapter, AUTGADMediationInterstitialAdConfiguration());

  XCTAssertEqual(delegate.didFailToPresentError, nil);
  UIViewController *viewController = [[UIViewController alloc] init];
  [delegate.interstitialAd presentFromViewController:viewController];
  XCTAssertEqual(delegate.didFailToPresentError.code, GADFBErrorAdNotValid);

  OCMVerify(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass showAdFromRootViewController:viewController]);
}

- (void)testLoadInterstitialAdWhenChildDirectedIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBInterstitialAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadInterstitialAd(_adapter, AUTGADMediationInterstitialAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadInterstitialAdWhenUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBInterstitialAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadInterstitialAd(_adapter, AUTGADMediationInterstitialAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadInterstitialAdWhenChildDirectedIsTrueAndUnderAgeIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBInterstitialAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadInterstitialAd(_adapter, AUTGADMediationInterstitialAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadInterstitialAdWhenChildDirectedIsFalseAndUnderAgeIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBInterstitialAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadInterstitialAd(_adapter, AUTGADMediationInterstitialAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadInterstitialAdWhenBothAreTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBInterstitialAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadInterstitialAd(_adapter, AUTGADMediationInterstitialAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadInterstitialAdWhenBothAreFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBInterstitialAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadInterstitialAd(_adapter, AUTGADMediationInterstitialAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadInterstitialAdWhenChildDirectedIsFalseAndUnderAgeIsNil {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBInterstitialAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadInterstitialAd(_adapter, AUTGADMediationInterstitialAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadInterstitialAdWhenUnderAgeIsFalseAndChildDirectedIsNil {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBInterstitialAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKInterstitialWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKInterstitialBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadInterstitialAd(_adapter, AUTGADMediationInterstitialAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

@end
