#import "GADMAdapterIronSourceRewardedAd.h"
#import "GADMediationAdapterIronSource.h"
#import "GADMAdapterIronSourceConstants.h"

#import <IronSource/IronSource.h>
#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationRewardedAdLoadAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

static NSString *const kAppKey = @"AppKey";
static NSString *const kInstanceId = @"1234";
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

/// An instance of GADMAdapterIronSourceRewardedAdDelegate.
static id<ISDemandOnlyRewardedVideoDelegate> _ironSourceRewardedAdDelegate;

@interface AUTIronSourceRewardedAdTests : XCTestCase

@end

@implementation AUTIronSourceRewardedAdTests {
  /// An adapter instance that is used to test loading an rewarded ad.
  GADMediationAdapterIronSource *_adapter;

  /// A  mock of the adapter to verify init method call on the adapter.
  id _adapterMock;

  /// A mock instance of IronSource.
  id _ironSourceMock;

  /// A partial mock instance of GADMAdapterIronSourceRewardedAd.
  id _adapterRewardedAd;

  /// Instance ID.
  __block NSString *_instanceId;
}

- (void)setUp {
  [super setUp];

  _adapter = [[GADMediationAdapterIronSource alloc] init];

  _adapterMock = OCMClassMock([GADMediationAdapterIronSource class]);
  OCMStub([_adapterMock alloc]).andReturn(_adapterMock);

  _ironSourceMock = OCMClassMock([IronSource class]);

  OCMStub([_ironSourceMock setISDemandOnlyRewardedVideoDelegate:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&_ironSourceRewardedAdDelegate atIndex:2];
      });

  _adapterRewardedAd = OCMPartialMock([GADMAdapterIronSourceRewardedAd alloc]);
  OCMStub([_adapterRewardedAd alloc]).andReturn(_adapterRewardedAd);
}

- (void)tearDown {
  [_adapterMock stopMocking];
  [_adapterRewardedAd stopMocking];
}

- (AUTKMediationRewardedAdEventDelegate *)
    checkLoadRewardedAdSuccessForSettings:(NSDictionary<NSString *, id> *)settings
                   withExpectedInstanceId:(NSString *)expectedInstanceId {
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = settings;
  configuration.credentials = credentials;
  configuration.watermark = [[NSData alloc] initWithBase64EncodedString:kIronSourceWatermarkBase64
                                                                options:0];
  OCMExpect([_ironSourceMock loadISDemandOnlyRewardedVideo:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&self->_instanceId atIndex:2];
        XCTAssertEqualObjects(self->_instanceId, expectedInstanceId);
        [_ironSourceRewardedAdDelegate rewardedVideoDidLoad:self->_instanceId];
      });
  OCMExpect(ClassMethod([_ironSourceMock setMetaDataWithKey:@"google_water_mark"
                                                      value:kIronSourceWatermarkBase64]));

  id<GADMediationRewardedAdEventDelegate> eventDelegate =
      AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);
  OCMVerify([_adapterMock initIronSourceSDKWithAppKey:kAppKey
                                           forAdUnits:[OCMArg checkWithBlock:^(id value) {
                                             NSSet *set = (NSSet *)value;
                                             return (BOOL)([set containsObject:IS_REWARDED_VIDEO] &&
                                                           [set count] == 1);
                                           }]]);
  OCMVerifyAll(_ironSourceMock);
  OCMVerify([(GADMAdapterIronSourceRewardedAd *)_adapterRewardedAd
      setState:GADMAdapterIronSourceInstanceStateLocked]);
  OCMVerify([(GADMAdapterIronSourceRewardedAd *)_adapterRewardedAd
      setState:GADMAdapterIronSourceInstanceStateCanLoad]);
  XCTAssertEqual([_adapterRewardedAd getState], GADMAdapterIronSourceInstanceStateCanLoad);
  return eventDelegate;
}

- (void)testLoadRewardedAdSuccess {
  NSDictionary<NSString *, id> *settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  [self checkLoadRewardedAdSuccessForSettings:settings withExpectedInstanceId:kInstanceId];
}

- (void)testLoadRwardedAdWithBidResponse {
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};;
  configuration.credentials = credentials;
  configuration.bidResponse = @"bidResponse";

  OCMExpect([_ironSourceMock loadISDemandOnlyRewardedVideoWithAdm:kInstanceId adm:@"bidResponse"])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&self->_instanceId atIndex:2];
        [_ironSourceRewardedAdDelegate rewardedVideoDidLoad:self->_instanceId];
      });

  AUTKWaitAndAssertLoadRewardedAd(_adapter, configuration);
  OCMVerify([_adapterMock initIronSourceSDKWithAppKey:kAppKey
                                           forAdUnits:[OCMArg checkWithBlock:^(id value) {
                                             NSSet *set = (NSSet *)value;
                                             return (BOOL)([set containsObject:IS_REWARDED_VIDEO] &&
                                                           [set count] == 1);
                                           }]]);
  OCMVerifyAll(_ironSourceMock);
  OCMVerify([(GADMAdapterIronSourceRewardedAd *)_adapterRewardedAd
      setState:GADMAdapterIronSourceInstanceStateLocked]);
  OCMVerify([(GADMAdapterIronSourceRewardedAd *)_adapterRewardedAd
      setState:GADMAdapterIronSourceInstanceStateCanLoad]);
  XCTAssertEqual([_adapterRewardedAd getState], GADMAdapterIronSourceInstanceStateCanLoad);
}

- (void)testLoadRewardedAdUsesDefaultInstanceIdWhenNoInstanceIdInAdConfig {
  NSDictionary<NSString *, id> *settings = @{GADMAdapterIronSourceAppKey : kAppKey};
  [self checkLoadRewardedAdSuccessForSettings:settings
                       withExpectedInstanceId:GADMIronSourceDefaultInstanceId];
}

- (void)testLoadFailureWithEmptyAppKey {
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterIronSourceAppKey : @""};
  configuration.credentials = credentials;

  NSError *expectedError =
      [NSError errorWithDomain:GADMAdapterIronSourceErrorDomain
                          code:GADMAdapterIronSourceErrorInvalidServerParameters
                      userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureWithNoAppKey {
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  configuration.credentials = credentials;

  NSError *expectedError =
      [NSError errorWithDomain:GADMAdapterIronSourceErrorDomain
                          code:GADMAdapterIronSourceErrorInvalidServerParameters
                      userInfo:nil];
  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, expectedError);
}

- (void)testLoadFailureWhenIronSourceAdLoadFails {
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  configuration.credentials = credentials;
  __block NSString *instanceId;
  NSError *ironSourceAdLoadError =
      [NSError errorWithDomain:@"ironsource.domain"
                          code:1
                      userInfo:@{NSLocalizedDescriptionKey : @"Rewarded ad load failed."}];
  OCMExpect([_ironSourceMock loadISDemandOnlyRewardedVideo:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&instanceId atIndex:2];
        [_ironSourceRewardedAdDelegate rewardedVideoDidFailToLoadWithError:ironSourceAdLoadError
                                                                instanceId:instanceId];
      });

  AUTKWaitAndAssertLoadRewardedAdFailure(_adapter, configuration, ironSourceAdLoadError);
  OCMVerify([_adapterMock initIronSourceSDKWithAppKey:kAppKey
                                           forAdUnits:[OCMArg checkWithBlock:^(id value) {
                                             NSSet *set = (NSSet *)value;
                                             return (BOOL)([set containsObject:IS_REWARDED_VIDEO] &&
                                                           [set count] == 1);
                                           }]]);
  OCMVerifyAll(_ironSourceMock);
  OCMVerify([(GADMAdapterIronSourceRewardedAd *)_adapterRewardedAd
      setState:GADMAdapterIronSourceInstanceStateLocked]);
  OCMVerify([(GADMAdapterIronSourceRewardedAd *)_adapterRewardedAd
      setState:GADMAdapterIronSourceInstanceStateCanLoad]);
  XCTAssertEqual([_adapterRewardedAd getState], GADMAdapterIronSourceInstanceStateCanLoad);
}

- (AUTKMediationRewardedAdEventDelegate *)loadRewardedAdAndGetEventDelegate {
  NSDictionary<NSString *, id> *settings =
      @{GADMAdapterIronSourceAppKey : kAppKey, GADMAdapterIronSourceInstanceId : kInstanceId};
  return [self checkLoadRewardedAdSuccessForSettings:settings withExpectedInstanceId:kInstanceId];
}

- (void)testRewardedAdPresentInvokesShowOnIronSourceSdk {
  // Load IronSource rewarded ad first.
  [self loadRewardedAdAndGetEventDelegate];
  UIViewController *rootViewController = [[UIViewController alloc] init];

  [_adapterRewardedAd presentFromViewController:rootViewController];

  OCMVerify([_ironSourceMock showISDemandOnlyRewardedVideo:rootViewController
                                                instanceId:_instanceId]);
}

- (void)
    testRewardedVideoDidOpenInvokesWillPresentFullScreenViewAndDidStartVideoAndReportImpression {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAdAndGetEventDelegate];
  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 0);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 0);

  [_ironSourceRewardedAdDelegate rewardedVideoDidOpen:_instanceId];

  XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didStartVideoInvokeCount, 1);
  XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1);
}

- (void)testRewardedVideoDidClickInvokesReportClick {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAdAndGetEventDelegate];
  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 0);

  [_ironSourceRewardedAdDelegate rewardedVideoDidClick:_instanceId];

  XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1);
}

- (void)testRewardedVideoDidCloseInvokesWillDismissFullScreenViewAndDidDismissFullScreenView {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAdAndGetEventDelegate];
  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 0);

  [_ironSourceRewardedAdDelegate rewardedVideoDidClose:_instanceId];

  XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1);
}

- (void)testRewardedVideoDidFailToShowInvokesDidFailToPresent {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAdAndGetEventDelegate];
  NSError *showError =
      [NSError errorWithDomain:@"ironsource.domain"
                          code:2
                      userInfo:@{
                        NSLocalizedDescriptionKey : @"IronSource rewarded ad presentation failed."
                      }];

  [_ironSourceRewardedAdDelegate rewardedVideoDidFailToShowWithError:showError
                                                          instanceId:_instanceId];

  NSError *presentationError = eventDelegate.didFailToPresentError;
  XCTAssertEqual(presentationError.domain, @"ironsource.domain");
  XCTAssertEqual(presentationError.code, 2);
  XCTAssertEqualObjects(presentationError.userInfo[NSLocalizedDescriptionKey],
                        @"IronSource rewarded ad presentation failed.");
}

- (void)testRewardedVideoAdRewardedInvokesDidEndVideoAndDidRewardUser {
  AUTKMediationRewardedAdEventDelegate *eventDelegate = [self loadRewardedAdAndGetEventDelegate];
  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 0);
  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 0);

  [_ironSourceRewardedAdDelegate rewardedVideoAdRewarded:_instanceId];

  XCTAssertEqual(eventDelegate.didEndVideoInvokeCount, 1);
  XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 1);
}

@end
