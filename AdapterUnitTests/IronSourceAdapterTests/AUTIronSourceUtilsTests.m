#import "GADMAdapterIronSourceUtils.h"

#import <IronSource/IronSource.h>
#import <XCTest/XCTest.h>

@interface AUTIronSourceUtilsTests : XCTestCase

@end

@implementation AUTIronSourceUtilsTests

- (void)testIronSourceBannerSizeIsRegularForRegularGoogleBanner {
  ISBannerSize *ironSourceBannerSize =
      [GADMAdapterIronSourceUtils ironSourceAdSizeFromRequestedSize:GADAdSizeBanner];

  XCTAssertEqual(ironSourceBannerSize.height, ISBannerSize_BANNER.height);
  XCTAssertEqual(ironSourceBannerSize.width, ISBannerSize_BANNER.width);
}

- (void)testIronSourceBannerSizeIsLargeForLargeGoogleBanner {
  ISBannerSize *ironSourceBannerSize =
      [GADMAdapterIronSourceUtils ironSourceAdSizeFromRequestedSize:GADAdSizeLargeBanner];

  XCTAssertEqual(ironSourceBannerSize.height, ISBannerSize_LARGE.height);
  XCTAssertEqual(ironSourceBannerSize.width, ISBannerSize_LARGE.width);
}

- (void)testIronSourceBannerSizeIsRectangleForMediumRectangularGoogleBanner {
  ISBannerSize *ironSourceBannerSize =
      [GADMAdapterIronSourceUtils ironSourceAdSizeFromRequestedSize:GADAdSizeMediumRectangle];

  XCTAssertEqual(ironSourceBannerSize.height, ISBannerSize_RECTANGLE.height);
  XCTAssertEqual(ironSourceBannerSize.width, ISBannerSize_RECTANGLE.width);
}

- (void)testIronSourceBannerSizeIsNilForUnsupportedGoogleBannerSize {
  ISBannerSize *ironSourceBannerSize =
      [GADMAdapterIronSourceUtils ironSourceAdSizeFromRequestedSize:GADAdSizeSkyscraper];

  XCTAssertNil(ironSourceBannerSize);
}

@end
