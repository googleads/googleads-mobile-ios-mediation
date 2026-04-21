// Copyright 2025 Google LLC.
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
import BidMachine
import Testing
import XCTest

@testable import GoogleBidMachineAdapter

@MainActor
@Suite("BidMachine adapter RTB interstitial")
final class BidMachineRTBInterstitialAdTests {

  let client: FakeBidMachineClient

  init() {
    client = FakeBidMachineClient()
    BidMachineClientFactory.debugClient = client
  }

  @Test("RTB interstitial ad load succeeds")
  func loadInterstitial_succeeds() async {
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.watermark = "test watermark".data(using: .utf8)
    let adapter = BidMachineAdapter()

    AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)
  }

  @Test("RTB interstitial ad load fails for failing to create a request config")
  func loadInterstiital_fails_whenBidMachineFailsToCreateRequestConfig() async {
    client.shouldBidMachineSucceedCreatingRequestConfig = false

    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    let adapter = BidMachineAdapter()

    AUTKWaitAndAssertLoadInterstitialAdFailure(
      adapter, adConfig, NSError(domain: "com.test.domain", code: 12345))
  }

  @Test("RTB interstitial ad load fails for failing to create an ad")
  func loadInterstitial_fails_whenBidMachineFailsToCreateAd() async {
    client.shouldBidMachineSucceedCreatingAd = false

    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    let adapter = BidMachineAdapter()

    AUTKWaitAndAssertLoadInterstitialAdFailure(
      adapter, adConfig, NSError(domain: "com.test.domain", code: 12345))
  }

  @Test("RTB interstitial ad load fails for failing to return an ad")
  func loadInterstitial_fails_whenBidMachineFailsToReturnAd() async {
    client.shouldBidMachineSucceedLoadingAd = false

    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.watermark = "test watermark".data(using: .utf8)
    let adapter = BidMachineAdapter()

    AUTKWaitAndAssertLoadInterstitialAdFailure(
      adapter, adConfig, NSError(domain: "com.test.domain", code: 12345))
  }

  @Test("Presentation fails")
  func presentation_fails() async {
    client.shouldBidMachineSucceedPresenting = false

    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.watermark = "test watermark".data(using: .utf8)
    let adapter = BidMachineAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.interstitialAd)
    eventDelegate.interstitialAd?.present(from: UIViewController())

    XCTAssertNotNil(eventDelegate.didFailToPresentError)
  }

  @Test("Impression count")
  func impreesion_count() async {
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.watermark = "test watermark".data(using: .utf8)
    let adapter = BidMachineAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.interstitialAd)
    let adDelegate = adapter.interstitialAdLoader as? BidMachineAdDelegate
    adDelegate?.didTrackImpression?(client.mockView)

    XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1)
  }

  @Test("Click count")
  func click_count() async {
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.watermark = "test watermark".data(using: .utf8)
    let adapter = BidMachineAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.interstitialAd)
    let adDelegate = adapter.interstitialAdLoader as? BidMachineAdDelegate
    adDelegate?.didUserInteraction?(client.mockView)

    XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1)
  }

}

@MainActor
@Suite("BidMachine adapter waterfall interstitial")
final class BidMachineWaterfallInterstitialAdTests {

  let client: FakeBidMachineClient

  init() {
    client = FakeBidMachineClient()
    BidMachineClientFactory.debugClient = client
  }

  @Test("Waterfall interstitial ad load succeeds")
  func loadInterstitial_succeeds() async {
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    let adapter = BidMachineAdapter()

    AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)
  }

  @Test("Waterfall interstitial ad load fails for failing to create a request config")
  func loadnterstiital_fails_whenBidMachineFailsToCreateRequestConfig() async {
    client.shouldBidMachineSucceedCreatingRequestConfig = false

    let adConfig = AUTKMediationInterstitialAdConfiguration()
    let adapter = BidMachineAdapter()

    AUTKWaitAndAssertLoadInterstitialAdFailure(
      adapter, adConfig, NSError(domain: "com.test.domain", code: 12345))
  }

  @Test("Waterfall interstitial ad load fails for failing to create an ad")
  func loadInterstitial_fails_whenBidMachineFailsToCreateAd() async {
    client.shouldBidMachineSucceedCreatingAd = false

    let adConfig = AUTKMediationInterstitialAdConfiguration()
    let adapter = BidMachineAdapter()

    AUTKWaitAndAssertLoadInterstitialAdFailure(
      adapter, adConfig, NSError(domain: "com.test.domain", code: 12345))
  }

  @Test("Waterfall interstitial ad load fails for failing to return an ad")
  func loadInterstitial_fails_whenBidMachineFailsToReturnAd() async {
    client.shouldBidMachineSucceedLoadingAd = false

    let adConfig = AUTKMediationInterstitialAdConfiguration()
    let adapter = BidMachineAdapter()

    AUTKWaitAndAssertLoadInterstitialAdFailure(
      adapter, adConfig, NSError(domain: "com.test.domain", code: 12345))
  }

  @Test("Presentation fails")
  func presentation_fails() async {
    client.shouldBidMachineSucceedPresenting = false

    let adConfig = AUTKMediationInterstitialAdConfiguration()
    let adapter = BidMachineAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.interstitialAd)
    eventDelegate.interstitialAd?.present(from: UIViewController())

    XCTAssertNotNil(eventDelegate.didFailToPresentError)
  }

  @Test("Impression count")
  func impreesion_count() async {
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    let adapter = BidMachineAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.interstitialAd)
    let adDelegate = adapter.interstitialAdLoader as? BidMachineAdDelegate
    adDelegate?.didTrackImpression?(client.mockView)

    XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1)

  }

  @Test("Click count")
  func click_count() async {
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    let adapter = BidMachineAdapter()

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, adConfig)
    XCTAssertNotNil(eventDelegate.interstitialAd)
    let adDelegate = adapter.interstitialAdLoader as? BidMachineAdDelegate
    adDelegate?.didUserInteraction?(client.mockView)

    XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1)
  }

}
