import AdapterUnitTestKit
import MolocoSDK
import XCTest

@testable import MolocoAdapter

final class MolocoRewardedAdTest: XCTestCase {

  private enum Constants {
    /// An ad unit ID used in testing.
    static let adUnitID = "12345"
    /// A bid response received by the adapter to load the ad.
    static let bidResponse = "bid_response"
  }

  func testRewardedLoadSuccess() {
    let molocoRewardedFactory = FakeMolocoRewardedFactory(loadError: nil)
    let adapter = MolocoMediationAdapter(molocoRewardedFactory: molocoRewardedFactory)
    let mediationAdConfig = AUTKMediationRewardedAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Constants.adUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Constants.bidResponse

    AUTKWaitAndAssertLoadRewardedAd(adapter, mediationAdConfig)
    XCTAssertEqual(molocoRewardedFactory.adUnitIDUsedToCreateMolocoAd, Constants.adUnitID)
    XCTAssertEqual(
      molocoRewardedFactory.fakeMolocoRewarded?.bidResponseUsedToLoadMolocoAd, Constants.bidResponse
    )
  }

  func testRewardedLoad_loadsWithEmptyBidResponse_ifBidResponseIsMissing() {
    let molocoRewardedFactory = FakeMolocoRewardedFactory(loadError: nil)
    let adapter = MolocoMediationAdapter(molocoRewardedFactory: molocoRewardedFactory)
    let mediationAdConfig = AUTKMediationRewardedAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Constants.adUnitID]
    mediationAdConfig.credentials = credentials

    AUTKWaitAndAssertLoadRewardedAd(adapter, mediationAdConfig)
    XCTAssertEqual(molocoRewardedFactory.fakeMolocoRewarded?.bidResponseUsedToLoadMolocoAd, "")
  }

  func testRewardedLoad_loadsWithTestAdUnitForTestRequest() {
    let molocoRewardedFactory = FakeMolocoRewardedFactory(loadError: nil)
    let adapter = MolocoMediationAdapter(molocoRewardedFactory: molocoRewardedFactory)
    let mediationAdConfig = AUTKMediationRewardedAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Constants.adUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Constants.bidResponse
    mediationAdConfig.isTestRequest = true

    AUTKWaitAndAssertLoadRewardedAd(adapter, mediationAdConfig)
    XCTAssertEqual(
      molocoRewardedFactory.adUnitIDUsedToCreateMolocoAd, MolocoConstants.molocoTestAdUnitName)
  }

  func testRewardedLoadFailure_ifAdUnitIdIsMissing() {
    let molocoRewardedFactory = FakeMolocoRewardedFactory(loadError: nil)
    let adapter = MolocoMediationAdapter(molocoRewardedFactory: molocoRewardedFactory)
    let mediationAdConfig = AUTKMediationRewardedAdConfiguration()
    let credentials = AUTKMediationCredentials()
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Constants.bidResponse

    let expectedError = NSError(
      domain: MolocoConstants.adapterErrorDomain,
      code: MolocoAdapterErrorCode.invalidAdUnitId.rawValue)
    AUTKWaitAndAssertLoadRewardedAdFailure(adapter, mediationAdConfig, expectedError)
  }

  func testRewardedLoadFailure_ifMolocoFailsToLoad() {
    let loadError = NSError(domain: "moloco_sdk_domain", code: 1002)
    let adapter = MolocoMediationAdapter(
      molocoRewardedFactory: FakeMolocoRewardedFactory(loadError: loadError))
    let mediationAdConfig = AUTKMediationRewardedAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Constants.adUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Constants.bidResponse

    AUTKWaitAndAssertLoadRewardedAdFailure(adapter, mediationAdConfig, loadError)
  }

  func testRewardedShowTriggersImpression() {
    let molocoRewardedFactory = FakeMolocoRewardedFactory(loadError: nil)
    let adapter = MolocoMediationAdapter(molocoRewardedFactory: molocoRewardedFactory)
    let mediationAdConfig = AUTKMediationRewardedAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Constants.adUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Constants.bidResponse
    let adEventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, mediationAdConfig)

    adEventDelegate.rewardedAd?.present(from: UIViewController())

    XCTAssertNil(adEventDelegate.didFailToPresentError)
    XCTAssertEqual(adEventDelegate.willPresentFullScreenViewInvokeCount, 1)
    XCTAssertEqual(adEventDelegate.reportImpressionInvokeCount, 1)
  }

  func testRewardedShowFailurePopulatesPresentError() {
    let showError = NSError(domain: "moloco_sdk_domain", code: 1003)
    let molocoRewardedFactory = FakeMolocoRewardedFactory(loadError: nil, showError: showError)
    let adapter = MolocoMediationAdapter(molocoRewardedFactory: molocoRewardedFactory)
    let mediationAdConfig = AUTKMediationRewardedAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Constants.adUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Constants.bidResponse
    let adEventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, mediationAdConfig)

    adEventDelegate.rewardedAd?.present(from: UIViewController())

    XCTAssertNotNil(adEventDelegate.didFailToPresentError)
    let didFailToPresentError = (adEventDelegate.didFailToPresentError as? NSError)
    XCTAssertEqual(didFailToPresentError?.domain, "moloco_sdk_domain")
    XCTAssertEqual(didFailToPresentError?.code, 1003)
    XCTAssertEqual(adEventDelegate.willPresentFullScreenViewInvokeCount, 1)
    XCTAssertEqual(adEventDelegate.reportImpressionInvokeCount, 0)
  }

  func testRewardedShowFailureWhenNotReady() {
    let molocoRewardedFactory = FakeMolocoRewardedFactory(loadError: nil, isReadyToBeShown: false)
    let adapter = MolocoMediationAdapter(molocoRewardedFactory: molocoRewardedFactory)
    let mediationAdConfig = AUTKMediationRewardedAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Constants.adUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Constants.bidResponse
    let adEventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, mediationAdConfig)

    adEventDelegate.rewardedAd?.present(from: UIViewController())

    XCTAssertNotNil(adEventDelegate.didFailToPresentError)
    let didFailToPresentError = (adEventDelegate.didFailToPresentError as? NSError)
    XCTAssertEqual(didFailToPresentError?.domain, MolocoConstants.adapterErrorDomain)
    XCTAssertEqual(didFailToPresentError?.code, MolocoAdapterErrorCode.adNotReadyForShow.rawValue)
    XCTAssertEqual(adEventDelegate.willPresentFullScreenViewInvokeCount, 0)
    XCTAssertEqual(adEventDelegate.reportImpressionInvokeCount, 0)
  }

}
