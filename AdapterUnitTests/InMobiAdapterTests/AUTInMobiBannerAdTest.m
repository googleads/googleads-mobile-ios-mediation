#import "GADMAdapterInMobiBannerAd.h"

#import <UIKit/UIKit.h>
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

/// IVars used in the GADMAdapterInMobiBannerAd.
typedef NSString *AUTInMobiBannerAdIVar NS_TYPED_ENUM;
AUTInMobiBannerAdIVar const AUTInMobiBannerAdIVarBannerAdEventDelegate = @"_bannerAdEventDelegate";
AUTInMobiBannerAdIVar const AUTInMobiBannerAdIVarBannerAdConfig = @"_bannerAdConfig";
AUTInMobiBannerAdIVar const AUTInMobiBannerAdIVarBannerAdLoadCompletionHandler =
    @"_bannerAdLoadCompletionHandler";
AUTInMobiBannerAdIVar const AUTInMobiBannerAdIVarAdView = @"_adView";

@interface GADMAdapterInMobiBannerAd (Test)
- (void)requestBannerWithSize:(GADAdSize)requestedAdSize;
- (void)stopBeingDelegate;
- (nonnull UIView *)view;
@end

/**
 * Returns a correctly configured banner ad configuration.
 */
GADMediationBannerAdConfiguration *_Nonnull AUTGADMediationBannerAdConfigurationForInMobi() {
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatBanner
                                            credentials:@{
                                              GADMAdapterInMobiAccountID : AUTInMobiAccountID,
                                              GADMAdapterInMobiPlacementID : AUTInMobiPlacementID
                                            }];
  GADInMobiExtras *extras = [[GADInMobiExtras alloc] init];
  [extras setKeywords:AUTInMobiKeywords];
  GADMediationBannerAdConfiguration *adConfiguration =
      [[GADMediationBannerAdConfiguration alloc] initWithAdSize:GADAdSizeBanner
                                                adConfiguration:nil
                                                      targeting:nil
                                                    credentials:credentials
                                                         extras:extras];

  return adConfiguration;
}

@interface AUTInMobiBannerAdTest : XCTestCase
@end

@implementation AUTInMobiBannerAdTest

- (void)testLoadBannerAdForAdConfiguration {
  GADMAdapterInMobiBannerAd *bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];

  id initializerSharedInstanceMock = OCMPartialMock(GADMAdapterInMobiInitializer.sharedInstance);
  OCMStub([initializerSharedInstanceMock initializeWithAccountID:OCMOCK_ANY
                                               completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained GADMAdapterInMobiInitCompletionHandler initHandler;
        [invocation getArgument:&initHandler atIndex:3];
        initHandler(nil);
      });

  id bannerAdMock = OCMPartialMock(bannerAd);
  OCMStub([bannerAdMock requestBannerWithSize:GADAdSizeBanner]).andDo(^(NSInvocation *invocation) {
    GADMediationBannerLoadCompletionHandler loadCompletionHandler =
        [bannerAd valueForKey:AUTInMobiBannerAdIVarBannerAdLoadCompletionHandler];
    loadCompletionHandler(bannerAd, nil);
  });

  __block BOOL completionHandlerInvoked = NO;
  GADMediationBannerLoadCompletionHandler completionHandler =
      ^(id<GADMediationBannerAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertEqualObjects(bannerAd, ad);
        XCTAssertNil(error);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationBannerAdEventDelegate));
      };
  [bannerAd loadBannerAdForAdConfiguration:AUTGADMediationBannerAdConfigurationForInMobi()
                         completionHandler:completionHandler];
  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testLoadBannerAdForAdConfigurationInitError {
  GADMAdapterInMobiBannerAd *bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];

  id initializerSharedInstanceMock = OCMPartialMock(GADMAdapterInMobiInitializer.sharedInstance);
  OCMStub([initializerSharedInstanceMock initializeWithAccountID:OCMOCK_ANY
                                               completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained GADMAdapterInMobiInitCompletionHandler initHandler;
        [invocation getArgument:&initHandler atIndex:3];
        initHandler(OCMClassMock([NSError class]));
      });

  id bannerAdMock = OCMPartialMock(bannerAd);
  OCMReject([bannerAdMock requestBannerWithSize:GADAdSizeBanner]);

  __block BOOL completionHandlerInvoked = NO;
  GADMediationBannerLoadCompletionHandler completionHandler =
      ^(id<GADMediationBannerAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNil(ad);
        XCTAssertNotNil(error);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationBannerAdEventDelegate));
      };
  [bannerAd loadBannerAdForAdConfiguration:AUTGADMediationBannerAdConfigurationForInMobi()
                         completionHandler:completionHandler];
  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testRequestBannerWithSize {
  GADMAdapterInMobiBannerAd *bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];
  [bannerAd setValue:AUTGADMediationBannerAdConfigurationForInMobi()
              forKey:AUTInMobiBannerAdIVarBannerAdConfig];
  GADInMobiExtras *extras = [[GADInMobiExtras alloc] init];
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      extras, GADMAdapterInMobiRequestParametersMediationTypeWaterfall,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment);
  IMBanner *mockBanner = (IMBanner *)[OCMockObject mockForClass:[IMBanner class]];
  OCMExpect([mockBanner shouldAutoRefresh:NO]);
  OCMExpect([mockBanner setTransitionAnimation:UIViewAnimationTransitionNone]);
  OCMExpect([mockBanner setKeywords:AUTInMobiKeywords]);
  OCMExpect([mockBanner setExtras:requestParameters]);
  OCMExpect([mockBanner load]);

  id mockBannerClass = OCMClassMock([IMBanner class]);
  OCMStub([mockBannerClass alloc]).andReturn(mockBannerClass);
  OCMStub([[mockBannerClass ignoringNonObjectArgs]
              initWithFrame:CGRectZero
                placementId:[AUTInMobiPlacementID longLongValue]
                   delegate:bannerAd])
      .andReturn(mockBanner);

  [bannerAd requestBannerWithSize:GADAdSizeBanner];

  OCMVerifyAll(mockBanner);
}

- (void)testRTBRequestBannerWithSize {
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatBanner
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
  GADMediationBannerAdConfiguration *adConfiguration = [[GADMediationBannerAdConfiguration alloc]
       initWithAdSize:GADAdSizeBanner
      adConfiguration:@{@"bid_response" : bidResponse, @"watermark" : watermarkString}
            targeting:nil
          credentials:credentials
               extras:extras];
  GADMAdapterInMobiBannerAd *bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];
  [bannerAd setValue:adConfiguration forKey:AUTInMobiBannerAdIVarBannerAdConfig];
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      extras, GADMAdapterInMobiRequestParametersMediationTypeRTB,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment);
  IMBanner *mockBanner = (IMBanner *)[OCMockObject mockForClass:[IMBanner class]];
  OCMExpect([mockBanner shouldAutoRefresh:NO]);
  OCMExpect([mockBanner setTransitionAnimation:UIViewAnimationTransitionNone]);
  OCMExpect([mockBanner setKeywords:AUTInMobiKeywords]);
  OCMExpect([mockBanner setExtras:requestParameters]);
  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];
  OCMExpect([mockBanner load:bidResponseData]);
  id mockBannerClass = OCMClassMock([IMBanner class]);
  OCMStub([mockBannerClass alloc]).andReturn(mockBannerClass);
  OCMStub([[mockBannerClass ignoringNonObjectArgs]
              initWithFrame:CGRectZero
                placementId:[AUTInMobiPlacementID longLongValue]
                   delegate:bannerAd])
      .andReturn(mockBanner);
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
  OCMExpect([mockBanner setWatermarkWith:watermarkMock]);

  [bannerAd requestBannerWithSize:GADAdSizeBanner];

  OCMVerifyAll(mockBanner);
  OCMVerifyAll(watermarkClassMock);
}

- (void)testRTBRequestBannerWithoutPlacementID {
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatBanner
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
  GADMediationBannerAdConfiguration *adConfiguration = [[GADMediationBannerAdConfiguration alloc]
       initWithAdSize:GADAdSizeBanner
      adConfiguration:@{@"bid_response" : bidResponse, @"watermark" : watermarkString}
            targeting:nil
          credentials:credentials
               extras:extras];
  GADMAdapterInMobiBannerAd *bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];
  [bannerAd setValue:adConfiguration forKey:AUTInMobiBannerAdIVarBannerAdConfig];
  NSDictionary<NSString *, id> *requestParameters = GADMAdapterInMobiRequestParameters(
      extras, GADMAdapterInMobiRequestParametersMediationTypeRTB,
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment);
  IMBanner *mockBanner = (IMBanner *)[OCMockObject mockForClass:[IMBanner class]];
  OCMExpect([mockBanner shouldAutoRefresh:NO]);
  OCMExpect([mockBanner setTransitionAnimation:UIViewAnimationTransitionNone]);
  OCMExpect([mockBanner setKeywords:AUTInMobiKeywords]);
  OCMExpect([mockBanner setExtras:requestParameters]);
  NSData *bidResponseData = [bidResponse dataUsingEncoding:NSUTF8StringEncoding];
  OCMExpect([mockBanner load:bidResponseData]);
  id mockBannerClass = OCMClassMock([IMBanner class]);
  OCMStub([mockBannerClass alloc]).andReturn(mockBannerClass);
  OCMStub([[mockBannerClass ignoringNonObjectArgs]
              initWithFrame:CGRectZero
                placementId:0
                   delegate:bannerAd])
      .andReturn(mockBanner);
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
  OCMExpect([mockBanner setWatermarkWith:watermarkMock]);

  [bannerAd requestBannerWithSize:GADAdSizeBanner];

  OCMVerifyAll(mockBanner);
  OCMVerifyAll(watermarkClassMock);
}

- (void)testRequestBannerWithSizeFailureWithNoPlacementID {
  GADMAdapterInMobiBannerAd *bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];

  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatBanner credentials:@{}];
  GADMediationBannerAdConfiguration *adConfiguration =
      [[GADMediationBannerAdConfiguration alloc] initWithAdSize:GADAdSizeBanner
                                                adConfiguration:nil
                                                      targeting:nil
                                                    credentials:credentials
                                                         extras:nil];
  [bannerAd setValue:adConfiguration forKey:AUTInMobiBannerAdIVarBannerAdConfig];

  __block BOOL completionHandlerInvoked = NO;
  GADMediationBannerLoadCompletionHandler completionHandler =
      ^(id<GADMediationBannerAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNil(ad);
        XCTAssertNotNil(error);
        XCTAssertTrue(error.code == GADMAdapterInMobiErrorInvalidServerParameters);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationBannerAdEventDelegate));
      };
  [bannerAd setValue:completionHandler forKey:AUTInMobiBannerAdIVarBannerAdLoadCompletionHandler];

  [bannerAd requestBannerWithSize:GADAdSizeBanner];

  XCTAssertTrue(completionHandler);
}

- (void)testRequestBannerWithSizeFailureWithInbalidBannerSize {
  GADMAdapterInMobiBannerAd *bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];
  [bannerAd setValue:AUTGADMediationBannerAdConfigurationForInMobi()
              forKey:AUTInMobiBannerAdIVarBannerAdConfig];

  __block BOOL completionHandlerInvoked = NO;
  GADMediationBannerLoadCompletionHandler completionHandler =
      ^(id<GADMediationBannerAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNil(ad);
        XCTAssertNotNil(error);
        XCTAssertTrue(error.code == GADMAdapterInMobiErrorBannerSizeMismatch);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationBannerAdEventDelegate));
      };
  [bannerAd setValue:completionHandler forKey:AUTInMobiBannerAdIVarBannerAdLoadCompletionHandler];

  [bannerAd requestBannerWithSize:GADAdSizeInvalid];

  XCTAssertTrue(completionHandler);
}

- (void)testStopBeingDelegate {
  IMBanner *banner = [[IMBanner alloc] initWithFrame:CGRectZero placementId:0];
  banner.delegate = OCMProtocolMock(@protocol(IMBannerDelegate));

  GADMAdapterInMobiBannerAd *bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];
  [bannerAd setValue:banner forKey:AUTInMobiBannerAdIVarAdView];

  XCTAssertNotNil(banner.delegate);
  [bannerAd stopBeingDelegate];
  XCTAssertNil(banner.delegate);
}

- (void)testIMBannerDelegateConformance {
  GADMAdapterInMobiBannerAd *bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];
  XCTAssertTrue([bannerAd conformsToProtocol:@protocol(IMBannerDelegate)]);
}

- (void)testBannerDidFinishLoading {
  GADMAdapterInMobiBannerAd *bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];
  id<GADMediationBannerAdEventDelegate> bannerEventDelegate =
      OCMProtocolMock(@protocol(GADMediationBannerAdEventDelegate));
  GADMediationBannerLoadCompletionHandler completionHandler =
      ^(id<GADMediationBannerAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertEqualObjects(bannerAd, ad);
        return bannerEventDelegate;
      };
  [bannerAd setValue:completionHandler forKey:AUTInMobiBannerAdIVarBannerAdLoadCompletionHandler];

  id<IMBannerDelegate> bannerDelegate = (id<IMBannerDelegate>)bannerAd;
  IMBanner *banner = [[IMBanner alloc] initWithFrame:CGRectZero placementId:0];
  XCTAssertNil([bannerAd valueForKey:AUTInMobiBannerAdIVarBannerAdEventDelegate]);
  [bannerDelegate bannerDidFinishLoading:banner];
  XCTAssertEqualObjects([bannerAd valueForKey:AUTInMobiBannerAdIVarBannerAdEventDelegate],
                        bannerEventDelegate);
}

- (void)testBannerDidFailToLoadWithError {
  GADMAdapterInMobiBannerAd *bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];
  IMRequestStatus *expectedError = OCMClassMock([IMRequestStatus class]);
  __block BOOL completionHandlerInvoked = NO;
  GADMediationBannerLoadCompletionHandler completionHandler =
      ^(id<GADMediationBannerAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNil(ad);
        XCTAssertEqualObjects(error, expectedError);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationBannerAdEventDelegate));
      };
  [bannerAd setValue:completionHandler forKey:AUTInMobiBannerAdIVarBannerAdLoadCompletionHandler];

  id<IMBannerDelegate> bannerDelegate = (id<IMBannerDelegate>)bannerAd;
  [bannerDelegate banner:OCMClassMock([IMBanner class]) didFailToLoadWithError:expectedError];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testBannerDidInteractWithParams {
  GADMAdapterInMobiBannerAd *bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];
  id<GADMediationBannerAdEventDelegate> bannerEventDelegate =
      OCMProtocolMock(@protocol(GADMediationBannerAdEventDelegate));
  OCMExpect([bannerEventDelegate reportClick]);
  [bannerAd setValue:bannerEventDelegate forKey:AUTInMobiBannerAdIVarBannerAdEventDelegate];

  id<IMBannerDelegate> bannerDelegate = (id<IMBannerDelegate>)bannerAd;
  IMBanner *banner = [[IMBanner alloc] initWithFrame:CGRectZero placementId:0];
  [bannerDelegate banner:banner didInteractWithParams:nil];

  OCMVerifyAll(bannerEventDelegate);
}

- (void)testBannerWillPresentScreen {
  GADMAdapterInMobiBannerAd *bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];
  id<GADMediationBannerAdEventDelegate> bannerEventDelegate =
      OCMProtocolMock(@protocol(GADMediationBannerAdEventDelegate));
  OCMExpect([bannerEventDelegate willPresentFullScreenView]);
  [bannerAd setValue:bannerEventDelegate forKey:AUTInMobiBannerAdIVarBannerAdEventDelegate];

  id<IMBannerDelegate> bannerDelegate = (id<IMBannerDelegate>)bannerAd;
  IMBanner *banner = [[IMBanner alloc] initWithFrame:CGRectZero placementId:0];
  [bannerDelegate bannerWillPresentScreen:banner];

  OCMVerifyAll(bannerEventDelegate);
}

- (void)testBannerWillDismissScreen {
  GADMAdapterInMobiBannerAd *bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];
  id<GADMediationBannerAdEventDelegate> bannerEventDelegate =
      OCMProtocolMock(@protocol(GADMediationBannerAdEventDelegate));
  OCMExpect([bannerEventDelegate willDismissFullScreenView]);
  [bannerAd setValue:bannerEventDelegate forKey:AUTInMobiBannerAdIVarBannerAdEventDelegate];

  id<IMBannerDelegate> bannerDelegate = (id<IMBannerDelegate>)bannerAd;
  IMBanner *banner = [[IMBanner alloc] initWithFrame:CGRectZero placementId:0];
  [bannerDelegate bannerWillDismissScreen:banner];

  OCMVerifyAll(bannerEventDelegate);
}

- (void)testBannerDidDismissScreen {
  GADMAdapterInMobiBannerAd *bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];
  id<GADMediationBannerAdEventDelegate> bannerEventDelegate =
      OCMProtocolMock(@protocol(GADMediationBannerAdEventDelegate));
  OCMExpect([bannerEventDelegate didDismissFullScreenView]);
  [bannerAd setValue:bannerEventDelegate forKey:AUTInMobiBannerAdIVarBannerAdEventDelegate];

  id<IMBannerDelegate> bannerDelegate = (id<IMBannerDelegate>)bannerAd;
  IMBanner *banner = [[IMBanner alloc] initWithFrame:CGRectZero placementId:0];
  [bannerDelegate bannerDidDismissScreen:banner];

  OCMVerifyAll(bannerEventDelegate);
}

- (void)testBannerAdImpressed {
  GADMAdapterInMobiBannerAd *bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];
  id<GADMediationBannerAdEventDelegate> bannerEventDelegate =
      OCMProtocolMock(@protocol(GADMediationBannerAdEventDelegate));
  OCMExpect([bannerEventDelegate reportImpression]);
  [bannerAd setValue:bannerEventDelegate forKey:AUTInMobiBannerAdIVarBannerAdEventDelegate];

  id<IMBannerDelegate> bannerDelegate = (id<IMBannerDelegate>)bannerAd;
  IMBanner *banner = [[IMBanner alloc] initWithFrame:CGRectZero placementId:0];
  [bannerDelegate bannerAdImpressed:banner];

  OCMVerifyAll(bannerEventDelegate);
}

- (void)testView {
  GADMAdapterInMobiBannerAd *bannerAd = [[GADMAdapterInMobiBannerAd alloc] init];
  UIView *expectedView = [[UIView alloc] init];
  [bannerAd setValue:expectedView forKey:AUTInMobiBannerAdIVarAdView];

  UIView *view = [bannerAd view];

  XCTAssertEqualObjects(view, expectedView);
}

@end
