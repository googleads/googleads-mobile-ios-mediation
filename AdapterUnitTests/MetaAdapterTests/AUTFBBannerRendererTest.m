#import "GADMediationAdapterFacebook.h"

#import <XCTest/XCTest.h>

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>

#import "AUTTestUtils.h"
#import "AdapterUnitTestKit/AdapterUnitTestKit.h"
#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"

static NSString *const AUTKBannerBidResponse = @"bidResponse";
static NSString *const AUTKBannerWatermark = @"watermark";
static CGFloat const AUTKBannerTestViewWidth = 320.0;
static CGFloat const AUTKBannerTestViewHeight = 50.0;

@interface AUTFBBannerRendererTest : XCTestCase
@end

/// Returns a correctly configured banner ad configuration.
AUTKMediationBannerAdConfiguration *_Nonnull AUTGADMediationBannerAdConfiguration() {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatBanner;
  credentials.settings = @{GADMAdapterFacebookBiddingPubID : GADMAdapterFacebookBiddingPubID};

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.extras = nil;
  configuration.bidResponse = AUTKBannerBidResponse;
  configuration.watermark = [AUTKBannerWatermark dataUsingEncoding:NSUTF8StringEncoding];
  configuration.adSize =
      GADAdSizeFromCGSize(CGSizeMake(AUTKBannerTestViewWidth, AUTKBannerTestViewHeight));
  UIViewController *topViewController = [[UIViewController alloc] init];
  configuration.topViewController = topViewController;

  return configuration;
}

@implementation AUTFBBannerRendererTest {
  GADMediationAdapterFacebook *_adapter;
  id _mockFBAdView;
  __weak id<FBAdViewDelegate> _bannerAdDelegate;
  id _fbAdSettingsMock;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterFacebook alloc] init];
  _mockFBAdView = OCMClassMock([FBAdView class]);
  OCMStub([_mockFBAdView alloc]).andReturn(_mockFBAdView);
  OCMStub([_mockFBAdView initWithPlacementID:[OCMArg any]
                                  bidPayload:[OCMArg any]
                          rootViewController:[OCMArg any]
                                       error:[OCMArg anyObjectRef]])
      .andReturn(_mockFBAdView);

  id delegateSave = [OCMArg checkWithBlock:^BOOL(id obj) {
    self->_bannerAdDelegate = obj;
    return YES;
  }];
  OCMStub([_mockFBAdView setDelegate:delegateSave]);
  OCMStub([_mockFBAdView setDelegate:delegateSave]);
  _fbAdSettingsMock = OCMClassMock([FBAdSettings class]);
}

- (void)tearDown {
  // Reset the GMA SDK state to ensure test isolation.
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  [_fbAdSettingsMock stopMocking];
  [super tearDown];
}

- (void)testRenderBanner {
  OCMExpect([_mockFBAdView setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
                             FBAdExtraHint *hint = (FBAdExtraHint *)obj;
                             NSData *watermarkData =
                                 [AUTKBannerWatermark dataUsingEncoding:NSUTF8StringEncoding];
                             NSString *watermarkString =
                                 [watermarkData base64EncodedStringWithOptions:0];
                             return [hint.mediationData isEqualToString:watermarkString];
                           }]]);
  OCMStub([(FBAdView *)_mockFBAdView loadAdWithBidPayload:AUTKBannerBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBAdView *ad = (FBAdView *)invocation.target;
        [self->_bannerAdDelegate adViewDidLoad:ad];
      });

  AUTKWaitAndAssertLoadBannerAd(_adapter, AUTGADMediationBannerAdConfiguration());
}

- (void)testRenderBannerFailureWithAdDidNotLoad {
  NSError *expectedError = [NSError errorWithDomain:@"GADFBErrorDomain" code:101 userInfo:nil];
  OCMStub([(FBAdView *)_mockFBAdView loadAdWithBidPayload:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        FBAdView *ad = (FBAdView *)invocation.target;
        [self->_bannerAdDelegate adView:ad didFailWithError:expectedError];
      });

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, AUTGADMediationBannerAdConfiguration(),
                                       expectedError);
}

- (void)testRenderBannerFailureWithCredentialsWithoutPubID {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatBanner;

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize =
      GADAdSizeFromCGSize(CGSizeMake(AUTKBannerTestViewWidth, AUTKBannerTestViewHeight));
  UIViewController *topViewController = [[UIViewController alloc] init];
  configuration.topViewController = topViewController;

  NSError *expectedError = [NSError errorWithDomain:@"com.google.mediation.facebook"
                                               code:GADFBErrorInvalidRequest
                                           userInfo:nil];
  OCMReject([_mockFBAdView loadAdWithBidPayload:[OCMArg any]]);
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testRenderBannerFailurewithRootViewControllernull {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.format = GADAdFormatBanner;
  credentials.settings = @{GADMAdapterFacebookBiddingPubID : GADMAdapterFacebookBiddingPubID};

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize =
      GADAdSizeFromCGSize(CGSizeMake(AUTKBannerTestViewWidth, AUTKBannerTestViewHeight));
  configuration.topViewController = nil;

  NSError *expectedError = [NSError errorWithDomain:@"com.google.mediation.facebook"
                                               code:GADFBErrorRootViewControllerNil
                                           userInfo:nil];
  OCMReject([_mockFBAdView loadAdWithBidPayload:[OCMArg any]]);
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testBannerClick {
  OCMStub([(FBAdView *)_mockFBAdView loadAdWithBidPayload:AUTKBannerBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBAdView *ad = (FBAdView *)invocation.target;
        [self->_bannerAdDelegate adViewDidLoad:ad];
      });

  AUTKMediationBannerAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, AUTGADMediationBannerAdConfiguration());

  XCTAssertEqual(delegate.reportClickInvokeCount, 0);
  [_bannerAdDelegate adViewDidClick:(FBAdView *)_mockFBAdView];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);
}

- (void)testBannerImpressionReport {
  OCMStub([(FBAdView *)_mockFBAdView loadAdWithBidPayload:AUTKBannerBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBAdView *ad = (FBAdView *)invocation.target;
        [self->_bannerAdDelegate adViewDidLoad:ad];
      });

  AUTKMediationBannerAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, AUTGADMediationBannerAdConfiguration());

  XCTAssertEqual(delegate.reportImpressionInvokeCount, 0);
  [_bannerAdDelegate adViewWillLogImpression:(FBAdView *)_mockFBAdView];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);
}

- (void)testViewControllerForPresentingModalView {
  AUTKMediationBannerAdConfiguration *configuration = AUTGADMediationBannerAdConfiguration();
  UIViewController *expectedViewController = configuration.topViewController;

  OCMStub([(FBAdView *)_mockFBAdView loadAdWithBidPayload:AUTKBannerBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBAdView *ad = (FBAdView *)invocation.target;
        [self->_bannerAdDelegate adViewDidLoad:ad];
      });

  AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);

  XCTAssertEqual([(id<FBAdViewDelegate>)_bannerAdDelegate viewControllerForPresentingModalView],
                 expectedViewController,
                 @"The viewControllerForPresentingModalView should return the topViewController "
                 @"from the configuration.");
}

- (void)testView {
  OCMStub([(FBAdView *)_mockFBAdView loadAdWithBidPayload:AUTKBannerBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBAdView *ad = (FBAdView *)invocation.target;
        [self->_bannerAdDelegate adViewDidLoad:ad];
      });

  AUTKWaitAndAssertLoadBannerAd(_adapter, AUTGADMediationBannerAdConfiguration());
  id<GADMediationBannerAd> bannerAd = (id<GADMediationBannerAd>)_bannerAdDelegate;

  XCTAssertEqual([bannerAd view], _mockFBAdView,
                 @"The view method should return the loaded FBAdView.");
}

- (void)testLoadBannerAdWhenChildDirectedIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBAdView setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
                             FBAdExtraHint *hint = (FBAdExtraHint *)obj;
                             NSData *watermarkData =
                                 [AUTKBannerWatermark dataUsingEncoding:NSUTF8StringEncoding];
                             NSString *watermarkString =
                                 [watermarkData base64EncodedStringWithOptions:0];
                             return [hint.mediationData isEqualToString:watermarkString];
                           }]]);
  OCMStub([(FBAdView *)_mockFBAdView loadAdWithBidPayload:AUTKBannerBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBAdView *ad = (FBAdView *)invocation.target;
        [self->_bannerAdDelegate adViewDidLoad:ad];
      });

  AUTKWaitAndAssertLoadBannerAd(_adapter, AUTGADMediationBannerAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadBannerAdWhenUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBAdView setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
                             FBAdExtraHint *hint = (FBAdExtraHint *)obj;
                             NSData *watermarkData =
                                 [AUTKBannerWatermark dataUsingEncoding:NSUTF8StringEncoding];
                             NSString *watermarkString =
                                 [watermarkData base64EncodedStringWithOptions:0];
                             return [hint.mediationData isEqualToString:watermarkString];
                           }]]);
  OCMStub([(FBAdView *)_mockFBAdView loadAdWithBidPayload:AUTKBannerBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBAdView *ad = (FBAdView *)invocation.target;
        [self->_bannerAdDelegate adViewDidLoad:ad];
      });

  AUTKWaitAndAssertLoadBannerAd(_adapter, AUTGADMediationBannerAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadBannerAdWhenAgeRestrictedTreatmentIsChild {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBAdView setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
                             FBAdExtraHint *hint = (FBAdExtraHint *)obj;
                             NSData *watermarkData =
                                 [AUTKBannerWatermark dataUsingEncoding:NSUTF8StringEncoding];
                             NSString *watermarkString =
                                 [watermarkData base64EncodedStringWithOptions:0];
                             return [hint.mediationData isEqualToString:watermarkString];
                           }]]);
  OCMStub([(FBAdView *)_mockFBAdView loadAdWithBidPayload:AUTKBannerBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBAdView *ad = (FBAdView *)invocation.target;
        [self->_bannerAdDelegate adViewDidLoad:ad];
      });

  AUTKWaitAndAssertLoadBannerAd(_adapter, AUTGADMediationBannerAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadBannerAdWhenChildDirectedIsTrueAndUnderAgeIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBAdView setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
                             FBAdExtraHint *hint = (FBAdExtraHint *)obj;
                             NSData *watermarkData =
                                 [AUTKBannerWatermark dataUsingEncoding:NSUTF8StringEncoding];
                             NSString *watermarkString =
                                 [watermarkData base64EncodedStringWithOptions:0];
                             return [hint.mediationData isEqualToString:watermarkString];
                           }]]);
  OCMStub([(FBAdView *)_mockFBAdView loadAdWithBidPayload:AUTKBannerBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBAdView *ad = (FBAdView *)invocation.target;
        [self->_bannerAdDelegate adViewDidLoad:ad];
      });

  AUTKWaitAndAssertLoadBannerAd(_adapter, AUTGADMediationBannerAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadBannerAdWhenChildDirectedIsFalseAndUnderAgeIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBAdView setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
                             FBAdExtraHint *hint = (FBAdExtraHint *)obj;
                             NSData *watermarkData =
                                 [AUTKBannerWatermark dataUsingEncoding:NSUTF8StringEncoding];
                             NSString *watermarkString =
                                 [watermarkData base64EncodedStringWithOptions:0];
                             return [hint.mediationData isEqualToString:watermarkString];
                           }]]);
  OCMStub([(FBAdView *)_mockFBAdView loadAdWithBidPayload:AUTKBannerBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBAdView *ad = (FBAdView *)invocation.target;
        [self->_bannerAdDelegate adViewDidLoad:ad];
      });

  AUTKWaitAndAssertLoadBannerAd(_adapter, AUTGADMediationBannerAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)
    testLoadBannerAdWhentagForChildDirectedTreatmentandTagForUnderAgeOfConsentAreTrueAndAgeRestrictedTreatmentIsChild {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentChild;
  OCMExpect([_fbAdSettingsMock setMixedAudience:YES]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBAdView setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
                             FBAdExtraHint *hint = (FBAdExtraHint *)obj;
                             NSData *watermarkData =
                                 [AUTKBannerWatermark dataUsingEncoding:NSUTF8StringEncoding];
                             NSString *watermarkString =
                                 [watermarkData base64EncodedStringWithOptions:0];
                             return [hint.mediationData isEqualToString:watermarkString];
                           }]]);
  OCMStub([(FBAdView *)_mockFBAdView loadAdWithBidPayload:AUTKBannerBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBAdView *ad = (FBAdView *)invocation.target;
        [self->_bannerAdDelegate adViewDidLoad:ad];
      });

  AUTKWaitAndAssertLoadBannerAd(_adapter, AUTGADMediationBannerAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadBannerAdWhenTagForChildDirectedTreatmentandTagForUnderAgeOfConsentAreFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBAdView setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
                             FBAdExtraHint *hint = (FBAdExtraHint *)obj;
                             NSData *watermarkData =
                                 [AUTKBannerWatermark dataUsingEncoding:NSUTF8StringEncoding];
                             NSString *watermarkString =
                                 [watermarkData base64EncodedStringWithOptions:0];
                             return [hint.mediationData isEqualToString:watermarkString];
                           }]]);
  OCMStub([(FBAdView *)_mockFBAdView loadAdWithBidPayload:AUTKBannerBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBAdView *ad = (FBAdView *)invocation.target;
        [self->_bannerAdDelegate adViewDidLoad:ad];
      });

  AUTKWaitAndAssertLoadBannerAd(_adapter, AUTGADMediationBannerAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadBannerAdWhenChildDirectedIsFalseAndUnderAgeIsNil {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBAdView setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
                             FBAdExtraHint *hint = (FBAdExtraHint *)obj;
                             NSData *watermarkData =
                                 [AUTKBannerWatermark dataUsingEncoding:NSUTF8StringEncoding];
                             NSString *watermarkString =
                                 [watermarkData base64EncodedStringWithOptions:0];
                             return [hint.mediationData isEqualToString:watermarkString];
                           }]]);
  OCMStub([(FBAdView *)_mockFBAdView loadAdWithBidPayload:AUTKBannerBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBAdView *ad = (FBAdView *)invocation.target;
        [self->_bannerAdDelegate adViewDidLoad:ad];
      });

  AUTKWaitAndAssertLoadBannerAd(_adapter, AUTGADMediationBannerAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadBannerAdWhenUnderAgeIsFalseAndChildDirectedIsNil {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBAdView setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
                             FBAdExtraHint *hint = (FBAdExtraHint *)obj;
                             NSData *watermarkData =
                                 [AUTKBannerWatermark dataUsingEncoding:NSUTF8StringEncoding];
                             NSString *watermarkString =
                                 [watermarkData base64EncodedStringWithOptions:0];
                             return [hint.mediationData isEqualToString:watermarkString];
                           }]]);
  OCMStub([(FBAdView *)_mockFBAdView loadAdWithBidPayload:AUTKBannerBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBAdView *ad = (FBAdView *)invocation.target;
        [self->_bannerAdDelegate adViewDidLoad:ad];
      });

  AUTKWaitAndAssertLoadBannerAd(_adapter, AUTGADMediationBannerAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

- (void)testLoadBannerAdWhenAgeRestrictedTreatmentIsTeen {
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentTeen;
  OCMExpect([_fbAdSettingsMock setMixedAudience:NO]);

  GADMAdapterFacebookSetMixedAudienceIfNeeded();
  OCMExpect([_mockFBAdView setExtraHint:[OCMArg checkWithBlock:^BOOL(id obj) {
                             FBAdExtraHint *hint = (FBAdExtraHint *)obj;
                             NSData *watermarkData =
                                 [AUTKBannerWatermark dataUsingEncoding:NSUTF8StringEncoding];
                             NSString *watermarkString =
                                 [watermarkData base64EncodedStringWithOptions:0];
                             return [hint.mediationData isEqualToString:watermarkString];
                           }]]);
  OCMStub([(FBAdView *)_mockFBAdView loadAdWithBidPayload:AUTKBannerBidResponse])
      .andDo(^(NSInvocation *invocation) {
        FBAdView *ad = (FBAdView *)invocation.target;
        [self->_bannerAdDelegate adViewDidLoad:ad];
      });

  AUTKWaitAndAssertLoadBannerAd(_adapter, AUTGADMediationBannerAdConfiguration());

  OCMVerifyAll(_fbAdSettingsMock);
}

@end
