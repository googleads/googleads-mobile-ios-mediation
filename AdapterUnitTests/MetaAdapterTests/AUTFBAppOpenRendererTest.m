#import "Bidding/GADFBAppOpenRenderer.h"

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import <GoogleMobileAds/GoogleMobileAds.h>
#import "AUTTestUtils.h"
#import "GADMediation+AdapterUnitTests.h"
#import "FBAudienceNetwork/FBAudienceNetwork.h"
#import "GADMAdapterFacebookConstants.h"
#import "GADMediationAdapterFacebook.h"
#import "GADFBUtils.h"



// Category to expose private FBInterstitialAdDelegate methods for testing.
@interface GADFBAppOpenRenderer (TestExposedMethods) <FBInterstitialAdDelegate>
@end

@implementation GADFBAppOpenRenderer (TestExposedMethods)
@end

@interface AUTFBAppOpenRendererTest : XCTestCase
@end

/**
 * Returns a correctly configured app open ad configuration.
 */
GADMediationAppOpenAdConfiguration *_Nonnull AUTGADMediationAppOpenAdConfiguration() {
  GADMediationCredentials *credentials = [[GADMediationCredentials alloc]
      initWithAdFormat:GADAdFormatAppOpen
           credentials:@{GADMAdapterFacebookBiddingPubID : GADMAdapterFacebookBiddingPubID}];
  return [[GADMediationAppOpenAdConfiguration alloc] initWithAdConfiguration:nil
                                                                   targeting:nil
                                                                 credentials:credentials
                                                                      extras:nil];
}

@implementation AUTFBAppOpenRendererTest {
  GADFBAppOpenRenderer *_renderer;
  id _mockFBInterstitialAdClass;
}

- (void)setUp {
  [super setUp];
  _renderer = [[GADFBAppOpenRenderer alloc] init];
  _mockFBInterstitialAdClass = OCMClassMock([FBInterstitialAd class]);

  OCMStub([_mockFBInterstitialAdClass alloc]).andReturn(_mockFBInterstitialAdClass);
  OCMStub([_mockFBInterstitialAdClass initWithPlacementID:[OCMArg any]])
      .andReturn(_mockFBInterstitialAdClass);
}

- (void)tearDown {
  [_mockFBInterstitialAdClass stopMocking];
  _mockFBInterstitialAdClass = nil;
  [super tearDown];
}


- (void)testRenderAppOpen {

  __block BOOL completionHandlerInvoked = NO;
  __block id<GADMediationAppOpenAdEventDelegate> eventDelegateMock = nil;

  GADMediationAppOpenLoadCompletionHandler handler =
      ^(id<GADMediationAppOpenAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(ad);
        XCTAssertTrue([ad conformsToProtocol:@protocol(GADMediationAppOpenAd)]);
        XCTAssertTrue([ad isKindOfClass:[GADFBAppOpenRenderer class]]);
        completionHandlerInvoked = YES;
        eventDelegateMock = OCMProtocolMock(@protocol(GADMediationAppOpenAdEventDelegate));
        return eventDelegateMock;
      };

  OCMStub([_mockFBInterstitialAdClass loadAdWithBidPayload:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        [(id<FBInterstitialAdDelegate>)_renderer interstitialAdDidLoad:_mockFBInterstitialAdClass];
      });

  [_renderer renderAppOpenForAdConfiguration:AUTGADMediationAppOpenAdConfiguration()
                           completionHandler:handler];

  XCTAssertTrue(completionHandlerInvoked);
  XCTAssertNotNil(eventDelegateMock);
}


- (void)testRenderAppOpenFailureWithAdDidNotLoad {
  __block BOOL completionHandlerInvoked = NO;
  NSError *expectedError = GADFBErrorWithCodeAndDescription(GADFBErrorAdNotValid, @"Test Failure");

  GADMediationAppOpenLoadCompletionHandler handler =
      ^(id<GADMediationAppOpenAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, expectedError.code);
        XCTAssertNil(ad);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationAppOpenAdEventDelegate));
      };

  OCMStub([_mockFBInterstitialAdClass loadAdWithBidPayload:[OCMArg any]]);

  [_renderer renderAppOpenForAdConfiguration:AUTGADMediationAppOpenAdConfiguration()
                           completionHandler:handler];

  [_renderer interstitialAd:_mockFBInterstitialAdClass didFailWithError:expectedError];

  XCTAssertTrue(completionHandlerInvoked);
}


- (void)testRenderAppOpenFailureWithCredentialsWithoutPubID {
  GADMediationCredentials *credentials =
      [[GADMediationCredentials alloc] initWithAdFormat:GADAdFormatAppOpen credentials:@{}];
  GADMediationAppOpenAdConfiguration *adConfiguration =
      [[GADMediationAppOpenAdConfiguration alloc] initWithAdConfiguration:nil
                                                                targeting:nil
                                                              credentials:credentials
                                                                   extras:nil];

  __block BOOL completionHandlerInvoked = NO;
  GADMediationAppOpenLoadCompletionHandler handler =
      ^(id<GADMediationAppOpenAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertEqual(error.code, GADFBErrorInvalidRequest);
        XCTAssertNil(ad);
        completionHandlerInvoked = YES;
        return OCMProtocolMock(@protocol(GADMediationAppOpenAdEventDelegate));
      };

  // Expect no interaction with FBInterstitialAd because the placement ID is missing.
  OCMReject([_mockFBInterstitialAdClass loadAdWithBidPayload:[OCMArg any]]);

  [_renderer renderAppOpenForAdConfiguration:adConfiguration completionHandler:handler];
  XCTAssertTrue(completionHandlerInvoked);
}


- (void)testAppOpenClick {
  id<GADMediationAppOpenAdEventDelegate> delegateMock =
      OCMProtocolMock(@protocol(GADMediationAppOpenAdEventDelegate));
  __block BOOL clicked = NO;
  OCMStub([delegateMock reportClick]).andDo(^(NSInvocation *invocation) {
    clicked = YES;
  });

  GADMediationAppOpenLoadCompletionHandler handler =
      ^(id<GADMediationAppOpenAd> _Nullable ad, NSError *_Nullable error) {
        return delegateMock;
      };
  [_renderer renderAppOpenForAdConfiguration:AUTGADMediationAppOpenAdConfiguration()
                           completionHandler:handler];
  [_renderer interstitialAdDidLoad:_mockFBInterstitialAdClass];


  [_renderer interstitialAdDidClick:_mockFBInterstitialAdClass];

  XCTAssertTrue(clicked);
}


- (void)testAppOpenImpressionReport {
  id<GADMediationAppOpenAdEventDelegate> delegateMock =
      OCMProtocolMock(@protocol(GADMediationAppOpenAdEventDelegate));
  __block BOOL impressionRecorded = NO;
  OCMStub([delegateMock reportImpression]).andDo(^(NSInvocation *invocation) {
    impressionRecorded = YES;
  });

  GADMediationAppOpenLoadCompletionHandler handler =
      ^(id<GADMediationAppOpenAd> _Nullable ad, NSError *_Nullable error) {
        return delegateMock;
      };
  [_renderer renderAppOpenForAdConfiguration:AUTGADMediationAppOpenAdConfiguration()
                           completionHandler:handler];

  [_renderer interstitialAdDidLoad:_mockFBInterstitialAdClass];

  [_renderer interstitialAdWillLogImpression:_mockFBInterstitialAdClass];

  XCTAssertTrue(impressionRecorded);
}


- (void)testAppOpenPresentFromViewController {

  id<GADMediationAppOpenAdEventDelegate> delegateMock =
      OCMProtocolMock(@protocol(GADMediationAppOpenAdEventDelegate));
  __block BOOL willPresentFullScreenView = NO;
  __block BOOL willDismissFullScreenView = NO;
  __block BOOL didDismissFullScreenView = NO;

  OCMStub([delegateMock willPresentFullScreenView]).andDo(^(NSInvocation *invocation) {
    willPresentFullScreenView = YES;
  });
  OCMStub([delegateMock willDismissFullScreenView]).andDo(^(NSInvocation *invocation) {
    willDismissFullScreenView = YES;
  });
  OCMStub([delegateMock didDismissFullScreenView]).andDo(^(NSInvocation *invocation) {
    didDismissFullScreenView = YES;
  });

  __block id<GADMediationAppOpenAd> mediationAppOpenAd;
  GADMediationAppOpenLoadCompletionHandler handler =
      ^(id<GADMediationAppOpenAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertTrue([ad conformsToProtocol:@protocol(GADMediationAppOpenAd)]);
        mediationAppOpenAd = (id<GADMediationAppOpenAd>)ad;
        return delegateMock;
      };

  [_renderer renderAppOpenForAdConfiguration:AUTGADMediationAppOpenAdConfiguration()
                           completionHandler:handler];
  [_renderer interstitialAdDidLoad:_mockFBInterstitialAdClass];
  OCMStub([(FBInterstitialAd *)_mockFBInterstitialAdClass showAdFromRootViewController:[OCMArg any]]).andReturn(YES);

  UIViewController *viewController = [[UIViewController alloc] init];
  [mediationAppOpenAd presentFromViewController:viewController];
  XCTAssertTrue(willPresentFullScreenView);

  [_renderer interstitialAdWillClose:_mockFBInterstitialAdClass];
  XCTAssertTrue(willDismissFullScreenView);

  [_renderer interstitialAdDidClose:_mockFBInterstitialAdClass];
  XCTAssertTrue(didDismissFullScreenView);

  OCMVerify([(FBInterstitialAd *)_mockFBInterstitialAdClass showAdFromRootViewController:viewController]);
}


- (void)testAppOpenPresentFromViewControllerFailure {
  id<GADMediationAppOpenAdEventDelegate> delegateMock =
      OCMProtocolMock(@protocol(GADMediationAppOpenAdEventDelegate));
  __block BOOL didFailToPresent = NO;
  OCMStub([delegateMock didFailToPresentWithError:[OCMArg checkWithBlock:^BOOL(NSError *error) {
                          return error.code == GADFBErrorAdNotValid;
                        }]])
      .andDo(^(NSInvocation *invocation) {
        didFailToPresent = YES;
      });

  __block id<GADMediationAppOpenAd> mediationAppOpenAd;
  GADMediationAppOpenLoadCompletionHandler handler =
      ^(id<GADMediationAppOpenAd> _Nullable ad, NSError *_Nullable error) {
        XCTAssertTrue([ad conformsToProtocol:@protocol(GADMediationAppOpenAd)]);
        mediationAppOpenAd = (id<GADMediationAppOpenAd>)ad;
        return delegateMock;
      };

  [_renderer renderAppOpenForAdConfiguration:AUTGADMediationAppOpenAdConfiguration()
                           completionHandler:handler];

  [_renderer interstitialAdDidLoad:_mockFBInterstitialAdClass];

  OCMStub([(FBInterstitialAd *)_mockFBInterstitialAdClass showAdFromRootViewController:[OCMArg any]]).andReturn(NO);

  UIViewController *viewController = [[UIViewController alloc] init];
  [mediationAppOpenAd presentFromViewController:viewController];

  XCTAssertTrue(didFailToPresent);

  OCMVerify([(FBInterstitialAd *)_mockFBInterstitialAdClass showAdFromRootViewController:viewController]);
}


@end
