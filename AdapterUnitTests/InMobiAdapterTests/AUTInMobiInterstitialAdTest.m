#import "GADMAdapterInMobiInterstitialAd.h"

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

@interface AUTInMobiInterstitialAdTest : XCTestCase
@end

/**
 * Returns a correctly configured interstitial ad configuration.
 */
GADMediationInterstitialAdConfiguration
    *_Nonnull AUTGADMediationInterstitialAdConfigurationForInMobi() {
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatBanner
                                            credentials:@{
                                              GADMAdapterInMobiAccountID : AUTInMobiAccountID,
                                              GADMAdapterInMobiPlacementID : AUTInMobiPlacementID
                                            }];
  GADInMobiExtras *extras = [[GADInMobiExtras alloc] init];
  [extras setKeywords:AUTInMobiKeywords];
  GADMediationInterstitialAdConfiguration *adConfiguration =
      [[GADMediationInterstitialAdConfiguration alloc] initWithAdConfiguration:nil
                                                                     targeting:nil
                                                                   credentials:credentials
                                                                        extras:extras];
  return adConfiguration;
}

@implementation AUTInMobiInterstitialAdTest {
  GADMAdapterInMobiInterstitialAd *_interstitialAd;
  IMInterstitial *_interstialMock;
}

- (void)setUp {
  [super setUp];
  _interstitialAd = [[GADMAdapterInMobiInterstitialAd alloc] init];
  AUTMockGADMAdapterInMobiInitializer();
  AUTMockIMSDKInit();
}

- (void)testLoadInterstitialAdForAdConfiguration {
  GADMediationInterstitialAdConfiguration *configuration =
      AUTGADMediationInterstitialAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  [self mockSuccessfulAdLoading];

  __block BOOL completionHandlerInvoked = NO;
  GADMediationInterstitialLoadCompletionHandler completionHandler =
      ^(id<GADMediationInterstitialAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertEqualObjects(ad, _interstitialAd);
        XCTAssertNil(error);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationInterstitialAdEventDelegate));
      };
  [_interstitialAd loadInterstitialAdForAdConfiguration:configuration
                                      completionHandler:completionHandler];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testLoadRTBInterstitialAdForAdConfiguration {
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatInterstitial
                                            credentials:@{
                                              GADMAdapterInMobiAccountID : AUTInMobiAccountID,
                                              GADMAdapterInMobiPlacementID : AUTInMobiPlacementID
                                            }];
  GADInMobiExtras *extras = [[GADInMobiExtras alloc] init];
  [extras setKeywords:AUTInMobiKeywords];
  NSString *bidResponse = @"bidResponse";
  NSString *watermarkString =
      @"iVBORw0KGgoAAAANSUhEUgAAACsAAAAWBAMAAACrl3iAAAAABlBMVEUAAAD+"
      @"AciWmZzWAAAAAnRSTlMAApidrBQAAAB/SURBVBjTbZDREcAwCEJ1A/"
      @"aftlVQvF79SPQk+kLEfySDiatAd98TgKtWRPruszolA5Ottp+96ah39qlm984XyQQoN3ekmUNLej1IgSm5PDQuDdK/"
      @"I4M+SW5z2JhLAr3DdVAivjj/wrpYiR2kkmjHQXFo9vVZ2u9sYJYsiWiZPYZ9BdmQ8Y2lAAAAAElFTkSuQmCC";
  GADMediationInterstitialAdConfiguration *adConfiguration =
      [[GADMediationInterstitialAdConfiguration alloc]
          initWithAdConfiguration:@{@"bid_response" : bidResponse, @"watermark" : watermarkString}
                        targeting:nil
                      credentials:credentials
                           extras:extras];
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      extras, GADMAdapterInMobiRequestParametersMediationTypeRTB,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];
  OCMStub([_interstialMock load:bidResponseData]).andDo(^(NSInvocation *invocation) {
    XCTAssertTrue([_interstitialAd conformsToProtocol:@protocol(IMInterstitialDelegate)]);
    id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_interstitialAd;
    [delegate interstitialDidFinishLoading:_interstialMock];
  });
  __block BOOL completionHandlerInvoked = NO;
  GADMediationInterstitialLoadCompletionHandler completionHandler =
      ^(id<GADMediationInterstitialAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertEqualObjects(ad, _interstitialAd);
        XCTAssertNil(error);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationInterstitialAdEventDelegate));
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
  OCMExpect([_interstialMock setWatermarkWith:watermarkMock]);

  [_interstitialAd loadInterstitialAdForAdConfiguration:adConfiguration
                                      completionHandler:completionHandler];

  XCTAssertTrue(completionHandlerInvoked);
  OCMVerifyAll(_interstialMock);
  OCMVerifyAll(watermarkClassMock);
}

- (void)testLoadRTBInterstitialAdWithoutPlacementID {
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatInterstitial
                                            credentials:@{
                                              GADMAdapterInMobiAccountID : AUTInMobiAccountID,
                                            }];
  GADInMobiExtras *extras = [[GADInMobiExtras alloc] init];
  [extras setKeywords:AUTInMobiKeywords];
  NSString *bidResponse = @"bidResponse";
  NSString *watermarkString =
      @"iVBORw0KGgoAAAANSUhEUgAAACsAAAAWBAMAAACrl3iAAAAABlBMVEUAAAD+"
      @"AciWmZzWAAAAAnRSTlMAApidrBQAAAB/SURBVBjTbZDREcAwCEJ1A/"
      @"aftlVQvF79SPQk+kLEfySDiatAd98TgKtWRPruszolA5Ottp+96ah39qlm984XyQQoN3ekmUNLej1IgSm5PDQuDdK/"
      @"I4M+SW5z2JhLAr3DdVAivjj/wrpYiR2kkmjHQXFo9vVZ2u9sYJYsiWiZPYZ9BdmQ8Y2lAAAAAElFTkSuQmCC";
  GADMediationInterstitialAdConfiguration *adConfiguration =
      [[GADMediationInterstitialAdConfiguration alloc]
          initWithAdConfiguration:@{@"bid_response" : bidResponse, @"watermark" : watermarkString}
                        targeting:nil
                      credentials:credentials
                           extras:extras];
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      extras, GADMAdapterInMobiRequestParametersMediationTypeRTB,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];
  OCMStub([_interstialMock load:bidResponseData]).andDo(^(NSInvocation *invocation) {
    XCTAssertTrue([_interstitialAd conformsToProtocol:@protocol(IMInterstitialDelegate)]);
    id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_interstitialAd;
    [delegate interstitialDidFinishLoading:_interstialMock];
  });
  __block BOOL completionHandlerInvoked = NO;
  GADMediationInterstitialLoadCompletionHandler completionHandler =
      ^(id<GADMediationInterstitialAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertEqualObjects(ad, _interstitialAd);
        XCTAssertNil(error);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationInterstitialAdEventDelegate));
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
  OCMExpect([_interstialMock setWatermarkWith:watermarkMock]);

  [_interstitialAd loadInterstitialAdForAdConfiguration:adConfiguration
                                      completionHandler:completionHandler];

  XCTAssertTrue(completionHandlerInvoked);
  OCMVerifyAll(_interstialMock);
  OCMVerifyAll(watermarkClassMock);
}

- (void)testLoadInterstitialAdForAdConfigurationFailureWithZeroLengthPlacementID {
  __block BOOL completionHandlerInvoked = NO;
  GADMediationInterstitialLoadCompletionHandler completionHandler =
      ^(id<GADMediationInterstitialAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNil(ad);
        XCTAssertEqual(error.code, GADMAdapterInMobiErrorInvalidServerParameters);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationInterstitialAdEventDelegate));
      };
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatBanner
                                            credentials:@{
                                              GADMAdapterInMobiPlacementID : @"",
                                              GADMAdapterInMobiAccountID : AUTInMobiAccountID,
                                            }];
  GADMediationInterstitialAdConfiguration *adConfiguration =
      [[GADMediationInterstitialAdConfiguration alloc] initWithAdConfiguration:nil
                                                                     targeting:nil
                                                                   credentials:credentials
                                                                        extras:nil];
  [_interstitialAd loadInterstitialAdForAdConfiguration:adConfiguration
                                      completionHandler:completionHandler];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testLoadInterstitialAdForAdConfigurationFailureWithError {
  GADMediationInterstitialAdConfiguration *configuration =
      AUTGADMediationInterstitialAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  // Mock unsuccessful ad loading.
  IMRequestStatus *expectedError = OCMClassMock([IMRequestStatus class]);
  OCMStub([_interstialMock load]).andDo(^(NSInvocation *invocation) {
    XCTAssertTrue([_interstitialAd conformsToProtocol:@protocol(IMInterstitialDelegate)]);
    id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_interstitialAd;
    [delegate interstitial:_interstialMock didFailToLoadWithError:expectedError];
  });

  __block BOOL completionHandlerInvoked = NO;
  GADMediationInterstitialLoadCompletionHandler completionHandler =
      ^(id<GADMediationInterstitialAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNil(ad);
        XCTAssertEqualObjects(error, expectedError);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationInterstitialAdEventDelegate));
      };
  [_interstitialAd loadInterstitialAdForAdConfiguration:configuration
                                      completionHandler:completionHandler];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testInitializerFailure {
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
  GADMediationInterstitialLoadCompletionHandler completionHandler =
      ^(id<GADMediationInterstitialAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNil(ad);
        XCTAssertEqualObjects(error, expectedError);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationInterstitialAdEventDelegate));
      };
  [_interstitialAd
      loadInterstitialAdForAdConfiguration:AUTGADMediationInterstitialAdConfigurationForInMobi()
                         completionHandler:completionHandler];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testPresentInterstitialAd {
  GADMediationInterstitialAdConfiguration *configuration =
      AUTGADMediationInterstitialAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  [self mockSuccessfulAdLoading];
  id<GADMediationInterstitialAdEventDelegate> interstitalAdEventDelegate =
      [self loadInterstitialAd];

  // Mock present from view controller.
  OCMStub([_interstialMock isReady]).andReturn(YES);
  OCMStub([_interstialMock showFrom:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Mock IMInterstitialDelegate present flow.
    XCTAssertTrue([_interstitialAd conformsToProtocol:@protocol(IMInterstitialDelegate)]);
    id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_interstitialAd;
    [delegate interstitialWillPresent:OCMClassMock([IMInterstitial class])];
    [delegate interstitialDidPresent:OCMClassMock([IMInterstitial class])];
  });
  OCMExpect([interstitalAdEventDelegate willPresentFullScreenView]);

  XCTAssertTrue([_interstitialAd conformsToProtocol:@protocol(GADMediationInterstitialAd)]);
  id<GADMediationInterstitialAd> mediationInterstitialAd =
      (id<GADMediationInterstitialAd>)_interstitialAd;
  [mediationInterstitialAd presentFromViewController:OCMClassMock([UIViewController class])];

  OCMVerifyAll(interstitalAdEventDelegate);
}

- (void)testPresentInterstitialAdFailure {
  GADMediationInterstitialAdConfiguration *configuration =
      AUTGADMediationInterstitialAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  [self mockSuccessfulAdLoading];
  id<GADMediationInterstitialAdEventDelegate> interstitalAdEventDelegate =
      [self loadInterstitialAd];

  // Mock present from view controller failure.
  IMRequestStatus *expectedError = OCMClassMock([IMRequestStatus class]);
  OCMStub([_interstialMock isReady]).andReturn(YES);
  OCMStub([_interstialMock showFrom:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Mock IMInterstitialDelegate present flow.
    XCTAssertTrue([_interstitialAd conformsToProtocol:@protocol(IMInterstitialDelegate)]);
    id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_interstitialAd;
    [delegate interstitial:_interstialMock didFailToPresentWithError:expectedError];
  });
  OCMExpect([interstitalAdEventDelegate didFailToPresentWithError:expectedError]);

  XCTAssertTrue([_interstitialAd conformsToProtocol:@protocol(GADMediationInterstitialAd)]);
  id<GADMediationInterstitialAd> mediationInterstitialAd =
      (id<GADMediationInterstitialAd>)_interstitialAd;
  [mediationInterstitialAd presentFromViewController:OCMClassMock([UIViewController class])];

  OCMVerifyAll(interstitalAdEventDelegate);
}

- (void)testPresentInterstitialAdIsNotReady {
  GADMediationInterstitialAdConfiguration *configuration =
      AUTGADMediationInterstitialAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  [self mockSuccessfulAdLoading];
  id<GADMediationInterstitialAdEventDelegate> interstitalAdEventDelegate =
      [self loadInterstitialAd];

  // Mock present from view controller failure.
  OCMStub([_interstialMock isReady]).andReturn(NO);
  OCMReject([_interstialMock showFrom:OCMOCK_ANY]);
  OCMExpect([interstitalAdEventDelegate didFailToPresentWithError:OCMOCK_ANY]);

  XCTAssertTrue([_interstitialAd conformsToProtocol:@protocol(GADMediationInterstitialAd)]);
  id<GADMediationInterstitialAd> mediationInterstitialAd =
      (id<GADMediationInterstitialAd>)_interstitialAd;
  [mediationInterstitialAd presentFromViewController:OCMClassMock([UIViewController class])];

  OCMVerifyAll(interstitalAdEventDelegate);
}

- (void)testDismissInterstitialAd {
  GADMediationInterstitialAdConfiguration *configuration =
      AUTGADMediationInterstitialAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  [self mockSuccessfulAdLoading];
  id<GADMediationInterstitialAdEventDelegate> interstitalAdEventDelegate =
      [self loadInterstitialAd];

  OCMExpect([interstitalAdEventDelegate willDismissFullScreenView]);
  OCMExpect([interstitalAdEventDelegate didDismissFullScreenView]);

  id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_interstitialAd;
  [delegate interstitialWillDismiss:OCMClassMock([IMInterstitial class])];
  [delegate interstitialDidDismiss:OCMClassMock([IMInterstitial class])];

  OCMVerifyAll(interstitalAdEventDelegate);
}

- (void)testClick {
  GADMediationInterstitialAdConfiguration *configuration =
      AUTGADMediationInterstitialAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  [self mockSuccessfulAdLoading];
  id<GADMediationInterstitialAdEventDelegate> interstitalAdEventDelegate =
      [self loadInterstitialAd];

  // Mock interstital click.
  OCMExpect([interstitalAdEventDelegate reportClick]);

  id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_interstitialAd;
  [delegate interstitial:OCMClassMock([IMInterstitial class]) didInteractWithParams:nil];

  OCMVerifyAll(interstitalAdEventDelegate);
}

- (void)testImpression {
  GADMediationInterstitialAdConfiguration *configuration =
      AUTGADMediationInterstitialAdConfigurationForInMobi();
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      configuration.extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment);
  [self mockIMInterstitialWithRequestParameters:requestParameters];
  [self mockSuccessfulAdLoading];
  id<GADMediationInterstitialAdEventDelegate> interstitalAdEventDelegate =
      [self loadInterstitialAd];

  OCMExpect([interstitalAdEventDelegate reportImpression]);

  id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_interstitialAd;
  [delegate interstitialAdImpressed:OCMClassMock([IMInterstitial class])];

  OCMVerifyAll(interstitalAdEventDelegate);
}

/**
 * Mocks mockIMInterstitial.
 */
- (void)mockIMInterstitialWithRequestParameters:
    (nullable NSDictionary<NSString *, id> *)requestParameters {
  // Mock IMInterstitial instance.
  _interstialMock = (IMInterstitial *)[OCMockObject mockForClass:[IMInterstitial class]];
  OCMStub([_interstialMock setKeywords:OCMOCK_ANY]);
  OCMExpect([_interstialMock setExtras:requestParameters]);

  // Mock IMInterstitial init method and return the mock itnerstitial object.
  id mockInterstitialClass = OCMClassMock([IMInterstitial class]);
  OCMStub([mockInterstitialClass alloc]).andReturn(mockInterstitialClass);
  OCMStub([[mockInterstitialClass ignoringNonObjectArgs]
              initWithPlacementId:[AUTInMobiPlacementID longLongValue]
                         delegate:OCMOCK_ANY])
      .andReturn(_interstialMock);
}

/**
 * Mocks successful ad loading.
 */
- (void)mockSuccessfulAdLoading {
  OCMExpect([_interstialMock load]).andDo(^(NSInvocation *invocation) {
    XCTAssertTrue([_interstitialAd conformsToProtocol:@protocol(IMInterstitialDelegate)]);
    id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)_interstitialAd;
    [delegate interstitialDidFinishLoading:_interstialMock];
  });
}

/**
 * Loads an interstital ad and returns its event delegate.
 *
 * Use this method to avoid ad loading boilerplate. Do not use this method in unit tests that test
 * the resulting ad or error.
 */
- (id<GADMediationInterstitialAdEventDelegate>)loadInterstitialAd {
  id<GADMediationInterstitialAdEventDelegate> interstitalAdEventDelegate =
      OCMProtocolMock(@protocol(GADMediationInterstitialAdEventDelegate));
  GADMediationInterstitialLoadCompletionHandler completionHandler =
      ^(id<GADMediationInterstitialAd> _Nullable ad, NSError *_Nullable error) {
        return interstitalAdEventDelegate;
      };
  [_interstitialAd
      loadInterstitialAdForAdConfiguration:AUTGADMediationInterstitialAdConfigurationForInMobi()
                         completionHandler:completionHandler];
  return interstitalAdEventDelegate;
}

@end
