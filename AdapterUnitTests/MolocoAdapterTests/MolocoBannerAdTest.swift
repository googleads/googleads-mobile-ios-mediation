import AdapterUnitTestKit
import MolocoSDK
import XCTest

@testable import MolocoAdapter

final class MolocoBannerAdTest: XCTestCase {

  private enum Constants {
    /// An ad unit ID used in testing.
    static let adUnitID = "12345"
  }

  func testFakeBannerFactory() throws {
    let molocoBannerFactory = FakeMolocoBannerFactory()
    let adConfiguration = GADMediationBannerAdConfiguration()
    let bannerLoader = BannerAdLoader(
      adConfiguration: adConfiguration, molocoBannerFactory: molocoBannerFactory
    ) { ad, error in
      return nil
    }
    let banner = molocoBannerFactory.createBanner(for: Constants.adUnitID, delegate: bannerLoader)
    let fakeMolocoBanner = try XCTUnwrap(banner as? FakeMolocoBanner)

    XCTAssertEqual(molocoBannerFactory.adUnitIDUsedToCreateMolocoAd, Constants.adUnitID)
    XCTAssertTrue(fakeMolocoBanner.isReady)
    XCTAssertEqual(fakeMolocoBanner.frame, CGRect.zero)
  }

}
