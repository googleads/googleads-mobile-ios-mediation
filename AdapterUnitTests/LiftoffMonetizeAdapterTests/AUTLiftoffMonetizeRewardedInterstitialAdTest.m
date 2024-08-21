#import "GADMediationAdapterVungle.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKMediationRewardedAdLoadAssertions.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

@interface AUTLiftoffMonetizeRewardedInterstitialAdTest : XCTestCase

@end

@implementation AUTLiftoffMonetizeRewardedInterstitialAdTest {
  /// An adapter instance that is used to test loading a rewarded interstitial ad.
  GADMediationAdapterVungle *_adapter;
}

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterVungle alloc] init];
}

- (void)testLoadRewardedInterstitialAdLoadsRewardedAd {
  GADMediationRewardedLoadCompletionHandler completionHandler =
      ^(id<GADMediationRewardedAd> _Nullable ad, NSError *_Nullable error) {
        return [[AUTKMediationRewardedAdEventDelegate alloc] init];
      };
  AUTKMediationRewardedAdConfiguration *configuration =
      [[AUTKMediationRewardedAdConfiguration alloc] init];
  id adapterMock = OCMPartialMock(_adapter);
  OCMStub([adapterMock loadRewardedAdForAdConfiguration:configuration
                                      completionHandler:completionHandler])
      .andDo(nil);

  [_adapter loadRewardedInterstitialAdForAdConfiguration:configuration
                                       completionHandler:completionHandler];

  // Here, just checking that loadRewardedAd is called. Tests for loadRewardedAd are in
  // AUTLiftoffMonetizeRTBRewardedAdTests and AUTLiftoffMonetizeWaterfallRewardedAdTests.
  OCMVerify([adapterMock loadRewardedAdForAdConfiguration:configuration
                                        completionHandler:completionHandler]);
}

@end
