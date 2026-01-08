#import "GADMAdapterInMobiRewardedAd.h"

#import <XCTest/XCTest.h>

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <InMobiSDK/InMobiSDK-Swift.h>

#import <OCMock/OCMock.h>

#import "AUTInMobiUtils.h"
#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiInitializer.h"
#import "GADMAdapterInMobiUtils.h"
#import "GADMediation+AdapterUnitTests.h"
#import "GADMediationAdapterInMobi.h"

@interface AUTInMobiRewardedAdTest : XCTestCase
@end

/**
 * Returns a correctly configured rewarded ad configuration.
 */
GADMediationRewardedAdConfiguration *_Nonnull AUTGADMediationRewardedAdConfigurationForInMobi() {
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatBanner
                                            credentials:@{
                                              GADMAdapterInMobiAccountID : AUTInMobiAccountID,
                                              GADMAdapterInMobiPlacementID : AUTInMobiPlacementID
                                            }];
  GADInMobiExtras *extras = [[GADInMobiExtras alloc] init];
  [extras setKeywords:AUTInMobiKeywords];
  GADMediationRewardedAdConfiguration *adConfiguration =
      [[GADMediationRewardedAdConfiguration alloc] initWithAdConfiguration:nil
                                                                 targeting:nil
                                                               credentials:credentials
                                                                    extras:extras];
  return adConfiguration;
}

@implementation AUTInMobiRewardedAdTest {
  /// The rewarded ad instance being tested.
  GADMAdapterInMobiRewardedAd *_rewardedAd;

  /// InMobi rewarded ad. IM SDK uses the interstitial type for the rewarded type.
  IMInterstitial *_rewardedMock;
}

- (void)setUp {
  [super setUp];
  AUTMockIMSDKInit();
  AUTMockGADMAdapterInMobiInitializer();
}

- (void)testLoadRewardedAdForAdConfiguration {
  GADMediationRewardedAdConfiguration *configuration =
      AUTGADMediationRewardedAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment, nil);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  [self mockSuccessfulAdLoading];

  __block BOOL completionHandlerInvoked = NO;
  GADMediationRewardedLoadCompletionHandler completionHandler =
      ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertEqualObjects(ad, _rewardedAd);
        XCTAssertNil(error);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationRewardedAd));
      };
  [_rewardedAd loadRewardedAdForAdConfiguration:configuration completionHandler:completionHandler];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testLoadRTBRewardedAdForAdConfiguration {
  GADInMobiExtras *extras = [[GADInMobiExtras alloc] init];
  [extras setKeywords:AUTInMobiKeywords];
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      extras, GADMAdapterInMobiRequestParametersMediationTypeRTB,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment, nil);
  [self mockIMInterstitialWithRequestParameters:requestParameters];

  NSNumber *placementIdentifier = [[NSNumber alloc] initWithInt:AUTInMobiPlacementID.intValue];
  _rewardedAd =
      [[GADMAdapterInMobiRewardedAd alloc] initWithPlacementIdentifier:placementIdentifier];

  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatBanner
                                            credentials:@{
                                              GADMAdapterInMobiAccountID : AUTInMobiAccountID,
                                              GADMAdapterInMobiPlacementID : AUTInMobiPlacementID
                                            }];

  NSString *bidResponse = @"bidResponse";
  NSString *watermarkString =
      @"iVBORw0KGgoAAAANSUhEUgAAACsAAAAWBAMAAACrl3iAAAAABlBMVEUAAAD+"
      @"AciWmZzWAAAAAnRSTlMAApidrBQAAAB/SURBVBjTbZDREcAwCEJ1A/"
      @"aftlVQvF79SPQk+kLEfySDiatAd98TgKtWRPruszolA5Ottp+96ah39qlm984XyQQoN3ekmUNLej1IgSm5PDQuDdK/"
      @"I4M+SW5z2JhLAr3DdVAivjj/wrpYiR2kkmjHQXFo9vVZ2u9sYJYsiWiZPYZ9BdmQ8Y2lAAAAAElFTkSuQmCC";
  GADMediationRewardedAdConfiguration *adConfiguration =
      [[GADMediationRewardedAdConfiguration alloc]
          initWithAdConfiguration:@{@"bid_response" : bidResponse, @"watermark" : watermarkString}
                        targeting:nil
                      credentials:credentials
                           extras:extras];

  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];
  OCMStub([_rewardedMock load:bidResponseData]).andDo(^(NSInvocation *invocation) {
    XCTAssertTrue([_rewardedAd conformsToProtocol:@protocol(IMInterstitialDelegate)]);
    id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_rewardedAd;
    [delegate interstitialDidFinishLoading:_rewardedMock];
  });
  __block BOOL completionHandlerInvoked = NO;
  GADMediationRewardedLoadCompletionHandler completionHandler =
      ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertEqualObjects(ad, _rewardedAd);
        XCTAssertNil(error);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationRewardedAd));
      };
  IMWatermark *watermarkMock = (IMWatermark *)[OCMockObject mockForClass:[IMWatermark class]];
  id watermarkClassMock = OCMClassMock([IMWatermark class]);
  OCMStub([watermarkClassMock alloc]).andReturn(watermarkClassMock);
  OCMExpect([watermarkClassMock initWithWaterMarkImageData:[OCMArg checkWithBlock:^BOOL(id obj) {
                                  NSData *imageData = (NSData *)obj;
                                  NSString *imageString =
                                      [imageData base64EncodedStringWithOptions:0];
                                  return [imageString isEqual:watermarkString];
                                }]])
      .andReturn(watermarkMock);
  OCMExpect([_rewardedMock setWatermarkWith:watermarkMock]);

  [_rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                              completionHandler:completionHandler];

  XCTAssertTrue(completionHandlerInvoked);
  OCMVerifyAll(_rewardedMock);
  OCMVerifyAll(watermarkClassMock);
}

- (void)testLoadRTBRewardedAdForAdConfigurationWithoutPlacementID {
  GADInMobiExtras *extras = [[GADInMobiExtras alloc] init];
  [extras setKeywords:AUTInMobiKeywords];
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      extras, GADMAdapterInMobiRequestParametersMediationTypeRTB,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment, nil);
  [self mockIMInterstitialWithRequestParameters:requestParameters];

  NSNumber *placementIdentifier = [[NSNumber alloc] initWithInt:AUTInMobiPlacementID.intValue];
  _rewardedAd =
      [[GADMAdapterInMobiRewardedAd alloc] initWithPlacementIdentifier:placementIdentifier];

  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatBanner
                                            credentials:@{
                                              GADMAdapterInMobiAccountID : AUTInMobiAccountID,
                                            }];

  NSString *bidResponse = @"bidResponse";
  NSString *watermarkString =
      @"iVBORw0KGgoAAAANSUhEUgAAACsAAAAWBAMAAACrl3iAAAAABlBMVEUAAAD+"
      @"AciWmZzWAAAAAnRSTlMAApidrBQAAAB/SURBVBjTbZDREcAwCEJ1A/"
      @"aftlVQvF79SPQk+kLEfySDiatAd98TgKtWRPruszolA5Ottp+96ah39qlm984XyQQoN3ekmUNLej1IgSm5PDQuDdK/"
      @"I4M+SW5z2JhLAr3DdVAivjj/wrpYiR2kkmjHQXFo9vVZ2u9sYJYsiWiZPYZ9BdmQ8Y2lAAAAAElFTkSuQmCC";
  GADMediationRewardedAdConfiguration *adConfiguration =
      [[GADMediationRewardedAdConfiguration alloc]
          initWithAdConfiguration:@{@"bid_response" : bidResponse, @"watermark" : watermarkString}
                        targeting:nil
                      credentials:credentials
                           extras:extras];

  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];
  OCMStub([_rewardedMock load:bidResponseData]).andDo(^(NSInvocation *invocation) {
    XCTAssertTrue([_rewardedAd conformsToProtocol:@protocol(IMInterstitialDelegate)]);
    id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_rewardedAd;
    [delegate interstitialDidFinishLoading:_rewardedMock];
  });
  __block BOOL completionHandlerInvoked = NO;
  GADMediationRewardedLoadCompletionHandler completionHandler =
      ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertEqualObjects(ad, _rewardedAd);
        XCTAssertNil(error);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationRewardedAd));
      };
  IMWatermark *watermarkMock = (IMWatermark *)[OCMockObject mockForClass:[IMWatermark class]];
  id watermarkClassMock = OCMClassMock([IMWatermark class]);
  OCMStub([watermarkClassMock alloc]).andReturn(watermarkClassMock);
  OCMExpect([watermarkClassMock initWithWaterMarkImageData:[OCMArg checkWithBlock:^BOOL(id obj) {
                                  NSData *imageData = (NSData *)obj;
                                  NSString *imageString =
                                      [imageData base64EncodedStringWithOptions:0];
                                  return [imageString isEqual:watermarkString];
                                }]])
      .andReturn(watermarkMock);
  OCMExpect([_rewardedMock setWatermarkWith:watermarkMock]);

  [_rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                              completionHandler:completionHandler];

  XCTAssertTrue(completionHandlerInvoked);
  OCMVerifyAll(_rewardedMock);
  OCMVerifyAll(watermarkClassMock);
}

- (void)testLoadRewardedAdForAdConfigurationFailureWithMultipleLoads {
  GADMediationRewardedAdConfiguration *configuration =
      AUTGADMediationRewardedAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment, nil);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  [self mockSuccessfulAdLoading];

  __block BOOL completionHandlerInvoked = NO;
  GADMediationRewardedLoadCompletionHandler completionHandler =
      ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertEqualObjects(ad, _rewardedAd);
        XCTAssertNil(error);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationRewardedAd));
      };
  [_rewardedAd loadRewardedAdForAdConfiguration:AUTGADMediationRewardedAdConfigurationForInMobi()
                              completionHandler:completionHandler];

  XCTAssertTrue(completionHandlerInvoked);

  completionHandlerInvoked = NO;
  XCTAssertFalse(completionHandlerInvoked);
  completionHandler = ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
    XCTAssertNil(ad);
    XCTAssertEqual(error.code, GADMAdapterInMobiErrorAdAlreadyLoaded);
    completionHandlerInvoked = YES;
    return OCMProtocolMock(@protocol(GADMediationRewardedAd));
  };
  [_rewardedAd loadRewardedAdForAdConfiguration:AUTGADMediationRewardedAdConfigurationForInMobi()
                              completionHandler:completionHandler];
  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testLoadRewardedAdForAdConfigurationFailureWithZeroLengthPlacementID {
  id mockInterstitialClass = OCMClassMock([IMInterstitial class]);
  OCMStub([mockInterstitialClass alloc]).andReturn(mockInterstitialClass);
  OCMStub([[mockInterstitialClass ignoringNonObjectArgs]
              initWithPlacementId:[AUTInMobiPlacementID longLongValue]
                         delegate:OCMOCK_ANY])
      .andReturn(_rewardedMock);

  NSNumber *placementIdentifier = [[NSNumber alloc] initWithInt:AUTInMobiPlacementID.intValue];
  _rewardedAd =
      [[GADMAdapterInMobiRewardedAd alloc] initWithPlacementIdentifier:placementIdentifier];

  __block BOOL completionHandlerInvoked = NO;
  GADMediationRewardedLoadCompletionHandler completionHandler =
      ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNil(ad);
        XCTAssertEqual(error.code, GADMAdapterInMobiErrorInvalidServerParameters);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationRewardedAd));
      };
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatBanner
                                            credentials:@{
                                              GADMAdapterInMobiPlacementID : @"",
                                              GADMAdapterInMobiAccountID : AUTInMobiAccountID,
                                            }];
  GADMediationRewardedAdConfiguration *adConfiguration =
      [[GADMediationRewardedAdConfiguration alloc] initWithAdConfiguration:nil
                                                                 targeting:nil
                                                               credentials:credentials
                                                                    extras:nil];
  [_rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                              completionHandler:completionHandler];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testLoadRewardedAdForAdConfigurationFailureWithError {
  GADMediationRewardedAdConfiguration *configuration =
      AUTGADMediationRewardedAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment, nil);
  [self mockIMInterstitialWithRequestParameters:requestParameters];

  NSNumber *placementIdentifier = [[NSNumber alloc] initWithInt:AUTInMobiPlacementID.intValue];
  _rewardedAd =
      [[GADMAdapterInMobiRewardedAd alloc] initWithPlacementIdentifier:placementIdentifier];

  // Mock unsuccessful ad loading.
  IMRequestStatus *expectedError = OCMClassMock([IMRequestStatus class]);
  OCMStub([_rewardedMock load]).andDo(^(NSInvocation *invocation) {
    XCTAssertTrue([_rewardedAd conformsToProtocol:@protocol(IMInterstitialDelegate)]);
    id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_rewardedAd;
    [delegate interstitial:_rewardedMock didFailToLoadWithError:expectedError];
  });

  __block BOOL completionHandlerInvoked = NO;
  GADMediationRewardedLoadCompletionHandler completionHandler =
      ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNil(ad);
        XCTAssertEqualObjects(error, expectedError);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationRewardedAd));
      };
  [_rewardedAd loadRewardedAdForAdConfiguration:AUTGADMediationRewardedAdConfigurationForInMobi()
                              completionHandler:completionHandler];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testInitializerFailure {
  NSNumber *placementIdentifier = [[NSNumber alloc] initWithInt:AUTInMobiPlacementID.intValue];
  _rewardedAd =
      [[GADMAdapterInMobiRewardedAd alloc] initWithPlacementIdentifier:placementIdentifier];

  // Mock 3rd party SDK to call completion handler with an error.
  NSError *expectedError = OCMClassMock([NSError class]);
  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMStub(ClassMethod([IMSDKMock initWithAccountID:OCMOCK_ANY
                                 consentDictionary:OCMOCK_ANY
                              andCompletionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionBlock)(NSError *_Nullable);
        [invocation getArgument:&completionBlock atIndex:4];
        completionBlock(expectedError);
      });

  __block BOOL completionHandlerInvoked = NO;
  GADMediationRewardedLoadCompletionHandler completionHandler =
      ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNil(ad);
        XCTAssertEqualObjects(error, expectedError);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationRewardedAd));
      };
  [_rewardedAd loadRewardedAdForAdConfiguration:AUTGADMediationRewardedAdConfigurationForInMobi()
                              completionHandler:completionHandler];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testPresentRewardedAd {
  GADMediationRewardedAdConfiguration *configuration =
      AUTGADMediationRewardedAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment, nil);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  [self mockSuccessfulAdLoading];
  id<GADMediationRewardedAdEventDelegate> rewardedAdEventDelegate = [self loadRewardedAd];

  // Mock present from view controller.
  OCMStub([_rewardedMock isReady]).andReturn(YES);
  OCMStub([_rewardedMock showFrom:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Mock IMInterstitialDelegate present flow.
    XCTAssertTrue([_rewardedAd conformsToProtocol:@protocol(IMInterstitialDelegate)]);
    id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_rewardedAd;
    [delegate interstitialWillPresent:OCMClassMock([IMInterstitial class])];
    [delegate interstitialDidPresent:OCMClassMock([IMInterstitial class])];
  });
  OCMExpect([rewardedAdEventDelegate willPresentFullScreenView]);
  OCMExpect([rewardedAdEventDelegate didStartVideo]);

  XCTAssertTrue([_rewardedAd conformsToProtocol:@protocol(GADMediationRewardedAd)]);
  id<GADMediationRewardedAd> mediationRewardedAd = (id<GADMediationRewardedAd>)_rewardedAd;
  [mediationRewardedAd presentFromViewController:OCMClassMock([UIViewController class])];

  OCMVerifyAll(rewardedAdEventDelegate);
}

- (void)testPresentRewardedAdFailure {
  GADMediationRewardedAdConfiguration *configuration =
      AUTGADMediationRewardedAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment, nil);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  [self mockSuccessfulAdLoading];
  id<GADMediationRewardedAdEventDelegate> rewardedAdEventDelegate = [self loadRewardedAd];

  // Mock present from view controller.
  IMRequestStatus *expectedError = OCMClassMock([IMRequestStatus class]);
  OCMStub([_rewardedMock isReady]).andReturn(YES);
  OCMStub([_rewardedMock showFrom:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Mock IMInterstitialDelegate present flow.
    XCTAssertTrue([_rewardedAd conformsToProtocol:@protocol(IMInterstitialDelegate)]);
    id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_rewardedAd;
    [delegate interstitial:_rewardedMock didFailToPresentWithError:expectedError];
  });
  OCMExpect([rewardedAdEventDelegate didFailToPresentWithError:expectedError]);

  XCTAssertTrue([_rewardedAd conformsToProtocol:@protocol(GADMediationRewardedAd)]);
  id<GADMediationRewardedAd> mediationRewardedAd = (id<GADMediationRewardedAd>)_rewardedAd;
  [mediationRewardedAd presentFromViewController:OCMClassMock([UIViewController class])];

  OCMVerifyAll(rewardedAdEventDelegate);
}

- (void)testPresentRewardedAdIsNotReady {
  GADMediationRewardedAdConfiguration *configuration =
      AUTGADMediationRewardedAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment, nil);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  [self mockSuccessfulAdLoading];
  id<GADMediationRewardedAdEventDelegate> rewardedAdEventDelegate = [self loadRewardedAd];

  // Mock present from view controller failure.
  OCMStub([_rewardedMock isReady]).andReturn(NO);
  OCMReject([_rewardedMock showFrom:OCMOCK_ANY with:IMInterstitialAnimationTypeCoverVertical]);
  OCMExpect([rewardedAdEventDelegate didFailToPresentWithError:OCMOCK_ANY]);

  XCTAssertTrue([_rewardedAd conformsToProtocol:@protocol(GADMediationRewardedAd)]);
  id<GADMediationInterstitialAd> mediationRewardedAd = (id<GADMediationInterstitialAd>)_rewardedAd;
  [mediationRewardedAd presentFromViewController:OCMClassMock([UIViewController class])];

  OCMVerifyAll(rewardedAdEventDelegate);
}

- (void)testDismissRewardedAd {
  GADMediationRewardedAdConfiguration *configuration =
      AUTGADMediationRewardedAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment, nil);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  [self mockSuccessfulAdLoading];
  id<GADMediationRewardedAdEventDelegate> rewardedAdEventDelegate = [self loadRewardedAd];

  OCMExpect([rewardedAdEventDelegate willDismissFullScreenView]);
  OCMExpect([rewardedAdEventDelegate didDismissFullScreenView]);

  id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_rewardedAd;
  [delegate interstitialWillDismiss:OCMClassMock([IMInterstitial class])];
  [delegate interstitialDidDismiss:OCMClassMock([IMInterstitial class])];

  OCMVerifyAll(rewardedAdEventDelegate);
}

- (void)testClick {
  GADMediationRewardedAdConfiguration *configuration =
      AUTGADMediationRewardedAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment, nil);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  [self mockSuccessfulAdLoading];
  id<GADMediationRewardedAdEventDelegate> rewardedAdEventDelegate = [self loadRewardedAd];

  OCMExpect([rewardedAdEventDelegate reportClick]);

  id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_rewardedAd;
  [delegate interstitial:OCMClassMock([IMInterstitial class]) didInteractWithParams:nil];

  OCMVerifyAll(rewardedAdEventDelegate);
}

- (void)testImpression {
  GADMediationRewardedAdConfiguration *configuration =
      AUTGADMediationRewardedAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment, nil);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  [self mockSuccessfulAdLoading];
  id<GADMediationRewardedAdEventDelegate> rewardedAdEventDelegate = [self loadRewardedAd];

  OCMExpect([rewardedAdEventDelegate reportImpression]);

  id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_rewardedAd;
  [delegate interstitialAdImpressed:OCMClassMock([IMInterstitial class])];

  OCMVerifyAll(rewardedAdEventDelegate);
}

- (void)testRewardCompletion {
  GADMediationRewardedAdConfiguration *configuration =
      AUTGADMediationRewardedAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment, nil);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  [self mockSuccessfulAdLoading];
  id<GADMediationRewardedAdEventDelegate> rewardedAdEventDelegate = [self loadRewardedAd];

  OCMExpect([rewardedAdEventDelegate didRewardUser]);
  OCMExpect([rewardedAdEventDelegate didEndVideo]);

  id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_rewardedAd;
  [delegate interstitial:OCMClassMock([IMInterstitial class])
      rewardActionCompletedWithRewards:OCMOCK_ANY];

  OCMVerifyAll(rewardedAdEventDelegate);
}

/**
 * Sets common IMSDK mocks.
 */
- (void)mockIMInterstitialWithRequestParameters:
    (nullable NSDictionary<NSString *, id> *)requestParameters {
  // Mock IMInterstitial instance.
  _rewardedMock = (IMInterstitial *)[OCMockObject mockForClass:[IMInterstitial class]];
  OCMStub([_rewardedMock setKeywords:OCMOCK_ANY]);
  OCMExpect([_rewardedMock setExtras:requestParameters]);

  // Mock IMInterstitial init method and return the mock itnerstitial object.
  id mockInterstitialClass = OCMClassMock([IMInterstitial class]);
  OCMStub([mockInterstitialClass alloc]).andReturn(mockInterstitialClass);
  OCMStub([[mockInterstitialClass ignoringNonObjectArgs]
              initWithPlacementId:[AUTInMobiPlacementID longLongValue]
                         delegate:OCMOCK_ANY])
      .andReturn(_rewardedMock);
}

/**
 * Mocks successful ad loading.
 */
- (void)mockSuccessfulAdLoading {
  NSNumber *placementIdentifier = [[NSNumber alloc] initWithInt:AUTInMobiPlacementID.intValue];
  _rewardedAd =
      [[GADMAdapterInMobiRewardedAd alloc] initWithPlacementIdentifier:placementIdentifier];

  OCMStub([_rewardedMock load]).andDo(^(NSInvocation *invocation) {
    XCTAssertTrue([_rewardedAd conformsToProtocol:@protocol(IMInterstitialDelegate)]);
    id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_rewardedAd;
    [delegate interstitialDidFinishLoading:_rewardedMock];
  });
}

/**
 * Loads a rewarded ad and returns its event delegate.
 *
 * Use this method to avoid ad loading boilerplate. Do not use this method in unit tests that test
 * the resulting ad or error.
 */
- (id<GADMediationRewardedAdEventDelegate>)loadRewardedAd {
  id<GADMediationRewardedAdEventDelegate> rewardedAdEventDelegate =
      OCMProtocolMock(@protocol(GADMediationRewardedAdEventDelegate));
  GADMediationRewardedLoadCompletionHandler completionHandler =
      ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
        return rewardedAdEventDelegate;
      };
  [_rewardedAd loadRewardedAdForAdConfiguration:AUTGADMediationRewardedAdConfigurationForInMobi()
                              completionHandler:completionHandler];
  return rewardedAdEventDelegate;
}

@end
