#import "AUTUnityTestCase.h"

#import <OCMock/OCMock.h>
#import <UnityAds/UnityAds.h>

@implementation AUTUnityTestCase

- (void)setUp {
  [super setUp];
  _adapter = [[GADMediationAdapterUnity alloc] init];
  _unityAdsClassMock = OCMClassMock([UnityAds class]);
  OCMStub(ClassMethod([_unityAdsClassMock initialize:AUTUnityGameID
                                            testMode:NO
                              initializationDelegate:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id<UnityAdsInitializationDelegate> initializationDelegate = nil;
        [invocation getArgument:&initializationDelegate atIndex:4];
        [initializationDelegate initializationComplete];
      });
}

@end
