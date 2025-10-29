#import "GADMAdapterInMobiDelegateManager.h"

#import <XCTest/XCTest.h>

#import <InMobiSDK/InMobiSDK-Swift.h>

#import <OCMock/OCMock.h>

@interface AUTInMobiDelegateManagerTest : XCTestCase
@end

@implementation AUTInMobiDelegateManagerTest {
  GADMAdapterInMobiDelegateManager *_manager;
}

- (void)setUp {
  _manager = GADMAdapterInMobiDelegateManager.sharedInstance;
}

- (void)testAddDelegateForPlacementIdentifier {
  NSNumber *placementIdentifier = @0;
  [_manager addDelegate:OCMProtocolMock(@protocol(IMInterstitialDelegate))
      forPlacementIdentifier:placementIdentifier];
  XCTAssertTrue([_manager containsDelegateForPlacementIdentifier:placementIdentifier]);
}

- (void)testRemoveDelegateForPlacementIdentifier {
  NSNumber *placementIdentifier = @0;
  [_manager addDelegate:OCMProtocolMock(@protocol(IMInterstitialDelegate))
      forPlacementIdentifier:placementIdentifier];

  XCTAssertTrue([_manager containsDelegateForPlacementIdentifier:placementIdentifier]);

  [_manager removeDelegateForPlacementIdentifier:placementIdentifier];

  XCTAssertFalse([_manager containsDelegateForPlacementIdentifier:placementIdentifier]);
}

@end
