#import "GADMediationAdapterUnity.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationRewardedAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <UnityAds/UnityAds.h>

#import "AUTUnityTestCase.h"
#import "GADMAdapterUnityConstants.h"

@interface AUTUnityRewardedAdTests : AUTUnityTestCase
@end

@implementation AUTUnityRewardedAdTests

- (void)testLoadWaterfallRewardedAd {
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
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;

  AUTKWaitAndAssertLoadRewardedAd(self.adapter, configuration);
}

- (void)testLoadBiddingRewardedAd {
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
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.bidResponse = AUTUnityBidResponse;
  configuration.credentials = credentials;

  AUTKWaitAndAssertLoadRewardedAd(self.adapter, configuration);
}

- (void)testLoadBiddingRewardedAdWithEmptySignal {
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
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.bidResponse = @"";
  configuration.credentials = credentials;

  AUTKWaitAndAssertLoadRewardedAd(self.adapter, configuration);
}

- (void)testLoadRewardedAdFailure {
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
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSString *errorDescription =
      [NSString stringWithFormat:@"No ad available for the placement ID: %@", AUTUnityPlacementID];
  NSDictionary *userInfo = @{
    NSLocalizedDescriptionKey : errorDescription,
    NSLocalizedFailureReasonErrorKey : errorDescription
  };
  NSError *error = [NSError errorWithDomain:GADMAdapterUnityErrorDomain
                                       code:GADMAdapterUnityErrorPlacementStateNoFill
                                   userInfo:nil];

  AUTKWaitAndAssertLoadRewardedAdFailure(self.adapter, configuration, error);
}

- (void)testRewardedAdPresentLifecycle {
  // First load a rewarded ad.
  __block __unsafe_unretained UADSLoadOptions *loadOptions = nil;
  __block __unsafe_unretained id<UnityAdsLoadDelegate, UnityAdsShowDelegate> unityDelegate = nil;
  OCMStub(OCMClassMethod([self.unityAdsClassMock load:AUTUnityPlacementID
                                              options:OCMOCK_ANY
                                         loadDelegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&loadOptions atIndex:3];
        [invocation getArgument:&unityDelegate atIndex:4];
        [unityDelegate unityAdsAdLoaded:AUTUnityPlacementID];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.watermark = [[NSData alloc] initWithBase64EncodedString:AUTUnityWatermarkBase64
                                                                options:0];

  AUTKMediationRewardedAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadRewardedAd(self.adapter, configuration);

  // After loading an Rewarded ad, verify that present ad invokes UnityAd
  // SDK's show method with appropriate parameters.
  UIViewController *presentViewController = [[UIViewController alloc] init];
  OCMExpect(OCMClassMethod([self.unityAdsClassMock show:presentViewController
                                            placementId:AUTUnityPlacementID
                                                options:OCMOCK_ANY
                                           showDelegate:unityDelegate]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained UADSShowOptions *showOptions = nil;
        [invocation getArgument:&showOptions atIndex:4];
        XCTAssertEqualObjects(loadOptions.objectId, showOptions.objectId);
        XCTAssertEqualObjects(showOptions.dictionary[@"watermark"], AUTUnityWatermarkBase64);
      });

  id<GADMediationRewardedAd> mediationRewardedAd = delegate.rewardedAd;

  // Simulate ad presentating.
  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 0);
  [mediationRewardedAd presentFromViewController:presentViewController];
  XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 1);
  OCMVerifyAll(self.unityAdsClassMock);

  // Simulate presented.
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 0);
  [unityDelegate unityAdsShowStart:AUTUnityPlacementID];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);

  // Simulate dismissing the presented ad.
  XCTAssertEqual(delegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(delegate.didRewardUserInvokeCount, 0);
  [unityDelegate unityAdsShowComplete:AUTUnityPlacementID
                      withFinishState:kUnityShowCompletionStateCompleted];
  XCTAssertEqual(delegate.willDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 1);

  // Reward must be granted when video is dimissed with completed state.
  XCTAssertEqual(delegate.didRewardUserInvokeCount, 1);
}

- (void)testRewardedAdPresentFailureLifecycle {
  // First load a rewarded ad.
  __block __unsafe_unretained UADSLoadOptions *loadOptions = nil;
  __block __unsafe_unretained id<UnityAdsLoadDelegate, UnityAdsShowDelegate> unityDelegate = nil;
  OCMStub(OCMClassMethod([self.unityAdsClassMock load:AUTUnityPlacementID
                                              options:OCMOCK_ANY
                                         loadDelegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&loadOptions atIndex:3];
        [invocation getArgument:&unityDelegate atIndex:4];
        [unityDelegate unityAdsAdLoaded:AUTUnityPlacementID];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;

  AUTKMediationRewardedAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadRewardedAd(self.adapter, configuration);

  // Simulate ad present failure.
  NSString *presentationErrorMessage = @"abcdefg";
  [unityDelegate unityAdsShowFailed:AUTUnityPlacementID
                          withError:kUnityShowErrorInternalError
                        withMessage:presentationErrorMessage];
  NSError *presentationError = delegate.didFailToPresentError;
  XCTAssertEqual(presentationError.domain, GADMAdapterUnitySDKErrorDomain);
  XCTAssertEqual(presentationError.code, kUnityShowErrorInternalError);
  XCTAssertEqualObjects(presentationError.userInfo[NSLocalizedDescriptionKey],
                        presentationErrorMessage);
}

- (void)testAdClick {
  // First load a rewarded ad.
  __block __unsafe_unretained UADSLoadOptions *loadOptions = nil;
  __block __unsafe_unretained id<UnityAdsLoadDelegate, UnityAdsShowDelegate> unityDelegate = nil;
  OCMStub(OCMClassMethod([self.unityAdsClassMock load:AUTUnityPlacementID
                                              options:OCMOCK_ANY
                                         loadDelegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&loadOptions atIndex:3];
        [invocation getArgument:&unityDelegate atIndex:4];
        [unityDelegate unityAdsAdLoaded:AUTUnityPlacementID];
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterUnityGameID : AUTUnityGameID, GADMAdapterUnityPlacementID : AUTUnityPlacementID};
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  configuration.credentials = credentials;

  AUTKMediationRewardedAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadRewardedAd(self.adapter, configuration);

  // Simulate ad clicking.
  XCTAssertEqual(delegate.reportClickInvokeCount, 0);
  [unityDelegate unityAdsShowClick:AUTUnityPlacementID];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);
}

@end
