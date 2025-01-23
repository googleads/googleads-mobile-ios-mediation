#import "GADMAdapterAppLovinUtils.h"

#import <XCTest/XCTest.h>

@interface AUTAppLovinUtilsTests : XCTestCase
@end

@implementation AUTAppLovinUtilsTests

- (void)testMultipleAdsEnabled {
  XCTAssertTrue(GADMAdapterAppLovinIsMultipleAdsLoadingEnabled());
}

@end
