#import "GADMediationAdapterIronSource.h"

#import <IronSource/IronSource.h>
#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationBannerAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterIronSourceBannerAd.h"
#import "GADMAdapterIronSourceBannerAdDelegate.h"
#import "GADMAdapterIronSourceConstants.h"

@interface AUTIronSourceBannerTests : XCTestCase

@end

static NSString *const AUTIronSourceBannerTestsAppKey = @"app_key";
static NSString *const AUTIronSourceBannerTestsInstanceId = @"1234";

@implementation AUTIronSourceBannerTests {
  /// An adapter instance that is used to test loading a banner ad.
  GADMediationAdapterIronSource *_adapter;

  /// A mock instance of IronSource.
  id _ironSourceMock;

  /// A banner ad delegate.
  GADMAdapterIronSourceBannerAdDelegate *_bannerAdDelegate;

  /// Instance ID.
  __block NSString *_instanceID;

  /// Fake UIView to mimic a banner ad loaded by IronSource SDK.
  id _loadedBannerAd;
}

- (void)setUp {
  [super setUp];

  _adapter = [[GADMediationAdapterIronSource alloc] init];

  _ironSourceMock = OCMClassMock([IronSource class]);
  OCMStub(ClassMethod([_ironSourceMock initISDemandOnly:OCMOCK_ANY adUnits:@[ IS_BANNER ]]));
}

- (void)setUpIronSourceMethods {
  __block id<ISDemandOnlyBannerDelegate> loadDelegate = nil;

  OCMStub(ClassMethod([_ironSourceMock setISDemandOnlyBannerDelegate:OCMOCK_ANY
                                                       forInstanceId:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&loadDelegate atIndex:2];
        XCTAssertTrue([loadDelegate conformsToProtocol:@protocol(ISDemandOnlyBannerDelegate)]);

        self->_bannerAdDelegate = loadDelegate;
      });

  ISBannerSize *requestedAdSize = [[ISBannerSize alloc] initWithWidth:GADAdSizeBanner.size.width
                                                            andHeight:GADAdSizeBanner.size.height];
  OCMStub(ClassMethod([_ironSourceMock loadISDemandOnlyBannerWithInstanceId:OCMOCK_ANY
                                                             viewController:OCMOCK_ANY
                                                                       size:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&(self->_instanceID) atIndex:2];
        self->_loadedBannerAd = [[UIView alloc]
            initWithFrame:CGRectMake(0, 0, requestedAdSize.width, requestedAdSize.height)];
        [self->_bannerAdDelegate bannerDidLoad:self->_loadedBannerAd instanceId:self->_instanceID];
      });
}

- (nonnull AUTKMediationBannerAdEventDelegate *)loadBannerAd {
  [self setUpIronSourceMethods];

  // Test loading a banner ad.
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIronSourceAppKey : AUTIronSourceBannerTestsAppKey,
    GADMAdapterIronSourceInstanceId : AUTIronSourceBannerTestsInstanceId
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;
  AUTKMediationBannerAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);
  XCTAssertNotNil(delegate);

  return delegate;
}

- (void)testLoadBannerAd {
  [self loadBannerAd];
}

- (void)testLoadFailureWithoutAppKey {
  [self setUpIronSourceMethods];

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterIronSourceInstanceId : AUTIronSourceBannerTestsInstanceId};

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIronSourceErrorDomain
                                 code:GADMAdapterIronSourceErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureWithInvalidAdSize {
  [self setUpIronSourceMethods];

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIronSourceAppKey : AUTIronSourceBannerTestsAppKey,
    GADMAdapterIronSourceInstanceId : AUTIronSourceBannerTestsInstanceId
  };

  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterIronSourceErrorDomain
                                 code:GADMAdapterIronSourceErrorBannerSizeMismatch
                             userInfo:nil];
  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadWithoutInstanceId {
  [self setUpIronSourceMethods];

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterIronSourceAppKey : AUTIronSourceBannerTestsAppKey};
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;
  AUTKMediationBannerAdEventDelegate *delegate =
      AUTKWaitAndAssertLoadBannerAd(_adapter, configuration);
  XCTAssertNotNil(delegate);
  XCTAssertEqualObjects(self->_instanceID, GADMIronSourceDefaultInstanceId);
}

- (void)testLoadFailureWhenIronSourceAdLoadFails {
  OCMStub(ClassMethod([_ironSourceMock setISDemandOnlyBannerDelegate:OCMOCK_ANY
                                                       forInstanceId:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&self->_bannerAdDelegate atIndex:2];
      });
  NSError *ironSourceAdLoadError =
      [NSError errorWithDomain:@"ironsource.domain"
                          code:3
                      userInfo:@{NSLocalizedDescriptionKey : @"Banner ad load failed."}];
  OCMStub(ClassMethod([_ironSourceMock loadISDemandOnlyBannerWithInstanceId:OCMOCK_ANY
                                                             viewController:OCMOCK_ANY
                                                                       size:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&(self->_instanceID) atIndex:2];
        [self->_bannerAdDelegate bannerDidFailToLoadWithError:ironSourceAdLoadError
                                                   instanceId:self->_instanceID];
      });
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{
    GADMAdapterIronSourceAppKey : AUTIronSourceBannerTestsAppKey,
    GADMAdapterIronSourceInstanceId : AUTIronSourceBannerTestsInstanceId
  };
  AUTKMediationBannerAdConfiguration *configuration =
      [[AUTKMediationBannerAdConfiguration alloc] init];
  configuration.credentials = credentials;
  configuration.adSize = GADAdSizeBanner;

  AUTKWaitAndAssertLoadBannerAdFailure(_adapter, configuration, ironSourceAdLoadError);
}

- (void)testBannerImpressionDelegateCallback {
  AUTKMediationBannerAdEventDelegate *delegate = [self loadBannerAd];

  XCTAssertNotNil(_bannerAdDelegate);
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 0);
  [_bannerAdDelegate bannerDidShow:AUTIronSourceBannerTestsInstanceId];
  XCTAssertEqual(delegate.reportImpressionInvokeCount, 1);
}

- (void)testBannerClickDelegateCallback {
  AUTKMediationBannerAdEventDelegate *delegate = [self loadBannerAd];

  XCTAssertNotNil(_bannerAdDelegate);
  XCTAssertEqual(delegate.reportClickInvokeCount, 0);
  [_bannerAdDelegate didClickBanner:AUTIronSourceBannerTestsInstanceId];
  XCTAssertEqual(delegate.reportClickInvokeCount, 1);
}

- (void)testBannerCloseDelegateCallback {
  AUTKMediationBannerAdEventDelegate *delegate = [self loadBannerAd];

  XCTAssertNotNil(_bannerAdDelegate);
  XCTAssertEqual(delegate.willDismissFullScreenViewInvokeCount, 0);
  [_bannerAdDelegate bannerWillLeaveApplication:AUTIronSourceBannerTestsInstanceId];
  XCTAssertEqual(delegate.willDismissFullScreenViewInvokeCount, 1);
}

- (void)testViewReturnsLoadedIronSourceBannerAd {
  AUTKMediationBannerAdEventDelegate *delegate = [self loadBannerAd];
  id<GADMediationBannerAd> mediationBannerAd = delegate.bannerAd;

  XCTAssertEqual(mediationBannerAd.view, self->_loadedBannerAd);
}

@end
