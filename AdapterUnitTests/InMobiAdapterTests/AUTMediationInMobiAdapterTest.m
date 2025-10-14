#import "GADMediationAdapterInMobi.h"

#import <XCTest/XCTest.h>

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <InMobiSDK/InMobiSDK-Swift.h>

#import <OCMock/OCMock.h>

#import "AUTInMobiUtils.h"
#import "AUTTestUtils.h"
#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiBannerAd.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiInitializer.h"
#import "GADMAdapterInMobiInterstitialAd.h"
#import "GADMAdapterInMobiRewardedAd.h"
#import "GADMAdapterInMobiUnifiedNativeAd.h"
#import "GADMediation+AdapterUnitTests.h"
#import "NativeAdKeys.h"

/// Data key for server configuration.
static NSString *_Nonnull const kConfigurationDataKey = @"data";

/// Format key for server configuration.
static NSString *const kConfigurationFormatKey = @"format";

/// Banner format for server configuration.
static NSString *_Nonnull const kConfigurationBannerFormat = @"banner";

/// Account ID for InMobi for server configuration.
static NSString *_Nonnull const kConfigurationAccountID = @"12345";

/// Name of the banner ad iVar within the GADMediationAdapterInMobi.
static NSString *_Nonnull const kAdapterBannerAdIVar = @"_bannerAd";

/// Name of the interstitial ad iVar within the GADMediationAdapterInMobi.
static NSString *_Nonnull const kAdapterInterstitialAdIVar = @"_interstitialAd";

/// Name of the rewarded ad iVar within the GADMediationAdapterInMobi.
static NSString *_Nonnull const kAdapterRewardedAdIVar = @"_rewardedAd";

/// Name of the native ad iVar within the GADMediationAdapterInMobi.
static NSString *_Nonnull const kAdapterNativeAdIVar = @"_nativeAd";

/**
 * Returns a correctly configured server configuration.
 */
GADMediationServerConfiguration *_Nonnull AUTDefaultMediationServerConfigurationForInMobi(void) {
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterInMobiAccountID : kConfigurationAccountID};
  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = @[ credentials ];
  return configuration;
}

@interface AUTMediationInMobiAdapterTest : XCTestCase
@end

@implementation AUTMediationInMobiAdapterTest

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
}

- (void)testCollectSignalsWithCOPPAUnset {
  NSString *versionString =
      [NSString stringWithFormat:@"afma-sdk-i-v%ld.%ld.%ld",
                                 GADMobileAds.sharedInstance.versionNumber.majorVersion,
                                 GADMobileAds.sharedInstance.versionNumber.minorVersion,
                                 GADMobileAds.sharedInstance.versionNumber.patchVersion];
  NSDictionary<NSString *, id> *requestParameters = @{
    GADMAdapterInMobiRequestParametersMediationTypeKey :
        GADMAdapterInMobiRequestParametersMediationTypeRTB,
    GADMAdapterInMobiRequestParametersSDKVersionKey : versionString,
  };
  NSString *expectedSignals = @"expectedSignals";

  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMStub(ClassMethod([IMSDKMock getTokenWithExtras:requestParameters andKeywords:nil]))
      .andReturn(expectedSignals);

  GADMediationAdapterInMobi *adapter = [[GADMediationAdapterInMobi alloc] init];
  GADRTBRequestParameters *params = [[GADRTBRequestParameters alloc] init];
  __block BOOL completionHandlerInvoked = NO;
  [adapter
      collectSignalsForRequestParameters:params
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertEqualObjects(signals, expectedSignals);
                         XCTAssertNil(error);
                         completionHandlerInvoked = YES;
                       }];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testCollectSignalsWithCOPPAFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
  NSString *versionString =
      [NSString stringWithFormat:@"afma-sdk-i-v%ld.%ld.%ld",
                                 GADMobileAds.sharedInstance.versionNumber.majorVersion,
                                 GADMobileAds.sharedInstance.versionNumber.minorVersion,
                                 GADMobileAds.sharedInstance.versionNumber.patchVersion];
  NSDictionary<NSString *, id> *requestParameters = @{
    GADMAdapterInMobiRequestParametersMediationTypeKey :
        GADMAdapterInMobiRequestParametersMediationTypeRTB,
    GADMAdapterInMobiRequestParametersSDKVersionKey : versionString,
    GADMAdapterInMobiRequestParametersCOPPAKey : @"0"
  };
  NSString *expectedSignals = @"expectedSignals";

  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMStub(ClassMethod([IMSDKMock getTokenWithExtras:requestParameters andKeywords:nil]))
      .andReturn(expectedSignals);

  GADMediationAdapterInMobi *adapter = [[GADMediationAdapterInMobi alloc] init];
  GADRTBRequestParameters *params = [[GADRTBRequestParameters alloc] init];
  __block BOOL completionHandlerInvoked = NO;
  [adapter
      collectSignalsForRequestParameters:params
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertEqualObjects(signals, expectedSignals);
                         XCTAssertNil(error);
                         completionHandlerInvoked = YES;
                       }];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testCollectSignalsWithCOPPATrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  NSString *versionString =
      [NSString stringWithFormat:@"afma-sdk-i-v%ld.%ld.%ld",
                                 GADMobileAds.sharedInstance.versionNumber.majorVersion,
                                 GADMobileAds.sharedInstance.versionNumber.minorVersion,
                                 GADMobileAds.sharedInstance.versionNumber.patchVersion];
  NSDictionary<NSString *, id> *requestParameters = @{
    GADMAdapterInMobiRequestParametersMediationTypeKey :
        GADMAdapterInMobiRequestParametersMediationTypeRTB,
    GADMAdapterInMobiRequestParametersSDKVersionKey : versionString,
    GADMAdapterInMobiRequestParametersCOPPAKey : @"1"
  };
  NSString *expectedSignals = @"expectedSignals";

  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMStub(ClassMethod([IMSDKMock getTokenWithExtras:requestParameters andKeywords:nil]))
      .andReturn(expectedSignals);

  GADMediationAdapterInMobi *adapter = [[GADMediationAdapterInMobi alloc] init];
  GADRTBRequestParameters *params = [[GADRTBRequestParameters alloc] init];
  __block BOOL completionHandlerInvoked = NO;
  [adapter
      collectSignalsForRequestParameters:params
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertEqualObjects(signals, expectedSignals);
                         XCTAssertNil(error);
                         completionHandlerInvoked = YES;
                       }];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testCollectSignalsFailureForEmptySignals {
  NSString *versionString =
      [NSString stringWithFormat:@"afma-sdk-i-v%ld.%ld.%ld",
                                 GADMobileAds.sharedInstance.versionNumber.majorVersion,
                                 GADMobileAds.sharedInstance.versionNumber.minorVersion,
                                 GADMobileAds.sharedInstance.versionNumber.patchVersion];
  NSDictionary<NSString *, id> *requestParameters = @{
    GADMAdapterInMobiRequestParametersMediationTypeKey :
        GADMAdapterInMobiRequestParametersMediationTypeRTB,
    GADMAdapterInMobiRequestParametersSDKVersionKey : versionString,
  };

  NSString *emptySignals = @"";
  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMStub(ClassMethod([IMSDKMock getTokenWithExtras:requestParameters andKeywords:nil]))
      .andReturn(emptySignals);

  GADMediationAdapterInMobi *adapter = [[GADMediationAdapterInMobi alloc] init];
  GADRTBRequestParameters *params = [[GADRTBRequestParameters alloc] init];
  __block BOOL completionHandlerInvoked = NO;
  [adapter
      collectSignalsForRequestParameters:params
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(signals);
                         XCTAssertNotNil(error);
                         XCTAssertEqual(error.code, GADMAdapterInMobiErrorInvalidBidToken);
                         completionHandlerInvoked = YES;
                       }];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testSetUpWithConfiguration {
  AUTMockGADMAdapterInMobiInitializer();
  AUTMockIMSDKInit();

  __block BOOL completionHandlerInvoked = NO;
  [GADMediationAdapterInMobi
      setUpWithConfiguration:AUTDefaultMediationServerConfigurationForInMobi()
           completionHandler:^(NSError *_Nullable error) {
             XCTAssertNil(error);
             completionHandlerInvoked = YES;
           }];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testMultipleSetUpWithConfiguration {
  AUTMockGADMAdapterInMobiInitializer();
  AUTMockIMSDKInit();

  __block BOOL completionHandlerInvoked = NO;
  [GADMediationAdapterInMobi
      setUpWithConfiguration:AUTDefaultMediationServerConfigurationForInMobi()
           completionHandler:^(NSError *_Nullable error) {
             XCTAssertNil(error);
             completionHandlerInvoked = YES;
           }];

  XCTAssertTrue(completionHandlerInvoked);

  completionHandlerInvoked = NO;
  [GADMediationAdapterInMobi
      setUpWithConfiguration:AUTDefaultMediationServerConfigurationForInMobi()
           completionHandler:^(NSError *_Nullable error) {
             XCTAssertNil(error);
             completionHandlerInvoked = YES;
           }];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testSetUpWithConfigurationFailureWithNoAccountID {
  AUTMockGADMAdapterInMobiInitializer();
  AUTMockIMSDKInit();
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{};
  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = @[ credentials ];

  __block BOOL completionHandlerInvoked = NO;
  [GADMediationAdapterInMobi
      setUpWithConfiguration:configuration
           completionHandler:^(NSError *_Nullable error) {
             XCTAssertEqual(error.code, GADMAdapterInMobiErrorInvalidServerParameters);
             completionHandlerInvoked = YES;
           }];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testSetUpWithConfigurationWithMultipleAccountIDs {
  AUTMockGADMAdapterInMobiInitializer();
  AUTMockIMSDKInit();
  AUTKMediationCredentials *credentials1 = [[AUTKMediationCredentials alloc] init];
  credentials1.settings = @{GADMAdapterInMobiAccountID : @"12345"};
  AUTKMediationCredentials *credentials2 = [[AUTKMediationCredentials alloc] init];
  credentials2.settings = @{GADMAdapterInMobiAccountID : @"67890"};
  AUTKMediationServerConfiguration *configuration = [[AUTKMediationServerConfiguration alloc] init];
  configuration.credentials = @[ credentials1, credentials2 ];

  __block BOOL completionHandlerInvoked = NO;
  [GADMediationAdapterInMobi setUpWithConfiguration:configuration
                                  completionHandler:^(NSError *_Nullable error) {
                                    XCTAssertNil(error);
                                    completionHandlerInvoked = YES;
                                  }];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testAdSDKVersion {
  NSString *versionString = @"1.2.3";
  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMStub(ClassMethod([IMSDKMock getVersion])).andReturn(versionString);
  GADVersionNumber expectedAdSDKVersion = {.majorVersion = 1, .minorVersion = 2, .patchVersion = 3};

  AUTAssertEqualVersion([GADMediationAdapterInMobi adSDKVersion], expectedAdSDKVersion);
}

- (void)testAdapterVersion {
  GADVersionNumber version = [GADMediationAdapterInMobi adapterVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 999);
}

- (void)testAdapterNetworkExtrasClass {
  Class networkClass = [GADMediationAdapterInMobi networkExtrasClass];
  Class expectedNetworkClass = [GADInMobiExtras class];

  XCTAssertEqual(networkClass, expectedNetworkClass);
}

- (void)testLoadBannerAd {
  AUTMockIMSDKInit();
  AUTMockGADMAdapterInMobiInitializer();

  // Mock IMBanner to call bannerDidFinishLoading IMBannerDelegate method.
  GADMediationAdapterInMobi *adapter = [[GADMediationAdapterInMobi alloc] init];
  id bannerMock = OCMClassMock([IMBanner class]);
  OCMStub([bannerMock alloc]).andReturn(bannerMock);
  // At this point, the delegate is not intialized yet. So init mock needs to use OCMOCK_ANY.
  OCMStub([[bannerMock ignoringNonObjectArgs] initWithFrame:CGRectMake(0, 0, 320, 50)
                                                placementId:[AUTInMobiPlacementID longLongValue]
                                                   delegate:OCMOCK_ANY])
      .andReturn(bannerMock);
  IMBanner *banner = (IMBanner *)bannerMock;
  OCMStub([banner load]).andDo(^(NSInvocation *invocation) {
    GADMAdapterInMobiBannerAd *bannerAd = AUTValueForKeyIfIsKindOfClass(
        adapter, kAdapterBannerAdIVar, [GADMAdapterInMobiBannerAd class]);
    id<IMBannerDelegate> delegate = (id<IMBannerDelegate>)bannerAd;
    [delegate bannerDidFinishLoading:banner];
  });

  // Try loading a banner ad.
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatBanner
                                            credentials:@{
                                              GADMAdapterInMobiAccountID : AUTInMobiAccountID,
                                              GADMAdapterInMobiPlacementID : AUTInMobiPlacementID
                                            }];
  GADMediationBannerAdConfiguration *adConfiguration =
      [[GADMediationBannerAdConfiguration alloc] initWithAdSize:GADAdSizeBanner
                                                adConfiguration:nil
                                                      targeting:nil
                                                    credentials:credentials
                                                         extras:nil];

  __block BOOL completionHandlerInvoked = NO;
  GADMediationBannerLoadCompletionHandler completionHandler =
      ^(id<GADMediationBannerAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNotNil(ad);
        XCTAssertNil(error);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationBannerAdEventDelegate));
      };

  [adapter loadBannerForAdConfiguration:adConfiguration completionHandler:completionHandler];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testLoadInterstitialAd {
  AUTMockIMSDKInit();
  AUTMockGADMAdapterInMobiInitializer();

  // Mock IMInterstitial to call interstitialDidFinishLoading IMInterstitialDelegate method.
  GADMediationAdapterInMobi *adapter = [[GADMediationAdapterInMobi alloc] init];
  id interstitialMock = OCMClassMock([IMInterstitial class]);
  OCMStub([interstitialMock alloc]).andReturn(interstitialMock);
  // At this point, the delegate is not intialized yet. So init mock needs to use OCMOCK_ANY.
  OCMStub([interstitialMock initWithPlacementId:[AUTInMobiPlacementID longLongValue]
                                       delegate:OCMOCK_ANY])
      .andReturn(interstitialMock);
  IMInterstitial *interstitial = (IMInterstitial *)interstitialMock;
  OCMStub([interstitial load]).andDo(^(NSInvocation *invocation) {
    GADMAdapterInMobiInterstitialAd *interstitialAd = AUTValueForKeyIfIsKindOfClass(
        adapter, kAdapterInterstitialAdIVar, [GADMAdapterInMobiInterstitialAd class]);
    id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)interstitialAd;
    [delegate interstitialDidFinishLoading:interstitial];
  });

  // Try loading an interstitial ad.
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatInterstitial
                                            credentials:@{
                                              GADMAdapterInMobiAccountID : AUTInMobiAccountID,
                                              GADMAdapterInMobiPlacementID : AUTInMobiPlacementID
                                            }];
  GADMediationInterstitialAdConfiguration *adConfiguration =
      [[GADMediationInterstitialAdConfiguration alloc] initWithAdConfiguration:nil
                                                                     targeting:nil
                                                                   credentials:credentials
                                                                        extras:nil];

  __block BOOL completionHandlerInvoked = NO;
  GADMediationInterstitialLoadCompletionHandler completionHandler =
      ^(id<GADMediationInterstitialAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNotNil(ad);
        XCTAssertNil(error);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationInterstitialAdEventDelegate));
      };

  [adapter loadInterstitialForAdConfiguration:adConfiguration completionHandler:completionHandler];

  XCTAssertTrue(completionHandlerInvoked);
}

- (void)testLoadNativeAd {
  AUTMockIMSDKInit();
  AUTMockGADMAdapterInMobiInitializer();

  // Mock IMNative convenience initializer.
  GADMediationAdapterInMobi *adapter = [[GADMediationAdapterInMobi alloc] init];
  id nativeMock = OCMClassMock([IMNative class]);
  OCMStub([nativeMock alloc]).andReturn(nativeMock);
  // At this point, the delegate is not intialized yet. So init mock needs to use OCMOCK_ANY.
  OCMStub([nativeMock initWithPlacementId:[AUTInMobiPlacementID longLongValue] delegate:OCMOCK_ANY])
      .andReturn(nativeMock);

  // Mock IMNative.
  IMNative *native = (IMNative *)nativeMock;
  OCMStub([native customAdContent])
      .andReturn(
          AUTNativeAdContentString(@"https://google.com/", @"https://google.com/", @"12345"));
  OCMStub([native adTitle]).andReturn(@"adTitle");
  OCMStub([native adDescription]).andReturn(@"body");
  OCMStub([native adCtaText]).andReturn(@"adCtaText");
  OCMStub([native adRating]).andReturn([[NSDecimalNumber alloc] initWithInt:12345]);
  OCMStub([native adIcon]).andReturn([[GADNativeAdImage alloc] init]);
  OCMStub([native load]).andDo(^(NSInvocation *invocation) {
    GADMAdapterInMobiUnifiedNativeAd *nativeAd = AUTValueForKeyIfIsKindOfClass(
        adapter, kAdapterNativeAdIVar, [GADMAdapterInMobiUnifiedNativeAd class]);
    id<IMNativeDelegate> delegate = (id<IMNativeDelegate>)nativeAd;
    [delegate nativeDidFinishLoading:native];
  });

  // Mock native ad image fetching.
  UIImage *testImage = [[UIImage alloc] init];
  id imageMock = OCMClassMock([UIImage class]);
  OCMStub(OCMClassMethod([imageMock imageWithData:OCMOCK_ANY])).andReturn(testImage);

  // Try loading a native ad.
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatNative
                                            credentials:@{
                                              GADMAdapterInMobiAccountID : AUTInMobiAccountID,
                                              GADMAdapterInMobiPlacementID : AUTInMobiPlacementID
                                            }];
  GADMediationNativeAdConfiguration *adConfiguration =
      [[GADMediationNativeAdConfiguration alloc] initWithOptions:nil
                                                 adConfiguration:nil
                                                       targeting:nil
                                                     credentials:credentials
                                                          extras:nil];

  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Completion handler run."];
  GADMediationNativeLoadCompletionHandler completionHandler =
      ^(id<GADMediationNativeAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNotNil(ad);
        XCTAssertNil(error);
        [expectation fulfill];
        return OCMProtocolMock(@protocol(GADMediationNativeAd));
      };

  [adapter loadNativeAdForAdConfiguration:adConfiguration completionHandler:completionHandler];

  [self waitForExpectations:@[ expectation ] timeout:AUTExpectationTimeout];
}

- (void)testLoadRewardedAd {
  AUTMockIMSDKInit();
  AUTMockGADMAdapterInMobiInitializer();

  // IMSDK uses IMInterstitial for rewarded ad. Mock IMInterstitial to call
  // interstitialDidFinishLoading IMInterstitialDelegate method.
  GADMediationAdapterInMobi *adapter = [[GADMediationAdapterInMobi alloc] init];
  id interstitialMock = OCMClassMock([IMInterstitial class]);
  OCMStub([interstitialMock alloc]).andReturn(interstitialMock);
  OCMStub([[interstitialMock ignoringNonObjectArgs]
              initWithPlacementId:[AUTInMobiPlacementID longLongValue]
                         delegate:OCMOCK_ANY])
      .andReturn(interstitialMock);
  IMInterstitial *interstitial = (IMInterstitial *)interstitialMock;
  OCMStub([interstitial load]).andDo(^(NSInvocation *invocation) {
    GADMAdapterInMobiRewardedAd *interstitialAd = AUTValueForKeyIfIsKindOfClass(
        adapter, kAdapterRewardedAdIVar, [GADMAdapterInMobiRewardedAd class]);
    id<IMInterstitialDelegate> delegate = (id<IMInterstitialDelegate>)interstitialAd;
    [delegate interstitialDidFinishLoading:interstitial];
  });

  // Try loading a rewarded ad.
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatRewarded
                                            credentials:@{
                                              GADMAdapterInMobiAccountID : AUTInMobiAccountID,
                                              GADMAdapterInMobiPlacementID : AUTInMobiPlacementID
                                            }];
  GADMediationRewardedAdConfiguration *adConfiguration =
      [[GADMediationRewardedAdConfiguration alloc] initWithAdConfiguration:nil
                                                                 targeting:nil
                                                               credentials:credentials
                                                                    extras:nil];
  __block BOOL completionHandlerInvoked = NO;
  GADMediationRewardedLoadCompletionHandler completionHandler =
      ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNotNil(ad);
        XCTAssertNil(error);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationRewardedAd));
      };

  [adapter loadRewardedAdForAdConfiguration:adConfiguration completionHandler:completionHandler];

  XCTAssertTrue(completionHandlerInvoked);
}

@end
