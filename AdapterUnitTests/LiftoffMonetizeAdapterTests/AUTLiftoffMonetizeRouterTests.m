// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"

#import <GoogleMobileAds/GoogleMobileAds.h>
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

  /// A mock of the VunglePrivacySettings class.
  id _vunglePrivacySettingsClassMock;

  /// Mock of the protocol GADMAdapterVungleDelegate.
  id _vungleDelegate;
}

- (void)setUp {
  [super setUp];
  _vungleRouter = [[GADMAdapterVungleRouter alloc] init];

  _vungleAdsClassMock = OCMClassMock([VungleAds class]);
  _vunglePrivacySettingsClassMock = OCMClassMock([VunglePrivacySettings class]);
  _vungleDelegate = OCMProtocolMock(@protocol(GADMAdapterVungleDelegate));
}

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
  GADMobileAds.sharedInstance.requestConfiguration.ageRestrictedTreatment =
      GADAgeRestrictedTreatmentUnspecified;

  [_vungleAdsClassMock stopMocking];
  [_vunglePrivacySettingsClassMock stopMocking];
  [super tearDown];
}

- (void)testSharedInstanceReturnsSameInstance {
  GADMAdapterVungleRouter *instance1 = [GADMAdapterVungleRouter sharedInstance];
  GADMAdapterVungleRouter *instance2 = [GADMAdapterVungleRouter sharedInstance];

  XCTAssertNotNil(instance1);
  XCTAssertEqualObjects(instance1, instance2);
}

- (void)testInitSetsIntegrationNameAndVersion {
  OCMStub([_vungleAdsClassMock isInitialized]).andReturn(YES);
  NSString *expectedVersion = [GADMAdapterVungleVersion stringByReplacingOccurrencesOfString:@"."
                                                                                  withString:@"_"];

  [_vungleRouter initWithAppId:kAppID delegate:_vungleDelegate];

  OCMVerify([_vungleAdsClassMock setIntegrationName:@"admob" version:expectedVersion]);
}

- (void)testInitInvokesDelegateWithInitializedAsYesIfLiftoffSdkIsAlreadyInitialized {
  OCMStub([_vungleAdsClassMock isInitialized]).andReturn(YES);

  [_vungleRouter initWithAppId:kAppID delegate:_vungleDelegate];

  OCMVerify([_vungleDelegate initialized:YES error:nil]);
}

- (void)testInitWhenLiftoffSdkIsNotInitializedUpdatesCOPPAStatusAndCallsInitWithAppId {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @1;
  OCMStub([_vungleAdsClassMock isInitialized]).andReturn(NO);

  [_vungleRouter initWithAppId:kAppID delegate:_vungleDelegate];

  OCMVerify([_vunglePrivacySettingsClassMock setCOPPAStatus:YES]);
  OCMVerify([_vungleAdsClassMock initWithAppId:kAppID completion:[OCMArg any]]);
}

- (void)testInitWhenLiftoffSdkInitSucceedsInvokesDelegateWithSuccess {
  OCMStub([_vungleAdsClassMock isInitialized]).andReturn(NO);
  OCMStub([_vungleAdsClassMock initWithAppId:kAppID completion:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        void (^completion)(NSError *_Nullable error);
        [invocation getArgument:&completion atIndex:3];
        if (completion) {
          completion(nil);
        }
      });

  [_vungleRouter initWithAppId:kAppID delegate:_vungleDelegate];

  OCMVerify([_vungleDelegate initialized:YES error:nil]);
}

- (void)testInitWhenLiftoffSdkInitFailsInvokesDelegateWithError {
  OCMStub([_vungleAdsClassMock isInitialized]).andReturn(NO);
  NSError *initError = [NSError errorWithDomain:@"com.vungle.error"
                                           code:100
                                       userInfo:@{NSLocalizedDescriptionKey : @"Init failed."}];
  OCMStub([_vungleAdsClassMock initWithAppId:kAppID completion:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        void (^completion)(NSError *_Nullable error);
        [invocation getArgument:&completion atIndex:3];
        if (completion) {
          completion(initError);
        }
      });

  [_vungleRouter initWithAppId:kAppID delegate:_vungleDelegate];

  OCMVerify([_vungleDelegate initialized:NO error:initError]);
}

- (void)testInitWithMultipleDelegatesWhenNotInitializedDispatchesCallbacksToAllDelegates {
  id delegate1 = OCMProtocolMock(@protocol(GADMAdapterVungleDelegate));
  id delegate2 = OCMProtocolMock(@protocol(GADMAdapterVungleDelegate));
  OCMStub([_vungleAdsClassMock isInitialized]).andReturn(NO);
  OCMStub([_vungleAdsClassMock initWithAppId:kAppID completion:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        void (^completion)(NSError *_Nullable error);
        [invocation getArgument:&completion atIndex:3];
        if (completion) {
          completion(nil);
        }
      });

  [_vungleRouter initWithAppId:kAppID delegate:delegate1];
  [_vungleRouter initWithAppId:kAppID delegate:delegate2];

  OCMVerify([delegate1 initialized:YES error:nil]);
  OCMVerify([delegate2 initialized:YES error:nil]);
}

- (void)testInitWithMultipleDelegatesWhenAlreadyInitializedDispatchesImmediateCallbacks {
  id delegate1 = OCMProtocolMock(@protocol(GADMAdapterVungleDelegate));
  id delegate2 = OCMProtocolMock(@protocol(GADMAdapterVungleDelegate));
  OCMStub([_vungleAdsClassMock isInitialized]).andReturn(YES);

  [_vungleRouter initWithAppId:kAppID delegate:delegate1];
  [_vungleRouter initWithAppId:kAppID delegate:delegate2];

  OCMVerify([delegate1 initialized:YES error:nil]);
  OCMVerify([delegate2 initialized:YES error:nil]);
}

- (void)testInitWithNilDelegateDoesNotCrashWhenAlreadyInitialized {
  OCMStub([_vungleAdsClassMock isInitialized]).andReturn(YES);

  XCTAssertNoThrow([_vungleRouter initWithAppId:kAppID delegate:nil]);
}

- (void)testInitWithNilDelegateDoesNotCrashWhenNotInitializedAndInitSucceeds {
  OCMStub([_vungleAdsClassMock isInitialized]).andReturn(NO);
  OCMStub([_vungleAdsClassMock initWithAppId:kAppID completion:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        void (^completion)(NSError *_Nullable error);
        [invocation getArgument:&completion atIndex:3];
        if (completion) {
          completion(nil);
        }
      });

  XCTAssertNoThrow([_vungleRouter initWithAppId:kAppID delegate:nil]);
}

- (void)testInitWithNilDelegateDoesNotCrashWhenNotInitializedAndInitFails {
  OCMStub([_vungleAdsClassMock isInitialized]).andReturn(NO);
  NSError *initError = [NSError errorWithDomain:@"com.vungle.error" code:101 userInfo:nil];
  OCMStub([_vungleAdsClassMock initWithAppId:kAppID completion:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        void (^completion)(NSError *_Nullable error);
        [invocation getArgument:&completion atIndex:3];
        if (completion) {
          completion(initError);
        }
      });

  XCTAssertNoThrow([_vungleRouter initWithAppId:kAppID delegate:nil]);
}

@end
