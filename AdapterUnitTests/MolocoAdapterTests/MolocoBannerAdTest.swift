import AdapterUnitTestKit
import MolocoSDK
import XCTest

@testable import MolocoAdapter

final class MolocoBannerAdTest: XCTestCase {

  /// An ad unit ID used in testing.
  static let testAdUnitID = "12345"
  /// A bid response received by the adapter to load the ad.
  static let testBidResponse = "bid_response"

  func testFakeBannerFactory() throws {
    let molocoBannerFactory = FakeMolocoBannerFactory()
    let adConfiguration = GADMediationBannerAdConfiguration()
    let bannerLoader = BannerAdLoader(
      adConfiguration: adConfiguration, molocoBannerFactory: molocoBannerFactory
    ) { ad, error in
      return nil
    }
    let banner = molocoBannerFactory.createBanner(for: Self.testAdUnitID, delegate: bannerLoader)
    let fakeMolocoBanner = try XCTUnwrap(banner as? FakeMolocoBanner)

    XCTAssertEqual(molocoBannerFactory.adUnitIDUsedToCreateMolocoAd, Self.testAdUnitID)
    XCTAssertTrue(fakeMolocoBanner.isReady)
    XCTAssertNotNil(fakeMolocoBanner.bannerDelegate)
    XCTAssertEqual(fakeMolocoBanner.frame, CGRect.zero)
  }

  func testBannerLoadSuccess() {
    let molocoBannerFactory = FakeMolocoBannerFactory()
    let adapter = MolocoMediationAdapter(molocoBannerFactory: molocoBannerFactory)
    let mediationAdConfig = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Self.testAdUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Self.testBidResponse

    AUTKWaitAndAssertLoadBannerAd(adapter, mediationAdConfig)
    XCTAssertEqual(molocoBannerFactory.adUnitIDUsedToCreateMolocoAd, Self.testAdUnitID)
    XCTAssertEqual(
      molocoBannerFactory.fakeMolocoBanner?.bidResponseUsedToLoadMolocoAd, Self.testBidResponse
    )
  }

  func testBannerLoadFailure() {
    let loadError = NSError(domain: "moloco_sdk_domain", code: 1002)
    let molocoBannerFactory = FakeMolocoBannerFactory(loadError: loadError)
    let adapter = MolocoMediationAdapter(molocoBannerFactory: molocoBannerFactory)
    let mediationAdConfig = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Self.testAdUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Self.testBidResponse

    AUTKWaitAndAssertLoadBannerAdFailure(adapter, mediationAdConfig, loadError)
  }

  func testBannerLoadFailure_ifAdUnitIdIsMissing() {
    let molocoBannerFactory = FakeMolocoBannerFactory()
    let adapter = MolocoMediationAdapter(molocoBannerFactory: molocoBannerFactory)
    let mediationAdConfig = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Self.testBidResponse

    let expectedError = NSError(
      domain: MolocoConstants.adapterErrorDomain,
      code: MolocoAdapterErrorCode.invalidAdUnitId.rawValue)
    AUTKWaitAndAssertLoadBannerAdFailure(adapter, mediationAdConfig, expectedError)
  }

  func testBannerLoadTriggersExpectedLifecycleEvents() throws {
    let molocoBannerFactory = FakeMolocoBannerFactory()
    let adapter = MolocoMediationAdapter(molocoBannerFactory: molocoBannerFactory)
    let mediationAdConfig = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Self.testAdUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Self.testBidResponse

    let adEventDelegate = AUTKWaitAndAssertLoadBannerAd(adapter, mediationAdConfig)

    XCTAssertNil(adEventDelegate.didFailToPresentError)
    let bannerAd = try XCTUnwrap(adEventDelegate.bannerAd)
    XCTAssertEqual(bannerAd.view, molocoBannerFactory.fakeMolocoBanner)
    XCTAssertEqual(adEventDelegate.reportClickInvokeCount, 1)
    XCTAssertEqual(adEventDelegate.reportImpressionInvokeCount, 1)
  }

  func testBannerShowFailureWithError() throws {
    let showError = NSError(domain: "moloco_sdk_domain", code: 1002)
    let molocoBannerFactory = FakeMolocoBannerFactory(showError: showError)
    let adapter = MolocoMediationAdapter(molocoBannerFactory: molocoBannerFactory)
    let mediationAdConfig = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Self.testAdUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Self.testBidResponse

    let adEventDelegate = AUTKWaitAndAssertLoadBannerAd(adapter, mediationAdConfig)
    let didFailToPresentError = try XCTUnwrap(adEventDelegate.didFailToPresentError as? NSError)

    XCTAssertEqual(didFailToPresentError.domain, "moloco_sdk_domain")
    XCTAssertEqual(didFailToPresentError.code, 1002)
    XCTAssertEqual(molocoBannerFactory.adUnitIDUsedToCreateMolocoAd, Self.testAdUnitID)
    XCTAssertEqual(
      molocoBannerFactory.fakeMolocoBanner?.bidResponseUsedToLoadMolocoAd, Self.testBidResponse
    )
    XCTAssertNotNil(adEventDelegate.didFailToPresentError)
    let bannerAd = try XCTUnwrap(adEventDelegate.bannerAd)
    XCTAssertEqual(bannerAd.view, molocoBannerFactory.fakeMolocoBanner)
    XCTAssertEqual(adEventDelegate.reportClickInvokeCount, 0)
    XCTAssertEqual(adEventDelegate.reportImpressionInvokeCount, 0)
  }

  func testBannerShowFailureWithDefaultError() throws {
    let molocoBannerFactory = FakeMolocoBannerFactory(shouldFailToShow: true)
    let adapter = MolocoMediationAdapter(molocoBannerFactory: molocoBannerFactory)
    let mediationAdConfig = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Self.testAdUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Self.testBidResponse

    let adEventDelegate = AUTKWaitAndAssertLoadBannerAd(adapter, mediationAdConfig)
    let didFailToPresentError = try XCTUnwrap(adEventDelegate.didFailToPresentError as? NSError)

    XCTAssertEqual(didFailToPresentError.domain, MolocoConstants.adapterErrorDomain)
    XCTAssertEqual(didFailToPresentError.code, MolocoAdapterErrorCode.adFailedToShow.rawValue)
    XCTAssertEqual(molocoBannerFactory.adUnitIDUsedToCreateMolocoAd, Self.testAdUnitID)
    XCTAssertEqual(
      molocoBannerFactory.fakeMolocoBanner?.bidResponseUsedToLoadMolocoAd, Self.testBidResponse
    )
    XCTAssertNotNil(adEventDelegate.didFailToPresentError)
    let bannerAd = try XCTUnwrap(adEventDelegate.bannerAd)
    XCTAssertEqual(bannerAd.view, molocoBannerFactory.fakeMolocoBanner)
    XCTAssertEqual(adEventDelegate.reportClickInvokeCount, 0)
    XCTAssertEqual(adEventDelegate.reportImpressionInvokeCount, 0)
  }

  func testViewWhenAdDidNotLoad() throws {
    let adEventDelegate = AUTKMediationBannerAdEventDelegate()
    let mediationAdConfig = AUTKMediationBannerAdConfiguration()
    let molocoBannerFactory = FakeMolocoBannerFactory(shouldFailToShow: true)
    adEventDelegate.bannerAd = BannerAdLoader(
      adConfiguration: mediationAdConfig, molocoBannerFactory: molocoBannerFactory,
      loadCompletionHandler: { _, _ in nil })

    let bannerAd = try XCTUnwrap(adEventDelegate.bannerAd)
    XCTAssertNotEqual(bannerAd.view, molocoBannerFactory.fakeMolocoBanner)
    XCTAssertFalse(bannerAd.view is FakeMolocoBanner)
  }

}
