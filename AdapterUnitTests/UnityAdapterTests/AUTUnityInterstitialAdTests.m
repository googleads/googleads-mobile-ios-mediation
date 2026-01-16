#import "GADMediationAdapterUnity.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationInterstitialAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <UnityAds/UnityAds.h>

#import "AUTUnityTestCase.h"
#import "GADMAdapterUnityConstants.h"

@interface AUTUnityInterstitialAdTests : AUTUnityTestCase
@end

@implementation AUTUnityInterstitialAdTests

- (void)setUp {
  [super setUp];
  OCMStub(ClassMethod([self.unityAdsClassMock isInitialized])).andReturn(YES);
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  [super tearDown];
}

- (void)loadWaterfallInterstitialAd {
  OCMStub(OCMClassMethod([self.unityAdsClassMock load:AUTUnityPlacementID
                                              options:OCMOCK_ANY
                                         loadDelegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<UnityAdsLoadDelegate> loadDelegate = nil;
        [invocation getArgument:&loadDelegate atIndex:4];
        [loadDelegate unityAdsAdLoaded:AUTUnityPlacementID];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  AUTKWaitAndAssertLoadInterstitialAd(self.adapter, configuration);
}

- (void)
    testLoadWaterfallInterstitialAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@YES]);
  OCMExpect([metaDataMock commit]);

  [self loadWaterfallInterstitialAd];

  OCMVerifyAll(metaDataMock);
}

- (void)
    testLoadWaterfallInterstitialAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@YES]);
  OCMExpect([metaDataMock commit]);

  [self loadWaterfallInterstitialAd];

  OCMVerifyAll(metaDataMock);
}

- (void)
    testLoadWaterfallInterstitialAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@YES]);
  OCMExpect([metaDataMock commit]);

  [self loadWaterfallInterstitialAd];

  OCMVerifyAll(metaDataMock);
}

- (void)
    testLoadWaterfallInterstitialAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@YES]);
  OCMExpect([metaDataMock commit]);

  [self loadWaterfallInterstitialAd];

  OCMVerifyAll(metaDataMock);
}

- (void)
    testLoadWaterfallInterstitialAdWhenTagForChildDirectedTreatmentIsUnspecifiedAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@YES]);
  OCMExpect([metaDataMock commit]);

  [self loadWaterfallInterstitialAd];

  OCMVerifyAll(metaDataMock);
}

- (void)
    testLoadWaterfallInterstitialAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@NO]);
  OCMExpect([metaDataMock commit]);

  [self loadWaterfallInterstitialAd];

  OCMVerifyAll(metaDataMock);
}

- (void)
    testLoadWaterfallInterstitialAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@NO]);
  OCMExpect([metaDataMock commit]);

  [self loadWaterfallInterstitialAd];

  OCMVerifyAll(metaDataMock);
}

- (void)
    testLoadWaterfallInterstitialAdWhenTagForChildDirectedTreatmentIsUnspecifiedAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@NO]);
  OCMExpect([metaDataMock commit]);

  [self loadWaterfallInterstitialAd];

  OCMVerifyAll(metaDataMock);
}
- (void)loadBiddingInterstitialAd {
  OCMStub(OCMClassMethod([self.unityAdsClassMock
                      load:AUTUnityPlacementID
                   options:[OCMArg checkWithBlock:^BOOL(id value) {
                     XCTAssertTrue([value isKindOfClass:[UADSLoadOptions class]]);
                     UADSLoadOptions *options = (UADSLoadOptions *)value;
                     return [options.adMarkup isEqualToString:AUTUnityBidResponse];
                   }]
              loadDelegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<UnityAdsLoadDelegate> loadDelegate = nil;
        [invocation getArgument:&loadDelegate atIndex:4];
        [loadDelegate unityAdsAdLoaded:AUTUnityPlacementID];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.bidResponse = AUTUnityBidResponse;
  configuration.credentials = credentials;
  AUTKWaitAndAssertLoadInterstitialAd(self.adapter, configuration);
}

- (void)
    testLoadBiddingInterstitialAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@YES]);
  OCMExpect([metaDataMock commit]);

  [self loadBiddingInterstitialAd];

  OCMVerifyAll(metaDataMock);
}

- (void)
    testLoadBiddingInterstitialAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@YES]);
  OCMExpect([metaDataMock commit]);

  [self loadBiddingInterstitialAd];

  OCMVerifyAll(metaDataMock);
}

- (void)
    testLoadBiddingInterstitialAdWhenTagForChildDirectedTreatmentIsTrueAndTagForUnderAgeOfConsentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@YES]);
  OCMExpect([metaDataMock commit]);

  [self loadBiddingInterstitialAd];

  OCMVerifyAll(metaDataMock);
}

- (void)
    testLoadBiddingInterstitialAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@YES]);
  OCMExpect([metaDataMock commit]);

  [self loadBiddingInterstitialAd];

  OCMVerifyAll(metaDataMock);
}

- (void)
    testLoadBiddingInterstitialAdWhenTagForChildDirectedTreatmentIsUnspecifiedAndTagForUnderAgeOfConsentIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@YES]);
  OCMExpect([metaDataMock commit]);

  [self loadBiddingInterstitialAd];

  OCMVerifyAll(metaDataMock);
}

- (void)
    testLoadBiddingInterstitialAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@NO]);
  OCMExpect([metaDataMock commit]);

  [self loadBiddingInterstitialAd];

  OCMVerifyAll(metaDataMock);
}

- (void)
    testLoadBiddingInterstitialAdWhenTagForChildDirectedTreatmentIsFalseAndTagForUnderAgeOfConsentIsUnspecified {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@NO]);
  OCMExpect([metaDataMock commit]);

  [self loadBiddingInterstitialAd];

  OCMVerifyAll(metaDataMock);
}

- (void)
    testLoadBiddingInterstitialAdWhenTagForChildDirectedTreatmentIsUnspecifiedAndTagForUnderAgeOfConsentIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  id metaDataMock = OCMClassMock([UADSMetaData class]);
  OCMStub([metaDataMock alloc]).andReturn(metaDataMock);
  OCMExpect([metaDataMock set:@"user.nonbehavioral" value:@NO]);
  OCMExpect([metaDataMock commit]);

  [self loadBiddingInterstitialAd];

  OCMVerifyAll(metaDataMock);
}

- (void)testLoadBiddingInterstitialAdWithEmptySignal {
  OCMStub(OCMClassMethod([self.unityAdsClassMock load:AUTUnityPlacementID
                                              options:[OCMArg checkWithBlock:^BOOL(id value) {
                                                XCTAssertTrue(
                                                    [value isKindOfClass:[UADSLoadOptions class]]);
                                                UADSLoadOptions *options = (UADSLoadOptions *)value;
                                                return [options.adMarkup isEqualToString:@""];
                                              }]
                                         loadDelegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<UnityAdsLoadDelegate> loadDelegate = nil;
        [invocation getArgument:&loadDelegate atIndex:4];
        [loadDelegate unityAdsAdLoaded:AUTUnityPlacementID];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.bidResponse = @"";
  configuration.credentials = credentials;
  AUTKWaitAndAssertLoadInterstitialAd(self.adapter, configuration);
}

- (void)testLoadInterstitialAdFailure {
  OCMStub(OCMClassMethod([self.unityAdsClassMock load:AUTUnityPlacementID
                                              options:OCMOCK_ANY
                                         loadDelegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<UnityAdsLoadDelegate> loadDelegate = nil;
        [invocation getArgument:&loadDelegate atIndex:4];
        [loadDelegate unityAdsAdFailedToLoad:AUTUnityPlacementID
                                   withError:kUnityAdsLoadErrorNoFill
                                 withMessage:@"abcdefg"];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *error = [NSError errorWithDomain:GADMAdapterUnitySDKErrorDomain
                                       code:kUnityAdsLoadErrorNoFill
                                   userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(self.adapter, configuration, error);
}

- (void)testInterstitialAdPresentLifecycle {
  // First load an intesrstitial ad.
  __block __unsafe_unretained UADSLoadOptions *loadOptions = nil;
  __block __unsafe_unretained id<UnityAdsLoadDelegate, UnityAdsShowDelegate> adapterDelegate = nil;
  OCMStub(OCMClassMethod([self.unityAdsClassMock load:AUTUnityPlacementID
                                              options:OCMOCK_ANY
                                         loadDelegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&loadOptions atIndex:3];
        [invocation getArgument:&adapterDelegate atIndex:4];
        [adapterDelegate unityAdsAdLoaded:AUTUnityPlacementID];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.watermark = [[NSData alloc] initWithBase64EncodedString:AUTUnityWatermarkBase64
                                                                options:0];
  AUTKMediationInterstitialAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadInterstitialAd(self.adapter, configuration);

  // After loading an interstitial ad, verify that present ad invokes UnityAd
  // SDK's show method with appropriate parameters.
  UIViewController *presentViewController = [[UIViewController alloc] init];
  OCMExpect(OCMClassMethod([self.unityAdsClassMock show:presentViewController
                                            placementId:AUTUnityPlacementID
                                                options:OCMOCK_ANY
                                           showDelegate:adapterDelegate]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained UADSShowOptions *showOptions = nil;
        [invocation getArgument:&showOptions atIndex:4];
        XCTAssertEqualObjects(loadOptions.objectId, showOptions.objectId);
        XCTAssertEqualObjects(showOptions.dictionary[@"watermark"], AUTUnityWatermarkBase64);
      });

  id<GADMediationInterstitialAd> mediationInterstitialAd = delegate.interstitialAd;

  // Simulate ad presentating.
  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 0);
  [mediationInterstitialAd presentFromViewController:presentViewController];
  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 1);
  OCMVerifyAll(self.unityAdsClassMock);

  // Simulate presented.
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 0);
  [adapterDelegate unityAdsShowStart:AUTUnityPlacementID];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);

  // Simulate dismissing the presented ad.
  XCTAssertEqual(delegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 0);
  [adapterDelegate unityAdsShowComplete:AUTUnityPlacementID
                        withFinishState:kUnityShowCompletionStateCompleted];
  XCTAssertEqual(delegate.willDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testInterstitialAdPresentFailureLifecycle {
  // First load an intesrstitial ad.
  __block __unsafe_unretained UADSLoadOptions *loadOptions = nil;
  __block __unsafe_unretained id<UnityAdsLoadDelegate, UnityAdsShowDelegate> adapterDelegate = nil;
  OCMStub(OCMClassMethod([self.unityAdsClassMock load:AUTUnityPlacementID
                                              options:OCMOCK_ANY
                                         loadDelegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&loadOptions atIndex:3];
        [invocation getArgument:&adapterDelegate atIndex:4];
        [adapterDelegate unityAdsAdLoaded:AUTUnityPlacementID];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  AUTKMediationInterstitialAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadInterstitialAd(self.adapter, configuration);

  // Simulate ad present failure.
  NSString *presentationErrorMessage = @"abcdefg";
  [adapterDelegate unityAdsShowFailed:AUTUnityPlacementID
                            withError:kUnityShowErrorInternalError
                          withMessage:presentationErrorMessage];
  NSError *presentationError = delegate.didFailToPresentError;
  XCTAssertEqual(presentationError.domain, GADMAdapterUnitySDKErrorDomain);
  XCTAssertEqual(presentationError.code, kUnityShowErrorInternalError);
  XCTAssertEqualObjects(presentationError.userInfo[NSLocalizedDescriptionKey],
                        presentationErrorMessage);
}

- (void)testAdClick {
  // First load an interstitial ad.
  __block __unsafe_unretained UADSLoadOptions *loadOptions = nil;
  __block __unsafe_unretained id<UnityAdsLoadDelegate, UnityAdsShowDelegate> adapterDelegate = nil;
  OCMStub(OCMClassMethod([self.unityAdsClassMock load:AUTUnityPlacementID
                                              options:OCMOCK_ANY
                                         loadDelegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&loadOptions atIndex:3];
        [invocation getArgument:&adapterDelegate atIndex:4];
        [adapterDelegate unityAdsAdLoaded:AUTUnityPlacementID];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  configuration.credentials = credentials;
  AUTKMediationInterstitialAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadInterstitialAd(self.adapter, configuration);

  // Simulate ad clicking.
  XCTAssertEqual(delegate.reportClickInvokeCount, 0);
  [adapterDelegate unityAdsShowClick:AUTUnityPlacementID];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);
}

@end
