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

- (void)tearDown {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = nil;
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = nil;
}

- (void)testAdapterSetUpWithoutTFCDAndTFUA {
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
  OCMExpect([sharedInstanceMock setCoppaApplies:IACoppaAppliesTypeUnknown]);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterFyberApplicationID : applicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterFyber class], credentials);
}

- (void)testAdapterSetUpWithTFCDSetToYes {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @YES;
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
  OCMExpect([sharedInstanceMock setCoppaApplies:IACoppaAppliesTypeGiven]);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterFyberApplicationID : applicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterFyber class], credentials);
}

- (void)testAdapterSetUpWithTFCDSetToNo {
  GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @NO;
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
  OCMExpect([sharedInstanceMock setCoppaApplies:IACoppaAppliesTypeDenied]);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterFyberApplicationID : applicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterFyber class], credentials);
}

- (void)testAdapterSetUpWithTFUASetToYes {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @YES;
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
  OCMExpect([sharedInstanceMock setCoppaApplies:IACoppaAppliesTypeGiven]);

  AUTKMediationCredentials *credentials = [[AUTKMediationCredentials alloc] init];
  credentials.settings = @{GADMAdapterFyberApplicationID : applicationID};
  AUTKWaitAndAssertAdapterSetUpWithCredentials([GADMediationAdapterFyber class], credentials);
}

- (void)testAdapterSetUpWithTFUASetToNo {
  GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @NO;
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
  OCMExpect([sharedInstanceMock setCoppaApplies:IACoppaAppliesTypeDenied]);

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

- (void)testSignalCollection {
  id mockBiddingManager = OCMClassMock([FMPBiddingManager class]);
  OCMStub([mockBiddingManager sharedInstance]).andReturn(mockBiddingManager);
  NSString *fakeToken = @"fake_bidding_token";
  OCMStub([mockBiddingManager biddingToken]).andReturn(fakeToken);

  GADMediationAdapterFyber *adapter = [[GADMediationAdapterFyber alloc] init];
  [adapter
      collectSignalsForRequestParameters:[[AUTKRTBRequestParameters alloc] init]
                       completionHandler:^(NSString *_Nullable signals, NSError *_Nullable error) {
                         XCTAssertEqualObjects(signals, fakeToken);
                       }];
}

@end
