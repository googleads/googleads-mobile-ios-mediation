#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleConstants.h"

#import <OCMock/OCMock.h>
#import <VungleAdsSDK/VungleAdsSDK.h>
#import <XCTest/XCTest.h>

static NSString *const kAppID = @"AppId";

/// Tests for GADMAdapterVungleRouter.
@interface AUTLiftoffMonetizeRouterTests : XCTestCase

@end

@implementation AUTLiftoffMonetizeRouterTests {
  /// The unit under test.
  GADMAdapterVungleRouter *_vungleRouter;

  /// A mock of the VungleAds class.
  id _vungleAdsClassMock;

  /// Mock of the protocol GADMAdapterVungleDelegate.
  id _vungleDelegate;
}

- (void)setUp {
  _vungleRouter = [[GADMAdapterVungleRouter alloc] init];

  _vungleAdsClassMock = OCMClassMock([VungleAds class]);
  _vungleDelegate = OCMProtocolMock(@protocol(GADMAdapterVungleDelegate));
}

- (void)testInitInvokesDelegateWithInitilizedAsYesIfLiftoffSdkIsAlreadyInitialized {
  id vungleAdsClassMock = OCMClassMock([VungleAds class]);
  OCMStub([vungleAdsClassMock isInitialized]).andReturn(YES);

  [_vungleRouter initWithAppId:kAppID delegate:_vungleDelegate];

  OCMVerify([_vungleDelegate initialized:YES error:nil]);
}

- (void)testInitInvokesInitOnLiftoffSdk {
  [_vungleRouter initWithAppId:kAppID delegate:_vungleDelegate];

  OCMVerify([_vungleAdsClassMock initWithAppId:kAppID completion:[OCMArg any]]);
}

@end
