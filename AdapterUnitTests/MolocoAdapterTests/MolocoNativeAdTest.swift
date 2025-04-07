import AdapterUnitTestKit
import MolocoSDK
import XCTest

@testable import MolocoAdapter

final class MolocoNativeAdTest: XCTestCase {

  /// An ad unit ID used in testing.
  static let testAdUnitID = "12345"
  /// A bid response received by the adapter to load the ad.
  static let testBidResponse = "bid_response"

  func loadNativeAd() -> AUTKMediationNativeAdEventDelegate {
    let molocoNativeFactory = FakeMolocoNativeFactory(loadError: nil)
    let adapter = MolocoMediationAdapter(molocoNativeFactory: molocoNativeFactory)
    let mediationAdConfig = AUTKMediationNativeAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Self.testAdUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Self.testBidResponse

    let nativeAdEventDelegate = AUTKWaitAndAssertLoadNativeAd(adapter, mediationAdConfig)
    XCTAssertEqual(molocoNativeFactory.adUnitIDUsedToCreateMolocoAd, Self.testAdUnitID)
    XCTAssertEqual(
      molocoNativeFactory.fakeMolocoNative?.bidResponseUsedToLoadMolocoAd, Self.testBidResponse
    )
    return nativeAdEventDelegate
  }

  func testNativeLoadSuccess() {
    XCTAssertNotNil(loadNativeAd())
  }

  func testNativeLoadFailure_ifBidResponseIsMissing() {
    let molocoNativeFactory = FakeMolocoNativeFactory(loadError: nil)
    let adapter = MolocoMediationAdapter(molocoNativeFactory: molocoNativeFactory)
    let mediationAdConfig = AUTKMediationNativeAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Self.testAdUnitID]
    mediationAdConfig.credentials = credentials

    let expectedError = NSError(
      domain: MolocoConstants.adapterErrorDomain,
      code: MolocoAdapterErrorCode.nilBidResponse.rawValue)
    AUTKWaitAndAssertLoadNativeAdFailure(adapter, mediationAdConfig, expectedError)
  }

  func testNativeLoad_loadsWithTestAdUnitForTestRequest() {
    let molocoNativeFactory = FakeMolocoNativeFactory(loadError: nil)
    let adapter = MolocoMediationAdapter(molocoNativeFactory: molocoNativeFactory)
    let mediationAdConfig = AUTKMediationNativeAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Self.testAdUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.isTestRequest = true

    let expectedError = NSError(
      domain: MolocoConstants.adapterErrorDomain,
      code: MolocoAdapterErrorCode.nilBidResponse.rawValue)
    AUTKWaitAndAssertLoadNativeAdFailure(adapter, mediationAdConfig, expectedError)
  }

  func testNativeLoadFailure_ifAdUnitIdIsMissing() {
    let molocoNativeFactory = FakeMolocoNativeFactory(loadError: nil)
    let adapter = MolocoMediationAdapter(molocoNativeFactory: molocoNativeFactory)
    let mediationAdConfig = AUTKMediationNativeAdConfiguration()
    let credentials = AUTKMediationCredentials()
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Self.testBidResponse

    let expectedError = NSError(
      domain: MolocoConstants.adapterErrorDomain,
      code: MolocoAdapterErrorCode.invalidAdUnitId.rawValue)
    AUTKWaitAndAssertLoadNativeAdFailure(adapter, mediationAdConfig, expectedError)
  }

  func testNativeLoadFailure_ifMolocoFailsToLoad() {
    let loadError = NSError(domain: "moloco_sdk_domain", code: 1002)
    let adapter = MolocoMediationAdapter(
      molocoNativeFactory: FakeMolocoNativeFactory(loadError: loadError))
    let mediationAdConfig = AUTKMediationNativeAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Self.testAdUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Self.testBidResponse

    AUTKWaitAndAssertLoadNativeAdFailure(adapter, mediationAdConfig, loadError)
  }

  func testNativeAdCorrectlyTriggersImpressionAndClick() {
    let molocoNativeFactory = FakeMolocoNativeFactory(loadError: nil)
    let adapter = MolocoMediationAdapter(molocoNativeFactory: molocoNativeFactory)
    let mediationAdConfig = AUTKMediationNativeAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Self.testAdUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Self.testBidResponse
    let adEventDelegate = AUTKWaitAndAssertLoadNativeAd(adapter, mediationAdConfig)
    MolocoTestUtils.flushMainThread(self)
    XCTAssertNotNil(adEventDelegate)
    adEventDelegate.nativeAd?.didRecordImpression?()
    adEventDelegate.nativeAd?.didRecordClickOnAsset?(
      with: .bodyAsset, view: UIView(), viewController: UIViewController())

    XCTAssertNil(adEventDelegate.didFailToPresentError)
    XCTAssertEqual(adEventDelegate.reportImpressionInvokeCount, 1)
    XCTAssertEqual(adEventDelegate.reportClickInvokeCount, 1)
  }

  func testIcon() {
    let eventDelegate = loadNativeAd()
    let nativeAd = eventDelegate.nativeAd
    XCTAssertTrue(nativeAd?.icon is NativeAdImage)
  }

  func testMediaView() {
    let eventDelegate = loadNativeAd()
    let nativeAd = eventDelegate.nativeAd
    XCTAssertTrue(nativeAd?.mediaView is UIView)
  }

  func testHeadline() {
    let eventDelegate = loadNativeAd()
    let nativeAd = eventDelegate.nativeAd
    XCTAssertEqual(nativeAd?.headline, FakeAssetValues.title)
  }

  func testBody() {
    let eventDelegate = loadNativeAd()
    let nativeAd = eventDelegate.nativeAd
    XCTAssertEqual(nativeAd?.body, FakeAssetValues.description)
  }

  func testCallToAction() {
    let eventDelegate = loadNativeAd()
    let nativeAd = eventDelegate.nativeAd
    XCTAssertEqual(nativeAd?.callToAction, FakeAssetValues.ctaTitle)
  }

  func testAdvertiser() {
    let eventDelegate = loadNativeAd()
    let nativeAd = eventDelegate.nativeAd
    XCTAssertEqual(nativeAd?.advertiser, FakeAssetValues.sponsorText)
  }

  func testStarRating() {
    let eventDelegate = loadNativeAd()
    let nativeAd = eventDelegate.nativeAd
    XCTAssertEqual(nativeAd?.starRating?.doubleValue, FakeAssetValues.rating)
  }

  func testUnusedNativeAdMetaData() {
    let eventDelegate = loadNativeAd()
    let nativeAd = eventDelegate.nativeAd

    XCTAssertNil(nativeAd?.adChoicesView)
    XCTAssertNil(nativeAd?.extraAssets)
    XCTAssertNil(nativeAd?.price)
    XCTAssertNil(nativeAd?.store)
  }

}
