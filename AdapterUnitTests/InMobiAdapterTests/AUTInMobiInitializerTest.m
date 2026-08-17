#import "GADMAdapterInMobiInitializer.h"

#import <InMobiSDK/InMobiSDK-Swift.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AUTInMobiUtils.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMediationAdapterInMobi.h"

@interface AUTInMobiInitializerTest : XCTestCase
@end

@implementation AUTInMobiInitializerTest {
  GADMAdapterInMobiInitializer *_initializer;
  id _imsdkMock;
}

- (void)setUp {
  [super setUp];
  _initializer = [[GADMAdapterInMobiInitializer alloc] init];
}

- (void)tearDown {
  [_imsdkMock stopMocking];
  _imsdkMock = nil;
  [super tearDown];
}

- (void)testInitializationStateMachine {
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateUninitialized);

  __block void (^capturedCompletionBlock)(NSError *_Nullable) = nil;
  _imsdkMock = OCMClassMock([IMSdk class]);
  OCMStub(ClassMethod([_imsdkMock initWithAccountID:OCMOCK_ANY
                                  consentDictionary:OCMOCK_ANY
                               andCompletionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionBlock)(NSError *_Nullable);
        [invocation getArgument:&completionBlock atIndex:4];
        capturedCompletionBlock = [completionBlock copy];
      });

  __block BOOL firstCallbackInvoked = NO;
  [_initializer initializeWithAccountID:AUTInMobiAccountID
                      completionHandler:^(NSError *_Nullable error) {
                        firstCallbackInvoked = YES;
                        XCTAssertNil(error);
                      }];

  // Verify transition from Uninitialized -> Initializing before completion handler runs.
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateInitializing);
  XCTAssertFalse(firstCallbackInvoked);

  // Invoke completion block to simulate SDK initialization finishing.
  XCTAssertNotNil(capturedCompletionBlock);
  capturedCompletionBlock(nil);

  // Verify transition from Initializing -> Initialized.
  XCTAssertTrue(firstCallbackInvoked);
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateInitialized);

  // Calling initialize again when already Initialized should immediately invoke callback with nil.
  __block BOOL subsequentCallbackInvoked = NO;
  [_initializer initializeWithAccountID:AUTInMobiAccountID
                      completionHandler:^(NSError *_Nullable error) {
                        subsequentCallbackInvoked = YES;
                        XCTAssertNil(error);
                      }];
  XCTAssertTrue(subsequentCallbackInvoked);
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateInitialized);
}

- (void)testMultipleConcurrentInitializationsQueuingAndCompleting {
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateUninitialized);

  __block void (^capturedCompletionBlock)(NSError *_Nullable) = nil;
  _imsdkMock = OCMClassMock([IMSdk class]);
  OCMStub(ClassMethod([_imsdkMock initWithAccountID:OCMOCK_ANY
                                  consentDictionary:OCMOCK_ANY
                               andCompletionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionBlock)(NSError *_Nullable);
        [invocation getArgument:&completionBlock atIndex:4];
        capturedCompletionBlock = [completionBlock copy];
      });

  NSUInteger const requestCount = 5;
  __block NSUInteger completedCount = 0;
  dispatch_group_t group = dispatch_group_create();

  for (NSUInteger i = 0; i < requestCount; i++) {
    dispatch_group_enter(group);
    [_initializer initializeWithAccountID:AUTInMobiAccountID
                        completionHandler:^(NSError *_Nullable error) {
                          XCTAssertNil(error);
                          @synchronized(self) {
                            completedCount++;
                          }
                          dispatch_group_leave(group);
                        }];
  }

  // Initializer should now be in Initializing state and all requests queued.
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateInitializing);
  XCTAssertEqual(completedCount, 0);

  // Fulfill IMSdk initialization.
  XCTAssertNotNil(capturedCompletionBlock);
  capturedCompletionBlock(nil);

  dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
  XCTAssertEqual(completedCount, requestCount);
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateInitialized);
}

- (void)testInitializationFailureResetsStateAndDrainsCallbackQueue {
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateUninitialized);

  __block void (^capturedCompletionBlock)(NSError *_Nullable) = nil;
  _imsdkMock = OCMClassMock([IMSdk class]);
  OCMStub(ClassMethod([_imsdkMock initWithAccountID:OCMOCK_ANY
                                  consentDictionary:OCMOCK_ANY
                               andCompletionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionBlock)(NSError *_Nullable);
        [invocation getArgument:&completionBlock atIndex:4];
        capturedCompletionBlock = [completionBlock copy];
      });

  NSUInteger const requestCount = 3;
  __block NSUInteger failedCallbackCount = 0;
  NSError *expectedError = [NSError errorWithDomain:@"com.inmobi.test" code:500 userInfo:nil];

  for (NSUInteger i = 0; i < requestCount; i++) {
    [_initializer initializeWithAccountID:AUTInMobiAccountID
                        completionHandler:^(NSError *_Nullable error) {
                          if (error != nil) {
                            XCTAssertEqualObjects(error, expectedError);
                            failedCallbackCount++;
                          }
                        }];
  }

  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateInitializing);
  XCTAssertEqual(failedCallbackCount, 0);

  // Fail the SDK initialization.
  XCTAssertNotNil(capturedCompletionBlock);
  capturedCompletionBlock(expectedError);

  // State must be reset back to Uninitialized and all callbacks drained.
  XCTAssertEqual(failedCallbackCount, requestCount);
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateUninitialized);

  // Verify retry after failure successfully initializes.
  [_imsdkMock stopMocking];
  _imsdkMock = AUTMockIMSDKInit();

  __block BOOL retrySucceeded = NO;
  [_initializer initializeWithAccountID:AUTInMobiAccountID
                      completionHandler:^(NSError *_Nullable error) {
                        XCTAssertNil(error);
                        retrySucceeded = YES;
                      }];

  XCTAssertTrue(retrySucceeded);
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateInitialized);
}

- (void)testInitializeFailureWithZeroLengthAccountID {
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateUninitialized);

  __block BOOL callbackInvoked = NO;
  [_initializer initializeWithAccountID:@""
                      completionHandler:^(NSError *_Nullable error) {
                        XCTAssertNotNil(error);
                        XCTAssertEqual(error.code, GADMAdapterInMobiErrorInvalidServerParameters);
                        callbackInvoked = YES;
                      }];

  XCTAssertTrue(callbackInvoked);
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateUninitialized);
}

- (void)testInitializeAgainWhileInitializingDoesNotRestartSDKInit {
  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateUninitialized);

  _imsdkMock = OCMClassMock([IMSdk class]);
  OCMStub(ClassMethod([_imsdkMock initWithAccountID:OCMOCK_ANY
                                  consentDictionary:OCMOCK_ANY
                               andCompletionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation){
          // Leave pending to maintain Initializing state.
      });

  [_initializer initializeWithAccountID:AUTInMobiAccountID
                      completionHandler:^(NSError *_Nullable error) {
                        XCTFail(@"Should not be invoked while pending.");
                      }];

  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateInitializing);

  // SDK init should not be called again while already initializing.
  OCMReject(ClassMethod([_imsdkMock initWithAccountID:OCMOCK_ANY
                                    consentDictionary:OCMOCK_ANY
                                 andCompletionHandler:OCMOCK_ANY]));

  [_initializer initializeWithAccountID:AUTInMobiAccountID
                      completionHandler:^(NSError *_Nullable error) {
                        XCTFail(@"Should not be invoked while pending.");
                      }];

  XCTAssertEqual(_initializer.initializationState, GADMAdapterInMobiInitStateInitializing);
}

@end
