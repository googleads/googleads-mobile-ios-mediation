#import "AppLovinAdapter-Swift.h"

#import <XCTest/XCTest.h>

@interface AUTAppLovinUtilsTests : XCTestCase
@end

@implementation AUTAppLovinUtilsTests

- (void)testMultipleAdsEnabled {
  XCTAssertTrue([GADMAdapterAppLovinUtils isMultipleAdsLoadingEnabled]);
}

@end
