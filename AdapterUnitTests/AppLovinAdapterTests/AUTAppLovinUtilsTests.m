#import "GADMAdapterAppLovinUtils.h"

#import <XCTest/XCTest.h>

@interface AUTAppLovinUtilsTests : XCTestCase
@end

@implementation AUTAppLovinUtilsTests

- (void)testMultipleAdsNil {
  XCTAssertFalse(GADMAdapterAppLovinIsMultipleAdsLoadingEnabled(nil));
}

- (void)testMultipleAdsNotSpecified {
  XCTAssertFalse(GADMAdapterAppLovinIsMultipleAdsLoadingEnabled(@{}));
}

- (void)testMultipleAdsDisabled {
  XCTAssertFalse(GADMAdapterAppLovinIsMultipleAdsLoadingEnabled(
      @{@"enable_multiple_ads_per_unit" : @"false"}));
}

- (void)testMultipleAdsEnabled {
  XCTAssertTrue(
      GADMAdapterAppLovinIsMultipleAdsLoadingEnabled(@{@"enable_multiple_ads_per_unit" : @"true"}));
}

@end
