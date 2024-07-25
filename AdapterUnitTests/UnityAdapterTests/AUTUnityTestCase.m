#import "AUTUnityTestCase.h"

#import <OCMock/OCMock.h>
#import <UnityAds/UnityAds.h>

@implementation AUTUnityTestCase

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterUnity alloc] init];
  _unityAdsClassMock = OCMClassMock([UnityAds class]);
  // Because the Unity adapter ensures one time initialization with static dispatch_once_t, its
  // tests need to track whether the UnityAds SDK has been intialized by any previous tests.
  static BOOL AUTUnityAdsSDKInitialized = NO;
  OCMStub(ClassMethod([_unityAdsClassMock isInitialized])).andReturn(AUTUnityAdsSDKInitialized);
  OCMStub(ClassMethod([_unityAdsClassMock initialize:AUTUnityGameID
                                            testMode:NO
                              initializationDelegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        AUTUnityAdsSDKInitialized = YES;
        __unsafe_unretained id<UnityAdsInitializationDelegate> initializationDelegate = nil;
        [invocation getArgument:&initializationDelegate atIndex:4];
        [initializationDelegate initializationComplete];
      });
}

@end
