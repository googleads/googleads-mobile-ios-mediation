#import "GADMediationAdapterIronSource.h"
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceUtils.h"

#import <IronSource/IronSource.h>
#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

static NSString *const kAppKey1 = @"AppKey_1";
static NSString *const kAppKey2 = @"AppKey_2";

@interface AUTIronSourceAdapterTests : XCTestCase

@end

@implementation AUTIronSourceAdapterTests {
  /// An adapter instance.
  GADMediationAdapterIronSource *_adapter;

  /// A mock instance of IronSource.
  id _ironSourceMock;
}

- (void)setUp {
  _adapter = OCMPartialMock([[GADMediationAdapterIronSource alloc] init]);

  id adapterClassMock = OCMClassMock([GADMediationAdapterIronSource class]);
  OCMStub([adapterClassMock alloc]).andReturn(_adapter);

  _ironSourceMock = OCMClassMock([IronSource class]);
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  [super tearDown];
}

- (void)testCollectSignals {
  NSString *expectedIronSourceSignal = @"ironSourceSignal";

  OCMExpect(ClassMethod([_ironSourceMock getISDemandOnlyBiddingData]))
      .andReturn(expectedIronSourceSignal);

  XCTestExpectation *expectation =
      [[XCTestExpectation alloc] initWithDescription:@"Signal collection."];
  [_adapter
      collectSignalsForRequestParameters:OCMOCK_ANY
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertNil(error);
                         XCTAssertEqualObjects(signals, expectedIronSourceSignal);
                         [expectation fulfill];
                       }];
  [self waitForExpectations:@[ expectation ]];
  OCMVerifyAll(_ironSourceMock);
}

- (void)testAdapterVersion {
  GADVersionNumber version = [GADMediationAdapterIronSource adapterVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 9999);
}

- (void)testAdSDKVersion {
  GADVersionNumber version = [GADMediationAdapterIronSource adSDKVersion];

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 99);
}

- (void)testAdSDKVersionWhenIronSouceVersionHasOnlyTwoComponents {
  id ironSourceMock = OCMClassMock([IronSourceAds class]);
  OCMStub([ironSourceMock sdkVersion]).andReturn(@"6.3");

  GADVersionNumber version = [GADMediationAdapterIronSource adSDKVersion];

  XCTAssertEqual(version.majorVersion, 6);
  XCTAssertEqual(version.minorVersion, 3);
  XCTAssertEqual(version.patchVersion, 0);
}

- (void)testAdSDKVersionWhenIronSourceVersionHasOnlyOneComponent {
  id ironSourceMock = OCMClassMock([IronSourceAds class]);
  OCMStub([ironSourceMock sdkVersion]).andReturn(@"6");

  GADVersionNumber version = [GADMediationAdapterIronSource adSDKVersion];

  XCTAssertEqual(version.majorVersion, 6);
  XCTAssertEqual(version.minorVersion, 0);
  XCTAssertEqual(version.patchVersion, 0);
}

- (void)testInitIronSourceSDK {
  AUTKMediationCredentials *interstitialCredentials = [[AUTKMediationCredentials alloc] init];
  // At least one of the credentials needs to contain an app key.
  interstitialCredentials.settings = @{GADMAdapterIronSourceAppKey : kAppKey1};
  interstitialCredentials.format = GADAdFormatInterstitial;
  AUTKMediationCredentials *rewardedCredentials = [[AUTKMediationCredentials alloc] init];
  rewardedCredentials.format = GADAdFormatRewarded;
  AUTKMediationCredentials *bannerCredentials = [[AUTKMediationCredentials alloc] init];
  bannerCredentials.format = GADAdFormatBanner;

  id levelPlayMock = OCMClassMock([LevelPlay class]);
  OCMReject([levelPlayMock setMetaDataWithKey:@"is_child_directed" value:OCMOCK_ANY]);

  id ironSourceMock = OCMClassMock([IronSourceAds class]);

  OCMExpect(ClassMethod([ironSourceMock initWithRequest:[OCMArg checkWithBlock:^(id value) {
                                          ISAInitRequest *request = (ISAInitRequest *)value;
                                          if (![request.appKey isEqualToString:kAppKey1]) {
                                            return NO;
                                          }

                                          NSMutableSet *foundTypes = [NSMutableSet set];
                                          for (ISAAdFormat *format in request.legacyAdFormats) {
                                            [foundTypes addObject:@(format.adFormatType)];
                                          }

                                          NSMutableSet<NSNumber *> *expectedTypes =
                                              [[NSMutableSet alloc] init];
                                          [expectedTypes addObject:@(ISAAdFormatTypeInterstitial)];
                                          [expectedTypes addObject:@(ISAAdFormatTypeRewarded)];
                                          [expectedTypes addObject:@(ISAAdFormatTypeBanner)];

                                          return [foundTypes isEqualToSet:expectedTypes];
                                        }]
                                             completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        void (^completionBlock)(BOOL, NSError *);
        [invocation getArgument:&completionBlock atIndex:3];
        if (completionBlock) {
          completionBlock(YES, nil);
        }
      });

  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray(
      [GADMediationAdapterIronSource class],
      @[ interstitialCredentials, rewardedCredentials, bannerCredentials ]);
  OCMVerifyAll(_adapter);
  OCMVerifyAll(levelPlayMock);
  OCMVerifyAll(ironSourceMock);
}

- (void)testInitIronSourceSDKWhenTagForChildIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;

  AUTKMediationCredentials *interstitialCredentials = [[AUTKMediationCredentials alloc] init];
  // At least one of the credentials needs to contain an app key.
  interstitialCredentials.settings = @{GADMAdapterIronSourceAppKey : kAppKey1};
  interstitialCredentials.format = GADAdFormatInterstitial;
  AUTKMediationCredentials *rewardedCredentials = [[AUTKMediationCredentials alloc] init];
  rewardedCredentials.format = GADAdFormatRewarded;
  AUTKMediationCredentials *bannerCredentials = [[AUTKMediationCredentials alloc] init];
  bannerCredentials.format = GADAdFormatBanner;

  id levelPlayMock = OCMClassMock([LevelPlay class]);
  OCMExpect([levelPlayMock setMetaDataWithKey:@"is_child_directed" value:@"YES"]);

  id ironSourceMock = OCMClassMock([IronSourceAds class]);

  OCMExpect(ClassMethod([ironSourceMock initWithRequest:[OCMArg checkWithBlock:^(id value) {
                                          ISAInitRequest *request = (ISAInitRequest *)value;
                                          if (![request.appKey isEqualToString:kAppKey1]) {
                                            return NO;
                                          }

                                          NSMutableSet *foundTypes = [NSMutableSet set];
                                          for (ISAAdFormat *format in request.legacyAdFormats) {
                                            [foundTypes addObject:@(format.adFormatType)];
                                          }

                                          NSMutableSet<NSNumber *> *expectedTypes =
                                              [[NSMutableSet alloc] init];
                                          [expectedTypes addObject:@(ISAAdFormatTypeInterstitial)];
                                          [expectedTypes addObject:@(ISAAdFormatTypeRewarded)];
                                          [expectedTypes addObject:@(ISAAdFormatTypeBanner)];

                                          return [foundTypes isEqualToSet:expectedTypes];
                                        }]
                                             completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        void (^completionBlock)(BOOL, NSError *);
        [invocation getArgument:&completionBlock atIndex:3];
        if (completionBlock) {
          completionBlock(YES, nil);
        }
      });

  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray(
      [GADMediationAdapterIronSource class],
      @[ interstitialCredentials, rewardedCredentials, bannerCredentials ]);
  OCMVerifyAll(_adapter);
  OCMVerifyAll(levelPlayMock);
  OCMVerifyAll(ironSourceMock);
}

- (void)testInitIronSourceSDKWhenTagForChildIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;

  AUTKMediationCredentials *interstitialCredentials = [[AUTKMediationCredentials alloc] init];
  // At least one of the credentials needs to contain an app key.
  interstitialCredentials.settings = @{GADMAdapterIronSourceAppKey : kAppKey1};
  interstitialCredentials.format = GADAdFormatInterstitial;
  AUTKMediationCredentials *rewardedCredentials = [[AUTKMediationCredentials alloc] init];
  rewardedCredentials.format = GADAdFormatRewarded;
  AUTKMediationCredentials *bannerCredentials = [[AUTKMediationCredentials alloc] init];
  bannerCredentials.format = GADAdFormatBanner;

  id levelPlayMock = OCMClassMock([LevelPlay class]);
  OCMExpect([levelPlayMock setMetaDataWithKey:@"is_child_directed" value:@"NO"]);

  id ironSourceMock = OCMClassMock([IronSourceAds class]);

  OCMExpect(ClassMethod([ironSourceMock initWithRequest:[OCMArg checkWithBlock:^(id value) {
                                          ISAInitRequest *request = (ISAInitRequest *)value;
                                          if (![request.appKey isEqualToString:kAppKey1]) {
                                            return NO;
                                          }

                                          NSMutableSet *foundTypes = [NSMutableSet set];
                                          for (ISAAdFormat *format in request.legacyAdFormats) {
                                            [foundTypes addObject:@(format.adFormatType)];
                                          }

                                          NSMutableSet<NSNumber *> *expectedTypes =
                                              [[NSMutableSet alloc] init];
                                          [expectedTypes addObject:@(ISAAdFormatTypeInterstitial)];
                                          [expectedTypes addObject:@(ISAAdFormatTypeRewarded)];
                                          [expectedTypes addObject:@(ISAAdFormatTypeBanner)];

                                          return [foundTypes isEqualToSet:expectedTypes];
                                        }]
                                             completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        void (^completionBlock)(BOOL, NSError *);
        [invocation getArgument:&completionBlock atIndex:3];
        if (completionBlock) {
          completionBlock(YES, nil);
        }
      });

  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray(
      [GADMediationAdapterIronSource class],
      @[ interstitialCredentials, rewardedCredentials, bannerCredentials ]);
  OCMVerifyAll(_adapter);
  OCMVerifyAll(levelPlayMock);
  OCMVerifyAll(ironSourceMock);
}

- (void)testInitIronSourceSDKWhenTagForUnderAgeIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  AUTKMediationCredentials *interstitialCredentials = [[AUTKMediationCredentials alloc] init];
  // At least one of the credentials needs to contain an app key.
  interstitialCredentials.settings = @{GADMAdapterIronSourceAppKey : kAppKey1};
  interstitialCredentials.format = GADAdFormatInterstitial;
  AUTKMediationCredentials *rewardedCredentials = [[AUTKMediationCredentials alloc] init];
  rewardedCredentials.format = GADAdFormatRewarded;
  AUTKMediationCredentials *bannerCredentials = [[AUTKMediationCredentials alloc] init];
  bannerCredentials.format = GADAdFormatBanner;

  id levelPlayMock = OCMClassMock([LevelPlay class]);
  OCMExpect([levelPlayMock setMetaDataWithKey:@"is_child_directed" value:@"YES"]);

  id ironSourceMock = OCMClassMock([IronSourceAds class]);

  OCMExpect(ClassMethod([ironSourceMock initWithRequest:[OCMArg checkWithBlock:^(id value) {
                                          ISAInitRequest *request = (ISAInitRequest *)value;
                                          if (![request.appKey isEqualToString:kAppKey1]) {
                                            return NO;
                                          }

                                          NSMutableSet *foundTypes = [NSMutableSet set];
                                          for (ISAAdFormat *format in request.legacyAdFormats) {
                                            [foundTypes addObject:@(format.adFormatType)];
                                          }

                                          NSMutableSet<NSNumber *> *expectedTypes =
                                              [[NSMutableSet alloc] init];
                                          [expectedTypes addObject:@(ISAAdFormatTypeInterstitial)];
                                          [expectedTypes addObject:@(ISAAdFormatTypeRewarded)];
                                          [expectedTypes addObject:@(ISAAdFormatTypeBanner)];

                                          return [foundTypes isEqualToSet:expectedTypes];
                                        }]
                                             completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        void (^completionBlock)(BOOL, NSError *);
        [invocation getArgument:&completionBlock atIndex:3];
        if (completionBlock) {
          completionBlock(YES, nil);
        }
      });

  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray(
      [GADMediationAdapterIronSource class],
      @[ interstitialCredentials, rewardedCredentials, bannerCredentials ]);
  OCMVerifyAll(_adapter);
  OCMVerifyAll(levelPlayMock);
  OCMVerifyAll(ironSourceMock);
}

- (void)testInitIronSourceSDKWhenTagForUnderAgeIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  AUTKMediationCredentials *interstitialCredentials = [[AUTKMediationCredentials alloc] init];
  // At least one of the credentials needs to contain an app key.
  interstitialCredentials.settings = @{GADMAdapterIronSourceAppKey : kAppKey1};
  interstitialCredentials.format = GADAdFormatInterstitial;
  AUTKMediationCredentials *rewardedCredentials = [[AUTKMediationCredentials alloc] init];
  rewardedCredentials.format = GADAdFormatRewarded;
  AUTKMediationCredentials *bannerCredentials = [[AUTKMediationCredentials alloc] init];
  bannerCredentials.format = GADAdFormatBanner;

  id levelPlayMock = OCMClassMock([LevelPlay class]);
  OCMExpect([levelPlayMock setMetaDataWithKey:@"is_child_directed" value:@"NO"]);

  id ironSourceMock = OCMClassMock([IronSourceAds class]);

  OCMExpect(ClassMethod([ironSourceMock initWithRequest:[OCMArg checkWithBlock:^(id value) {
                                          ISAInitRequest *request = (ISAInitRequest *)value;
                                          if (![request.appKey isEqualToString:kAppKey1]) {
                                            return NO;
                                          }

                                          NSMutableSet *foundTypes = [NSMutableSet set];
                                          for (ISAAdFormat *format in request.legacyAdFormats) {
                                            [foundTypes addObject:@(format.adFormatType)];
                                          }

                                          NSMutableSet<NSNumber *> *expectedTypes =
                                              [[NSMutableSet alloc] init];
                                          [expectedTypes addObject:@(ISAAdFormatTypeInterstitial)];
                                          [expectedTypes addObject:@(ISAAdFormatTypeRewarded)];
                                          [expectedTypes addObject:@(ISAAdFormatTypeBanner)];

                                          return [foundTypes isEqualToSet:expectedTypes];
                                        }]
                                             completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        void (^completionBlock)(BOOL, NSError *);
        [invocation getArgument:&completionBlock atIndex:3];
        if (completionBlock) {
          completionBlock(YES, nil);
        }
      });

  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray(
      [GADMediationAdapterIronSource class],
      @[ interstitialCredentials, rewardedCredentials, bannerCredentials ]);
  OCMVerifyAll(_adapter);
  OCMVerifyAll(levelPlayMock);
  OCMVerifyAll(ironSourceMock);
}

- (void)testInitIronSourceSDKWhenTagForChildIsTrueAndTagForUnderAgeIsFalse {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;

  AUTKMediationCredentials *interstitialCredentials = [[AUTKMediationCredentials alloc] init];
  // At least one of the credentials needs to contain an app key.
  interstitialCredentials.settings = @{GADMAdapterIronSourceAppKey : kAppKey1};
  interstitialCredentials.format = GADAdFormatInterstitial;
  AUTKMediationCredentials *rewardedCredentials = [[AUTKMediationCredentials alloc] init];
  rewardedCredentials.format = GADAdFormatRewarded;
  AUTKMediationCredentials *bannerCredentials = [[AUTKMediationCredentials alloc] init];
  bannerCredentials.format = GADAdFormatBanner;

  id levelPlayMock = OCMClassMock([LevelPlay class]);
  OCMExpect([levelPlayMock setMetaDataWithKey:@"is_child_directed" value:@"YES"]);

  id ironSourceMock = OCMClassMock([IronSourceAds class]);

  OCMExpect(ClassMethod([ironSourceMock initWithRequest:[OCMArg checkWithBlock:^(id value) {
                                          ISAInitRequest *request = (ISAInitRequest *)value;
                                          if (![request.appKey isEqualToString:kAppKey1]) {
                                            return NO;
                                          }

                                          NSMutableSet *foundTypes = [NSMutableSet set];
                                          for (ISAAdFormat *format in request.legacyAdFormats) {
                                            [foundTypes addObject:@(format.adFormatType)];
                                          }

                                          NSMutableSet<NSNumber *> *expectedTypes =
                                              [[NSMutableSet alloc] init];
                                          [expectedTypes addObject:@(ISAAdFormatTypeInterstitial)];
                                          [expectedTypes addObject:@(ISAAdFormatTypeRewarded)];
                                          [expectedTypes addObject:@(ISAAdFormatTypeBanner)];

                                          return [foundTypes isEqualToSet:expectedTypes];
                                        }]
                                             completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        void (^completionBlock)(BOOL, NSError *);
        [invocation getArgument:&completionBlock atIndex:3];
        if (completionBlock) {
          completionBlock(YES, nil);
        }
      });

  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray(
      [GADMediationAdapterIronSource class],
      @[ interstitialCredentials, rewardedCredentials, bannerCredentials ]);
  OCMVerifyAll(_adapter);
  OCMVerifyAll(levelPlayMock);
  OCMVerifyAll(ironSourceMock);
}

- (void)testInitIronSourceSDKWhenTagForChildIsFalseAndTagForUnderAgeIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  AUTKMediationCredentials *interstitialCredentials = [[AUTKMediationCredentials alloc] init];
  // At least one of the credentials needs to contain an app key.
  interstitialCredentials.settings = @{GADMAdapterIronSourceAppKey : kAppKey1};
  interstitialCredentials.format = GADAdFormatInterstitial;
  AUTKMediationCredentials *rewardedCredentials = [[AUTKMediationCredentials alloc] init];
  rewardedCredentials.format = GADAdFormatRewarded;
  AUTKMediationCredentials *bannerCredentials = [[AUTKMediationCredentials alloc] init];
  bannerCredentials.format = GADAdFormatBanner;

  id levelPlayMock = OCMClassMock([LevelPlay class]);
  OCMExpect([levelPlayMock setMetaDataWithKey:@"is_child_directed" value:@"YES"]);

  id ironSourceMock = OCMClassMock([IronSourceAds class]);

  OCMExpect(ClassMethod([ironSourceMock initWithRequest:[OCMArg checkWithBlock:^(id value) {
                                          ISAInitRequest *request = (ISAInitRequest *)value;
                                          if (![request.appKey isEqualToString:kAppKey1]) {
                                            return NO;
                                          }

                                          NSMutableSet *foundTypes = [NSMutableSet set];
                                          for (ISAAdFormat *format in request.legacyAdFormats) {
                                            [foundTypes addObject:@(format.adFormatType)];
                                          }

                                          NSMutableSet<NSNumber *> *expectedTypes =
                                              [[NSMutableSet alloc] init];
                                          [expectedTypes addObject:@(ISAAdFormatTypeInterstitial)];
                                          [expectedTypes addObject:@(ISAAdFormatTypeRewarded)];
                                          [expectedTypes addObject:@(ISAAdFormatTypeBanner)];

                                          return [foundTypes isEqualToSet:expectedTypes];
                                        }]
                                             completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        void (^completionBlock)(BOOL, NSError *);
        [invocation getArgument:&completionBlock atIndex:3];
        if (completionBlock) {
          completionBlock(YES, nil);
        }
      });

  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray(
      [GADMediationAdapterIronSource class],
      @[ interstitialCredentials, rewardedCredentials, bannerCredentials ]);
  OCMVerifyAll(_adapter);
  OCMVerifyAll(levelPlayMock);
  OCMVerifyAll(ironSourceMock);
}

- (void)testInitIronSourceSDKWhenTagForChildIsTrueAndTagForUnderAgeIsTrue {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;

  AUTKMediationCredentials *interstitialCredentials = [[AUTKMediationCredentials alloc] init];
  // At least one of the credentials needs to contain an app key.
  interstitialCredentials.settings = @{GADMAdapterIronSourceAppKey : kAppKey1};
  interstitialCredentials.format = GADAdFormatInterstitial;
  AUTKMediationCredentials *rewardedCredentials = [[AUTKMediationCredentials alloc] init];
  rewardedCredentials.format = GADAdFormatRewarded;
  AUTKMediationCredentials *bannerCredentials = [[AUTKMediationCredentials alloc] init];
  bannerCredentials.format = GADAdFormatBanner;

  id levelPlayMock = OCMClassMock([LevelPlay class]);
  OCMExpect([levelPlayMock setMetaDataWithKey:@"is_child_directed" value:@"YES"]);

  id ironSourceMock = OCMClassMock([IronSourceAds class]);

  OCMExpect(ClassMethod([ironSourceMock initWithRequest:[OCMArg checkWithBlock:^(id value) {
                                          ISAInitRequest *request = (ISAInitRequest *)value;
                                          if (![request.appKey isEqualToString:kAppKey1]) {
                                            return NO;
                                          }

                                          NSMutableSet *foundTypes = [NSMutableSet set];
                                          for (ISAAdFormat *format in request.legacyAdFormats) {
                                            [foundTypes addObject:@(format.adFormatType)];
                                          }

                                          NSMutableSet<NSNumber *> *expectedTypes =
                                              [[NSMutableSet alloc] init];
                                          [expectedTypes addObject:@(ISAAdFormatTypeInterstitial)];
                                          [expectedTypes addObject:@(ISAAdFormatTypeRewarded)];
                                          [expectedTypes addObject:@(ISAAdFormatTypeBanner)];

                                          return [foundTypes isEqualToSet:expectedTypes];
                                        }]
                                             completion:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        void (^completionBlock)(BOOL, NSError *);
        [invocation getArgument:&completionBlock atIndex:3];
        if (completionBlock) {
          completionBlock(YES, nil);
        }
      });

  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray(
      [GADMediationAdapterIronSource class],
      @[ interstitialCredentials, rewardedCredentials, bannerCredentials ]);
  OCMVerifyAll(_adapter);
  OCMVerifyAll(levelPlayMock);
  OCMVerifyAll(ironSourceMock);
}

- (void)testSetUpInitializesWithAnyOneAppKeyWhenThereAreMultipleAppKeys {
  AUTKMediationCredentials *interstitialCredentials = [[AUTKMediationCredentials alloc] init];
  interstitialCredentials.settings = @{GADMAdapterIronSourceAppKey : kAppKey1};
  interstitialCredentials.format = GADAdFormatInterstitial;
  AUTKMediationCredentials *rewardedCredentials = [[AUTKMediationCredentials alloc] init];
  rewardedCredentials.settings = @{GADMAdapterIronSourceAppKey : kAppKey2};
  rewardedCredentials.format = GADAdFormatRewarded;
  AUTKMediationCredentials *bannerCredentials = [[AUTKMediationCredentials alloc] init];
  bannerCredentials.format = GADAdFormatBanner;
  GADMediationAdapterSetUpCompletionBlock completionBlock =
      [OCMArg invokeBlockWithArgs:[NSNull null], nil];
  OCMExpect([_adapter initIronSourceSDKWithAppKey:[OCMArg checkWithBlock:^(id value) {
                        return ([@[ kAppKey1, kAppKey2 ] containsObject:value]);
                      }]
                                       forAdUnits:[OCMArg any]
                                completionHandler:completionBlock])
      .andDo(nil);

  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray(
      [GADMediationAdapterIronSource class],
      @[ interstitialCredentials, rewardedCredentials, bannerCredentials ]);
  OCMVerifyAll(_adapter);
}

- (void)testSetUpFailsWithNoAppKey {
  AUTKMediationCredentials *interstitialCredentials = [[AUTKMediationCredentials alloc] init];
  interstitialCredentials.format = GADAdFormatInterstitial;
  AUTKMediationCredentials *rewardedCredentials = [[AUTKMediationCredentials alloc] init];
  rewardedCredentials.format = GADAdFormatRewarded;
  AUTKMediationCredentials *bannerCredentials = [[AUTKMediationCredentials alloc] init];
  bannerCredentials.format = GADAdFormatBanner;
  NSError *expectedError =
      [NSError errorWithDomain:GADMAdapterIronSourceErrorDomain
                          code:GADMAdapterIronSourceErrorInvalidServerParameters
                      userInfo:nil];

  AUTKWaitAndAssertAdapterSetUpFailureWithCredentialsArray(
      [GADMediationAdapterIronSource class],
      @[ interstitialCredentials, rewardedCredentials, bannerCredentials ], expectedError);
}

@end
