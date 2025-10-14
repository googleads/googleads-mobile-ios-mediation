#import "GADMAdapterInMobiInitializer.h"

#import <XCTest/XCTest.h>

#import <InMobiSDK/InMobiSDK-Swift.h>

#import <OCMock/OCMock.h>

#import "AUTInMobiUtils.h"
#import "GADMediationAdapterInMobi.h"

@interface AUTInMobiInitializerTest : XCTestCase
@end

@implementation AUTInMobiInitializerTest {
  GADMAdapterInMobiInitializer *_initializer;
}

- (void)setUp {
  [super setUp];
  // Intentionally initializing a new instance instead of using the singleton.
  _initializer = [[GADMAdapterInMobiInitializer alloc] init];
  AUTMockIMSDKInit();
}

- (void)testInitialize {
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateUninitialized);

  [_initializer initializeWithAccountID:AUTInMobiAccountID
                      completionHandler:^(NSError *_Nullable error) {
                        XCTAssertNil(error);
                      }];

  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateInitialized);
}

- (void)testInitializeMultipleTimes {
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateUninitialized);

  [_initializer initializeWithAccountID:AUTInMobiAccountID
                      completionHandler:^(NSError *_Nullable error){
                      }];

  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateInitialized);

  __block BOOL secondCompletionHandlerInvoked = NO;
  [_initializer initializeWithAccountID:AUTInMobiAccountID
                      completionHandler:^(NSError *_Nullable error) {
                        secondCompletionHandlerInvoked = YES;
                      }];

  XCTAssertTrue(secondCompletionHandlerInvoked);
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateInitialized);
}

- (void)testInitializeAgainWhileInitializing {
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateUninitialized);

  // The GADMAdapterInMobiInitializer's initializeWithAccountID method internally calls IMSDK's
  // initWithAccoutID.
  __block BOOL completionBlockInvoked = NO;
  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMStub(ClassMethod([IMSDKMock initWithAccountID:OCMOCK_ANY
                                 consentDictionary:OCMOCK_ANY
                              andCompletionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        // Not invoking the completion block to simulate the initializing state.
        completionBlockInvoked = YES;
      });
  [_initializer initializeWithAccountID:AUTInMobiAccountID
                      completionHandler:^(NSError *_Nullable error) {
                        XCTFail(@"Shouldn't be called.");
                      }];
  XCTAssertTrue(completionBlockInvoked);

  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateInitializing);

  // If the state is initializing, then the initializer should not restart the initialize process.
  OCMReject(ClassMethod([IMSDKMock initWithAccountID:OCMOCK_ANY
                                   consentDictionary:OCMOCK_ANY
                                andCompletionHandler:OCMOCK_ANY]));
  [_initializer initializeWithAccountID:AUTInMobiAccountID
                      completionHandler:^(NSError *_Nullable error) {
                        XCTFail(@"Shouldn't be called.");
                      }];

  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateInitializing);
}

- (void)testInitializeFailureWithZeroLengthAccountID {
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateUninitialized);

  [_initializer initializeWithAccountID:@""
                      completionHandler:^(NSError *_Nullable error) {
                        XCTAssertNotNil(error);
                        XCTAssertEqual(error.code, GADMAdapterInMobiErrorInvalidServerParameters);
                      }];

  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateUninitialized);
}

- (void)testInitializeFailureWithError {
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateUninitialized);

  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMStub(ClassMethod([IMSDKMock initWithAccountID:OCMOCK_ANY
                                 consentDictionary:OCMOCK_ANY
                              andCompletionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionBlock)(NSError *_Nullable);
        [invocation getArgument:&completionBlock atIndex:4];
        completionBlock(OCMClassMock([NSError class]));
      });

  [_initializer initializeWithAccountID:AUTInMobiAccountID
                      completionHandler:^(NSError *_Nullable error) {
                        XCTAssertNotNil(error);
                      }];

  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateUninitialized);
}

@end
