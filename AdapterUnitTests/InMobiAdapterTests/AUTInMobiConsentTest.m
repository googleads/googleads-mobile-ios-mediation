#import <Foundation/Foundation.h>
#import "GADMInMobiConsent.h"

#import <XCTest/XCTest.h>

#import <InMobiSDK/InMobiSDK-Swift.h>

#import <OCMock/OCMock.h>

#import "AUTInMobiUtils.h"
#import "GADMAdapterInMobiInitializer.h"

@interface AUTInMobiConsentTest : XCTestCase
@end

@implementation AUTInMobiConsentTest

- (void)tearDown {
  // Reset the static global consent dictionary every time after the unit test is run.
  id nilConsent = nil;
  [GADMInMobiConsent updateGDPRConsent:nilConsent];
}

- (void)testUpdateGDPRConsent {
  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMStub(ClassMethod([IMSDKMock initWithAccountID:OCMOCK_ANY
                                 consentDictionary:OCMOCK_ANY
                              andCompletionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionBlock)(NSError *_Nullable);
        [invocation getArgument:&completionBlock atIndex:4];
        completionBlock(nil);
      });
  OCMExpect([IMSDKMock updateGDPRConsent:OCMOCK_ANY]);

  GADMAdapterInMobiInitializer *initializer = [[GADMAdapterInMobiInitializer alloc] init];
  [initializer initializeWithAccountID:@"12345"
                     completionHandler:^(NSError *_Nullable error){
                     }];
  id initializerMock = OCMClassMock([GADMAdapterInMobiInitializer class]);
  OCMStub([initializerMock sharedInstance]).andReturn(initializer);

  XCTAssertNil(GADMInMobiConsent.consent);

  // Possible key-value pairs in the consent object can be found from:
  // https://support.inmobi.com/monetize/sdk-documentation/ios-guidelines/overview-ios-guidelines/#initializing-the-sdk
  NSString *GDPRConsentKey = @"gdpr_consent";
  NSString *GDPRConsentValue = @"12345";
  NSDictionary<NSString *, NSString *> *expectedConsent = @{GDPRConsentKey : GDPRConsentValue};
  [GADMInMobiConsent updateGDPRConsent:expectedConsent];

  XCTAssertEqualObjects(GADMInMobiConsent.consent, expectedConsent);
  OCMVerifyAll(IMSDKMock);
}

@end
