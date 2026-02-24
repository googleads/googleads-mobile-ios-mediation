#import "GADMediationAdapterFacebook.h"

#import <XCTest/XCTest.h>

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>

#import "AUTTestUtils.h"
#import "AdapterUnitTestKit/AdapterUnitTestKit.h"
#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"

static NSString *const AUTKAppOpenBidResponse = @"bidResponse";
static NSString *const AUTKAppOpenWatermark = @"watermark";

@interface AUTFBAppOpenRendererTest : XCTestCase
@end

/**
 * Returns a correctly configured app open ad configuration.
 */
AUTKMediationAppOpenAdConfiguration *_Nonnull AUTGADMediationAppOpenAdConfiguration() {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatAppOpen;
  credentials.settings = @{GADMAdapterFacebookBiddingPubID : GADMAdapterFacebookBiddingPubID};

  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = nil;
  configuration.bidResponse = AUTKAppOpenBidResponse;
  configuration.watermark = [AUTKAppOpenWatermark dataUsingEncoding:NSUTF8StringEncoding];

  return configuration;
}

@implementation AUTFBAppOpenRendererTest {
  GADMediationAdapterFacebook *_adapter;
  id _mockFBInterstitialAdClass;
  __weak id<FBInterstitialAdDelegate> _interstitialAdDelegate;
  id _fbAdSettingsMock;
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

- (void)testRenderAppOpen {
  OCMExpect([_mockFBInterstitialAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKAppOpenWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKAppOpenBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadAppOpenAd(_adapter, AUTGADMediationAppOpenAdConfiguration());
}

- (void)testRenderAppOpenFailureWithAdDidNotLoad {
  NSError *expectedError = [NSError errorWithDomain:@"GADFBErrorDomain" code:101 userInfo:nil];
  OCMStub([(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = invocation.target;
        [self->_interstitialAdDelegate interstitialAd:ad didFailWithError:expectedError];
      });

  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, AUTGADMediationAppOpenAdConfiguration(),
                                        expectedError);
}

- (void)testRenderAppOpenFailureWithCredentialsWithoutPubID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatAppOpen;
  AUTKMediationAppOpenAdConfiguration *configuration =
      [[AUTKMediationAppOpenAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = nil;

  NSError *expectedError = [NSError errorWithDomain:@"com.google.mediation.facebook"
                                               code:GADFBErrorInvalidRequest
                                           userInfo:nil];
  OCMReject([_mockFBInterstitialAdClass loadAdWithBidPayload:[OCMArg any]]);

  AUTKWaitAndAssertLoadAppOpenAdFailure(_adapter, configuration, expectedError);
}

- (void)testAppOpenClick {
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKAppOpenBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKMediationAppOpenAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadAppOpenAd(_adapter, AUTGADMediationAppOpenAdConfiguration());

  XCTAssertEqual(delegate.reportClickInvokeCount, 0);
  [(id<FBInterstitialAdDelegate>)_interstitialAdDelegate
      interstitialAdDidClick:(FBInterstitialAd *)_mockFBInterstitialAdClass];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);
}

- (void)testAppOpenImpressionReport {
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKAppOpenBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKMediationAppOpenAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadAppOpenAd(_adapter, AUTGADMediationAppOpenAdConfiguration());

  XCTAssertEqual(delegate.reportImpressionInvokeCount, 0);
  [(id<FBInterstitialAdDelegate>)_interstitialAdDelegate
      interstitialAdWillLogImpression:(FBInterstitialAd *)_mockFBInterstitialAdClass];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);
}

- (void)testAppOpenPresentFromViewController {
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKAppOpenBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass showAdFromRootViewController:[OCMArg any]])
      .andReturn(YES);

  AUTKMediationAppOpenAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadAppOpenAd(_adapter, AUTGADMediationAppOpenAdConfiguration());

  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(delegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 0);

  UIViewController *viewController = [[UIViewController alloc] init];
  [delegate.appOpenAd presentFromViewController:viewController];
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

- (void)testAppOpenPresentFromViewControllerFailure {
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKAppOpenBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass showAdFromRootViewController:[OCMArg any]])
      .andReturn(NO);

  AUTKMediationAppOpenAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadAppOpenAd(_adapter, AUTGADMediationAppOpenAdConfiguration());

  XCTAssertEqual(delegate.didFailToPresentError, nil);
  UIViewController *viewController = [[UIViewController alloc] init];
  [delegate.appOpenAd presentFromViewController:viewController];
  XCTAssertEqual(delegate.didFailToPresentError.code, GADFBErrorAdNotValid);

  OCMVerify(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass showAdFromRootViewController:viewController]);
}

- (void)testLoadAppOpenAdWhenChildDirectedIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBInterstitialAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKAppOpenWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKAppOpenBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadAppOpenAd(_adapter, AUTGADMediationAppOpenAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadAppOpenAdWhenUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBInterstitialAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKAppOpenWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKAppOpenBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadAppOpenAd(_adapter, AUTGADMediationAppOpenAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadAppOpenAdWhenChildDirectedIsTrueAndUnderAgeIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBInterstitialAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKAppOpenWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKAppOpenBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadAppOpenAd(_adapter, AUTGADMediationAppOpenAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadAppOpenAdWhenChildDirectedIsFalseAndUnderAgeIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBInterstitialAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKAppOpenWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKAppOpenBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadAppOpenAd(_adapter, AUTGADMediationAppOpenAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadAppOpenAdWhenBothAreTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBInterstitialAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKAppOpenWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKAppOpenBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadAppOpenAd(_adapter, AUTGADMediationAppOpenAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadAppOpenAdWhenBothAreFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBInterstitialAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKAppOpenWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKAppOpenBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadAppOpenAd(_adapter, AUTGADMediationAppOpenAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadAppOpenAdWhenChildDirectedIsFalseAndUnderAgeIsNil {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBInterstitialAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKAppOpenWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKAppOpenBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadAppOpenAd(_adapter, AUTGADMediationAppOpenAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadAppOpenAdWhenUnderAgeIsFalseAndChildDirectedIsNil {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBInterstitialAdClass
      setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
        FBAdExtraHint *hint = (FBAdExtraHint *)obj;
        NSData *watermarkData = [AUTKAppOpenWatermark dataUsingEncoding:NSUTF8StringEncoding];
        NSString *watermarkString = [watermarkData base64EncodedStringWithOptions:0];
        return [hint.mediationData isEqualToString:watermarkString];
      }]]);
  OCMStub(
      [(FBInterstitialAd *)_mockFBInterstitialAdClass loadAdWithBidPayload:AUTKAppOpenBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBInterstitialAd *ad = (FBInterstitialAd *)invocation.target;
        [self->_interstitialAdDelegate interstitialAdDidLoad:ad];
      });

  AUTKWaitAndAssertLoadAppOpenAd(_adapter, AUTGADMediationAppOpenAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

@end
