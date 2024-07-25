#import "GADMAdapterVungleUtils.h"
#import "GADMAdapterVungleConstants.h"

#import <XCTest/XCTest.h>

/// This file contains tests for those GADMAdapterVungleUtils functionalities which are not
/// excercised by the other tests for the Liftoff adapter.
@interface AUTLiftoffMonetizeUtilsTests : XCTestCase

@end

@implementation AUTLiftoffMonetizeUtilsTests

- (void)testAdSizeIsMediumeRectangleForMediumRectangle {
  GADAdSize adSizeForMediumRectangle = GADMAdapterVungleAdSizeForAdSize(GADAdSizeMediumRectangle);

  XCTAssertEqual(adSizeForMediumRectangle.size.height, GADAdSizeMediumRectangle.size.height);
  XCTAssertEqual(adSizeForMediumRectangle.size.width, GADAdSizeMediumRectangle.size.width);
}

- (void)testAdSizeIsShortBannerForShortBanner {
  const CGSize shortBannerCGSize = {300, 50};
  GADAdSize shortBannerSize = GADAdSizeFromCGSize(shortBannerCGSize);

  GADAdSize adSizeForShortBanner = GADMAdapterVungleAdSizeForAdSize(shortBannerSize);

  XCTAssertEqual(adSizeForShortBanner.size.height, shortBannerSize.size.height);
  XCTAssertEqual(adSizeForShortBanner.size.width, shortBannerSize.size.width);
}

- (void)testAdSizeIsBannerForBanner {
  GADAdSize adSizeForBanner = GADMAdapterVungleAdSizeForAdSize(GADAdSizeBanner);

  XCTAssertEqual(adSizeForBanner.size.height, GADAdSizeBanner.size.height);
  XCTAssertEqual(adSizeForBanner.size.width, GADAdSizeBanner.size.width);
}

- (void)testAdSizeIsLeaderboardForLeaderboard {
  GADAdSize adSizeForLeaderboard = GADMAdapterVungleAdSizeForAdSize(GADAdSizeLeaderboard);

  XCTAssertEqual(adSizeForLeaderboard.size.height, GADAdSizeLeaderboard.size.height);
  XCTAssertEqual(adSizeForLeaderboard.size.width, GADAdSizeLeaderboard.size.width);
}

- (void)testAdSizeIsInvalidForUnsupportedSize {
  GADAdSize adSizeForUnsupportedSize = GADMAdapterVungleAdSizeForAdSize(GADAdSizeSkyscraper);

  XCTAssertEqual(adSizeForUnsupportedSize.size.height, GADAdSizeInvalid.size.height);
  XCTAssertEqual(adSizeForUnsupportedSize.size.width, GADAdSizeInvalid.size.width);
}

- (void)testLiftoffSizeForMediumRectangleSize {
  XCTAssertEqual(GADMAdapterVungleConvertGADAdSizeToBannerSize(GADAdSizeMediumRectangle),
                 BannerSizeMrec);
}

- (void)testLiftoffSizeForLeaderboardSize {
  XCTAssertEqual(GADMAdapterVungleConvertGADAdSizeToBannerSize(GADAdSizeLeaderboard),
                 BannerSizeLeaderboard);
}

- (void)testLiftoffSizeForStandardBannerSize {
  XCTAssertEqual(GADMAdapterVungleConvertGADAdSizeToBannerSize(GADAdSizeBanner), BannerSizeRegular);
}

- (void)testLiftoffSizeForShortBannerSize {
  const CGSize shortBannerCGSize = {300, 50};
  GADAdSize shortBannerSize = GADAdSizeFromCGSize(shortBannerCGSize);

  XCTAssertEqual(GADMAdapterVungleConvertGADAdSizeToBannerSize(shortBannerSize), BannerSizeShort);
}

@end
