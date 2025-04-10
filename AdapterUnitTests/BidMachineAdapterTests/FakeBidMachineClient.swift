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

final class FakeBidMachineClient: NSObject, BidMachineClient {

  private static let supportedFormats: [AdFormat] = [
    .banner, .interstitial, .rewarded, .native,
  ]

  var delegate: BidMachineAdDelegate?
  var sourceId: String?
  var isTestMode: Bool?
  var isCOPPA: Bool?
  var shouldBidMachineSucceedCreatingRequestConfig = true
  var shouldBidMachineSucceedCreatingAd = true
  var shouldBidMachineSucceedLoadingAd = true
  var shouldBidMachineSucceedPresenting = true

  func version() -> String {
    return BidMachineSdk.sdkVersion
  }

  func initialize(with sourceId: String, isTestMode: Bool, isCOPPA: Bool?) {
    self.sourceId = sourceId
    self.isTestMode = isTestMode
    self.isCOPPA = isCOPPA
  }

  func collectSignals(for adFormat: AdFormat, completionHandler: @escaping (String?) -> Void)
    throws(BidMachineAdapterError)
  {
    if !Self.supportedFormats.contains(adFormat) {
      throw BidMachineAdapterError(
        errorCode: .invalidRTBRequestParameters, description: "test description.")
    }
    completionHandler("Test signals")
  }

  func loadRTBBannerAd(
    with bidResponse: String,
    delegate: any BidMachineAdDelegate,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    if !shouldBidMachineSucceedCreatingRequestConfig {
      throw NSError(domain: "com.test.domain", code: 12345)
    }

    if !shouldBidMachineSucceedCreatingAd {
      completionHandler(NSError(domain: "com.test.domain", code: 12345))
      return
    }

    completionHandler(nil)
    if shouldBidMachineSucceedLoadingAd {
      delegate.didLoadAd(MockView())
    } else {
      delegate.didFailLoadAd(
        OCMockObject.mock(for: BidMachineBanner.self) as! BidMachineBanner,
        NSError(domain: "com.test.domain", code: 12345))
    }
  }

  func loadRTBInterstitialAd(
    with bidResponse: String, delegate: any BidMachine.BidMachineAdDelegate,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    if !shouldBidMachineSucceedCreatingRequestConfig {
      throw NSError(domain: "com.test.domain", code: 12345)
    }

    let fakeInterstitialAd =
      OCMockObject.mock(for: BidMachineInterstitial.self) as! BidMachineInterstitial

    if !shouldBidMachineSucceedCreatingAd {
      completionHandler(NSError(domain: "com.test.domain", code: 12345))
      return
    }

    completionHandler(nil)
    if shouldBidMachineSucceedLoadingAd {
      delegate.didLoadAd(fakeInterstitialAd)
      self.delegate = delegate
    } else {
      delegate.didFailLoadAd(
        OCMockObject.mock(for: BidMachineInterstitial.self) as! BidMachineInterstitial,
        NSError(domain: "com.test.domain", code: 12345))
    }
  }

  func present(_ interstitialAd: BidMachineInterstitial?, from viewController: UIViewController)
    throws(BidMachineAdapterError)
  {
    let fakeAd = OCMockObject.mock(for: BidMachineInterstitial.self) as! BidMachineInterstitial
    if shouldBidMachineSucceedPresenting {
      delegate?.willPresentScreen?(fakeAd)
      delegate?.didDismissAd?(fakeAd)
    } else {
      delegate?.didFailPresentAd?(fakeAd, NSError(domain: "com.test.domain", code: 12345))
    }
  }

  func loadRTBRewardedAd(
    with bidResponse: String, delegate: any BidMachine.BidMachineAdDelegate,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    if !shouldBidMachineSucceedCreatingRequestConfig {
      throw NSError(domain: "com.test.domain", code: 12345)
    }

    if !shouldBidMachineSucceedCreatingAd {
      completionHandler(NSError(domain: "com.test.domain", code: 12345))
      return
    }

    if shouldBidMachineSucceedLoadingAd {
      completionHandler(nil)
      delegate.didLoadAd(OCMockObject.mock(for: BidMachineRewarded.self) as! BidMachineRewarded)
      self.delegate = delegate
    } else {
      completionHandler(nil)
      delegate.didFailLoadAd(
        OCMockObject.mock(for: BidMachineRewarded.self) as! BidMachineRewarded,
        NSError(domain: "com.test.domain", code: 12345))
    }
  }

  func present(_ rewardedAd: BidMachineRewarded?, from viewController: UIViewController)
    throws(GoogleBidMachineAdapter.BidMachineAdapterError)
  {
    let fakeAd = OCMockObject.mock(for: BidMachineRewarded.self) as! BidMachineRewarded
    if shouldBidMachineSucceedPresenting {
      delegate?.willPresentScreen?(fakeAd)
      delegate?.didDismissAd?(fakeAd)
    } else {
      delegate?.didFailPresentAd?(fakeAd, NSError(domain: "com.test.domain", code: 12345))
    }
  }

  func loadRTBNativeAd(
    with bidResponse: String,
    delegate: any BidMachine.BidMachineAdDelegate,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    if !shouldBidMachineSucceedCreatingRequestConfig {
      throw NSError(domain: "com.test.domain", code: 12345)
    }

    if !shouldBidMachineSucceedCreatingAd {
      completionHandler(NSError(domain: "com.test.domain", code: 12345))
      return
    }

    if shouldBidMachineSucceedLoadingAd {
      completionHandler(nil)
      delegate.didLoadAd(OCMockObject.mock(for: BidMachineNative.self) as! BidMachineNative)
      self.delegate = delegate
    } else {
      completionHandler(nil)
      delegate.didFailLoadAd(
        OCMockObject.mock(for: BidMachineRewarded.self) as! BidMachineRewarded,
        NSError(domain: "com.test.domain", code: 12345))
    }
  }

}

final class MockView: UIView, BidMachineAdProtocol {

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  init() {
    super.init(frame: .zero)
  }

  var auctionInfo: any BidMachine.BidMachineAuctionResponseProtocol {
    return OCMockObject.mock(for: BidMachineAuctionResponseProtocol.self)
      as! BidMachineAuctionResponseProtocol
  }
  var requestInfo: any BidMachine.BidMachineRequestInfoProtocol {
    return OCMockObject.mock(for: BidMachineRequestInfoProtocol.self)
      as! BidMachineRequestInfoProtocol
  }
  var controller: UIViewController?
  var delegate: (any BidMachine.BidMachineAdDelegate)?
  var canShow: Bool = true
  func loadAd() {
  }
}
