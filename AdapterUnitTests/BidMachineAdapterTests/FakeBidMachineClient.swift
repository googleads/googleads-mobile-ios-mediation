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

  var sourceId: String?
  var isTestMode: Bool?
  var isCOPPA: Bool?
  var shouldBidMachineSucceedCreatingRequestConfig = true
  var shouldBidMachineSucceedCreatingAd = true
  var shouldBidMachineSucceedLoadingAd = true

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
