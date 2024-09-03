#import "GADMAdapterIronSourceInterstitialAd.h"
#import "GADMediationAdapterIronSource.h"
#import "GADMAdapterIronSourceConstants.h"

#import <IronSource/IronSource.h>
#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationInterstitialAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

static NSString *const kAppKey = @"AppKey";
static NSString *const kInstanceId = @"1234";

/// An instance of GADMAdapterIronSourceInterstitialAdDelegate.
static id<ISDemandOnlyInterstitialDelegate> kIronSourceInterstitialDelegate;

@interface AUTIronSourceInterstitialTests : XCTestCase
@end

@implementation AUTIronSourceInterstitialTests {
  /// An adapter instance that is used to test loading an interstitial ad.
  GADMediationAdapterIronSource *_adapter;

  /// A  mock of the adapter to verify init method call on the adapter.
  id _adapterMock;

  /// A mock instance of IronSource.
  id _ironSourceMock;
    
  id _ironSourceAdsMock;

  id _request;

  /// A partial mock instance of GADMAdapterIronSourceInterstitialAd.
  id _adapterInterstitialAd;

  /// Instance ID.
  __block NSString *_instanceId;
}

- (void)setUp {

    [super setUp];
    _ironSourceMock = OCMClassMock([IronSource class]);
    _ironSourceAdsMock = OCMClassMock([IronSourceAds class]);
    OCMStub([_ironSourceMock setISDemandOnlyInterstitialDelegate:[OCMArg any]])
        .andDo(^(NSInvocation *invocation) {
          [invocation getArgument:&kIronSourceInterstitialDelegate atIndex:2];
        });
    
    _adapterInterstitialAd = OCMPartialMock([GADMAdapterIronSourceInterstitialAd alloc]);
    OCMStub([_adapterInterstitialAd alloc]).andReturn(_adapterInterstitialAd);

    _adapter = [[GADMediationAdapterIronSource alloc] init];
    
    // Create mocks for IronSource and IronSourceAds

    _request = [OCMArg any];  // Mock request argument
    
    // Define the mock's behavior for initWithRequest:completion:
    OCMStub([_ironSourceAdsMock initWithRequest:[OCMArg any] completion:([OCMArg invokeBlockWithArgs:@YES, [NSNull null], nil])]);
    
}

- (void)tearDown {
  [_adapterMock stopMocking];
  [_adapterInterstitialAd stopMocking];

  GADMAdapterIronSourceInterstitialAd *adInstance =
      [GADMAdapterIronSourceInterstitialAd delegateForKey:kInstanceId];
  [adInstance setState:GADMAdapterIronSourceInstanceStateStart];
}

- (AUTKMediationInterstitialAdEventDelegate *)
    checkLoadInterstitialSuccessForSettings:(NSDictionary<NSString *, id> *)settings
                     withExpectedInstanceId:(NSString *)expectedInstanceId {
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = settings;
  configuration.credentials = credentials;

  OCMExpect([_ironSourceMock loadISDemandOnlyInterstitial:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&self->_instanceId atIndex:2];
        XCTAssertEqualObjects(self->_instanceId, expectedInstanceId);
        [kIronSourceInterstitialDelegate interstitialDidLoad:self->_instanceId];
      });
 
  id<GADMediationInterstitialAdEventDelegate> eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);
    GADMediationAdapterSetUpCompletionBlock completionBlock = [OCMArg invokeBlockWithArgs:[NSNull null], nil];

   OCMVerifyAll(_ironSourceMock);
  OCMVerify([(GADMAdapterIronSourceInterstitialAd *)_adapterInterstitialAd
      setState:GADMAdapterIronSourceInstanceStateLocked]);
  OCMVerify([(GADMAdapterIronSourceInterstitialAd *)_adapterInterstitialAd
      setState:GADMAdapterIronSourceInstanceStateCanLoad]);
  XCTAssertEqual([_adapterInterstitialAd getState], GADMAdapterIronSourceInstanceStateCanLoad);
  return eventDelegate;
}

- (void)testLoadInterstitialSuccess {
  NSDictionary<NSString *, id> *settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  [self checkLoadInterstitialSuccessForSettings:settings withExpectedInstanceId:kInstanceId];
}

- (void)testLoadInterstitialUsesDefaultInstanceIdWhenNoInstanceIdInAdConfig {
  NSDictionary<NSString *, id> *settings = @{GADMAdapterIronSourceAppKey : kAppKey};
  [self checkLoadInterstitialSuccessForSettings:settings
                         withExpectedInstanceId:GADMIronSourceDefaultInstanceId];
}

- (void)testLoadFailureWithEmptyAppKey {
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterIronSourceAppKey : @""};
  configuration.credentials = credentials;

  NSError *expectedError =
      [NSError errorWithDomain:GADMAdapterIronSourceErrorDomain
                          code:GADMAdapterIronSourceErrorInvalidServerParameters
                      userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureWithNoAppKey {
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError =
      [NSError errorWithDomain:GADMAdapterIronSourceErrorDomain
                          code:GADMAdapterIronSourceErrorInvalidServerParameters
                      userInfo:nil];
  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureWhenIronSourceAdLoadFails {
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  configuration.credentials = credentials;
  __block NSString *instanceId;
  NSError *ironSourceAdLoadError =
      [NSError errorWithDomain:@"ironsource.domain"
                          code:1
                      userInfo:@{NSLocalizedDescriptionKey : @"Interstitial ad load failed."}];
  OCMExpect([_ironSourceMock loadISDemandOnlyInterstitial:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&instanceId atIndex:2];
        [kIronSourceInterstitialDelegate interstitialDidFailToLoadWithError:ironSourceAdLoadError
                                                                 instanceId:instanceId];
      });

  AUTKWaitAndAssertLoadInterstitialAdFailure(_adapter, configuration, ironSourceAdLoadError);
    GADMediationAdapterSetUpCompletionBlock completionBlock = [OCMArg invokeBlockWithArgs:[NSNull null], nil];

  OCMVerifyAll(_ironSourceMock);
  OCMVerify([(GADMAdapterIronSourceInterstitialAd *)_adapterInterstitialAd
      setState:GADMAdapterIronSourceInstanceStateLocked]);
  OCMVerify([(GADMAdapterIronSourceInterstitialAd *)_adapterInterstitialAd
      setState:GADMAdapterIronSourceInstanceStateCanLoad]);
  XCTAssertEqual([_adapterInterstitialAd getState], GADMAdapterIronSourceInstanceStateCanLoad);
}

- (AUTKMediationInterstitialAdEventDelegate *)loadInterstitialAndGetEventDelegate {
  NSDictionary<NSString *, id> *settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  return [self checkLoadInterstitialSuccessForSettings:settings withExpectedInstanceId:kInstanceId];
}

- (void)testInterstitialPresentInvokesPresentOnIronSourceSdk {
  // Load IronSource interstitial ad first.
  [self loadInterstitialAndGetEventDelegate];
  UIViewController *rootViewController = [[UIViewController alloc] init];

  [_adapterInterstitialAd presentFromViewController:rootViewController];

  OCMVerify([_ironSourceMock showISDemandOnlyInterstitial:rootViewController
                                               instanceId:_instanceId]);
}

- (void)testInterstitialDidOpenInvokesWillPresentFullScreenViewAndReportImpression {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadInterstitialAndGetEventDelegate];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);

  [kIronSourceInterstitialDelegate interstitialDidOpen:_instanceId];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testDidClickInterstitialInvokesReportClick {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadInterstitialAndGetEventDelegate];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);

  [kIronSourceInterstitialDelegate didClickInterstitial:_instanceId];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testInterstitialDidCloseInvokesWillDismissFullScreenViewAndDidDismissFullScreenView {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadInterstitialAndGetEventDelegate];
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);

  [kIronSourceInterstitialDelegate interstitialDidClose:_instanceId];

  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testInterstitialDidFailToShowInvokesDidFailToPresent {
  AUTKMediationInterstitialAdEventDelegate *eventDelegate =
      [self loadInterstitialAndGetEventDelegate];
  NSError *showError = [NSError
      errorWithDomain:@"ironsource.domain"
                 code:2
             userInfo:@{
               NSLocalizedDescriptionKey : @"IronSource interstitial ad presentation failed."
             }];

  [kIronSourceInterstitialDelegate interstitialDidFailToShowWithError:showError
                                                           instanceId:_instanceId];

  NSError *presentationError = eventDelegate.didFailToPresentError;
  XCTAssertEqual(presentationError.domain, @"ironsource.domain");
  XCTAssertEqual(presentationError.code, 2);
  XCTAssertEqualObjects(presentationError.userInfo[NSLocalizedDescriptionKey],
                        @"IronSource interstitial ad presentation failed.");
}

@end
