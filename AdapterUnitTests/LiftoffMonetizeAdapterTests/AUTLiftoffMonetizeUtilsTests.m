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
    VungleAdSize* vungleAdSize =
        GADMAdapterVungleConvertGADAdSizeToVungleAdSize(GADAdSizeMediumRectangle, kPlacementID);

    XCTAssertNotNil(vungleAdSize);
    XCTAssertEqual(vungleAdSize.size.width, VungleAdSize.VungleAdSizeMREC.size.width);
    XCTAssertEqual(vungleAdSize.size.height, VungleAdSize.VungleAdSizeMREC.size.height);
}

- (void)testLiftoffSizeForLeaderboardSize {
    VungleAdSize* vungleAdSize =
        GADMAdapterVungleConvertGADAdSizeToVungleAdSize(GADAdSizeLeaderboard, kPlacementID);

    XCTAssertNotNil(vungleAdSize);
    XCTAssertEqual(vungleAdSize.size.width, VungleAdSize.VungleAdSizeLeaderboard.size.width);
    XCTAssertEqual(vungleAdSize.size.height, VungleAdSize.VungleAdSizeLeaderboard.size.height);
}

- (void)testLiftoffSizeForStandardBannerSize {
    VungleAdSize* vungleAdSize =
        GADMAdapterVungleConvertGADAdSizeToVungleAdSize(GADAdSizeBanner, kPlacementID);

    XCTAssertNotNil(vungleAdSize);
    XCTAssertEqual(vungleAdSize.size.width, VungleAdSize.VungleAdSizeBannerRegular.size.width);
    XCTAssertEqual(vungleAdSize.size.height, VungleAdSize.VungleAdSizeBannerRegular.size.height);
}

- (void)testLiftoffSizeForShortBannerSize {
  const CGSize shortBannerCGSize = {300, 50};
  GADAdSize shortBannerSize = GADAdSizeFromCGSize(shortBannerCGSize);
    
    VungleAdSize* vungleAdSize =
        GADMAdapterVungleConvertGADAdSizeToVungleAdSize(shortBannerSize, kPlacementID);

    XCTAssertNotNil(vungleAdSize);
    XCTAssertEqual(vungleAdSize.size.width, VungleAdSize.VungleAdSizeBannerShort.size.width);
    XCTAssertEqual(vungleAdSize.size.height, VungleAdSize.VungleAdSizeBannerShort.size.height);
}

- (void)testLiftoffReturnsCustomSizeForNonStandardGoogleBannerSize {
  VungleAdSize* vungleAdSize =
      GADMAdapterVungleConvertGADAdSizeToVungleAdSize(GADAdSizeSkyscraper, kPlacementID);

  XCTAssertNotNil(vungleAdSize);
  XCTAssertEqual(vungleAdSize.size.width, GADAdSizeSkyscraper.size.width);
  XCTAssertEqual(vungleAdSize.size.height, GADAdSizeSkyscraper.size.height);
}

@end
