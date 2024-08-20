// Copyright 2024 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import AdapterUnitTestKit
import MolocoSDK
import XCTest

@testable import MolocoAdapter

final class MolocoInterstitialAdTest: XCTestCase {

  /// A bid response received by the adapter to load the ad.
  let bidResponse = "bid_response"

  /// An ad unit ID used in testing.
  let adUnitID = "12345"

  func testInterstitialLoadSuccess() {
    let molocoInterstitialFactory = FakeMolocoInterstitialFactory(loadError: nil)
    let adapter = MolocoMediationAdapter(
      molocoInterstitialFactory: molocoInterstitialFactory)
    let mediationAdConfig = AUTKMediationInterstitialAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: adUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = bidResponse

    AUTKWaitAndAssertLoadInterstitialAd(adapter, mediationAdConfig)
    XCTAssertEqual(molocoInterstitialFactory.adUnitIDUsedToCreateMolocoAd, adUnitID)
    XCTAssertEqual(
      molocoInterstitialFactory.getCreatedMolocoInterstital()?.bidResponseUsedToLoadMolocoAd,
      bidResponse)
  }

  func testInterstitialLoad_loadsWithEmptyBidResponse_ifBidResponseIsMissing() {
    let molocoInterstitialFactory = FakeMolocoInterstitialFactory(loadError: nil)
    let adapter = MolocoMediationAdapter(molocoInterstitialFactory: molocoInterstitialFactory)
    let mediationAdConfig = AUTKMediationInterstitialAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: adUnitID]
    mediationAdConfig.credentials = credentials

    AUTKWaitAndAssertLoadInterstitialAd(adapter, mediationAdConfig)
    XCTAssertEqual(
      molocoInterstitialFactory.getCreatedMolocoInterstital()?.bidResponseUsedToLoadMolocoAd, "")
  }

  func testInterstitialLoad_loadsWithTestAdUnitForTestRequest() {
    let molocoInterstitialFactory = FakeMolocoInterstitialFactory(loadError: nil)
    let adapter = MolocoMediationAdapter(
      molocoInterstitialFactory: molocoInterstitialFactory)
    let mediationAdConfig = AUTKMediationInterstitialAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: adUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = bidResponse
    mediationAdConfig.isTestRequest = true

    AUTKWaitAndAssertLoadInterstitialAd(adapter, mediationAdConfig)
    XCTAssertEqual(
      molocoInterstitialFactory.adUnitIDUsedToCreateMolocoAd, MolocoConstants.molocoTestAdUnitName)
  }

  func testInterstitialLoadFailure_ifAdUnitIdIsMissing() {
    let adapter = MolocoMediationAdapter(
      molocoInterstitialFactory: FakeMolocoInterstitialFactory(loadError: nil))
    let mediationAdConfig = AUTKMediationInterstitialAdConfiguration()
    let credentials = AUTKMediationCredentials()
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = bidResponse

    let expectedError = NSError(
      domain: MolocoConstants.adapterErrorDomain,
      code: MolocoAdapterErrorCode.invalidAdUnitId.rawValue)
    AUTKWaitAndAssertLoadInterstitialAdFailure(adapter, mediationAdConfig, expectedError)
  }

  func testInterstitialLoadFailure_ifMolocoFailsToLoad() {
    let loadError = NSError(domain: "moloco_sdk_domain", code: 1002)
    let adapter = MolocoMediationAdapter(
      molocoInterstitialFactory: FakeMolocoInterstitialFactory(loadError: loadError))
    let mediationAdConfig = AUTKMediationInterstitialAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: adUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = bidResponse

    AUTKWaitAndAssertLoadInterstitialAdFailure(adapter, mediationAdConfig, loadError)
  }

  func testIntestitialPresentSuccessAndSubsequentLifecycleEvents() {
    let adapter = MolocoMediationAdapter(
      molocoInterstitialFactory: FakeMolocoInterstitialFactory(
        loadError: nil, isReadyToBeShown: true, showShallSucceed: true))
    let mediationAdConfig = AUTKMediationInterstitialAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: adUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = bidResponse
    let adEventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, mediationAdConfig)

    adEventDelegate.interstitialAd?.present(from: UIViewController())

    XCTAssertEqual(adEventDelegate.willPresentFullScreenViewInvokeCount, 1)
    XCTAssertEqual(adEventDelegate.reportImpressionInvokeCount, 1)
    XCTAssertEqual(adEventDelegate.reportClickInvokeCount, 1)
    XCTAssertEqual(adEventDelegate.didDismissFullScreenViewInvokeCount, 1)
  }

  func testIntestitialPresentFailure_ifAdIsNotReady() {
    let adapter = MolocoMediationAdapter(
      molocoInterstitialFactory: FakeMolocoInterstitialFactory(
        loadError: nil, isReadyToBeShown: false))
    let mediationAdConfig = AUTKMediationInterstitialAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: adUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = bidResponse
    let adEventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, mediationAdConfig)

    adEventDelegate.interstitialAd?.present(from: UIViewController())

    let didFailToPresentError = (adEventDelegate.didFailToPresentError as? NSError)
    XCTAssertEqual(
      didFailToPresentError?.domain,
      MolocoConstants.adapterErrorDomain)
    XCTAssertEqual(
      didFailToPresentError?.code,
      MolocoAdapterErrorCode.adNotReadyForShow.rawValue)
  }

  func testDidFailToPresentIsInvokedWithMolocoError_ifMolocoFailsToShowAdWithError() {
    let showError = NSError(domain: "moloco_sdk_domain", code: 1003)
    let adapter = MolocoMediationAdapter(
      molocoInterstitialFactory: FakeMolocoInterstitialFactory(
        loadError: nil, isReadyToBeShown: true, showShallSucceed: false, showError: showError))
    let mediationAdConfig = AUTKMediationInterstitialAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: adUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = bidResponse
    let adEventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, mediationAdConfig)

    adEventDelegate.interstitialAd?.present(from: UIViewController())

    let didFailToPresentError = (adEventDelegate.didFailToPresentError as? NSError)
    XCTAssertEqual(didFailToPresentError?.domain, "moloco_sdk_domain")
    XCTAssertEqual(didFailToPresentError?.code, 1003)
  }

  func testDidFailToPresentIsInvokedWithAdapterError_ifMolocoFailsToShowAdButWithNoError() {
    let adapter = MolocoMediationAdapter(
      molocoInterstitialFactory: FakeMolocoInterstitialFactory(
        loadError: nil, isReadyToBeShown: true, showShallSucceed: false, showError: nil))
    let mediationAdConfig = AUTKMediationInterstitialAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: adUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = bidResponse
    let adEventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, mediationAdConfig)

    adEventDelegate.interstitialAd?.present(from: UIViewController())

    let didFailToPresentError = (adEventDelegate.didFailToPresentError as? NSError)
    XCTAssertEqual(didFailToPresentError?.domain, MolocoConstants.adapterErrorDomain)
    XCTAssertEqual(didFailToPresentError?.code, MolocoAdapterErrorCode.adFailedToShow.rawValue)
  }
}
