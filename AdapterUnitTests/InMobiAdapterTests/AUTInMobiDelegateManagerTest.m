#import "GADMAdapterInMobiDelegateManager.h"

#import <InMobiSDK/InMobiSDK-Swift.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

@interface AUTTestInMobiInterstitialDelegate : NSObject <IMInterstitialDelegate>
@end

@implementation AUTTestInMobiInterstitialDelegate
@end

@interface AUTInMobiDelegateManagerTest : XCTestCase
@end

@implementation AUTInMobiDelegateManagerTest {
  GADMAdapterInMobiDelegateManager *_manager;
}

- (void)setUp {
  [super setUp];
  _manager = [[GADMAdapterInMobiDelegateManager alloc] init];
}

- (void)tearDown {
  _manager = nil;
  [super tearDown];
}

- (void)testAddAndContainsDelegate {
  NSNumber *placementIdentifier = @12345;
  AUTTestInMobiInterstitialDelegate *delegate = [[AUTTestInMobiInterstitialDelegate alloc] init];

  XCTAssertFalse([_manager containsDelegateForPlacementIdentifier:placementIdentifier]);

  [_manager addDelegate:delegate forPlacementIdentifier:placementIdentifier];

  XCTAssertTrue([_manager containsDelegateForPlacementIdentifier:placementIdentifier]);
  XCTAssertFalse([_manager containsDelegateForPlacementIdentifier:@99999]);
}

- (void)testRemoveDelegateForPlacementIdentifier {
  NSNumber *placementIdentifier = @12345;
  AUTTestInMobiInterstitialDelegate *delegate = [[AUTTestInMobiInterstitialDelegate alloc] init];

  [_manager addDelegate:delegate forPlacementIdentifier:placementIdentifier];
  XCTAssertTrue([_manager containsDelegateForPlacementIdentifier:placementIdentifier]);

  [_manager removeDelegateForPlacementIdentifier:placementIdentifier];
  XCTAssertFalse([_manager containsDelegateForPlacementIdentifier:placementIdentifier]);
}

- (void)testWeakReferenceCleanupOnDealloc {
  NSNumber *placementIdentifier = @54321;

  @autoreleasepool {
    AUTTestInMobiInterstitialDelegate *delegate = [[AUTTestInMobiInterstitialDelegate alloc] init];
    [_manager addDelegate:delegate forPlacementIdentifier:placementIdentifier];
    XCTAssertTrue([_manager containsDelegateForPlacementIdentifier:placementIdentifier]);
  }

  // Once the autoreleasepool drains and delegate is deallocated, the weak reference is cleared.
  XCTAssertFalse([_manager containsDelegateForPlacementIdentifier:placementIdentifier]);
}

- (void)testCollisionHandlingAndMultiplePlacements {
  NSNumber *placement1 = @100;
  NSNumber *placement2 = @200;

  AUTTestInMobiInterstitialDelegate *delegate1 = [[AUTTestInMobiInterstitialDelegate alloc] init];
  AUTTestInMobiInterstitialDelegate *delegate2 = [[AUTTestInMobiInterstitialDelegate alloc] init];
  AUTTestInMobiInterstitialDelegate *delegate3 = [[AUTTestInMobiInterstitialDelegate alloc] init];

  [_manager addDelegate:delegate1 forPlacementIdentifier:placement1];
  [_manager addDelegate:delegate2 forPlacementIdentifier:placement2];

  XCTAssertTrue([_manager containsDelegateForPlacementIdentifier:placement1]);
  XCTAssertTrue([_manager containsDelegateForPlacementIdentifier:placement2]);

  // Overwrite placement1 with delegate3 (collision/update handling).
  [_manager addDelegate:delegate3 forPlacementIdentifier:placement1];
  XCTAssertTrue([_manager containsDelegateForPlacementIdentifier:placement1]);
  XCTAssertTrue([_manager containsDelegateForPlacementIdentifier:placement2]);

  // Remove placement1, placement2 should remain unaffected.
  [_manager removeDelegateForPlacementIdentifier:placement1];
  XCTAssertFalse([_manager containsDelegateForPlacementIdentifier:placement1]);
  XCTAssertTrue([_manager containsDelegateForPlacementIdentifier:placement2]);

  [_manager removeDelegateForPlacementIdentifier:placement2];
  XCTAssertFalse([_manager containsDelegateForPlacementIdentifier:placement2]);
}

- (void)testThreadSafeConcurrentAccess {
  NSUInteger const iterationCount = 100;
  NSMutableArray<AUTTestInMobiInterstitialDelegate *> *retainedDelegates =
      [[NSMutableArray alloc] init];

  for (NSUInteger i = 0; i < iterationCount; i++) {
    [retainedDelegates addObject:[[AUTTestInMobiInterstitialDelegate alloc] init]];
  }

  dispatch_queue_t concurrentQueue =
      dispatch_queue_create("com.inmobi.delegateManager.testQueue", DISPATCH_QUEUE_CONCURRENT);
  dispatch_group_t group = dispatch_group_create();

  for (NSUInteger i = 0; i < iterationCount; i++) {
    NSNumber *placementId = @(i);
    AUTTestInMobiInterstitialDelegate *delegate = retainedDelegates[i];

    dispatch_group_async(group, concurrentQueue, ^{
      [self->_manager addDelegate:delegate forPlacementIdentifier:placementId];
    });

    dispatch_group_async(group, concurrentQueue, ^{
      [self->_manager containsDelegateForPlacementIdentifier:placementId];
    });

    if (i % 2 == 0) {
      dispatch_group_async(group, concurrentQueue, ^{
        [self->_manager removeDelegateForPlacementIdentifier:placementId];
      });
    }
  }

  long result = dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
  XCTAssertEqual(result, 0,
                 @"Concurrent operations should complete without timing out or crashing.");
}

@end
