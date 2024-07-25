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

- (void)testLoadWaterfallInterstitialAd {
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

- (void)testLoadBiddingInterstitialAd {
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

  NSString *errorDescription =
      [NSString stringWithFormat:@"No ad available for the placement ID: %@", AUTUnityPlacementID];
  NSDictionary *userInfo = @{
    NSLocalizedDescriptionKey : errorDescription,
    NSLocalizedFailureReasonErrorKey : errorDescription
  };
  NSError *error = [NSError errorWithDomain:GADMAdapterUnityErrorDomain
                                       code:GADMAdapterUnityErrorPlacementStateNoFill
                                   userInfo:userInfo];
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
