#import "GADMAdapterVungleUtils.h"
#import "GADMAdapterVungleConstants.h"

#import <XCTest/XCTest.h>

static NSString* const kPlacementID = @"12345";

/// This file contains tests for those GADMAdapterVungleUtils functionalities which are not
/// excercised by the other tests for the Liftoff adapter.
@interface AUTLiftoffMonetizeUtilsTests : XCTestCase

@end

@implementation AUTLiftoffMonetizeUtilsTests

- (void)testLiftoffSizeForMediumRectangleSize {
  XCTAssertEqual(
      GADMAdapterVungleConvertGADAdSizeToVungleAdSize(GADAdSizeMediumRectangle, kPlacementID),
      VungleAdSize.VungleAdSizeMREC);
}

- (void)testLiftoffSizeForLeaderboardSize {
  XCTAssertEqual(
      GADMAdapterVungleConvertGADAdSizeToVungleAdSize(GADAdSizeLeaderboard, kPlacementID),
      VungleAdSize.VungleAdSizeLeaderboard);
}

- (void)testLiftoffSizeForStandardBannerSize {
  XCTAssertEqual(GADMAdapterVungleConvertGADAdSizeToVungleAdSize(GADAdSizeBanner, kPlacementID),
                 VungleAdSize.VungleAdSizeBannerRegular);
}

- (void)testLiftoffSizeForShortBannerSize {
  const CGSize shortBannerCGSize = {300, 50};
  GADAdSize shortBannerSize = GADAdSizeFromCGSize(shortBannerCGSize);

  XCTAssertEqual(GADMAdapterVungleConvertGADAdSizeToVungleAdSize(shortBannerSize, kPlacementID),
                 VungleAdSize.VungleAdSizeBannerShort);
}

- (void)testLiftoffReturnsCustomSizeForNonStandardGoogleBannerSize {
  VungleAdSize* vungleAdSize =
      GADMAdapterVungleConvertGADAdSizeToVungleAdSize(GADAdSizeSkyscraper, kPlacementID);

  XCTAssertNotNil(vungleAdSize);
  XCTAssertEqual(vungleAdSize.size.width, GADAdSizeSkyscraper.size.width);
  XCTAssertEqual(vungleAdSize.size.height, GADAdSizeSkyscraper.size.height);
}

@end
