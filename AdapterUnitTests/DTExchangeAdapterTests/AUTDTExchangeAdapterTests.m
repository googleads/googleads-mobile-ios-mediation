#import "GADMediationAdapterFyber.h"

#import <AdapterUnitTestKit/AUTKAdConfiguration.h>
#import <AdapterUnitTestKit/AUTKAdapterSetUpAssertions.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IASDKCore/IASDKCore.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "GADMAdapterFyberConstants.h"
#import "GADMAdapterFyberExtras.h"

@interface AUTDTExchangeAdapterTests : XCTestCase
@end

@implementation AUTDTExchangeAdapterTests

- (void)testAdapterSetUp {
  NSString *applicationID = @"123";

  // Mock IASDK
  id sharedInstanceMock = OCMClassMock([IASDKCore class]);
  OCMStub(ClassMethod([sharedInstanceMock sharedInstance])).andReturn(sharedInstanceMock);
  OCMStub([sharedInstanceMock isInitialised]).andReturn(NO);
  OCMStub([sharedInstanceMock initWithAppID:applicationID
                            completionBlock:OCMOCK_ANY
                            completionQueue:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionBlock)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionBlock atIndex:3];
        completionBlock(YES, nil);
      });

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterFyberApplicationID : applicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterFyber class], credentials);
}

- (void)testAdapterSetUpCompletionWhenInitialized {
  NSString *applicationID = @"123";

  // Mock IASDK
  id sharedInstanceMock = OCMClassMock([IASDKCore class]);
  OCMStub(ClassMethod([sharedInstanceMock sharedInstance])).andReturn(sharedInstanceMock);
  OCMStub([sharedInstanceMock isInitialised]).andReturn(YES);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterFyberApplicationID : applicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterFyber class], credentials);
}

- (void)testAdapterSetUpWithMultipleCredentials {
  NSString *firstApplicationID = @"123";
  NSString *secondApplicationID = @"456";

  // Mock IASDK
  id sharedInstanceMock = OCMClassMock([IASDKCore class]);
  OCMStub(ClassMethod([sharedInstanceMock sharedInstance])).andReturn(sharedInstanceMock);
  OCMStub([sharedInstanceMock isInitialised]).andReturn(NO);
  OCMStub([sharedInstanceMock initWithAppID:firstApplicationID
                            completionBlock:OCMOCK_ANY
                            completionQueue:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionBlock)(BOOL success, NSError *_Nullable error);
        [invocation getArgument:&completionBlock atIndex:3];
        completionBlock(YES, nil);
      });

  AUTKMediationCredentials *firstCredentials = [[AUTKMediationCredentials alloc] init];
  firstCredentials.settings = @{GADMAdapterFyberApplicationID : firstApplicationID};
  AUTKMediationCredentials *secondCredentials = [[AUTKMediationCredentials alloc] init];
  secondCredentials.settings = @{GADMAdapterFyberApplicationID : secondApplicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentialsArray([GADMediationAdapterFyber class],
                                                    @[ firstCredentials, secondCredentials ]);
}

- (void)testAdapterSetUpFailureWithNoAppID {
  // Mock IASDK
  id sharedInstanceMock = OCMClassMock([IASDKCore class]);
  OCMStub(ClassMethod([sharedInstanceMock sharedInstance])).andReturn(sharedInstanceMock);
  OCMStub([sharedInstanceMock isInitialised]).andReturn(NO);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  NSError *expectedError =
      [[NSError alloc] initWithDomain:GADMAdapterFyberErrorDomain
                                 code:GADMAdapterFyberErrorInvalidServerParameters
                             userInfo:nil];
  AUTKWaitAndAssertAdapterSetUpFailureWithCredentials([GADMediationAdapterFyber class], credentials,
                                                      expectedError);
}

- (void)testAdapterVersion {
  GADVersionNumber version = GADMediationAdapterFyber.adapterVersion;

  XCTAssertGreaterThan(version.majorVersion, 0);
  XCTAssertLessThanOrEqual(version.majorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.minorVersion, 0);
  XCTAssertLessThanOrEqual(version.minorVersion, 99);
  XCTAssertGreaterThanOrEqual(version.patchVersion, 0);
  XCTAssertLessThanOrEqual(version.patchVersion, 999);
}

- (void)testAdSDKVersion {
  // Mock IASDK
  id sharedInstanceMock = OCMClassMock([IASDKCore class]);
  OCMStub(ClassMethod([sharedInstanceMock sharedInstance])).andReturn(sharedInstanceMock);
  IASDKCore *explicitSharedInstanceMock = (IASDKCore *)sharedInstanceMock;
  OCMStub([explicitSharedInstanceMock version]).andReturn(@"1.2.3");

  GADVersionNumber expectedAdapterSDKVersion = {
      .majorVersion = 1, .minorVersion = 2, .patchVersion = 3};
  AUTKAssertEqualVersion([GADMediationAdapterFyber adSDKVersion], expectedAdapterSDKVersion);
}

- (void)testNetworkExtrasClass {
  XCTAssertEqual([GADMediationAdapterFyber networkExtrasClass], [GADMAdapterFyberExtras class]);
}

@end
