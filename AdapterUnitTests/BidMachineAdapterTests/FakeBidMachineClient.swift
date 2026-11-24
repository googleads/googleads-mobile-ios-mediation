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

import BidMachine
import GoogleMobileAds
import UIKit

@testable import GoogleBidMachineAdapter

@MainActor
final class FakeBidMachineClient: NSObject, @preconcurrency BidMachineClient {

  let bannerAd = OCMockObject.mock(for: BidMachine.BannerView.self) as! BidMachine.BannerView
  let interstitialAd =
    OCMockObject.mock(for: BidMachine.InterstitialAd.self) as! BidMachine.InterstitialAd
  let rewardedAd = OCMockObject.mock(for: BidMachine.RewardedAd.self) as! BidMachine.RewardedAd
  let nativeAd = OCMockObject.mock(for: BidMachine.NativeAd.self) as! BidMachine.NativeAd

  var interstitialDelegate: BidMachine.InterstitialAdDelegate?
  var rewardedDelegate: BidMachine.RewardedAdDelegate?
  var sourceId: String?
  var isCOPPA: Bool?
  nonisolated(unsafe) var placementId: String?
  nonisolated(unsafe) var placementIds: [String]?
  var shouldBidMachineSucceedCreatingRequestConfig = true
  var shouldBidMachineSucceedCreatingAd = true
  var shouldBidMachineSucceedLoadingAd = true
  var shouldBidMachineSucceedPresenting = true

  nonisolated func version() -> String {
    return BidMachineSdk.sdkVersion
  }

  func initialize(with sourceId: String, isCOPPA: Bool?) {
    self.sourceId = sourceId
    self.isCOPPA = isCOPPA
  }

  nonisolated func collectSignals(
    placementIds: [String],
    completionHandler: @escaping (String?, NSError?) -> Void
  ) {
    self.placementIds = placementIds
    completionHandler("Test signals", nil)
  }

  func loadWaterfallBannerAd(
    size: AdSize, delegate: any BidMachine.BannerViewDelegate, placementId: String?,
    completionHandler: @escaping (BidMachine.BannerView?, NSError?) -> Void
  ) throws {
    self.placementId = placementId
    try completeLoad(with: bannerAd, completionHandler: completionHandler)
  }

  func loadRTBBannerAd(
    with bidResponse: String,
    size: AdSize,
    delegate: any BidMachine.BannerViewDelegate,
    watermark: String,
    completionHandler: @escaping (BidMachine.BannerView?, NSError?) -> Void
  ) throws {
    try completeLoad(with: bannerAd, completionHandler: completionHandler)
  }

  func loadWaterfallInterstitialAd(
    delegate: any BidMachine.InterstitialAdDelegate, placementId: String?,
    completionHandler: @escaping (BidMachine.InterstitialAd?, NSError?) -> Void
  ) throws {
    self.placementId = placementId
    interstitialDelegate = delegate
    try completeLoad(with: interstitialAd, completionHandler: completionHandler)
  }

  func loadRTBInterstitialAd(
    with bidResponse: String,
    delegate: any BidMachine.InterstitialAdDelegate,
    watermark: String,
    completionHandler: @escaping (BidMachine.InterstitialAd?, NSError?) -> Void
  ) throws {
    interstitialDelegate = delegate
    try completeLoad(with: interstitialAd, completionHandler: completionHandler)
  }

  func present(_ interstitialAd: BidMachine.InterstitialAd?, from viewController: UIViewController)
    throws(BidMachineAdapterError)
  {
    if shouldBidMachineSucceedPresenting {
      interstitialDelegate?.didPresent(self.interstitialAd)
      interstitialDelegate?.didDismiss(self.interstitialAd)
    } else {
      interstitialDelegate?.didFailPresent(self.interstitialAd, error: Self.fakePresentError())
    }
  }

  func loadWaterfallRewardedAd(
    delegate: any BidMachine.RewardedAdDelegate,
    placementId: String?,
    completionHandler: @escaping (BidMachine.RewardedAd?, NSError?) -> Void
  ) throws {
    self.placementId = placementId
    rewardedDelegate = delegate
    try completeLoad(with: rewardedAd, completionHandler: completionHandler)
  }

  func loadRTBRewardedAd(
    with bidResponse: String,
    delegate: any BidMachine.RewardedAdDelegate,
    watermark: String,
    completionHandler: @escaping (BidMachine.RewardedAd?, NSError?) -> Void
  ) throws {
    rewardedDelegate = delegate
    try completeLoad(with: rewardedAd, completionHandler: completionHandler)
  }

  func present(_ rewardedAd: BidMachine.RewardedAd?, from viewController: UIViewController)
    throws(GoogleBidMachineAdapter.BidMachineAdapterError)
  {
    if shouldBidMachineSucceedPresenting {
      rewardedDelegate?.didPresent(self.rewardedAd)
      rewardedDelegate?.didDismiss(self.rewardedAd)
    } else {
      rewardedDelegate?.didFailPresent(self.rewardedAd, error: Self.fakePresentError())
    }
  }

  func loadRTBNativeAd(
    with bidResponse: String,
    delegate: any BidMachine.NativeAdDelegate,
    watermark: String,
    completionHandler: @escaping (BidMachine.NativeAd?, NSError?) -> Void
  ) throws {
    try completeLoad(with: nativeAd, completionHandler: completionHandler)
  }

  func loadWaterfallNativeAd(
    delegate: any BidMachine.NativeAdDelegate,
    placementId: String?,
    completionHandler: @escaping (BidMachine.NativeAd?, NSError?) -> Void
  ) throws {
    self.placementId = placementId
    try completeLoad(with: nativeAd, completionHandler: completionHandler)
  }

  /// Completes a load with the ad or with the failure the test asked for.
  private func completeLoad<Ad>(
    with ad: Ad,
    completionHandler: (Ad?, NSError?) -> Void
  ) throws {
    if !shouldBidMachineSucceedCreatingRequestConfig {
      throw NSError(domain: "com.test.domain", code: 12345)
    }

    if shouldBidMachineSucceedCreatingAd && shouldBidMachineSucceedLoadingAd {
      completionHandler(ad, nil)
    } else {
      completionHandler(nil, NSError(domain: "com.test.domain", code: 12345))
    }
  }

  private static func fakePresentError() -> BidMachineError {
    return OCMockObject.mock(for: BidMachineError.self) as! BidMachineError
  }

}
