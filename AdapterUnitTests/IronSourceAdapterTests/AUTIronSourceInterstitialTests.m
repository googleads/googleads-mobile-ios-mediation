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
static NSString *_Nonnull kIronSourceWatermarkBase64 =
    @"iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAADTUlEQVR42u2cC2sTQRSFE6qoaKGo+MAUk+"
    @"ymtex2d5NIfaRoUFG0tEVD/P//"
    @"5DhnbaDWtklKHntnzgfzA3bO7Jx779yZWk0IIYQQQgghhBBCCCG8ZoyNLMP9KMOTKMV21EMc50jiFFGzQLOZ4FmS4IEma"
    @"kk03uHeboZWO8dhlOOnm/zfM40C43aGz60UGUWikJrNG8IV3ulhjxM6swBTBsVsd/F6p4/HmuE5/"
    @"oZWjgOu7kUJcdnY6eJLnKGhGb+"
    @"C5hB3OwWKTobRMoW4TJhXB3gkBc5BU57LG5YwuJUNh7gVfLRUbk9rFOIfUQr8aCR4GKxXlPt4RcSYjHLLDM1bGOW4jz6p"
    @"mhgX/pZOGOZdYMvlE7+qLEYwojCSqvqfcXEwIfVSDEYwVfSMWbJ9DxNJ1KMCA3NiTEaG4zjGHW/"
    @"kYNHPrBiTsotbUF6I0e/jtjXfuDKrz/"
    @"HCfhaeIfVBjLOo68h0xZhnFquuTSkUvgYnxhufxJiUVxik2DNyF5Usu4S+"
    @"xqjLXmml1cVLL8XgX5Lj0J6ZW847ZkgWTeUlzMp9M/P/"
    @"8pIU23b8w+2xPotRCrKPviVBegEI8t2Sf7z3XRD6iJnwd5GtO5UuzQ+"
    @"waUOQAkchCMLOSRseEoAYpoqNoQjCPmIJohLKjYqKoxAEMdPxGIqp83jBxpZVYBiCIJYy9bcB+"
    @"MexndJ7isx3QZj8WhLkaQBJYWroNAR15yOnnucgW6YOqHjfwtvtqjxXN8ZeH8+9LZl0kdtrORljw0qX+"
    @"9yCWO319alJ7pyZfzLbl+VTG+lkmL/"
    @"yxvsVvojBxr+"
    @"afVwInOObB2KMzNSupsFnLawLwupDzSfKx2GsCtLFR5P9vDOck5hrvma7j78PCrjchGGjoYruiffPPPEmLksPFkw8mFeD"
    @"SlGq3Lvl/"
    @"owAH6RBvYoFSC4ULphaqJSJY0Uu9nCBeBlNzQu3BzchX9e5RZnpsVol7ARcpeHzja5Whl29xTjFW7hal9lKdHYskLD4qf"
    @"meQxiezfPZv4X8NQVOmZjy5pNejluE+Q+wyVdKO/v4UPrNNWV9bkXMsNkfxtO9v/"
    @"mEzHolsALLMwpOelmNlR8IIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGE3/wBjW9SKC7yayAAAAAASUVORK5CYII=";

@interface AUTIronSourceInterstitialTests : XCTestCase
@end

@implementation AUTIronSourceInterstitialTests {
  /// An adapter instance that is used to test loading an interstitial ad.
  GADMediationAdapterIronSource *_adapter;

  /// A  mock of the adapter to verify init method call on the adapter.
  id _adapterMock;

  /// A mock instance of IronSource.
  id _ironSourceMock;

  /// A partial mock instance of GADMAdapterIronSourceInterstitialAd.
  id _adapterInterstitialAd;

  /// Instance ID.
  __block NSString *_instanceId;
}

- (void)setUp {
  [super setUp];

  _adapter = [[GADMediationAdapterIronSource alloc] init];

  _adapterMock = OCMClassMock([GADMediationAdapterIronSource class]);
  OCMStub([_adapterMock alloc]).andReturn(_adapterMock);

  _ironSourceMock = OCMClassMock([IronSource class]);

  OCMStub([_ironSourceMock setISDemandOnlyInterstitialDelegate:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&kIronSourceInterstitialDelegate atIndex:2];
      });

  _adapterInterstitialAd = OCMPartialMock([GADMAdapterIronSourceInterstitialAd alloc]);
  OCMStub([_adapterInterstitialAd alloc]).andReturn(_adapterInterstitialAd);
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
  configuration.watermark = [[NSData alloc] initWithBase64EncodedString:kIronSourceWatermarkBase64
                                                                options:0];
  OCMExpect([_ironSourceMock loadISDemandOnlyInterstitial:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&self->_instanceId atIndex:2];
        XCTAssertEqualObjects(self->_instanceId, expectedInstanceId);
        [kIronSourceInterstitialDelegate interstitialDidLoad:self->_instanceId];
      });
  OCMExpect(ClassMethod([_ironSourceMock setMetaDataWithKey:@"google_water_mark"
                                                      value:kIronSourceWatermarkBase64]));

  id<GADMediationInterstitialAdEventDelegate> eventDelegate =
      AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);
  OCMVerify([_adapterMock initIronSourceSDKWithAppKey:kAppKey
                                           forAdUnits:[OCMArg checkWithBlock:^(id value) {
                                             NSSet *set = (NSSet *)value;
                                             return (BOOL)([set containsObject:IS_INTERSTITIAL] &&
                                                           [set count] == 1);
                                           }]]);
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

- (void)testLoadInterstitialWithBidResponse {
  AUTKMediationInterstitialAdConfiguration *configuration =
      [[AUTKMediationInterstitialAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  configuration.credentials = credentials;
  configuration.bidResponse = @"bidResponse";
  OCMExpect([_ironSourceMock loadISDemandOnlyInterstitialWithAdm:kInstanceId adm:@"bidResponse"])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&self->_instanceId atIndex:2];
        [kIronSourceInterstitialDelegate interstitialDidLoad:self->_instanceId];
      });

  AUTKWaitAndAssertLoadInterstitialAd(_adapter, configuration);
  OCMVerify([_adapterMock initIronSourceSDKWithAppKey:kAppKey
                                           forAdUnits:[OCMArg checkWithBlock:^(id value) {
                                             NSSet *set = (NSSet *)value;
                                             return (BOOL)([set containsObject:IS_INTERSTITIAL] &&
                                                           [set count] == 1);
                                           }]]);
  OCMVerifyAll(_ironSourceMock);
  OCMVerify([(GADMAdapterIronSourceInterstitialAd *)_adapterInterstitialAd
      setState:GADMAdapterIronSourceInstanceStateLocked]);
  OCMVerify([(GADMAdapterIronSourceInterstitialAd *)_adapterInterstitialAd
      setState:GADMAdapterIronSourceInstanceStateCanLoad]);
  XCTAssertEqual([_adapterInterstitialAd getState], GADMAdapterIronSourceInstanceStateCanLoad);
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
  OCMVerify([_adapterMock initIronSourceSDKWithAppKey:kAppKey
                                           forAdUnits:[OCMArg checkWithBlock:^(id value) {
                                             NSSet *set = (NSSet *)value;
                                             return (BOOL)([set containsObject:IS_INTERSTITIAL] &&
                                                           [set count] == 1);
                                           }]]);
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
