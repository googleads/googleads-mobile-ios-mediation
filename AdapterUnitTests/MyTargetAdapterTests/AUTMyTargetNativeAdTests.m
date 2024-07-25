#import "GADMediationAdapterMyTarget.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationNativeAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <MyTargetSDK/MyTargetSDK.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtras.h"

static NSUInteger AUTSlotID = 12345;

@interface MTRGNativeAd (UnitTest)

- (void)registerView:(nonnull UIView *)containerView
        withController:(nonnull UIViewController *)controller
    withClickableViews:(nullable NSArray<UIView *> *)clickableViews
       withMediaAdView:(nonnull MTRGMediaAdView *)mediaAdView;

@end

@interface AUTMyTargetNativeAdTests : XCTestCase
@end

@implementation AUTMyTargetNativeAdTests {
  MTRGNativeAd *_nativeAdMock;
}

- (nonnull MTRGNativePromoBanner *)mockPromoBanner:(nonnull MTRGNativePromoBanner *)promoBanner
                                             title:(nullable NSString *)title
                                   descriptionText:(nullable NSString *)descriptionText
                                           ctaText:(nullable NSString *)ctaText
                                            domain:(nullable NSString *)domain
                                              icon:(nullable MTRGImageData *)icon
                                             image:(nullable MTRGImageData *)image
                                            rating:(nullable NSNumber *)rating
                                  advertisingLabel:(nullable NSString *)advertisingLabel
                                   ageRestrictions:(nullable NSString *)ageRestrictions
                                          category:(nullable NSString *)category
                                       subcategory:(nullable NSString *)subcategory
                                             votes:(NSUInteger)votes {
  MTRGNativePromoBanner *promoBannerMock = OCMPartialMock(promoBanner);
  OCMStub([promoBannerMock title]).andReturn(title);
  OCMStub([promoBannerMock descriptionText]).andReturn(descriptionText);
  OCMStub([promoBannerMock ctaText]).andReturn(ctaText);
  OCMStub([promoBannerMock domain]).andReturn(domain);
  OCMStub([promoBannerMock icon]).andReturn(icon);
  OCMStub([promoBannerMock image]).andReturn(image);
  OCMStub([promoBannerMock rating]).andReturn(rating);
  OCMStub([promoBannerMock advertisingLabel]).andReturn(advertisingLabel);
  OCMStub([promoBannerMock ageRestrictions]).andReturn(ageRestrictions);
  OCMStub([promoBannerMock category]).andReturn(category);
  OCMStub([promoBannerMock subcategory]).andReturn(subcategory);
  OCMStub([promoBannerMock votes]).andReturn(votes);
  return promoBannerMock;
}

- (nonnull AUTKMediationNativeAdEventDelegate *)
    loadNativeAdWithPromoBanner:(nonnull MTRGNativePromoBanner *)promoBanner
                       nativeAd:(MTRGNativeAd *)nativeAd
                shouldLoadImage:(BOOL)shouldLoadImage
                      imageData:(nullable MTRGImageData *)imageData {
  MTRGNativePromoBanner *promoBannerMock = [self mockPromoBanner:promoBanner
                                                           title:@"headline"
                                                 descriptionText:@"body"
                                                         ctaText:@"callToAction"
                                                          domain:@"advertiser"
                                                            icon:imageData
                                                           image:imageData
                                                          rating:@(3)
                                                advertisingLabel:@"advertisingLabel"
                                                 ageRestrictions:@"ageRestrictions"
                                                        category:@"category"
                                                     subcategory:@"subcategory"
                                                           votes:3];

  _nativeAdMock = OCMPartialMock(nativeAd);
  OCMStub([_nativeAdMock load]).andDo(^(NSInvocation *invocation) {
    [self->_nativeAdMock.delegate onLoadWithNativePromoBanner:promoBannerMock
                                                     nativeAd:self->_nativeAdMock];
  });
  id nativeAdClassMock = OCMClassMock([MTRGNativeAd class]);
  OCMStub([nativeAdClassMock nativeAdWithSlotId:AUTSlotID]).andReturn(_nativeAdMock);
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @(AUTSlotID),
  };
  GADMAdapterMyTargetExtras *extras = [[GADMAdapterMyTargetExtras alloc] init];
  extras.isDebugMode = YES;
  GADNativeAdImageAdLoaderOptions *imageOptions = [[GADNativeAdImageAdLoaderOptions alloc] init];
  imageOptions.disableImageLoading = !shouldLoadImage;
  GADNativeAdViewAdOptions *dummyOptions = [[GADNativeAdViewAdOptions alloc] init];
  AUTKMediationNativeAdConfiguration *nativeAdConfiguration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  nativeAdConfiguration.credentials = credentials;
  nativeAdConfiguration.extras = extras;
  nativeAdConfiguration.options = @[ dummyOptions, imageOptions ];
  AUTKMediationNativeAdEventDelegate *eventDelegate =
      AUTKWaitAndAssertLoadNativeAd(adapter, nativeAdConfiguration);
  XCTAssertEqual(_nativeAdMock.cachePolicy,
                 (shouldLoadImage ? MTRGCachePolicyAll : MTRGCachePolicyVideo));
  XCTAssertNotNil(eventDelegate.nativeAd);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertNil(eventDelegate.didFailToPresentError);
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);
  XCTAssertTrue([eventDelegate.nativeAd handlesUserClicks]);
  XCTAssertTrue([eventDelegate.nativeAd handlesUserImpressions]);
  XCTAssertTrue([eventDelegate.nativeAd hasVideoContent]);
  return eventDelegate;
}

- (void)loadNativeAdAndFailForMissingAssetsWithPromoBanner:
    (nonnull MTRGNativePromoBanner *)promoBanner {
  OCMStub([_nativeAdMock load]).andDo(^(NSInvocation *invocation) {
    [self->_nativeAdMock.delegate onLoadWithNativePromoBanner:promoBanner
                                                     nativeAd:self->_nativeAdMock];
  });
  id nativeAdClassMock = OCMClassMock([MTRGNativeAd class]);
  OCMStub([nativeAdClassMock nativeAdWithSlotId:AUTSlotID]).andReturn(_nativeAdMock);
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @(AUTSlotID),
  };
  AUTKMediationNativeAdConfiguration *nativeAdConfiguration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  nativeAdConfiguration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                 code:GADMAdapterMyTargetErrorMissingNativeAssets
                             userInfo:@{
                               NSLocalizedDescriptionKey : @"foobar",
                               NSLocalizedFailureReasonErrorKey : @"foobar",
                             }];

  AUTKWaitAndAssertLoadNativeAdFailure(adapter, nativeAdConfiguration, expectedError);
}

- (void)testOnLoadWithNativeAdWithImage {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *nativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);

  [self loadNativeAdWithPromoBanner:promoBanner
                           nativeAd:nativeAd
                    shouldLoadImage:YES
                          imageData:imageDataMock];
}

- (void)testOnLoadWithNativeAdWithoutImage {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *nativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock url]).andReturn(@"https://google.com");

  [self loadNativeAdWithPromoBanner:promoBanner
                           nativeAd:nativeAd
                    shouldLoadImage:NO
                          imageData:imageDataMock];
}

- (void)testMyFyberLoadFailureForNofill {
  MTRGNativeAd *nativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGNativeAd *nativeAdMock = OCMPartialMock(nativeAd);
  NSError *loadError = [[NSError alloc] initWithDomain:@"MyFyberDomain" code:12345 userInfo:nil];
  OCMStub([nativeAdMock load]).andDo(^(NSInvocation *invocation) {
    [nativeAdMock.delegate onLoadFailedWithError:loadError nativeAd:nativeAd];
  });
  id nativeAdClassMock = OCMClassMock([MTRGNativeAd class]);
  OCMStub([nativeAdClassMock nativeAdWithSlotId:AUTSlotID]).andReturn(nativeAdMock);
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationNativeAdConfiguration *nativeAdConfiguration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @(AUTSlotID),
  };
  GADMAdapterMyTargetExtras *extras = [[GADMAdapterMyTargetExtras alloc] init];
  extras.isDebugMode = YES;
  nativeAdConfiguration.extras = extras;
  nativeAdConfiguration.credentials = credentials;
  NSError *expectedError = [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                                      code:GADMAdapterMyTargetErrorNoFill
                                                  userInfo:@{
                                                    NSLocalizedDescriptionKey : @"foobar",
                                                    NSLocalizedFailureReasonErrorKey : @"foobar",
                                                  }];

  AUTKWaitAndAssertLoadNativeAdFailure(adapter, nativeAdConfiguration, expectedError);
}

- (void)testMyFyberLoadFailureForMissingTitle {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *nativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  _nativeAdMock = OCMPartialMock(nativeAd);
  MTRGNativePromoBanner *promoBannerMock = [self mockPromoBanner:promoBanner
                                                           title:nil
                                                 descriptionText:@"body"
                                                         ctaText:@"callToAction"
                                                          domain:@"advertiser"
                                                            icon:[[MTRGImageData alloc] init]
                                                           image:[[MTRGImageData alloc] init]
                                                          rating:@(3)
                                                advertisingLabel:@"advertisingLabel"
                                                 ageRestrictions:@"ageRestrictions"
                                                        category:@"category"
                                                     subcategory:@"subcategory"
                                                           votes:3];

  [self loadNativeAdAndFailForMissingAssetsWithPromoBanner:promoBannerMock];
}

- (void)testMyFyberLoadFailureForMissingDescriptionText {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *nativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  _nativeAdMock = OCMPartialMock(nativeAd);
  MTRGNativePromoBanner *promoBannerMock = [self mockPromoBanner:promoBanner
                                                           title:@"title"
                                                 descriptionText:nil
                                                         ctaText:@"callToAction"
                                                          domain:@"advertiser"
                                                            icon:[[MTRGImageData alloc] init]
                                                           image:[[MTRGImageData alloc] init]
                                                          rating:@(3)
                                                advertisingLabel:@"advertisingLabel"
                                                 ageRestrictions:@"ageRestrictions"
                                                        category:@"category"
                                                     subcategory:@"subcategory"
                                                           votes:3];

  [self loadNativeAdAndFailForMissingAssetsWithPromoBanner:promoBannerMock];
}

- (void)testMyFyberLoadFailureForMissingCallToActionText {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *nativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  _nativeAdMock = OCMPartialMock(nativeAd);
  MTRGNativePromoBanner *promoBannerMock = [self mockPromoBanner:promoBanner
                                                           title:@"title"
                                                 descriptionText:@"body"
                                                         ctaText:nil
                                                          domain:@"advertiser"
                                                            icon:[[MTRGImageData alloc] init]
                                                           image:[[MTRGImageData alloc] init]
                                                          rating:@(3)
                                                advertisingLabel:@"advertisingLabel"
                                                 ageRestrictions:@"ageRestrictions"
                                                        category:@"category"
                                                     subcategory:@"subcategory"
                                                           votes:3];

  [self loadNativeAdAndFailForMissingAssetsWithPromoBanner:promoBannerMock];
}

- (void)testMyFyberLoadFailureForMissingImage {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *nativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  _nativeAdMock = OCMPartialMock(nativeAd);
  MTRGNativePromoBanner *promoBannerMock = [self mockPromoBanner:promoBanner
                                                           title:@"title"
                                                 descriptionText:@"body"
                                                         ctaText:nil
                                                          domain:@"advertiser"
                                                            icon:[[MTRGImageData alloc] init]
                                                           image:nil
                                                          rating:@(3)
                                                advertisingLabel:@"advertisingLabel"
                                                 ageRestrictions:@"ageRestrictions"
                                                        category:@"category"
                                                     subcategory:@"subcategory"
                                                           votes:3];

  [self loadNativeAdAndFailForMissingAssetsWithPromoBanner:promoBannerMock];
}

- (void)testMyFyberLoadFailureForInvalidImageData {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *nativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  _nativeAdMock = OCMPartialMock(nativeAd);
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock url]).andReturn(nil);
  OCMStub([imageDataMock image]).andReturn(nil);
  MTRGImageData *iconDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([iconDataMock url]).andReturn(@"https://google.com");
  OCMStub([iconDataMock image]).andReturn([[UIImage alloc] init]);
  MTRGNativePromoBanner *promoBannerMock = [self mockPromoBanner:promoBanner
                                                           title:@"title"
                                                 descriptionText:@"body"
                                                         ctaText:@"ctaText"
                                                          domain:@"advertiser"
                                                            icon:iconDataMock
                                                           image:imageDataMock
                                                          rating:@(3)
                                                advertisingLabel:@"advertisingLabel"
                                                 ageRestrictions:@"ageRestrictions"
                                                        category:@"category"
                                                     subcategory:@"subcategory"
                                                           votes:3];

  [self loadNativeAdAndFailForMissingAssetsWithPromoBanner:promoBannerMock];
}

- (void)testMyFyberLoadFailureForMissingDomain {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *nativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  _nativeAdMock = OCMPartialMock(nativeAd);
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock url]).andReturn(@"https://google.com");
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);
  MTRGImageData *iconDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([iconDataMock url]).andReturn(@"https://google.com");
  OCMStub([iconDataMock image]).andReturn([[UIImage alloc] init]);
  MTRGNativePromoBanner *promoBannerMock = [self mockPromoBanner:promoBanner
                                                           title:@"title"
                                                 descriptionText:@"body"
                                                         ctaText:@"ctaText"
                                                          domain:nil
                                                            icon:iconDataMock
                                                           image:imageDataMock
                                                          rating:@(3)
                                                advertisingLabel:@"advertisingLabel"
                                                 ageRestrictions:@"ageRestrictions"
                                                        category:@"category"
                                                     subcategory:@"subcategory"
                                                           votes:3];
  OCMStub([promoBannerMock navigationType]).andReturn(MTRGNavigationTypeWeb);

  [self loadNativeAdAndFailForMissingAssetsWithPromoBanner:promoBannerMock];
}

- (void)testMyFyberLoadFailureForInvalidIconData {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *nativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  _nativeAdMock = OCMPartialMock(nativeAd);
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock url]).andReturn(@"https://google.com");
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);
  MTRGImageData *iconDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([iconDataMock url]).andReturn(nil);
  OCMStub([iconDataMock image]).andReturn(nil);
  MTRGNativePromoBanner *promoBannerMock = [self mockPromoBanner:promoBanner
                                                           title:@"title"
                                                 descriptionText:@"body"
                                                         ctaText:@"ctaText"
                                                          domain:@"advertiser"
                                                            icon:iconDataMock
                                                           image:imageDataMock
                                                          rating:@(3)
                                                advertisingLabel:@"advertisingLabel"
                                                 ageRestrictions:@"ageRestrictions"
                                                        category:@"category"
                                                     subcategory:@"subcategory"
                                                           votes:3];
  OCMStub([promoBannerMock navigationType]).andReturn(MTRGNavigationTypeStore);

  [self loadNativeAdAndFailForMissingAssetsWithPromoBanner:promoBannerMock];
}

- (void)testNilSlotIDFailure {
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  GADMediationNativeAdConfiguration *nativeAdConfiguration =
      [[GADMediationNativeAdConfiguration alloc] init];
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                 code:GADMAdapterMyTargetErrorInvalidServerParameters
                             userInfo:nil];

  AUTKWaitAndAssertLoadNativeAdFailure(adapter, nativeAdConfiguration, expectedError);
}

- (void)testEmptyStringSlotIDFailure {
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationNativeAdConfiguration *nativeAdConfiguration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @"",
  };
  nativeAdConfiguration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                 code:GADMAdapterMyTargetErrorInvalidServerParameters
                             userInfo:nil];

  AUTKWaitAndAssertLoadNativeAdFailure(adapter, nativeAdConfiguration, expectedError);
}

- (void)testNonNumericStringSlotIDFailure {
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationNativeAdConfiguration *nativeAdConfiguration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @"foobar",
  };
  nativeAdConfiguration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                 code:GADMAdapterMyTargetErrorInvalidServerParameters
                             userInfo:nil];

  AUTKWaitAndAssertLoadNativeAdFailure(adapter, nativeAdConfiguration, expectedError);
}

- (void)testZeroSlotIDFailure {
  GADMediationAdapterMyTarget *adapter = [[GADMediationAdapterMyTarget alloc] init];
  AUTKMediationNativeAdConfiguration *nativeAdConfiguration =
      [[AUTKMediationNativeAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterMyTargetSlotIdKey : @0,
  };
  nativeAdConfiguration.credentials = credentials;
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterMyTargetAdapterErrorDomain
                                 code:GADMAdapterMyTargetErrorInvalidServerParameters
                             userInfo:nil];

  AUTKWaitAndAssertLoadNativeAdFailure(adapter, nativeAdConfiguration, expectedError);
}

- (void)testOnClickWithNativeAd {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *nativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:nativeAd
                        shouldLoadImage:YES
                              imageData:imageDataMock];
  [nativeAd.delegate onAdClickWithNativeAd:nativeAd];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testOnDisplayWithNativeAd {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *nativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:nativeAd
                        shouldLoadImage:YES
                              imageData:imageDataMock];
  [nativeAd.delegate onAdShowWithNativeAd:nativeAd];

  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testOnVideoPlayWithNativeAd {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *nativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:nativeAd
                        shouldLoadImage:YES
                              imageData:imageDataMock];
  [nativeAd.delegate onVideoPlayWithNativeAd:nativeAd];

  XCTAssertEqual(eventDelegate.didPlayVideoInvokeCount, 1);
}

- (void)testOnVideoPauseWithNativeAd {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *nativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:nativeAd
                        shouldLoadImage:YES
                              imageData:imageDataMock];
  [nativeAd.delegate onVideoPauseWithNativeAd:nativeAd];

  XCTAssertEqual(eventDelegate.didPauseVideoInvokeCount, 1);
}

- (void)testOnVideoCompleteWithNativeAd {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *nativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:nativeAd
                        shouldLoadImage:YES
                              imageData:imageDataMock];
  [nativeAd.delegate onVideoCompleteWithNativeAd:nativeAd];

  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 1);
}

- (void)testMediaView {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *mintegralNativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);
  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:mintegralNativeAd
                        shouldLoadImage:YES
                              imageData:imageDataMock];
  id<GADMediatedUnifiedNativeAd> unifiedNativeAd = eventDelegate.nativeAd;

  MTRGMediaAdView *mediaView = (MTRGMediaAdView *)unifiedNativeAd.mediaView;
  XCTAssertTrue([mediaView isKindOfClass:[MTRGMediaAdView class]]);
  XCTAssertEqual(unifiedNativeAd.mediaContentAspectRatio, mediaView.aspectRatio);
}

- (void)testImageIcon {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *mintegralNativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:mintegralNativeAd
                        shouldLoadImage:YES
                              imageData:imageDataMock];
  id<GADMediatedUnifiedNativeAd> unifiedNativeAd = eventDelegate.nativeAd;

  XCTAssertNotNil(unifiedNativeAd.icon);
}

- (void)testURLIcon {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *mintegralNativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock url]).andReturn(@"https://google.com");

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:mintegralNativeAd
                        shouldLoadImage:NO
                              imageData:imageDataMock];
  id<GADMediatedUnifiedNativeAd> unifiedNativeAd = eventDelegate.nativeAd;

  XCTAssertNotNil(unifiedNativeAd.icon);
}

- (void)testHeadline {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *mintegralNativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:mintegralNativeAd
                        shouldLoadImage:YES
                              imageData:imageDataMock];
  id<GADMediatedUnifiedNativeAd> unifiedNativeAd = eventDelegate.nativeAd;

  XCTAssertEqualObjects(unifiedNativeAd.headline, @"headline");
}

- (void)testBody {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *mintegralNativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:mintegralNativeAd
                        shouldLoadImage:YES
                              imageData:imageDataMock];
  id<GADMediatedUnifiedNativeAd> unifiedNativeAd = eventDelegate.nativeAd;

  XCTAssertEqualObjects(unifiedNativeAd.body, @"body");
}

- (void)testCallToAction {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *mintegralNativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:mintegralNativeAd
                        shouldLoadImage:YES
                              imageData:imageDataMock];
  id<GADMediatedUnifiedNativeAd> unifiedNativeAd = eventDelegate.nativeAd;

  XCTAssertEqualObjects(unifiedNativeAd.callToAction, @"callToAction");
}

- (void)testAdvertiser {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *mintegralNativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:mintegralNativeAd
                        shouldLoadImage:YES
                              imageData:imageDataMock];
  id<GADMediatedUnifiedNativeAd> unifiedNativeAd = eventDelegate.nativeAd;

  XCTAssertEqualObjects(unifiedNativeAd.advertiser, @"advertiser");
}

- (void)testImageImages {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *mintegralNativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:mintegralNativeAd
                        shouldLoadImage:YES
                              imageData:imageDataMock];
  id<GADMediatedUnifiedNativeAd> unifiedNativeAd = eventDelegate.nativeAd;

  XCTAssertNotNil(unifiedNativeAd.images);
}

- (void)testURLImages {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *mintegralNativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock url]).andReturn(@"https://google.com");

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:mintegralNativeAd
                        shouldLoadImage:NO
                              imageData:imageDataMock];
  id<GADMediatedUnifiedNativeAd> unifiedNativeAd = eventDelegate.nativeAd;

  XCTAssertNotNil(unifiedNativeAd.images);
}

- (void)testStartRating {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *mintegralNativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:mintegralNativeAd
                        shouldLoadImage:YES
                              imageData:imageDataMock];
  id<GADMediatedUnifiedNativeAd> unifiedNativeAd = eventDelegate.nativeAd;

  XCTAssertEqual(unifiedNativeAd.starRating.intValue, 3);
}

- (void)testExtraAssets {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *mintegralNativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:mintegralNativeAd
                        shouldLoadImage:YES
                              imageData:imageDataMock];
  id<GADMediatedUnifiedNativeAd> unifiedNativeAd = eventDelegate.nativeAd;

  // 5 for adverising label, age restriction, category, sub-category, and votes.
  XCTAssertEqual(unifiedNativeAd.extraAssets.allKeys.count, 5);
}

- (void)testUnusedNativeAdInformation {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *mintegralNativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:mintegralNativeAd
                        shouldLoadImage:YES
                              imageData:imageDataMock];
  id<GADMediatedUnifiedNativeAd> unifiedNativeAd = eventDelegate.nativeAd;

  XCTAssertNil(unifiedNativeAd.adChoicesView);
  XCTAssertNil(unifiedNativeAd.store);
  XCTAssertNil(unifiedNativeAd.price);
}

- (void)testViewRegistration {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *mintegralNativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:mintegralNativeAd
                        shouldLoadImage:YES
                              imageData:imageDataMock];
  id<GADMediatedUnifiedNativeAd> unifiedNativeAd = eventDelegate.nativeAd;
  MTRGMediaAdView *mediaView = (MTRGMediaAdView *)unifiedNativeAd.mediaView;
  OCMExpect([_nativeAdMock registerView:OCMOCK_ANY
                         withController:OCMOCK_ANY
                     withClickableViews:OCMOCK_ANY
                        withMediaAdView:mediaView]);
  [unifiedNativeAd didRenderInView:[[UIView alloc] init]
               clickableAssetViews:@{}
            nonclickableAssetViews:@{}
                    viewController:[[UIViewController alloc] init]];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Wait for main queue to be flushed."];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });
  [self waitForExpectations:@[ expectation ]];
  OCMVerifyAll(_nativeAdMock);
}

- (void)testUntrack {
  MTRGNativePromoBanner *promoBanner = [[MTRGNativePromoBanner alloc] init];
  MTRGNativeAd *mintegralNativeAd = [[MTRGNativeAd alloc] initWithSlotId:AUTSlotID];
  MTRGImageData *imageDataMock = OCMPartialMock([[MTRGImageData alloc] init]);
  OCMStub([imageDataMock image]).andReturn([[UIImage alloc] init]);

  AUTKMediationNativeAdEventDelegate *eventDelegate =
      [self loadNativeAdWithPromoBanner:promoBanner
                               nativeAd:mintegralNativeAd
                        shouldLoadImage:YES
                              imageData:imageDataMock];
  id<GADMediatedUnifiedNativeAd> unifiedNativeAd = eventDelegate.nativeAd;

  OCMExpect([_nativeAdMock unregisterView]);
  [unifiedNativeAd didUntrackView:[[UIView alloc] init]];
  OCMVerifyAll(_nativeAdMock);
}

@end
