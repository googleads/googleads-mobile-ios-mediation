import AdapterUnitTestKit
import MolocoSDK
import XCTest

@testable import MolocoAdapter

final class MolocoBannerAdTest: XCTestCase {

  /// An ad unit ID used in testing.
  let testAdUnitID = "12345"
  /// A bid response received by the adapter to load the ad.
  let testBidResponse = "bid_response"

  func testFakeBannerFactory() throws {
    let molocoBannerFactory = FakeMolocoBannerFactory()
    let adConfiguration = GADMediationBannerAdConfiguration()
    let bannerLoader = BannerAdLoader(
      adConfiguration: adConfiguration, molocoBannerFactory: molocoBannerFactory
    ) { ad, error in
      return nil
    }
    let banner = molocoBannerFactory.createBanner(for: testAdUnitID, delegate: bannerLoader)
    let fakeMolocoBanner = try XCTUnwrap(banner as? FakeMolocoBanner)

    XCTAssertEqual(molocoBannerFactory.adUnitIDUsedToCreateMolocoAd, testAdUnitID)
    XCTAssertTrue(fakeMolocoBanner.isReady)
    XCTAssertNotNil(fakeMolocoBanner.bannerDelegate)
    XCTAssertEqual(fakeMolocoBanner.frame, CGRect.zero)
  }

  func testBannerLoadSuccess() {
    // TODO: b/368608855 - Assert a successful load after submitting required banner adapter CLs.
  }

  func testBannerLoadFailure_ifAdUnitIdIsMissing() {
    let molocoBannerFactory = FakeMolocoBannerFactory()
    let adapter = MolocoMediationAdapter(molocoBannerFactory: molocoBannerFactory)
    let mediationAdConfig = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = testBidResponse

    let expectedError = NSError(
      domain: MolocoConstants.adapterErrorDomain,
      code: MolocoAdapterErrorCode.invalidAdUnitId.rawValue)
    AUTKWaitAndAssertLoadBannerAdFailure(adapter, mediationAdConfig, expectedError)
  }

}
